
`ifndef TB_ENV_SV
`define TB_ENV_SV

class tb_env extends uvm_env;
  `uvm_component_utils(tb_env)

  tb_agent agt;
  tb_scoreboard sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = tb_agent::type_id::create("agt", this);
    sb = tb_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.agt_ap.connect(sb.analysis_export);
  endfunction
endclass

`endif
