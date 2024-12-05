
`ifndef TB_AGENT_SV
`define TB_AGENT_SV

class tb_agent extends uvm_agent;
  `uvm_component_utils(tb_agent)

  tb_driver drv;
  tb_monitor mon;
  tb_sequencer sqr;
  uvm_analysis_port #(sequence_item) agt_ap;

  virtual fsm_if vif;
  uvm_active_passive_enum is_active;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual fsm_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found")

    if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active))
      is_active = UVM_ACTIVE; // Default to active

    if (is_active == UVM_ACTIVE) begin
      drv = tb_driver::type_id::create("drv", this);
      sqr = tb_sequencer::type_id::create("sqr", this);
    end

    mon = tb_monitor::type_id::create("mon", this);
	agt_ap = new("agt_ap",this);

  endfunction

  function void connect_phase(uvm_phase phase);
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
    mon.mon_ap.connect(agt_ap);	
  endfunction
endclass

`endif
