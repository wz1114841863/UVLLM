#!/bin/bash
#

test_name="radix2_div_test"    # uvm_test class
top_mod="tb_top"          # top module name

export UVM_HOME=/YOUR/PATH/TO/UVM
export VCS_HOME=/YOUR/PATH/TO/VCS


vlogan -full64 -sverilog -f ../tb/src_list.f -ntb_opts uvm +incdir+$UVM_HOME/src 
if [ $? -ne 0 ]; then
    exit -1
fi


gcc -c -o c_model.o ../tb/ref_model.c -I$UVM_HOME/src/dpi
if [ $? -ne 0 ]; then
    exit -1
fi

# Elaborate the design

vcs -full64 -debug_acc+all+dmptf -debug_region+cell+encrypt -timescale=1ns/1ps +vcs+dumpvars+dumpfile=test.vcd $top_mod -o simv $UVM_HOME/src/dpi/uvm_dpi.cc c_model.o -CFLAGS -DVCS

#vcs -full64 -debug_acc+all+dmptf -debug_region+cell+encrypt -timescale=1ns/1ps +vcs+dumpvars+dumpfile=test.vcd $top_mod -o simv $UVM_HOME/src/dpi/uvm_dpi.cc -CFLAGS -DVCS
if [ $? -ne 0 ]; then
    exit -1
fi

# Run the simulation
./simv +UVM_TESTNAME=$test_name +UVM_VERBOSITY=UVM_HIGH +ntb_random_seed=$seed -l simv.log

