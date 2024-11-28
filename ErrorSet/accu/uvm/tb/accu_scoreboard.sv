import "DPI-C" function void accu_reference_model(
    input int data_in,
    input bit valid_in,
	input bit rst_n,
    output int data_out,
    output bit valid_out
);



class accu_scoreboard extends uvm_component;
  `uvm_component_utils(accu_scoreboard)


  uvm_analysis_export#(accu_transaction) analysis_export;
  uvm_tlm_analysis_fifo#(accu_transaction) sb_fifo;
  
  accu_transaction  item, exp_item;
  
  int data_out_exp, valid_out_exp;
  int pass_count, err_count, total_count;
  real pass_rate;


  function new(string name = "accu_scoreborad" , uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase (uvm_phase phase);
        super.build_phase(phase);
	    analysis_export=new("analysis_export",this);
        sb_fifo=new("sb_fifo",this);
        exp_item=new("exp_item");
  endfunction

  function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        analysis_export.connect(sb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
	  super.run_phase(phase);
	  forever begin
		  sb_fifo.get(item);
		  
		  //ref_model
		  accu_reference_model(item.data_in, item.valid_in, item.rst_n, data_out_exp, valid_out_exp);
		  
		  exp_item.data_in = item.data_in;
		  exp_item.valid_in = item.valid_in;
		  exp_item.valid_out = item.valid_out;
		  exp_item.data_out = data_out_exp;
		  
		  if(item.valid_out == 1)begin
			  if(item.data_out == data_out_exp)begin
				  pass_count++;
				  `uvm_info("Scoreboard", $sformatf("expected = actual, act_data_out: %0h, exp_data_out: %0h", item.data_out, data_out_exp), UVM_LOW);
			  end
			  else begin
				  err_count++;
				  `uvm_error("Scoreboard", $sformatf("expected = actual, act_data_out: %0h, exp_data_out: %0h", item.data_out, data_out_exp));


			  end
		  $display("act_data:");
	      item.print();
	      $display("exp_data");
	      exp_item.print();
			  
		  end

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
