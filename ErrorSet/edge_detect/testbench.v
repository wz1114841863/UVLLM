
`timescale 1ns/1ns

module edge_detect_tb();

    reg a;
    reg clk;
    reg rst_n;
    wire rise;
    wire down;
    wire rise_ref;
    wire down_ref;

    // Instantiate DUT
    edge_detect uut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .rise(rise),
        .down(down)
    );

    // Instantiate Reference Model
    ref_edge_detect ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .rise(rise_ref),
        .down(down_ref)
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
        forever #5 clk = ~clk;  // 100MHz clock
    end

    // Test sequence
    initial begin
        #10;
        reset();

        // Directed Test: Known patterns
        $display("Directed Test: Known patterns");
        apply_test(2'b01); // Rising edge
        apply_test(2'b10); // Falling edge
        apply_test(2'b00); // No edge
        apply_test(2'b11); // No edge

        // Reset during operation
        $display("Reset During Operation");
        apply_test(2'b01);
        reset();
        apply_test(2'b10);

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(10) begin
            apply_test($random);
        end
    end

    // Apply a test vector
    task apply_test(input [1:0] test_sequence);
        integer i;
        begin
            for (i = 0; i < 2; i = i + 1) begin
                a = test_sequence[i];
                @(posedge clk);
                check_results();
            end
        end
    endtask

    // Check results and log any mismatches
    task check_results;
        begin
            if (rise !== rise_ref || down !== down_ref) begin
                error_count = error_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Input: clk = %b, rst_n = %b, a = %b\n", clk, rst_n, a);
                $fwrite(log_file, "DUT Output: rise = %b, down = %b\n", rise, down);
                $fwrite(log_file, "Reference Input: clk = %b, rst_n = %b, a = %b\n", clk, rst_n, a);
                $fwrite(log_file, "Reference Output: rise = %b, down = %b\n", rise_ref, down_ref);
                $fwrite(log_file, "------------------------------------\n");
            end
        end
    endtask

    // Reset task
    task reset;
    begin
        rst_n = 0;
        #10;
        rst_n = 1;
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
module ref_edge_detect(
    input clk, rst_n, a,
    output reg rise, down
);

    reg a0;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rise <= 1'b0;
            down <= 1'b0;
            a0 <= 1'b0;
        end else begin
            if (a && ~a0) begin
                rise <= 1;
                down <= 0;
            end else if (~a && a0) begin
                rise <= 0;
                down <= 1;
            end else begin
                rise <= 0;
                down <= 0;
            end
            a0 <= a;
        end
    end

endmodule
