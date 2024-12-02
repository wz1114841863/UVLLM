class radix2_div_test extends uvm_test;
    `uvm_component_utils(radix2_div_test)

    radix2_div_env env;
    radix2_div_sequence seq;

    function new(string name = "radix2_div_test",uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = radix2_div_env::type_id::create("env", this);
        seq = radix2_div_sequence::type_id::create("seq");
    endfunction

    task run_phase(uvm_phase phase);
	    super.run_phase(phase);
        phase.raise_objection(this);
        `uvm_info("run_phase", "main started",UVM_MEDIUM)

        // Create and start a sequence
        seq.start(env.agent.sequencer);
	    `uvm_info("run_phase", "finished",UVM_MEDIUM)
		//#10000;

        phase.drop_objection(this);
    endtask
endclass
