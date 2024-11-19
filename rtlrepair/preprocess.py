# Copyright 2022 The Regents of the University of California
# released under BSD 3-Clause License
# author: Kevin Laeufer <laeufer@cs.berkeley.edu>
import os
import shutil
import re
from dataclasses import dataclass
from pathlib import Path
import subprocess

#from benchmarks import Benchmark, get_other_sources
from rtlrepair import parse_verilog, serialize
from rtlrepair.utils import ensure_block
from rtlrepair.visitor import AstVisitor
import pyverilog.vparser.ast as vast

import claude_api

def _same_warnings(old: list, new: list) -> bool:
    return {_warning_sig(w) for w in old} == {_warning_sig(w) for w in new}


def _check_for_verilator():
    r = subprocess.run(["verilator", "-version"], stdout=subprocess.PIPE)
    assert r.returncode == 0, "failed to find verilator"


# while WIDTH warnings can be indicative of a bug, they are generally too noisy to deal with easily
# CASEOVERLAP might be an interesting warning to deal with
# PINCONNECTEMPTY better be optimized
_ignore_warnings = {"DECLFILENAME", "ASSIGNDLY", "UNUSED", "EOFNEWLINE", "WIDTH", "CASEOVERLAP", "STMTDLY",
                    "TIMESCALEMOD", "MULTIDRIVEN", "UNDRIVEN", "LITENDIAN", 
                    "PINCONNECTEMPTY", "PINMISSING", "UNOPTFLAT", "SYNCASYNCNET", "SELRANGE", "UNSIGNED", "CMPCONST"}
_ignore_errors = "Unsupported tristate construct"
_verilator_lint_flags = ["--lint-only", "-Wno-fatal", "-Wall"] + [f"-Wno-{w}" for w in _ignore_warnings]
_verilator_warn = re.compile(r"%Warning-([A-Z]+): ([^:]+):(\d+):(\d+):([^\n]+)")

_verilator_err = re.compile(r"%Error: (\S+):(\d+):\d+: (.+)")
_verilator_err2 = re.compile(r"%Error-([A-Z]+): ([^:]+):(\d+):(\d+):([^\n]+)")

def remove_blank_lines(lines: list) -> list:
    return [ll.strip() for ll in lines if len(ll.strip()) > 0]


@dataclass
class LintWarning:
    tpe: str
    filename: Path
    line: int
    col: int
    msg: str


def _warning_sig(warn: LintWarning) -> str:
    return f"{warn.tpe}@{warn.line}"

def parse_linter_output(lines: list) -> list:
    out = []
    for line in lines:
        m = _verilator_warn.search(line)
        if m is not None:
            (tpe, filename, line, col, msg) = m.groups()
            out.append(LintWarning(tpe, Path(filename), int(line), int(col), msg.strip()))
        elif len(out) > 0:
            out[0].msg += "\n" + line
    return out

def run_linter(iteration: int, filename: Path, preprocess_dir: Path, include: Path):
    _check_for_verilator()
    cmd = ["verilator"] + _verilator_lint_flags + [f"-I{include.resolve()}" if include else "", str(filename.resolve())]
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    info = (r.stdout + r.stderr).decode('utf-8').splitlines()
    info = remove_blank_lines(info)
    if len(info) == 0:
        return [], []

    with open(preprocess_dir / f"{iteration}_linter.txt", "w") as f:
        f.write("\n".join(info) + "\n")

    errors = [line for line in info if (re.match(_verilator_err, line) or re.match(_verilator_err2, line) and _ignore_errors not in line)]
    warnings = parse_linter_output(info)
    return warnings, errors

