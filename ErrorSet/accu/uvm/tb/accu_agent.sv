
class accu_agent extends uvm_agent;
  `uvm_component_utils(accu_agent)

  //accu_agent_cfg cfg;
  accu_driver driver;
  accu_monitor monitor;
  accu_sequencer sequencer;

  uvm_analysis_port #(accu_transaction) agt_ap;

  function new(string name="accu_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //cfg = accu_agent_cfg::type_id::create("cfg", this);
    driver = accu_driver::type_id::create("driver", this);
    monitor = accu_monitor::type_id::create("monitor", this);
    sequencer = accu_sequencer::type_id::create("sequencer", this);
	agt_ap = new("agt_ap",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
	monitor.mon_ap.connect(agt_ap);
  endfunction
endclass
