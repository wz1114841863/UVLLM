import uvm_pkg::*;
`include "uvm_macros.svh"

class tb_sequence_item extends uvm_sequence_item;

  rand logic [31:0] a, b;
  rand logic [5:0] aluc;
  logic [31:0] r;
  logic zero;
  logic flag;

  `uvm_object_utils_begin(tb_sequence_item)
    `uvm_field_int(a, UVM_ALL_ON)
    `uvm_field_int(b, UVM_ALL_ON)
    `uvm_field_int(aluc, UVM_ALL_ON)
    `uvm_field_int(r, UVM_ALL_ON)
    `uvm_field_int(zero, UVM_ALL_ON)
    `uvm_field_int(flag, UVM_ALL_ON)
  `uvm_object_utils_end
  
  constraint aluc_constraint {
	aluc inside {6'b100000, 6'b100001, 6'b100010, 6'b100011, 6'b100100, 6'b100101, 6'b100110, 6'b100111, 6'b101010, 6'b101011, 6'b000000, 6'b000010, 6'b000011, 6'b000110, 6'b000111, 6'b001111, 6'b000100};
  }

  constraint valid_shift {
    a inside {[0:31]}; 
    b != 0;            
  }

  function new(string name = "tb_sequence_item");
    super.new(name);
  endfunction

endclass
