import os

TIMEOUT = 2
REPAIR_TIME = 7200

PROJECT_PATH = os.path.join(os.path.abspath(os.path.dirname(__file__)), "..")
BENCHMARKS = os.path.join(PROJECT_PATH, "ErrorSet")
WORK_DIR = os.path.join(PROJECT_PATH, "workdir")
PATCH_DIR = os.path.join(PROJECT_PATH, "patch")
LOG_PATH = os.path.join(PROJECT_PATH, "logs/UVLLM.log")


if __name__ == "__main__":
    print(PROJECT_PATH)
    print(BENCHMARKS)
    print(WORK_DIR)
    print(PATCH_DIR)
    print(LOG_PATH)
