# UVLLM
1. 环境配置
```
git clone git@github.com:wz1114841863/UVLLM.git
cd ./UVLLM
git submodule update --init --recursive

sudo apt-get install iverilog
uv venv --python=3.12
source .venv/bin/activate
uv pip install -r requirements.txt

# 执行
python UVLLM/Main.py -b ErrorSet
```

# Reproduction
Our prototype needs three input options for execution:

* `--benchmark/-b`: the benchmark name. (ErrorSet for the example)

* `--project/-p`: the project name of DUT in the benchmark. (accu for the example)

* `--version/-v`: the error index for the DUT. (1 for the example)

```
Example: python UVLLM/Main.py -b ErrorSet -p accu -v 1
```

For the total benchmark test, use:

```
Example: python UVLLM/Main.py -b ErrorSet
```
