
`ifndef TEST_SV
`define TEST_SV

class test extends uvm_test;
  `uvm_component_utils(test)

  tb_env test_env;
  tb_sequence seq;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    test_env = tb_env::type_id::create("test_env", this);
    seq = tb_sequence::type_id::create("seq");
  endfunction

  task run_phase(uvm_phase phase);
	super.run_phase(phase);
    phase.raise_objection(this);
    `uvm_info("run_phase", "main started",UVM_MEDIUM)

    seq.start(test_env.agt.sqr);

	`uvm_info("run_phase", "finished",UVM_MEDIUM)
	#10;
    phase.drop_objection(this);
  endtask
endclass

`endif
