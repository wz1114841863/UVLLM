
`timescale 1ns / 1ps

module tb_multi_booth_8bit;
    // Inputs
    reg clk;
    reg reset;
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [15:0] p;
    wire rdy;
    wire [15:0] ref_p;
    wire ref_rdy;

	integer fail_count = 0;
    integer log_file;

    
    // Instantiate the DUT
    multi_booth_8bit uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .p(p),
        .rdy(rdy)
    );
    
    // Instantiate the reference DUT
    ref_multi_booth_8bit ref_dut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .p(ref_p),
        .rdy(ref_rdy)
    );

	initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end

	initial begin
        log_file = $fopen("test.txt", "w");
    end


    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end
    
    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        a = 0;
        b = 0;
        
        // Apply reset
        #10 reset = 0;
        
        // Directed test cases
        run_test(8'd15, 8'd3);  // 15 * 3 = 45
        run_test(-8, -2);       // -8 * -2 = 16
        run_test(8'd7, -5);     // 7 * -5 = -35
        run_test(8'd0, 8'd10);  // 0 * 10 = 0

        // Random test cases
        repeat (1000) begin
            run_test($random, $random);
        end
        
		// Display final result
        #1000;
        if (fail_count == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========");
        end else begin
            $display("=========== Your Design Failed ===========");
        end

        $finish;
    end

    // Task to run a single test
    task run_test(input signed [7:0] test_a, input signed [7:0] test_b);
        begin
            // Apply inputs
            a = test_a;
            b = test_b;
            
            // Wait for both DUT and reference DUT to complete
            wait(rdy && ref_rdy);
            
            // Check result
            if (p !== ref_p) begin
				fail_count = fail_count + 1;
				$fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Inputs: a = %h, b = %h\n", a, b);
                $fwrite(log_file, "DUT Output: p = %h\n", p);
                $fwrite(log_file, "Reference Inputs: a = %h, b = %h\n", a, b);
                $fwrite(log_file, "Reference Output: p = %h\n", ref_p);
                $fwrite(log_file, "------------------------------------\n");
            end else begin
                $display("PASS: a=%d, b=%d, p=%d", a, b, p);
            end
            
            // Reset for next test
            reset = 1;
            #10 reset = 0;
        end
    endtask
endmodule


module ref_multi_booth_8bit (p, rdy, clk, reset, a, b);
   input clk, reset;
   input [7:0] a, b;
   output [15:0] p;
   output rdy;
   
   reg [15:0] p;
   reg [15:0] multiplier;
   reg [15:0] multiplicand;
   reg rdy;
   reg [4:0] ctr;

always @(posedge clk or posedge reset) begin
    if (reset) 
    begin
    rdy     <= 0;
    p   <= 0;
    ctr     <= 0;
    multiplier <= {{8{a[7]}}, a};
    multiplicand <= {{8{b[7]}}, b};
    end 
    else 
    begin 
      if(ctr < 16) 
          begin
          multiplicand <= multiplicand << 1;
            if (multiplier[ctr] == 1)
            begin
                p <= p + multiplicand;
            end
            ctr <= ctr + 1;
          end
       else 
           begin
           rdy <= 1;
           end
    end
  end     
endmodule

