`include "uvm_macros.svh"
import uvm_pkg::*;

module tb_top ();
  
  bit clk;
  bit rst_n;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  // Interface instantiation
  accu_if vif(clk, rst_n);

  // Instantiate DUT
  accu dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(vif.data_in),
    .valid_in(vif.valid_in),
    .valid_out(vif.valid_out),
    .data_out(vif.data_out)
  );

 
  // Run the test
  initial begin
	uvm_config_db#(virtual accu_if)::set(null, "*", "vif", vif);
    run_test("accu_test");
  end

  initial begin 
		$dumpfile("test.vcd"); 
		$dumpvars(0); 
  end

endmodule

