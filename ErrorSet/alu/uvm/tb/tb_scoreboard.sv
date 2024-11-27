import "DPI-C" function void alu_model(
	input int a, 
	input int b, 
	input byte aluc, 
	output int r, 
	output byte zero, 
	output byte carry, 
	output byte negative, 
	output byte overflow, 
	output int flag
);

class tb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(tb_scoreboard)

  uvm_analysis_export#(tb_sequence_item) analysis_export;
  uvm_tlm_analysis_fifo#(tb_sequence_item) sb_fifo;
  tb_sequence_item item, exp_item;
  int pass_count, err_count, total_count;
  real pass_rate;
	int r_exp, zero_exp, carry_exp, negative_exp, overflow_exp, flag_exp;


  function new(string name = "tb_scoreborad" , uvm_component parent = null);
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
		  alu_model(item.a, item.b, item.aluc, r_exp, zero_exp, carry_exp, negative_exp, overflow_exp, flag_exp);
		  exp_item.a = item.a;
		  exp_item.b = item.b;
		  exp_item.aluc = item.aluc;
		  exp_item.r = r_exp;
		  exp_item.zero = zero_exp;
		  exp_item.flag = flag_exp;
		  
		  check_results();
	  end
  endtask

  task check_results();
	  if(item.flag === 'z)begin
	     if(item.r == r_exp && item.zero == zero_exp)begin
            pass_count++;
            `uvm_info("Scoreboard1", $sformatf("expected = actual, act_r: %0h, exp_r: %0h, act_zero: %0h, exp_zero: %0h", item.r, r_exp, item.zero, zero_exp), UVM_LOW);
		 end
		 else begin
			err_count++;
            `uvm_error("Scoreboard1", $sformatf("expected != actual, act_r: %0h, exp_r: %0h, act_zero: %0h, exp_zero: %0h, act_flag: %0h, exp_flag: %0h", item.r, r_exp, item.zero, zero_exp, item.flag, flag_exp));
		 end
	  end
	  else begin
	     if(item.r == r_exp && item.zero == zero_exp && item.flag == flag_exp)begin
		    pass_count++;
            `uvm_info("Scoreboard2", $sformatf("expected = actual, act_r: %0h, exp_r: %0h, act_zero: %0h, exp_zero: %0h, act_flag: %0h, exp_flag: %0h", item.r, r_exp, item.zero, zero_exp, item.flag, flag_exp), UVM_LOW);

	     end
	     else begin
		    err_count++;
            `uvm_error("Scoreboard2", $sformatf("expected != actual, act_r: %0h, exp_r: %0h, act_zero: %0h, exp_zero: %0h, act_flag: %0h, exp_flag: %0h", item.r, r_exp, item.zero, zero_exp, item.flag, flag_exp));

	     end
	  end
	  $display("act_data:");
	  item.print();
	  $display("exp_data");
	  exp_item.print();


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
