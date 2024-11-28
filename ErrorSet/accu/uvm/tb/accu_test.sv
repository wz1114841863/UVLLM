
class accu_test extends uvm_test;
  `uvm_component_utils(accu_test)

  accu_env env;
  accu_sequence seq;

 function new(string name = "accu_test",uvm_component parent = null);
    super.new(name, parent);
  endfunction

  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = accu_env::type_id::create("env", this);
	seq = accu_sequence::type_id::create("seq", this);
  endfunction

  task run_phase(uvm_phase phase);
	super.run_phase(phase);
    phase.raise_objection(this);
    `uvm_info("run_phase", "main started",UVM_MEDIUM)
    seq.start(env.agent.sequencer);
	`uvm_info("run_phase", "finished",UVM_MEDIUM)
    phase.drop_objection(this);
  endtask
endclass
