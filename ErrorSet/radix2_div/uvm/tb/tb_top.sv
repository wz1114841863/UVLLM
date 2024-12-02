`include "uvm_macros.svh"
import uvm_pkg::*;

module tb_top();
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    logic clk;
    logic rst;
    
	radix2_div_if div_if(clk, rst);

    radix2_div dut (
        .clk(clk),
        .rst(rst),
        .dividend(div_if.dividend),
        .divisor(div_if.divisor),
        .sign(div_if.sign),
        .opn_valid(div_if.opn_valid),
        .res_valid(div_if.res_valid),
        .res_ready(div_if.res_ready),
        .result(div_if.result)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #20 rst = 0;
    end

    initial begin
        run_test("radix2_div_test");
    end

    initial begin
        uvm_config_db#(virtual radix2_div_if)::set(null, "*", "vif", div_if);
    end

	initial begin 
		$dumpfile("test.vcd"); 
		$dumpvars(0); 
    end

endmodule

