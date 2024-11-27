
class tb_agent extends uvm_agent;
  `uvm_component_utils(tb_agent)

  tb_driver driver;
  tb_monitor monitor;
  tb_sequencer sequencer;

  uvm_analysis_port #(tb_sequence_item) agt_ap;


  function new(string name="tb_agt", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver = tb_driver::type_id::create("driver", this);
    monitor = tb_monitor::type_id::create("monitor", this);
    sequencer = tb_sequencer::type_id::create("sequencer", this);
    agt_ap = new("agt_ap",this);

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
	monitor.mon_ap.connect(agt_ap);
  endfunction
endclass
