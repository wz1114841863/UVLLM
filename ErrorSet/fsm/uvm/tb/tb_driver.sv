`ifndef TB_DRIVER_SV
`define TB_DRIVER_SV

class tb_driver extends uvm_driver#(sequence_item);
  `uvm_component_utils(tb_driver)

  virtual fsm_if vif;
  sequence_item seq_item;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fsm_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
	super.run_phase(phase);
    forever begin
      seq_item = sequence_item::type_id::create("seq_item");
      seq_item_port.get_next_item(seq_item);
      vif.IN = seq_item.in_signal;
      // Wait for a clock cycle
      @(posedge vif.CLK);
      seq_item_port.item_done();
    end
  endtask
endclass

`endif

