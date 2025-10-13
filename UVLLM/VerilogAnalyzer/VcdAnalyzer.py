import math
import re
import io
import copy
import os
import tempfile
import shutil
from vcd.reader import TokenKind, tokenize, ScopeDecl
from utils import Logger


def computeUnitLevel(tsUnit, tsPrecision):
    """计算时间单位换算成纳秒的倍数."""
    tsUnitMatch = re.match("(\d+)(\w+)", tsUnit)
    tsPrecisionMatch = re.match("(\d+)(\w+)", tsPrecision)
    tsu1, tsu2 = int(tsUnitMatch[1]), tsUnitMatch[2]
    tsp1, tsp2 = int(tsPrecisionMatch[1]), tsPrecisionMatch[2]
    UnifiedUnitToNanoSecond = {
        "s": 1000000,
        "ms": 1000,
        "ns": 1,
        "ps": 0.001,
        "fs": 0.000001,
    }
    return tsp1 * UnifiedUnitToNanoSecond[tsp2] / (tsu1 * UnifiedUnitToNanoSecond[tsu2])


def mapInstanceToModule(instances, moduleInfo, tmpModule, tmpInstance):
    """递归映射实例名到模块名."""
    if tmpModule not in instances:
        return
    for instance in instances[tmpModule]:
        moduleInfo["{}.{}".format(tmpInstance, instance[1])] = instance[0]
        mapInstanceToModule(
            instances, moduleInfo, instance[0], "{}.{}".format(tmpInstance, instance[1])
        )


def getModuleInfo(topModule):
    """获取模块信息映射."""
    moduleInfo = {}
    for tmpModule, tmpInstances in topModule.items():
        for tmpInstance in tmpInstances:
            moduleInfo[tmpInstance] = tmpModule
            # mapInstanceToModule(instances, moduleInfo, tmpModule, tmpInstance)
    return moduleInfo


def getTmpSignalValue(time, vcd):
    """获取指定时间点的信号值."""
    tmpSignalValue = {}
    for signal, valueList in vcd.items():
        tmpSignalValue[signal] = "x"
        for ts, value in valueList:
            if float(time) >= ts:
                tmpSignalValue[signal] = value
            else:
                break
    return tmpSignalValue


def getInputSignalValue(attributesDict, prevSimSignalValue, tmpSimSignalValue):
    """获取每个信号的输入值."""
    inputSignalValues = {}
    tmpInputSignalValue = {}
    for signal in tmpSimSignalValue.keys():
        tmpInputSignalValue = copy.deepcopy(tmpSimSignalValue)
        if attributesDict[signal]["type"] == "reg":
            tmpInputSignalValue[signal] = prevSimSignalValue[signal]
    for signal in tmpSimSignalValue.keys():
        inputSignalValue = copy.deepcopy(tmpInputSignalValue)
        inputSignalValue[signal] = prevSimSignalValue[signal]
        inputSignalValues[signal] = inputSignalValue
    return inputSignalValues


def getInternalSignals(simVarsDict, oracleAttributesDict):
    """获取所有的内部信号."""
    IOSignals, internalSignals = [], []
    for signals in simVarsDict.values():
        if signals[0].count(".") == 1:
            IOSignals.extend(signals)
        else:
            for signal in signals:
                if signal not in IOSignals and signal not in oracleAttributesDict:
                    internalSignals.append(signal)
    return internalSignals


def getInputValueOfInternalSignals(timeStamp, internalSignals, simVcdFile, timeScale):
    """针对内部信号再跑一遍 VCD, 提取它们在每个跳变沿的完整输入快照"""
    simScopes = []
    simVarsDict = {}
    prevSimVarsChangeDict = {}
    tmpSimVarsChangeDict = {}
    simAttributesDict = {}
    currentSimTimeStamp = 0
    simTimeStamp = 0
    unitLevel = computeUnitLevel(timeScale[0], timeScale[1])
    retSimVarsChangeDicts = {}

    f2 = open(simVcdFile, "r")
    headFlag = False
    while True:
        token2 = f2.readline()
        if "$timescale" in token2:
            headFlag = True
        if "$end" in token2 and headFlag:
            break

    changeVars = []
    while True:
        changeVars = []
        # for vcdLine in f2:
        vcdLine = f2.readline()
        while vcdLine:
            vcdBytes = vcdLine.encode("utf-8")
            tokens = list(tokenize(io.BytesIO(vcdBytes)))
            # tlist = [i for i in tokens]
            assert len(tokens) <= 1
            if len(tokens) == 0:
                vcdLine = f2.readline()
                continue
            token = tokens[0]
            if token.kind == TokenKind.SCOPE:
                scope = token.data.ident
                simScopes.append(scope)
            if token.kind == TokenKind.VAR:
                # if len(simScopes) <= 1: continue # exclude the signals in testbench
                if token.data.id_code not in simVarsDict:
                    simVarsDict[token.data.id_code] = []
                simVarsDict[token.data.id_code].append(
                    "{}.{}".format(".".join(simScopes), token.data.reference)
                )
                simAttributesDict[
                    "{}.{}".format(".".join(simScopes), token.data.reference)
                ] = {
                    "type": token.data.type_.name,
                    "size": token.data.size,
                    "bit_index": token.data.bit_index,
                }
                prevSimVarsChangeDict[
                    "{}.{}".format(".".join(simScopes), token.data.reference)
                ] = ("'b" + token.data.size * "x")
            if token.kind == TokenKind.UPSCOPE:
                simScopes.pop(-1)
            if token.kind == TokenKind.CHANGE_TIME:
                currentSimTimeStamp = simTimeStamp
                simTimeStamp = token.data
                if simTimeStamp != 0:
                    break
            if (
                token.kind == TokenKind.CHANGE_SCALAR
                or token.kind == TokenKind.CHANGE_VECTOR
            ):
                if token.data.id_code not in simVarsDict:
                    vcdLine = f2.readline()
                    continue
                for signal in simVarsDict[token.data.id_code]:
                    changeVars.append(signal)
                    dataValue = token.data.value
                    if isinstance(token.data.value, int):
                        dataValue = bin(token.data.value)[2:]
                    if simAttributesDict[signal]["size"] != len(dataValue):
                        if dataValue == "x" or dataValue == "z":
                            tmpSimVarsChangeDict[signal] = (
                                "'b" + simAttributesDict[signal]["size"] * dataValue
                            )
                        else:
                            tmpSimVarsChangeDict[signal] = "'b" + dataValue.zfill(
                                simAttributesDict[signal]["size"]
                            )
                    else:
                        tmpSimVarsChangeDict[signal] = "'b" + dataValue
            vcdLine = f2.readline()

        for internalSignal in internalSignals:
            if internalSignal in changeVars:
                retSimVarsChangeDicts[internalSignal] = copy.deepcopy(
                    tmpSimVarsChangeDict
                )
                for signal in retSimVarsChangeDicts[internalSignal].keys():
                    if simAttributesDict[signal]["type"] == "reg":
                        retSimVarsChangeDicts[internalSignal][signal] = (
                            prevSimVarsChangeDict[signal]
                        )

        if timeStamp <= simTimeStamp * unitLevel:
            f2.close()
            return retSimVarsChangeDicts

        prevSimVarsChangeDict = copy.deepcopy(tmpSimVarsChangeDict)

        current_position2 = f2.tell()
        f2.seek(0, 2)
        end_position2 = f2.tell()
        f2.seek(current_position2)
        if current_position2 == end_position2:
            f2.close()
            return {}


def getTimeScale(simVcd):
    """扫描 VCD 里最大时间戳,向上取整"""
    timeScale = 0
    for _, sValue in simVcd.items():
        st, _ = sValue[-1]
        if timeScale < st:
            timeScale = st
    return math.ceil(timeScale) + 1


def getNearTimeStamp(timeStamp, simVcd):
    """优先找时钟周期,返回{前后各 circle=2 周期}的时间索引"""
    timeStamps = [i for i in range(getTimeScale(simVcd))]
    circle = 1
    for k, v in simVcd.items():
        if "clk" in k or "clock" in k:
            timeStamps = [vi[0] for vi in v]
            circle = 2
            break
    index = timeStamps.index(timeStamp)
    preIndex = index - circle if index - circle > 0 else 0
    postIndex = (
        index + circle if index + circle < len(timeStamps) else len(timeStamps) - 1
    )
    return preIndex, postIndex, timeStamps


def groupSimVarsDict(simVarsDict):
    """把同名的端口信号合并."""
    tmpSimVarsDict = {}
    for k, vars in simVarsDict.items():
        if len(vars) == 1 and vars[0].count(".") == 1:
            tmpSimVarsDict[k] = vars
    for k1, vars1 in tmpSimVarsDict.items():
        signal1 = vars1[0][vars1[0].index(".") + 1 :]
        for k2, vars2 in simVarsDict.items():
            var2 = vars2[0]
            if var2.count(".") != 2:
                continue
            signal2 = var2[var2.rindex(".") + 1 :]
            if signal1 == signal2:
                simVarsDict[k1].extend(vars2)


def MapIOSignals(simVarsDict, mismatchSignals, oracleSignalValue):
    """映射输入输出信号的值."""
    for k, vars in simVarsDict.items():
        if len(vars) == 1:
            continue
        if vars[0] in oracleSignalValue:
            for var in vars[1:]:
                oracleSignalValue[var] = oracleSignalValue[vars[0]]
        if vars[0] in mismatchSignals:
            mismatchSignals.remove(vars[0])
            mismatchSignals.extend(vars[1:])
    for mismatchSignal in mismatchSignals:
        if mismatchSignal.count(".") == 1:
            mismatchSignals.remove(mismatchSignal)


signal_pattern = re.compile(r"\$var\s+(wire|reg)\s+(\d+)\s+([^\s]+)\s+([^\s]+)")


def parse_vcd(vcd_file, IOsignals):
    """解析 VCD 文件, 返回 IO 信号的作用域列表."""
    io_scopes = []
    signals = {}
    with open(vcd_file, "r") as file:
        for line in file:
            match = signal_pattern.search(line)
            if match:
                signal_type, size, scope, name = match.groups()
                if name in IOsignals:
                    signals[name] = {
                        "type": signal_type,
                        "size": int(size),
                        "scope": scope,
                    }
    for name in IOsignals:
        io_scopes.append(signals[name]["scope"])
    return io_scopes


def ModifyOracle(input_vcd, IOsignals, logger):
    """过滤VCD文件,只保留IO信号的记录."""
    temp_fd, temp_path = tempfile.mkstemp()  # Create a temp file
    io_scopes = parse_vcd(input_vcd, IOsignals)
    with open(input_vcd, "r") as infile, os.fdopen(temp_fd, "w") as outfile:
        writing = False
        for line in infile:
            # 写入信号声明
            if line.startswith("$var"):
                match = signal_pattern.search(line)
                if match:
                    signal_name = match.group(4)
                    if signal_name in IOsignals:
                        outfile.write(line)
            elif line.startswith("#"):
                outfile.write(line)
                writing = True
            elif writing:
                if line.startswith("$"):
                    outfile.write(line)
                else:
                    if line.startswith("b"):
                        scope = line.split()[-1]
                        if scope in io_scopes:
                            outfile.write(line)
                    else:
                        scope = line[-2]
                        if scope in io_scopes:
                            outfile.write(line)

            else:
                outfile.write(line)
    shutil.move(temp_path, input_vcd)


