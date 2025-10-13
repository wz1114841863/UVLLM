import copy
from VerilogAnalyzer import DataFlowAnalyzer, SignalAnalyzer
from pyverilog.dataflow.dataflow import *


class Locator:
    def __init__(
        self, timeStamp, mismatchSignals, bindDicts, terms, parameters, moduleInfo
    ) -> None:
        self.suspiciousSignals = copy.deepcopy(mismatchSignals)  # 当前可疑信号列表
        self.timeStamp = timeStamp  # 当前分析的时间戳
        self.bindDicts = bindDicts  # 所有信号的绑定字典
        self.terms = terms  # 所有信号/参数/常量节点
        self.parameters = parameters  # 所有参数节点
        self.moduleInfo = moduleInfo  # 模块信息
        self.spsBindDicts = []  # 可疑信号的绑定字典
        self.executedPaths = []  # 执行路径
        self.availableTerms = []  # 可用的信号/参数/常量节点
        self.availableParamters = []  # 可用的参数节点
        self.availableRenameInfo = []  # 可用的重命名信息

        self.renameNodeExecutedPath = {}  # 重命名节点的执行路径
        self.spsNodes = []  # 可疑信号节点

    def locate(self, tmpInputSignalValues, tmpOracleSignalValue, logger):
        """入口函数, 判断是否初始可疑信号为空"""
        if self.suspiciousSignals == None:
            pass
        else:
            self.dynamicSlice(tmpInputSignalValues, tmpOracleSignalValue, logger)

    def filterTermsAndParameters(self, module, signal):
        """按模块名 + 信号名过滤信号/参数节点."""
        sTerms, sParameters = {}, {}
        subInstance = module
        if "." in signal:
            subInstance = "{}.{}".format(module, signal[: signal.rindex(".")])
        for tk, tv in self.terms.items():
            tkInstance = ".".join([sc.scopename for sc in tk.scopechain[:-1]])
            if tkInstance == subInstance:
                sTerms[tk] = tv
        for pk, pv in self.parameters.items():
            pkInstance = ".".join([sc.scopename for sc in pk.scopechain[:-1]])
            if pkInstance == subInstance:
                sParameters[pk] = pv
        return sTerms, sParameters

    def dynamicSlice(self, tmpInputSignalValues, tmpOracleSignalValue, logger):
        for suspiciousSignal in self.suspiciousSignals:
            (
                spsBindDicts,
                executedPaths,
                availableTerms,
                availableParamters,
                availableRenameInfo,
            ) = ([], [], [], [], [])
            tmpInputSignalValue = {}
            if suspiciousSignal in tmpInputSignalValues:
                tmpInputSignalValue = tmpInputSignalValues[suspiciousSignal]

            # logger.info(suspiciousSignal)
            subSuspiciousSignal = suspiciousSignal[suspiciousSignal.find(".") + 1 :]
            index = subSuspiciousSignal.find(".")
            instance, signal = (
                subSuspiciousSignal[:index],
                subSuspiciousSignal[index + 1 :],
            )
            module = self.moduleInfo[instance]
            sTerms, sParameters = self.filterTermsAndParameters(module, signal)
            # logger.info(signal)

            sRenameInfo = {}
            subInstance = suspiciousSignal[: suspiciousSignal.rindex(".")]
            # logger.info("s")
            for tk, tv in sTerms.items():
                if tv.termtype and "Rename" in tv.termtype:
                    msb, _ = DataFlowAnalyzer.traverseDataflow(
                        subInstance,
                        tmpInputSignalValue,
                        sParameters,
                        sRenameInfo,
                        tv.msb,
                    )
                    lsb, _ = DataFlowAnalyzer.traverseDataflow(
                        subInstance,
                        tmpInputSignalValue,
                        sParameters,
                        sRenameInfo,
                        tv.lsb,
                    )
                    msb, lsb = SignalAnalyzer.converse(msb), SignalAnalyzer.converse(
                        lsb
                    )
                    if tk not in sRenameInfo:
                        sRenameInfo[tk] = "'b" + (msb - lsb + 1) * "x"
                    # rnBindDict = self.bindDicts[tk][0]
                    rnBindDict = self.bindDicts.get(tk, [None])[0]
                    if rnBindDict is None:
                        continue
                    # logger.info(self.renameNodeExecutedPath)
                    sv, sbEp = DataFlowAnalyzer.traverseDataflow(
                        subInstance,
                        tmpInputSignalValue,
                        sParameters,
                        sRenameInfo,
                        rnBindDict.tree,
                    )
                    # logger.info(rnBindDict.tree.operator if isinstance(rnBindDict.tree, DFOperator) else 1)
                    if tk not in self.renameNodeExecutedPath:
                        self.renameNodeExecutedPath[tk] = sbEp
                    if isinstance(sv, int):
                        sv = bin(sv)[2:]
                    if "'" in sv:
                        sv = sv[sv.find("'") + 2 :]
                    if (
                        rnBindDict.lsb == None
                        and rnBindDict.msb == None
                        and rnBindDict.ptr == None
                    ):
                        sRenameInfo[tk] = "'b" + sv
                    else:
                        sRenameInfo[tk] = "'b" + (msb - lsb + 1) * sv[0]

            bindDict = DataFlowAnalyzer.getBindDict(self.bindDicts, module, signal)
            for bd in bindDict:
                # logger.info(bd)
                sv, ep = DataFlowAnalyzer.traverseDataflow(
                    subInstance, tmpInputSignalValue, sParameters, sRenameInfo, bd.tree
                )
                lsb, lsbEp = DataFlowAnalyzer.traverseDataflow(
                    subInstance, tmpInputSignalValue, sParameters, sRenameInfo, bd.lsb
                )
                msb, msbEp = DataFlowAnalyzer.traverseDataflow(
                    subInstance, tmpInputSignalValue, sParameters, sRenameInfo, bd.msb
                )
                assert bd.ptr == None or len(bd.ptr) == 1
                bdPtr = bd.ptr if bd.ptr == None else bd.ptr[0]
                ptr, ptrEp = DataFlowAnalyzer.traverseDataflow(
                    subInstance, tmpInputSignalValue, sParameters, sRenameInfo, bdPtr
                )
                if suspiciousSignal in tmpInputSignalValue:
                    inputSignalValue = tmpInputSignalValue[suspiciousSignal]
                elif bd.dest in sParameters:
                    inputSignalValue = sParameters[bd.dest]
                inputSignalValue = inputSignalValue[inputSignalValue.find("'b") + 2 :]
                if suspiciousSignal in tmpOracleSignalValue:
                    oracleSignalValue = tmpOracleSignalValue[suspiciousSignal]
                    oracleSignalValue = oracleSignalValue[
                        oracleSignalValue.find("'b") + 2 :
                    ]
                else:
                    oracleSignalValue = None
                # logger.info(oracleSignalValue)
                # logger.info(sv)
                if lsb == None and msb == None and ptr == None:
                    if sv == None:
                        sv = inputSignalValue
                    if oracleSignalValue and SignalAnalyzer.equal(
                        sv, oracleSignalValue
                    ):
                        ep, lsbEp, msbEp, ptrEp = [], [], [], []
                else:
                    try:
                        if ptr != None:
                            ptr = int(ptr)
                            if sv == None:
                                sv = inputSignalValue[::-1][ptr]
                            if oracleSignalValue and SignalAnalyzer.equal(
                                sv, oracleSignalValue[::-1][ptr]
                            ):
                                ep, lsbEp, msbEp, ptrEp = [], [], [], []
                            # logger.info(3)
                        else:
                            lsb, msb = int(lsb), int(msb)
                            if sv == None:
                                sv = inputSignalValue[::-1][lsb : msb + 1]
                            if oracleSignalValue and SignalAnalyzer.equal(
                                sv, oracleSignalValue[::-1][lsb : msb + 1]
                            ):
                                ep, lsbEp, msbEp, ptrEp = [], [], [], []
                            # logger.info(4)
                    except:
                        print("Out of Bound!")
                        continue

                nSuspiciousSignals = DataFlowAnalyzer.getSuspiciousSignals(
                    subInstance, sRenameInfo, ep + lsbEp + msbEp + ptrEp
                )
                for nss in nSuspiciousSignals:
                    if nss not in self.suspiciousSignals:
                        self.suspiciousSignals.append(nss)
                spsBindDicts.append(bd)
                executedPaths.append(ep)
                availableTerms.append(sTerms)
                availableParamters.append(sParameters)
                availableRenameInfo.append(sRenameInfo)
            self.spsBindDicts.append(spsBindDicts)
            self.executedPaths.append(executedPaths)
            self.availableTerms.append(availableTerms)
            self.availableParamters.append(availableParamters)
            self.availableRenameInfo.append(availableRenameInfo)

    def getSuspiciousSignals(self):
        return self.suspiciousSignals

    def getBindDicts(self):
        return self.spsBindDicts

    def getExecutedPaths(self):
        return self.executedPaths

    def getAvailableTerms(self):
        return self.availableTerms

    def getAvailableParameters(self):
        return self.availableParamters

    def getAvailableRenameInfo(self):
        return self.availableRenameInfo

    def collectSuspiciousNode(self, dfNode, nodes):
        """递归收集可疑节点."""
        if isinstance(dfNode, DFBranch):
            if dfNode.condnode in nodes:
                if dfNode.condnode not in self.spsNodes:
                    self.spsNodes.append(dfNode.condnode)
            if dfNode.truenode in nodes:
                if not isinstance(dfNode.truenode, DFBranch):
                    self.spsNodes.append(dfNode.truenode)
                else:
                    self.collectSuspiciousNode(dfNode.truenode, nodes)
            if dfNode.falsenode in nodes:
                if not isinstance(dfNode.falsenode, DFBranch):
                    self.spsNodes.append(dfNode.falsenode)
                else:
                    self.collectSuspiciousNode(dfNode.falsenode, nodes)
        else:
            self.spsNodes.append(dfNode)

    def getAllNodeId(self, node):
        retNodeIds = []
        if node.nodeid != None:
            retNodeIds.append(node.nodeid)
        for childNode in node.children():
            retNodeIds.extend(self.getAllNodeId(childNode))
        return retNodeIds

    def getSpsNodeIds(self):
        spsNodeIds = set()
        for eps, bds, ars in zip(
            self.executedPaths, self.spsBindDicts, self.availableRenameInfo
        ):
            for ep, bd, ar in zip(eps, bds, ars):
                if bd.alwaysinfo != None:
                    if bd.alwaysinfo.clock != None:
                        sNodeIds = self.getAllNodeId(bd.alwaysinfo.clock)
                        for sNodeId in sNodeIds:
                            spsNodeIds.add(sNodeId)
                    if bd.alwaysinfo.reset != None:
                        sNodeIds = self.getAllNodeId(bd.alwaysinfo.reset)
                        for sNodeId in sNodeIds:
                            spsNodeIds.add(sNodeId)
                    for sens in bd.alwaysinfo.senslist:
                        sNodeIds = self.getAllNodeId(sens)
                        for sNodeId in sNodeIds:
                            spsNodeIds.add(sNodeId)
                self.spsNodes = []
                self.collectSuspiciousNode(bd.tree, ep)
                for spsNode in self.spsNodes:
                    sNodeIds = []
                    if isinstance(spsNode, DFTerminal) and spsNode.name in ar:
                        for rNode in self.renameNodeExecutedPath[spsNode.name]:
                            sNodeIds.extend(self.getAllNodeId(rNode))
                    else:
                        sNodeIds = self.getAllNodeId(spsNode)
                    for sNodeId in sNodeIds:
                        spsNodeIds.add(sNodeId)
        return list(spsNodeIds)
