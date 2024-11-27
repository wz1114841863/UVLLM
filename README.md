# UVLLM: An Automated Universal Verification Framework using Large Language Model
This repository contains artefacts and workflows to reproduce experiments from the DAC 2025 submission 2081
"UVLLM: An Automated Universal RTL Verification Framework using LLMs"
# Platform pre-requisities
1. An x86-64 system (more cores will improve simulation time).
2. Linux operating system (we used Ubuntu 20.04).
# Dependencies Installation
Building simulation platform, Python libs, and other dependencies:

### Step1: Building simulation platform

`git clone https://github.com/verilator/verilator.git`

`sudo apt get install iverilog`

### Step2: Building Python libs

`pip install requirements.txt`

### Commercial Verilog Simulator: VCS

To perform a full evaluation, you need access to the commercial VCS simulator from Synopsys. The setup for VCS may depend on the kind of licensing you use. Please contact your local computer support person for guidance.
For an alternative try, we use a testbench with stimulus from UVM framework.

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
Example: python ./Main.py -b ErrorSet
```
