import os
import pyverilog
from pyverilog.vparser.ast import *
from pyverilog.vparser.parser import parse
from pyverilog.ast_code_generator.codegen import ASTCodeGenerator

"""

| 函数/类                 | 函数说明
| ---------------------- | ------------------------------------------
| `AstParser`            | 把 Verilog 文件解析成 AST(Source 根节点).
| `AstGenerator`         | 把 AST 重新变回 `.v` 源码.
| `getParentModule`      | 给定任意节点,找它所在的 module 名.
| `getAllModules`        | 返回 AST 里所有 module 名字.
| `getModuleDefAstNodes` | 按名字列表把 AST 中对应 ModuleDef 节点抠出来.
| `mapFileToModule`      | 建立"文件 → 内部 module 名列表"反向索引.
| `getIOSignals`         | 提取 AST 中所有模块的**端口线名**.
| `getSpsLineno`         | 根据可疑节点 ID 反查**原始文件行号 + 源码内容**,用于打印报告或缺陷定位.

"""


class AstParser:
    """解析 Verilog 文件,返回 AST."""

    def __init__(self, args) -> None:
        self.ast, _ = parse(
            args["filelist"],  # 文件路径
            preprocess_include=args["include"],  # -I 目录
            preprocess_define=args["define"],  # -D 宏定义
        )

    def getAst(self):
        return self.ast


class AstGenerator:
    """把 AST 转成 Verilog 代码字符串."""

    def __init__(self) -> None:
        self.generator = ASTCodeGenerator()

    def visit(self, ast):
        code = self.generator.visit(ast)
        return code


def getParentModule(parentAstNode, astNode, currentModule=None):
    """给定任意的AST节点, 返回其所属的module 名称."""
    if isinstance(parentAstNode, ModuleDef):
        currentModule = parentAstNode.name
    if parentAstNode == astNode:
        return currentModule
    for cn in parentAstNode.children():
        retModule = getParentModule(cn, astNode, currentModule)
        if retModule:
            return retModule
    return None


def getAllModules(vast):
    """递归遍历 AST, 返回所有 module 名称列表."""
    if isinstance(vast, ModuleDef):
        return [vast.name]
    allModules = []
    for childAst in vast.children():
        childModules = getAllModules(childAst)
        allModules.extend(childModules)
    return allModules


def getModuleDefAstNodes(sourceAst, moduleNames):
    """从 AST 里找出指定名称的 module 定义节点,返回节点列表."""
    retModules = []
    assert isinstance(sourceAst, Source)
    for module in sourceAst.description.definitions:
        assert isinstance(module, ModuleDef)
        if module.name in moduleNames:
            retModules.append(module)
    return tuple(retModules)


def mapFileToModule(args):
    """对给定的 Verilog 文件列表,返回文件到 module 名称列表的映射字典."""
    fileToModulesMap = {}
    for srcFile in args["filelist"]:
        try:
            tmpArgs = {
                "filelist": [srcFile],
                "include": args["include"],
                "define": args["define"],
            }
            tmpAst = AstParser(tmpArgs).getAst()
            tmpModules = getAllModules(tmpAst)
            fileToModulesMap[srcFile] = tmpModules
        except Exception as e:
            pass
    return fileToModulesMap


def getSrcFileAndModules(module, fileToModulesMap, vast):
    retFile, retModuleNames = "", []
    for srcFile, modules in fileToModulesMap.items():
        if module in modules:
            retFile = srcFile
            retModuleNames = modules
            break
    assert retFile != ""
    retModules = getModuleDefAstNodes(vast, retModuleNames)
    return retFile, retModules


def getIOSignals(vast, logger):
    """提取一个 Source 里所有模块的端口名列表
    Traverse the AST to find all modules and extract their I/O signals.
    :param ast: The top-level AST node (Source).
    :return: A dictionary mapping module names to their I/O signals.
    """
    # Check if the node is a Source and has a description containing ModuleDefs
    if isinstance(vast, Source):
        for definition in vast.description.definitions:
            if isinstance(definition, ModuleDef):
                # logger.info("{}".format(vast.description.definitions))
                # Collect all signal names for this module
                signals = []
                if definition.portlist:
                    for port in definition.portlist.ports:
                        # logger.info("{}".format(port.first))
                        if isinstance(port, Ioport):
                            signals.append(port.first.name)
                        elif isinstance(port, Port):
                            signals.append(port.name)
    logger.info("{}".format(signals))
    return signals


def getSpsLineno(ast, nodeIds, fileToModulesMap, lineGapMap, logger):
    """给定 AST 和可疑节点 ID 列表,返回可疑节点所在的文件和行号列表."""
    spsLinenos = set()
    spsCodes = []
    t1 = [ast]
    modules = []
    while len(t1) > 0:
        t = t1.pop(0)
        if isinstance(t, ModuleDef):
            modules.append(t)
        elif isinstance(t, Source) or isinstance(t, Description):
            for childAst in t.children():
                t1.append(childAst)
    for module in modules:
        currentFile = None
        for fileName, modules2 in fileToModulesMap.items():
            if module.name in modules2:
                currentFile = fileName
        t2 = [module]
        while len(t2) > 0:
            t = t2.pop(0)
            #         if t.nodeid in nodeIds:
            #             spsLinenos.add((currentFile, t.lineno-lineGapMap[currentFile]))
            #         for childAst in t.children():
            #             t2.append(childAst)
            # return spsLinenos
            if t.nodeid in nodeIds:
                lineno = t.lineno - lineGapMap[currentFile]
                line_info = (currentFile, lineno)  # tuple for file and line no.
                printed_lines = set()
                if line_info not in spsLinenos:  # check whether been added
                    spsLinenos.add(line_info)
                    # check whether the line been printed
                    if lineno not in printed_lines:
                        try:
                            with open(currentFile, "r") as file:
                                lines = file.readlines()
                                if lineno <= len(lines):
                                    spsCode = lines[lineno - 1].strip()
                                    spsCodes.append((spsCode))  # Store the line content
                                    logger.info(
                                        "Suspicious line in {}: Line {}: {}".format(
                                            currentFile, lineno, spsCode
                                        )
                                    )
                                    printed_lines.add(lineno)  # label as printed
                                else:
                                    logger.error(
                                        "Line number {} is out of range for file {}.".format(
                                            lineno, currentFile
                                        )
                                    )
                        except FileNotFoundError:
                            logger.error("File not found: {}".format(currentFile))
                        except Exception as e:
                            logger.error(
                                "An error occurred while reading {}: {}".format(
                                    currentFile, e
                                )
                            )
            for childAst in t.children():
                t2.append(childAst)
    return spsLinenos, list(set(spsCodes))
