
`timescale 1ns/1ns

module fsm_tb();

    reg IN;
    reg CLK;
    reg RST;
    wire MATCH;
    wire MATCH_ref;

    // Instantiate DUT
    fsm uut (
        .IN(IN),
        .MATCH(MATCH),
        .CLK(CLK),
        .RST(RST)
    );

    // Instantiate Reference Model
    ref_fsm ref_model (
        .IN(IN),
        .MATCH(MATCH_ref),
        .CLK(CLK),
        .RST(RST)
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
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    // Test sequence
    initial begin
        #10;
        reset();

        // Directed Test: Known patterns
        $display("Directed Test: Known patterns");
        apply_test(3'b101); // Sequence to reach s5
        apply_test(3'b110); // Sequence to reach s5
        apply_test(3'b100); // Sequence to reach s4
        apply_test(3'b000); // Stay in s0

		// Edge case tests
        $display("Edge Case Tests");
        apply_test(3'b000); // Test edge case
        apply_test(3'b111); // Test edge case

		// Reset during operation
        $display("Reset During Operation");
        apply_test(3'b010);
        reset();
        apply_test(3'b110);

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(10) begin
            apply_test($random);
        end

    end

    // Apply a test vector
    task apply_test(input [2:0] test_sequence);
        integer i;
        begin
            for (i = 0; i < 3; i = i + 1) begin
                IN = test_sequence[i];
                @(posedge CLK);
                check_results();
            end
        end
    endtask

    // Check results and log any mismatches
    task check_results;
        begin
            if (MATCH !== MATCH_ref) begin
                error_count = error_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Input: clk = %b, RST = %b, IN = %b\n", CLK, RST, IN);
                $fwrite(log_file, "DUT Output: MATCH = %b\n", MATCH);
                $fwrite(log_file, "Reference Input: clk = %b, RST = %b, IN = %b\n", CLK, RST, IN);
                $fwrite(log_file, "Reference Output: MATCH = %b\n", MATCH_ref);
                $fwrite(log_file, "------------------------------------\n");
            end
        end
    endtask

    // Reset task
    task reset;
    begin
        RST = 1;
        #10;
        RST = 0;
    end
    endtask

    // Display final result
    initial begin
        #1000;
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
module ref_fsm(
    input IN, CLK, RST,
    output reg MATCH
);

    reg [2:0] ST_cr, ST_nt;

    parameter s0 = 3'b000;
    parameter s1 = 3'b001;
    parameter s2 = 3'b010;
    parameter s3 = 3'b011;
    parameter s4 = 3'b100;
    parameter s5 = 3'b101;

    always @(posedge CLK or posedge RST) begin
        if (RST)
            ST_cr <= s0;
        else
            ST_cr <= ST_nt;
    end

    always @(*) begin
        case (ST_cr)
            s0: ST_nt = (IN == 0) ? s0 : s1;
            s1: ST_nt = (IN == 0) ? s2 : s1;
            s2: ST_nt = (IN == 0) ? s3 : s1;
            s3: ST_nt = (IN == 0) ? s0 : s4;
            s4: ST_nt = (IN == 0) ? s2 : s5;
            s5: ST_nt = (IN == 0) ? s2 : s1;
            default: ST_nt = s0;
        endcase
    end

    always @(*) begin
        if (RST)
            MATCH <= 0;
        else if (ST_cr == s4 && IN == 1)
            MATCH <= 1;
        else
            MATCH <= 0;
    end

endmodule
