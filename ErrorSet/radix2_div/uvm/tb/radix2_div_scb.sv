import "DPI-C" function void radix2_div_model(
    input int dividend,
    input int divisor,
    input bit sign,
    output int result
);

class radix2_div_scb extends uvm_scoreboard;
    `uvm_component_utils(radix2_div_scb)

    uvm_analysis_export#(radix2_div_transaction) analysis_export;
    uvm_tlm_analysis_fifo#(radix2_div_transaction) sb_fifo;

	radix2_div_transaction  tr, exp_tr;

	int result_exp;
    int pass_count, err_count, total_count;
    real pass_rate;


    function new(string name = "radix2_div_scb" , uvm_component parent = null);
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
          radix2_div_model(tr.dividend, tr.divisor, tr.sign, result_exp);
          exp_tr.dividend = tr.dividend;
          exp_tr.divisor = tr.divisor;
          exp_tr.sign = tr.sign;
          exp_tr.result = result_exp;
		  
		  if(tr.result == result_exp)begin
				  pass_count++;
				  `uvm_info("Scoreboard", $sformatf("expected = actual, act_result: %0h, exp_result: %0h", tr.result, result_exp), UVM_LOW);
		  end
		  else begin
				  err_count++;
				  `uvm_error("Scoreboard", $sformatf("expected = actual, act_result: %0h, exp_result: %0h", tr.result, result_exp));


		  end
		  $display("act_result:");
	      tr.print();
	      $display("exp_result");
	      exp_tr.print();


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
