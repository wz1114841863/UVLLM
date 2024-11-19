
`timescale 1ns/1ns

module pe_tb();

    reg clk;
    reg rst;
    reg [31:0] a;
    reg [31:0] b;
    wire [31:0] c;
    wire [31:0] c_ref;

    // Instantiate DUT
    pe uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .c(c)
    );

    // Instantiate Reference Model
    pe_ref ref_model (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .c(c_ref)
    );

    integer log_file;
    integer error_count = 0;

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
        apply_test(32'd1, 32'd2); // Test 1
        apply_test(32'd3, 32'd4); // Test 2
        apply_test(32'd5, 32'd6); // Test 3

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(10) begin
            apply_test($random, $random);
        end

    end

    // Apply a test vector
    task apply_test(input [31:0] test_a, input [31:0] test_b);
        begin
            a = test_a;
            b = test_b;
            #10;
            check_results();
        end
    endtask

    // Check results and log any mismatches
    task check_results;
        if (c !== c_ref) begin
            error_count = error_count + 1;
            $fwrite(log_file, "Error Time: %0t ns\n", $time);
            $fwrite(log_file, "DUT Inputs: a = %d, b = %d\n", a, b);
            $fwrite(log_file, "DUT Output: c = %d\n", c);
            $fwrite(log_file, "Reference Inputs: a = %d, b = %d\n", a, b);
            $fwrite(log_file, "Reference Output: c = %d\n", c_ref);
            $fwrite(log_file, "------------------------------------\n");
        end
    endtask

    // Reset task
    task reset;
    begin
        rst = 1;
        #10;
        rst = 0;
    end
    endtask

    // Display final result
    initial begin
        #1000;
        if (error_count == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule

// Reference Model Module
module pe_ref(
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] c
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            c <= 0;
        else
            c <= c + a * b;
    end

endmodule
