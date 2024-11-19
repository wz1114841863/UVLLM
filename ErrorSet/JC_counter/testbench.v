
`timescale 1ns/1ns

module JC_counter_tb();

    reg clk;
    reg rst_n;
    wire [63:0] Q;
    wire [63:0] Q_ref;

    // Instantiate DUT
    JC_counter uut (
        .clk(clk),
        .rst_n(rst_n),
        .Q(Q)
    );

    // Instantiate Reference Model
    JC_counter_ref ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .Q(Q_ref)
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
        apply_test(64'h0000000000000000); // All zeros
        apply_test(64'hFFFFFFFFFFFFFFFF); // All ones
        apply_test(64'h8000000000000000); // Single one at MSB
        apply_test(64'h0000000000000001); // Single one at LSB

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(10) begin
            apply_test($random);
        end

        $fclose(log_file);
        $finish;
    end

    // Apply a test vector
    task apply_test(input [63:0] test_Q);
        begin
            // Initialize Q
            force uut.Q = test_Q;
            force ref_model.Q = test_Q;

            // Release force after initialization
            #1 release uut.Q;
            release ref_model.Q;

            // Check results over several cycles
            repeat (10) begin
                @(posedge clk);
                check_results(test_Q);
            end
        end
    endtask

    // Check results and log any mismatches
    task check_results(input [63:0] test_Q);
        begin
            if (Q !== Q_ref) begin
                error_count = error_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Input: clk = %b, rst_n = %b\n", clk, rst_n);
                $fwrite(log_file, "DUT Output: Q = %h\n", Q);
                $fwrite(log_file, "Reference Input: clk = %b, rst_n = %b\n", clk, rst_n);
                $fwrite(log_file, "Reference Output: Q = %h\n", Q_ref);
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

// Reference model definition
module JC_counter_ref(
   input                clk ,
   input                rst_n,
 
   output reg [63:0]     Q  
);
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) Q <= 'd0;
        else if(!Q[0]) Q <= {1'b1, Q[63 : 1]};
        else Q <= {1'b0, Q[63 : 1]};
    end
endmodule
