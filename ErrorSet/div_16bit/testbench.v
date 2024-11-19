
`timescale 1ns/1ns

module div_16bit_tb();

    reg [15:0] A;
    reg [7:0] B;
    wire [15:0] result;
    wire [15:0] odd;
    wire [15:0] result_ref;
    wire [15:0] odd_ref;

    // Instantiate DUT
    div_16bit uut (
        .A(A),
        .B(B),
        .result(result),
        .odd(odd)
    );

    // Instantiate Reference Model
    ref_div_16bit ref_model (
        .A(A),
        .B(B),
        .result(result_ref),
        .odd(odd_ref)
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

    // Test sequence
    initial begin
        // Directed Test: Known patterns
        $display("Directed Test: Known patterns");
        apply_test(16'hFFFF, 8'hFF); // Max values
        apply_test(16'h1234, 8'h12); // Arbitrary values
        apply_test(16'h0000, 8'h01); // Zero dividend
        apply_test(16'hABCD, 8'h00); // Zero divisor

		// Boundary Tests
        $display("Boundary Tests");
        apply_test(16'h8000, 8'h01); // Min positive value for A
        apply_test(16'h7FFF, 8'h01); // Max positive value for A
        apply_test(16'h8000, 8'hFF); // Min positive value for A with max B
        apply_test(16'h7FFF, 8'hFF); // Max positive value for A with max B
        apply_test(16'h8000, 8'h00); // Min positive value for A with zero B (divisor zero)
        apply_test(16'hFFFF, 8'h00); // Max value for A with zero B (divisor zero)

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(20) begin
            apply_test($random, $random);
        end
    end

    // Apply a test vector
    task apply_test(input [15:0] test_A, input [7:0] test_B);
        begin
            A = test_A;
            B = test_B;
            #50;
            check_results();
        end
    endtask

    // Check results and log any mismatches
    task check_results;
        begin
            if (result !== result_ref || odd !== odd_ref) begin
                error_count = error_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Input: A = %h, B = %h\n", A, B);
                $fwrite(log_file, "DUT Output: result = %h, odd = %h\n", result, odd);
                $fwrite(log_file, "Reference Input: A = %h, B = %h\n", A, B);
                $fwrite(log_file, "Reference Output: result = %h, odd = %h\n", result_ref, odd_ref);
                $fwrite(log_file, "------------------------------------\n");
            end
        end
    endtask

    // Display final result
    initial begin
        #500;
        if (error_count == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule

// Reference model definition
module ref_div_16bit(
    input [15:0] A,
    input [7:0] B,
    output reg [15:0] result,
    output reg [15:0] odd
);
 
	reg [15:0] a_reg;
    reg [15:0] b_reg;
    reg [31:0] tmp_a;
    reg [31:0] tmp_b;
    integer i;
    
    always@(*) begin
        a_reg = A;
        b_reg = B;
    end
    
    always@(*) begin
        begin
            tmp_a = {16'b0, a_reg};
            tmp_b = {b_reg, 16'b0};
            for(i = 0;i < 16;i = i+1) begin
                tmp_a = tmp_a << 1;
                if (tmp_a >= tmp_b) begin
                    tmp_a = tmp_a - tmp_b + 1;
                end
                else begin
                    tmp_a = tmp_a;
                end
            end
        end
    end
    
    assign odd = tmp_a[31:16];
    assign result = tmp_a[15:0];
	

endmodule
