`ifndef TB_MONITOR_SV
`define TB_MONITOR_SV

class tb_monitor extends uvm_monitor;
  `uvm_component_utils(tb_monitor)
  sequence_item seq_item;

  virtual fsm_if vif;
  uvm_analysis_port#(sequence_item) mon_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_ap=new("mon_ap",this);
    if (!uvm_config_db#(virtual fsm_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
	super.run_phase(phase);
    forever begin
      seq_item = sequence_item::type_id::create("seq_item");
      @(posedge vif.CLK);
      seq_item.rst = vif.RST;
      seq_item.in_signal = vif.IN;
      seq_item.match = vif.MATCH;
	  //seq_item.print();
      mon_ap.write(seq_item);
    end
  endtask
endclass

`endif

