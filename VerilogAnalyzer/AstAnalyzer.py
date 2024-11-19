import os
import pyverilog
from pyverilog.vparser.ast import *
from pyverilog.vparser.parser import parse
from pyverilog.ast_code_generator.codegen import ASTCodeGenerator

class AstParser:
    def __init__(self, args) -> None:
        self.ast, _ = parse(args["filelist"],
                        preprocess_include=args["include"],
                        preprocess_define=args["define"])

    def getAst(self):
        return self.ast

class AstGenerator:
    def __init__(self) -> None:
        self.generator = ASTCodeGenerator()
    
    def visit(self, ast):
        code = self.generator.visit(ast)
        return code
    

def getParentModule(parentAstNode, astNode, currentModule=None):
    if isinstance(parentAstNode, ModuleDef):
        currentModule = parentAstNode.name
    if parentAstNode == astNode:
        return currentModule
    for cn in parentAstNode.children():
        retModule = getParentModule(cn, astNode, currentModule)
        if retModule: return retModule
    return None

def getAllModules(vast):
    if isinstance(vast, ModuleDef):
        return [vast.name]
    allModules = []
    for childAst in vast.children():
        childModules = getAllModules(childAst)
        allModules.extend(childModules)
    return allModules

def getModuleDefAstNodes(sourceAst, moduleNames):
    retModules = []
    assert isinstance(sourceAst, Source)
    for module in sourceAst.description.definitions:
        assert isinstance(module, ModuleDef)
        if module.name in moduleNames:
            retModules.append(module)
    return tuple(retModules)

def mapFileToModule(args):
    fileToModulesMap = {}
    for srcFile in args["filelist"]:
        try:
            tmpArgs = {"filelist":[srcFile], "include":args["include"], "define":args["define"]}
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

def getIOSignals(vast,logger):
    """
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
                                with open(currentFile, 'r') as file:
                                    lines = file.readlines()
                                    if lineno <= len(lines):
                                        spsCode = lines[lineno - 1].strip()
                                        spsCodes.append((spsCode))  # Store the line content
                                        logger.info("Suspicious line in {}: Line {}: {}".format(currentFile, lineno, spsCode))
                                        printed_lines.add(lineno)  # label as printed
                                    else:
                                        logger.error("Line number {} is out of range for file {}.".format(lineno, currentFile))
                            except FileNotFoundError:
                                logger.error("File not found: {}".format(currentFile))
                            except Exception as e:
                                logger.error("An error occurred while reading {}: {}".format(currentFile, e))
            for childAst in t.children():
                t2.append(childAst)
    return spsLinenos, list(set(spsCodes))