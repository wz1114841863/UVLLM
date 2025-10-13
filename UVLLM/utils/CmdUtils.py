import logging
import subprocess
import time


def runCmd(cmd, cwd=None, logger=None):
    if logger == None:
        logger = logging.getLogger()
    startTime = time.time()
    logger.info("cmd to run: {}".format(cmd))
    p = subprocess.run(
        cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd
    )
    try:
        output = p.stdout.decode("utf-8")
    except UnicodeDecodeError:
        logger.warning("cmd UnicodeDecoderError")
        output = p.stdout.decode("unicode_escape")
    error = p.stderr.decode("utf-8")
    if len(error) > 0:
        logger.error("output error: {}".format(error))
        output = error

    if len(output) > 0:
        logger.info("output of this cmd:\n{}".format(output))

    logger.info("cmd execution time: {}".format(time.time() - startTime))
    return output


def run_cmd(cmd, cwd=None, logger=None, timeout=0):
    """
    执行本地 shell 命令,返回 stdout(utf-8 字符串).
    如果返回码非 0,抛 CalledProcessError.
    如 timeout>0,秒级超时.
    """
    if logger is None:
        logger = logging.getLogger(__name__)

    logger.info("cmd to run: %s  cwd=%s", cmd, cwd)
    start = time.time()

    try:
        cp = subprocess.run(
            cmd,
            shell=True,  # 如想彻底避免注入,可传列表并 shell=False
            cwd=cwd,
            capture_output=True,  # 3.7+ 简写
            text=False,  # 先拿 bytes,自己解码更可控
            timeout=timeout or None,
            check=False,  # 我们自己判断返回码
        )
    except subprocess.TimeoutExpired as e:
        logger.error("cmd timeout after %ss", timeout)
        raise

    # 统一解码,容错
    def _decode(bs):
        for enc in ("utf-8", "gbk", "unicode_escape"):
            try:
                return bs.decode(enc)
            except UnicodeDecodeError:
                continue
        return bs.decode("utf-8", errors="replace")

    stdout = _decode(cp.stdout)
    stderr = _decode(cp.stderr)

    logger.info("cmd exit code: %s", cp.returncode)
    if stderr:
        logger.warning("cmd stderr:\n%s", stderr.rstrip())
    if stdout:
        logger.info("cmd stdout:\n%s", stdout.rstrip())

    logger.info("cmd execution time: %.2fs", time.time() - start)

    # 调用方关心失败就抛异常;不关心就 try/except 掉
    if cp.returncode != 0:
        raise subprocess.CalledProcessError(
            cp.returncode, cmd, output=stdout, stderr=stderr
        )

    return stdout
