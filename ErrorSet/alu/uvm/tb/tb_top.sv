import uvm_pkg::*;
`include "uvm_macros.svh"

module tb_top ();

	bit clk ;
    initial begin
        forever begin
            #10;
            clk=!clk;
        end
    end


  // Interface
  alu_if vif(clk);

  // DUT instance
  alu dut (
    .a(vif.a),
    .b(vif.b),
    .aluc(vif.aluc),
    .r(vif.r),
    .zero(vif.zero),
    .carry(vif.carry),
    .negative(vif.negative),
    .overflow(vif.overflow),
    .flag(vif.flag)
  );

  // Run the UVM test
  initial begin
	uvm_config_db#(virtual alu_if)::set(null, "*", "vif", vif);
    run_test("tb_test");
  end

  initial begin 
		$dumpfile("test.vcd"); 
		$dumpvars(0); 
  end

endmodule
