
class tb_sequencer extends uvm_sequencer#(tb_sequence_item);
  `uvm_component_utils(tb_sequencer)

  function new(string name = "tb_sequencer" , uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass
