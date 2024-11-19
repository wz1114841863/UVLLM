
`timescale 1ns/1ns

module tb_multi_16bit;

    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] ain;
    reg [15:0] bin;
    wire [31:0] yout;
    wire done;

    integer fail_count = 0;
    integer log_file;
    reg [31:0] expected_product;

    // Instantiate DUT
    multi_16bit uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .ain(ain),
        .bin(bin),
        .yout(yout),
        .done(done)
    );

    // Instantiate Reference Model
    wire [31:0] ref_yout;
    wire ref_done;

    reference_model ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .ain(ain),
        .bin(bin),
        .yout(ref_yout),
        .done(ref_done)
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
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        #10;
        reset();

        // Directed Test: Known patterns
        $display("Directed Test: Known patterns");
        apply_test(16'hFFFF, 16'h0001); // Test pattern 1
        apply_test(16'hAAAA, 16'h5555); // Test pattern 2
        apply_test(16'h0000, 16'hFFFF); // Test pattern 3

        // Additional Directed Tests
        $display("Additional Directed Tests");
        apply_test(16'h0000, 16'h0000); // Zero input
        apply_test(16'h0001, 16'h0001); // Single bit input
        apply_test(16'hFFFF, 16'hFFFF); // Max value input
        apply_test(16'h8000, 16'h0001); // Boundary value input
        apply_test(16'h0001, 16'h8000); // Boundary value input

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(50) begin
            apply_test($random, $random);
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

    // Apply a test vector
    task apply_test(input [15:0] test_a, input [15:0] test_b);
        begin
            ain = test_a;
            bin = test_b;
            start = 1;
            @(posedge clk);
            start = 0; // Ensure start is deasserted after one clock cycle


            if (yout !== ref_yout || done !== ref_done) begin
                fail_count = fail_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Inputs: ain = %h, bin = %h\n", test_a, test_b);
                $fwrite(log_file, "DUT Output: yout = %h, done = %h\n", yout, done);
                $fwrite(log_file, "Reference Inputs: ain = %h, bin = %h\n", test_a, test_b);
                $fwrite(log_file, "Reference Output: yout = %h, done = %h\n", ref_yout, ref_done);
                $fwrite(log_file, "------------------------------------\n");
            end
        end
    endtask

    // Reset task
    task reset;
    begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end
    endtask

endmodule

module reference_model(
    input clk,
    input rst_n,
    input start,
    input [15:0] ain,
    input [15:0] bin,
    output reg [31:0] yout,
    output reg done
);

    reg [15:0] areg;
    reg [15:0] breg;
    reg [31:0] yout_r;
	reg done_r;
    reg [4:0] i;

 
	always @(posedge clk or negedge rst_n)
    if (!rst_n) i <= 5'd0;
    else if (start && i < 5'd17) i <= i + 1'b1; 
    else if (!start) i <= 5'd0;

    always @(posedge clk or negedge rst_n)
    if (!rst_n) done_r <= 1'b0;
    else if (i == 5'd16) done_r <= 1'b1; 
    else if (i == 5'd17) done_r <= 1'b0; 

    assign done = done_r;

    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
        areg <= 16'h0000;
        breg <= 16'h0000;
        yout_r <= 32'h00000000;
    end
    else if (start) begin 
		if (i == 5'd0) begin 
            areg <= ain;
            breg <= bin;
        end
        else if (i > 5'd0 && i < 5'd17) begin
            if (areg[i-1]) 
            yout_r <= yout_r + ({16'h0000, breg} << (i-1)); 
        end
    end
end

assign yout = yout_r;


endmodule



