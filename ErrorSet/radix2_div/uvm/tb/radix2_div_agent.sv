
class radix2_div_agent extends uvm_agent;
    `uvm_component_utils(radix2_div_agent)

    radix2_div_driver driver;
    radix2_div_monitor monitor;
    radix2_div_sequencer sequencer;

	uvm_analysis_port #(radix2_div_transaction) agt_ap;


    function new(string name="radix2_div_agent", uvm_component parent = null);
       super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = radix2_div_driver::type_id::create("driver", this);
        monitor = radix2_div_monitor::type_id::create("monitor", this);
        sequencer = radix2_div_sequencer::type_id::create("sequencer", this);
		agt_ap = new("agt_ap",this);
    endfunction

    function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
		monitor.mon_ap.connect(agt_ap);
    endfunction
endclass
