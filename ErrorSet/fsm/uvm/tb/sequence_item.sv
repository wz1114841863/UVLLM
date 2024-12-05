
`ifndef SEQUENCE_ITEM_SV
`define SEQUENCE_ITEM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"


class sequence_item extends uvm_sequence_item;

  rand bit rst;
  rand bit in_signal;
  bit match;

  `uvm_object_utils_begin(sequence_item)
        `uvm_field_int(rst, UVM_ALL_ON)
        `uvm_field_int(in_signal, UVM_ALL_ON)
        `uvm_field_int(match, UVM_ALL_ON)
  `uvm_object_utils_end


  function new(string name = "sequence_item");
    super.new(name);
  endfunction

endclass

`endif
