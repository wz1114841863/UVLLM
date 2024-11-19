
`timescale 1ns/1ps

module right_shifter_tb();

    reg clk;
    reg d;
    wire [7:0] q_dut;
    wire [7:0] q_ref;

    // Instantiate DUT
    right_shifter uut (
        .clk(clk),
        .d(d),
        .q(q_dut)
    );

    // Instantiate Reference Model
    reference_model ref_model (
        .clk(clk),
        .d(d),
        .q(q_ref)
    );

    integer log_file;
    integer error = 0;

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
        #20;

        // Directed test case 1: Shifting in a known sequence
        $display("Directed Test 1: Shifting in known sequence");
        d = 1;
        repeat(8) @(posedge clk);
        #10;
        check_results();

        // Directed test case 2: Shifting with alternating bits
        $display("Directed Test 2: Shifting with alternating bits");
        d = 0;
        repeat(8) @(posedge clk);
        d = 1;
        repeat(8) @(posedge clk);
        #10;
        check_results();
    end

    // Random test sequence
    initial begin
        #200;
        
        $display("Random Test: Random d values over multiple cycles");
        repeat(50) begin
            d = $random % 2;
            #10;
            check_results();
        end
        
        //$fclose(log_file);
        //$finish;
    end

    // Check results and log any mismatches
    task check_results;
        if (q_dut !== q_ref) begin
            error = error + 1;
            $fwrite(log_file, "Error Time: %0t ns\n", $time);
            $fwrite(log_file, "DUT Input: d = %b\n", d);
            $fwrite(log_file, "DUT Output: q = %b\n", q_dut);
            $fwrite(log_file, "Reference Model Input: d = %b\n", d);
            $fwrite(log_file, "Reference Model Output: q = %b\n", q_ref);
            $fwrite(log_file, "------------------------------------\n");
        end
    endtask

    // Display final result
    initial begin
        #1000;
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule

// Reference Model Module (using DUT's logic directly)
module reference_model(
    input clk,
    input d,
    output reg [7:0] q
);

    initial q = 0;

    always @(posedge clk) begin
        q <= (q >> 1);
        q[7] <= d;
    end

endmodule
