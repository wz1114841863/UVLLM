`ifndef TB_SCOREBOARD_SV
`define TB_SCOREBOARD_SV

import "DPI-C" function void fsm_model(
	input int IN, 
	input int RST, 
	output int MATCH
);

class tb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(tb_scoreboard)

  uvm_analysis_export#(sequence_item) analysis_export;
  uvm_tlm_analysis_fifo#(sequence_item) sb_fifo;

  sequence_item  tr, exp_tr;

  bit ref_match;
  int pass_count, err_count, total_count;
  real pass_rate;

  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase (uvm_phase phase);
        super.build_phase(phase);
	    analysis_export=new("analysis_export",this);
        sb_fifo=new("sb_fifo",this);
        exp_tr=new("exp_tr");
  endfunction

  function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        analysis_export.connect(sb_fifo.analysis_export);
  endfunction

 
  task run_phase(uvm_phase phase);
	  super.run_phase(phase);
	  forever begin
		  sb_fifo.get(tr);
          //ref_model
		  fsm_model(tr.in_signal, tr.rst, ref_match);
		  
		  exp_tr.rst = tr.rst;
		  exp_tr.in_signal = tr.in_signal;
		  
		  //check
		  if (tr.match != ref_match) begin
			  err_count++;
			  `uvm_error("REF_MODEL", $sformatf("Mismatch: Expected %0d, Got %0d", ref_match, tr.match));
			
          end
		  else begin
			  pass_count++;
			  `uvm_info("REF_MODEL", $sformatf("Match: Expected %0d, Got %0d", ref_match, tr.match),UVM_LOW);

		  end

		  $display("Expected:");
	      exp_tr.print();
	      $display("Got:");
	      tr.print();
	  end
   endtask


   function void report_phase (uvm_phase phase);
        super.report_phase(phase);
		
		if(err_count == 0)begin
			`uvm_info("TEST_SUMMARY", $sformatf("pass_count=%0d err_count=%0d", pass_count, err_count), UVM_LOW)

		    $write("%c[7;32m",27);
	        $display("TEST PASSED"); 
	        $write("%c[0m",27);
		end
		else begin
			`uvm_error("TEST_SUMMARY", $sformatf("pass_count=%0d err_count=%0d", pass_count, err_count))

		    $write("%c[7;31m",27);
	        $display("TEST FAILED"); 
	        $write("%c[0m",27);

		end

		total_count = err_count + pass_count;
        pass_rate = 0.0;

        if (total_count > 0) begin
             pass_rate = pass_count / real'(total_count) * 100.0;
        end
  
        `uvm_info("TEST_SUMMARY", $sformatf("case_pass_rate=%.2f%%", pass_rate), UVM_LOW);


   endfunction 



   
  endclass

`endif

