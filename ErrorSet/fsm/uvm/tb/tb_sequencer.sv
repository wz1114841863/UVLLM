
`ifndef TB_SEQUENCER_SV
`define TB_SEQUENCER_SV

class tb_sequencer extends uvm_sequencer#(sequence_item);
  `uvm_component_utils(tb_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif
