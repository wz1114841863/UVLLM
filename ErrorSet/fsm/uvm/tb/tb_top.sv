`include "uvm_macros.svh"
import uvm_pkg::*;


module tb_top ();
  logic CLK, RST;
  logic IN, MATCH;

  // Interface instantiation
  fsm_if fsm_if(CLK, RST);

  // DUT instantiation
  fsm dut (
    .IN(fsm_if.IN),
    .MATCH(fsm_if.MATCH),
    .CLK(CLK),
    .RST(RST)
  );

  // Clock generation
  initial begin
    CLK = 0;
    forever #5 CLK = ~CLK; // 100 MHz clock
  end

  // Reset generation
  initial begin
    RST = 1;
    #5 RST = 0; // Deassert reset after 10 ns
  end

  // UVM run
  initial begin
	uvm_config_db#(virtual fsm_if)::set(null, "*", "vif", fsm_if);
    run_test("test");
  end

  initial begin 
		$dumpfile("test.vcd"); 
		$dumpvars(0); 
  end

endmodule