def preprocess(working_dir: Path, verilog_path: Path, include: Path, logger):
    assert working_dir.exists()
    preprocess_dir = working_dir / "0_preprocess"
    if preprocess_dir.exists():
        shutil.rmtree(preprocess_dir)
    os.mkdir(preprocess_dir)

    change_count = 0
    previous_warnings = []
    filename = verilog_path
    logger.info(filename)
    for ii in range(5):
        warnings, errors = run_linter(ii, filename, preprocess_dir, include)
        logger.info(warnings)
        logger.info(errors)
        if errors:
            new_code, fix = claude_api.api_syntax(filename, errors, None, logger)
            logger.info(fix)
            if fix:
                fixed_filename = preprocess_dir / f"{filename.stem}.{ii}.v"
                with open(fixed_filename, "w") as f:
                    f.write(new_code)
                filename = fixed_filename
                change_count += 1
                logger.info(filename.stem)
            else:
                break
        elif warnings:
            if "IMPLICIT" in warnings[0].tpe:
                new_code, fix = claude_api.api_syntax(filename, warnings[0].msg, None, logger)
                logger.info(fix)
                if fix:
                    fixed_filename = preprocess_dir / f"{filename.stem}.{ii}.v"
                    with open(fixed_filename, "w") as f:
                        f.write(new_code)
                    filename = fixed_filename
                    change_count += 1
                    logger.info(filename)
                    logger.info(filename.stem)
                else:
                    break

            elif change_count > 0: 
            # check to see if warnings actually changed or if we are at a fixed point
                if _same_warnings(previous_warnings, warnings):
                        break
            else:
                fixed_filename = preprocess_dir / f"{filename.stem}.{ii}.v"
                ast = parse_verilog(filename, None)
                fixer = LintFixer(warnings)
                change_count += fixer.apply(ast)
                with open(fixed_filename, "w") as f:
                    f.write(serialize(ast))
                filename = fixed_filename
                previous_warnings = warnings
        else:
            break

    return filename, change_count

_fix_warnings = {"CASEINCOMPLETE", "BLKSEQ", "LATCH", "COMBDLY"}


def filter_warnings(warnings: list) -> list:
    out = []
    for warn in warnings:
        if warn.tpe in _fix_warnings:
            out.append(warn)
        elif warn.tpe not in _ignore_warnings:
            raise RuntimeWarning(f"Unknown warning type: {warn}")
    return out


_latch_re = re.compile(r"Latch inferred for signal '([^']+)'")

# TODO: maybe change back to 0
_default_value = "'d0"

def assign_latch_signal(latch_warning: LintWarning):
    m = _latch_re.search(latch_warning.msg)
    assert m is not None, latch_warning.msg
    signal_parts = m.group(1).split(".")
    ident = vast.Identifier(signal_parts[-1].strip())
    return vast.BlockingSubstitution(vast.Lvalue(ident), vast.Rvalue(vast.IntConst(_default_value)))


class LintFixer(AstVisitor):
    """ This class addressed the following lint warning:
        - CASEINCOMPLETE: Case values incompletely covered (example pattern 0x5)
        - LATCH
        - BLKSEQ: Blocking assignment '=' in sequential logic process
        - COMBDLY: Non-blocking assignment \'<=\' in combinational logic process
    """

    def __init__(self, warnings: list):
        super().__init__()
        self.warnings = filter_warnings(warnings)
        self.change_count = 0

    def _find_warnings(self, tpe: str, line: int):
        out = []
        for warn in self.warnings:
            if warn.tpe == tpe and warn.line == line:
                out.append(warn)
        return out

    def apply(self, ast: vast.Source) -> int:
        self.change_count = 0
        self.visit(ast)
        return self.change_count

    def visit_CaseStatement(self, node: vast.CaseStatement):
        node = self.generic_visit(node)
        # add empty default case to fix incomplete cases (this will reveal LATCH warnings in verilator)
        if len(self._find_warnings("CASEINCOMPLETE", node.lineno)) > 0:
            default = vast.Case(None, vast.Block(tuple([])))
            node.caselist = tuple(list(node.caselist) + [default])
            self.change_count += 1
        return node

    def visit_Always(self, node: vast.Always):
        node = self.generic_visit(node)
        # add a default assignment if a latch is unintentionally created
        latches = self._find_warnings("LATCH", node.lineno)
        if len(latches) == 0:
            return node
        assignments = [assign_latch_signal(ll) for ll in latches]
        stmt = ensure_block(node.statement)
        stmt.statements = tuple(assignments + list(stmt.statements))
        node.statement = stmt
        self.change_count += len(assignments)
        return node

    def visit_BlockingSubstitution(self, node: vast.BlockingSubstitution):
        node = self.generic_visit(node)
        # change to non-blocking if we got a blocking assignment in sequential logic process
        if len(self._find_warnings("BLKSEQ", node.lineno)) > 0:
            node = vast.NonblockingSubstitution(node.left, node.right, node.ldelay, node.rdelay, node.lineno)
            self.change_count += 1
        return node

    def visit_NonblockingSubstitution(self, node: vast.NonblockingSubstitution):
        node = self.generic_visit(node)
        # change to blocking if we got a non-blocking assignment in combinatorial logic process
        if len(self._find_warnings("COMBDLY", node.lineno)) > 0:
            node = vast.BlockingSubstitution(node.left, node.right, node.ldelay, node.rdelay, node.lineno)
            self.change_count += 1
        return node
    