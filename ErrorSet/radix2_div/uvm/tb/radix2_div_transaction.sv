import uvm_pkg::*;
`include "uvm_macros.svh"

class radix2_div_transaction extends uvm_sequence_item;

    rand bit [7:0] dividend;
    rand bit [7:0] divisor;
    rand bit sign;
    bit [15:0] result;

	`uvm_object_utils_begin(radix2_div_transaction)
        `uvm_field_int(dividend, UVM_ALL_ON)
        `uvm_field_int(divisor, UVM_ALL_ON)
        `uvm_field_int(sign, UVM_ALL_ON)
        `uvm_field_int(result, UVM_ALL_ON)
    `uvm_object_utils_end

	constraint divisor_constraint {
		divisor != 0;
	}

    function new(string name = "radix2_div_transaction");
        super.new(name);
    endfunction
endclass
