import uvm_pkg::*;
`include "uvm_macros.svh"

class accu_transaction extends uvm_sequence_item;
  //`uvm_object_utils(accu_transaction)

  //rand bit [7:0] data_in;
  //rand bit valid_in;
  //bit [9:0] data_out;
  //bit valid_out;

  rand logic [7:0] data_in;
  rand logic valid_in;
  rand logic rst_n;
  logic [9:0] data_out;
  logic valid_out;

   `uvm_object_utils_begin(accu_transaction)
    `uvm_field_int(data_in, UVM_ALL_ON)
    `uvm_field_int(valid_in, UVM_ALL_ON)
    `uvm_field_int(rst_n, UVM_ALL_ON | UVM_NOPRINT)
    `uvm_field_int(data_out, UVM_ALL_ON)
    `uvm_field_int(valid_out, UVM_ALL_ON)
   `uvm_object_utils_end


  function new(string name = "accu_transaction");
    super.new(name);
  endfunction

endclass
