
`timescale 1ns/1ns

module parallel2serial_tb();

    reg clk;
    reg rst_n;
    reg [3:0] d;
    wire valid_out;
    wire dout;
    wire valid_out_ref;
    wire dout_ref;

    // Instantiate DUT
    parallel2serial uut (
        .clk(clk),
        .rst_n(rst_n),
        .d(d),
        .valid_out(valid_out),
        .dout(dout)
    );

    // Instantiate Reference Model
    parallel2serial_ref ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .d(d),
        .valid_out(valid_out_ref),
        .dout(dout_ref)
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
        apply_test(4'b1010); // Test pattern 1
        apply_test(4'b1100); // Test pattern 2
        apply_test(4'b1111); // Test pattern 3

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(20) begin
            apply_test($random);
        end

    end

    // Apply a test vector
    task apply_test(input [3:0] test_d);
        begin
           	d = test_d;
            repeat(4) begin
                @(posedge clk);
                check_results();
            end
        end
    endtask

    // Check results and log any mismatches
    task check_results;
        if (dout !== dout_ref || valid_out !== valid_out_ref) begin
            error_count = error_count + 1;
            $fwrite(log_file, "Error Time: %0t ns\n", $time);
            $fwrite(log_file, "DUT Input: clk = %b, rst_n = %b, d = %b\n", clk, rst_n, d);
            $fwrite(log_file, "DUT Output: dout = %b, valid_out = %b\n", dout, valid_out);
            $fwrite(log_file, "Reference Input: clk = %b, rst_n = %b, d = %b\n", clk, rst_n, d);
            $fwrite(log_file, "Reference Output: dout = %b, valid_out = %b\n", dout_ref, valid_out_ref);
            $fwrite(log_file, "------------------------------------\n");
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

// Reference Model Module
module parallel2serial_ref(
    input wire clk,
    input wire rst_n,
    input wire [3:0] d,
    output reg valid_out,
    output reg dout
);

    reg [3:0] data = 'd0;
    reg [1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 'd0;
            cnt <= 'd0;
            valid_out <= 'd0;
        end else begin
            if (cnt == 'd3) begin
                data <= d;
                cnt <= 'd0;
                valid_out <= 1;
            end else begin
                cnt <= cnt + 'd1;
                valid_out <= 0;
                data <= {data[2:0], data[3]};
            end
        end
    end

    always @(*) begin
        dout = data[3];
    end

endmodule