def getMismatchSignal(oracleVcdFile, simVcdFile, timeScale, logger):
    """对比两个 VCD 文件,返回第一个时间戳不匹配的信号列表."""
    oracleScopes, simScopes = [], []
    oracleVarsDict, simVarsDict = {}, {}
    prevOracleVarsChangeDict, prevSimVarsChangeDict = {}, {}
    tmpOracleVarsChangeDict, tmpSimVarsChangeDict = {}, {}
    oracleAttributesDict, simAttributesDict = {}, {}
    currentOracleTimeStamp, currentSimTimeStamp = 0, 0
    oracleTimeStamp, simTimeStamp = 0, 0
    unitLevel = computeUnitLevel(timeScale[0], timeScale[1])

    f1, f2 = open(oracleVcdFile, "r"), open(simVcdFile, "r")
    headFlag = False
    while True:
        token1 = f1.readline()
        token2 = f2.readline()
        if "$timescale" in token2:
            headFlag = True
        if "$end" in token2 and headFlag:
            break
    # logger.info(1)

    compareFlag = 0
    while True:
        if compareFlag == 0 or compareFlag == 1:
            # for vcdLine in f1:
            vcdLine = f1.readline()
            while vcdLine:
                vcdBytes = vcdLine.encode("utf-8")
                tokens = list(tokenize(io.BytesIO(vcdBytes)))
                # logger.info(tokens)
                # tlist = [i for i in tokens]
                if len(tokens) == 0:
                    vcdLine = f1.readline()
                    continue
                token = tokens[0]
                if token.kind == TokenKind.SCOPE:
                    scope = token.data.ident
                    oracleScopes.append(scope)
                if token.kind == TokenKind.VAR:
                    # if len(oracleScopes) <= 1: continue # exclude the signals in testbench
                    if token.data.id_code not in oracleVarsDict:
                        # logger.info("{}".format(token.data.reference))
                        oracleVarsDict[token.data.id_code] = []
                    oracleVarsDict[token.data.id_code].append(
                        "{}.{}".format(".".join(oracleScopes), token.data.reference)
                    )
                    oracleAttributesDict[
                        "{}.{}".format(".".join(oracleScopes), token.data.reference)
                    ] = {
                        "type": token.data.type_.name,
                        "size": token.data.size,
                        "bit_index": token.data.bit_index,
                    }
                    prevOracleVarsChangeDict[
                        "{}.{}".format(".".join(oracleScopes), token.data.reference)
                    ] = ("'b" + token.data.size * "x")
                if token.kind == TokenKind.UPSCOPE:
                    oracleScopes.pop(-1)
                if token.kind == TokenKind.CHANGE_TIME:
                    currentOracleTimeStamp = oracleTimeStamp
                    oracleTimeStamp = token.data
                    if oracleTimeStamp != 0:
                        break
                if (
                    token.kind == TokenKind.CHANGE_SCALAR
                    or token.kind == TokenKind.CHANGE_VECTOR
                ):
                    if token.data.id_code not in oracleVarsDict:
                        vcdLine = f1.readline()
                        continue
                    for signal in oracleVarsDict[token.data.id_code]:
                        dataValue = token.data.value
                        if isinstance(token.data.value, int):
                            dataValue = bin(token.data.value)[2:]
                        if oracleAttributesDict[signal]["size"] != len(dataValue):
                            if dataValue == "x" or dataValue == "z":
                                tmpOracleVarsChangeDict[signal] = (
                                    "'b"
                                    + oracleAttributesDict[signal]["size"] * dataValue
                                )
                            else:
                                tmpOracleVarsChangeDict[signal] = (
                                    "'b"
                                    + dataValue.zfill(
                                        oracleAttributesDict[signal]["size"]
                                    )
                                )
                        else:
                            tmpOracleVarsChangeDict[signal] = "'b" + dataValue
                vcdLine = f1.readline()
        # logger.info(1)
        if compareFlag == 0 or compareFlag == 2:
            # for vcdLine in f2:
            vcdLine = f2.readline()
            while vcdLine:
                vcdBytes = vcdLine.encode("utf-8")
                tokens = list(tokenize(io.BytesIO(vcdBytes)))
                # tlist = [i for i in tokens]
                assert len(tokens) <= 1
                if len(tokens) == 0:
                    vcdLine = f2.readline()
                    continue
                token = tokens[0]
                if token.kind == TokenKind.SCOPE:
                    scope = token.data.ident
                    simScopes.append(scope)
                if token.kind == TokenKind.VAR:
                    # if len(simScopes) <= 1: continue # exclude the signals in testbench
                    if token.data.id_code not in simVarsDict:
                        simVarsDict[token.data.id_code] = []
                    simVarsDict[token.data.id_code].append(
                        "{}.{}".format(".".join(simScopes), token.data.reference)
                    )
                    simAttributesDict[
                        "{}.{}".format(".".join(simScopes), token.data.reference)
                    ] = {
                        "type": token.data.type_.name,
                        "size": token.data.size,
                        "bit_index": token.data.bit_index,
                    }
                    prevSimVarsChangeDict[
                        "{}.{}".format(".".join(simScopes), token.data.reference)
                    ] = ("'b" + token.data.size * "x")
                if token.kind == TokenKind.UPSCOPE:
                    simScopes.pop(-1)
                if token.kind == TokenKind.CHANGE_TIME:
                    currentSimTimeStamp = simTimeStamp
                    simTimeStamp = token.data
                    if simTimeStamp != 0:
                        break
                if (
                    token.kind == TokenKind.CHANGE_SCALAR
                    or token.kind == TokenKind.CHANGE_VECTOR
                ):
                    if token.data.id_code not in simVarsDict:
                        vcdLine = f2.readline()
                        continue
                    for signal in simVarsDict[token.data.id_code]:
                        dataValue = token.data.value
                        if isinstance(token.data.value, int):
                            dataValue = bin(token.data.value)[2:]
                        if simAttributesDict[signal]["size"] != len(dataValue):
                            if dataValue == "x" or dataValue == "z":
                                tmpSimVarsChangeDict[signal] = (
                                    "'b" + simAttributesDict[signal]["size"] * dataValue
                                )
                            else:
                                tmpSimVarsChangeDict[signal] = "'b" + dataValue.zfill(
                                    simAttributesDict[signal]["size"]
                                )
                        else:
                            tmpSimVarsChangeDict[signal] = "'b" + dataValue
                vcdLine = f2.readline()

        mismatchSignals = []
        # logger.info(currentOracleTimeStamp)
        # logger.info(currentSimTimeStamp)
        if currentOracleTimeStamp != currentSimTimeStamp:
            if currentOracleTimeStamp > currentSimTimeStamp:
                for signal, value in tmpSimVarsChangeDict.items():
                    if (
                        signal in prevOracleVarsChangeDict
                        and value != prevOracleVarsChangeDict[signal]
                    ):
                        mismatchSignals.append(signal)
                # assert len(mismatchSignals) > 0
                if len(mismatchSignals) > 0:
                    f1.close()
                    f2.close()
                    return (
                        currentSimTimeStamp * unitLevel,
                        mismatchSignals,
                        simVarsDict,
                        simAttributesDict,
                        oracleAttributesDict,
                        prevSimVarsChangeDict,
                        tmpSimVarsChangeDict,
                        prevOracleVarsChangeDict,
                    )
                compareFlag = 2
            else:
                for signal, value in prevSimVarsChangeDict.items():
                    if (
                        signal in tmpOracleVarsChangeDict
                        and value != tmpOracleVarsChangeDict[signal]
                    ):
                        mismatchSignals.append(signal)
                # assert len(mismatchSignals) > 0
                if len(mismatchSignals) > 0:
                    f1.close()
                    f2.close()
                    return (
                        currentOracleTimeStamp * unitLevel,
                        mismatchSignals,
                        simVarsDict,
                        simAttributesDict,
                        oracleAttributesDict,
                        prevSimVarsChangeDict,
                        prevSimVarsChangeDict,
                        tmpOracleVarsChangeDict,
                    )
                compareFlag = 1
        elif currentOracleTimeStamp != 0 and currentSimTimeStamp != 0:
            for signal, value in tmpSimVarsChangeDict.items():
                if (
                    signal in tmpOracleVarsChangeDict
                    and value != tmpOracleVarsChangeDict[signal]
                ):
                    mismatchSignals.append(signal)
            if len(mismatchSignals) > 0:
                f1.close()
                f2.close()
                return (
                    currentSimTimeStamp * unitLevel,
                    mismatchSignals,
                    simVarsDict,
                    simAttributesDict,
                    oracleAttributesDict,
                    prevSimVarsChangeDict,
                    tmpSimVarsChangeDict,
                    tmpOracleVarsChangeDict,
                )
            compareFlag = 0

        prevOracleVarsChangeDict = copy.deepcopy(tmpOracleVarsChangeDict)
        prevSimVarsChangeDict = copy.deepcopy(tmpSimVarsChangeDict)

        current_position1 = f1.tell()
        f1.seek(0, 2)
        end_position1 = f1.tell()
        f1.seek(current_position1)
        current_position2 = f2.tell()
        f2.seek(0, 2)
        end_position2 = f2.tell()
        f2.seek(current_position2)
        if current_position1 == end_position1 and current_position2 == end_position2:
            f1.close()
            f2.close()
            return 0, [], {}, {}, {}, {}, {}, {}
