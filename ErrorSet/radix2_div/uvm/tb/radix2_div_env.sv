

class radix2_div_env extends uvm_env;
    `uvm_component_utils(radix2_div_env)

    radix2_div_agent agent;
	radix2_div_scb   scb;
    
    function new(string name = "radix2_div_env" , uvm_component parent = null);
       super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = radix2_div_agent::type_id::create("agent", this);
        scb = radix2_div_scb::type_id::create("scb", this);
    endfunction

	function void connect_phase(uvm_phase phase);
	  super.connect_phase(phase);
	  agent.agt_ap.connect(scb.analysis_export);
  endfunction

endclass
