
class tb_env extends uvm_env;
  `uvm_component_utils(tb_env)

  tb_agent agent;
  tb_scoreboard scoreboard;

  function new(string name = "tb_env" , uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = tb_agent::type_id::create("agent", this);
    scoreboard = tb_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.agt_ap.connect(scoreboard.analysis_export);
  endfunction
endclass
