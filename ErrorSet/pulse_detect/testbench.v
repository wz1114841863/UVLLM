
`timescale 1ns/1ns

module pulse_detect_tb();

    reg clk;
    reg rst_n;
    reg data_in;
    wire data_out;
    wire data_out_ref;

    // Instantiate DUT
    pulse_detect uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Instantiate Reference Model
    pulse_detect_ref ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out_ref)
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
        test_sequence(3'b000); // No pulse
        test_sequence(3'b010); // Detect pulse
        test_sequence(3'b011); // No pulse
        test_sequence(4'b0100); // Detect pulse

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(20) begin
            test_sequence($random);
        end

        //$fclose(log_file);
        //$finish;
    end

    // Apply a test sequence
    task test_sequence(input [31:0] seq);
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            data_in = seq[i];
            #10;
            check_results();
        end
    endtask

    // Check results and log any mismatches
    task check_results;
        if (data_out !== data_out_ref) begin
            error_count = error_count + 1;
            $fwrite(log_file, "Error Time: %0t ns\n", $time);
            $fwrite(log_file, "DUT Input: data_in = %b\n", data_in);
            $fwrite(log_file, "DUT Output: data_out = %b\n", data_out);
            $fwrite(log_file, "Reference Input: data_in = %b\n", data_in);
            $fwrite(log_file, "Reference Output: data_out_ref = %b\n", data_out_ref);
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
module pulse_detect_ref(
    input clk,
    input rst_n,
    input data_in,
    output reg data_out
);

    parameter s0 = 2'b00; // initial
    parameter s1 = 2'b01; // 0, 00
    parameter s2 = 2'b10; // 01
    parameter s3 = 2'b11; // 010

    reg [1:0] pulse_level1, pulse_level2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pulse_level1 <= s0;
        else
            pulse_level1 <= pulse_level2;
    end

    always @(*) begin
        case (pulse_level1)
            s0: begin
                if (data_in == 0)
                    pulse_level2 = s1;
                else
                    pulse_level2 = s0;
            end

            s1: begin
                if (data_in == 1)
                    pulse_level2 = s2;
                else
                    pulse_level2 = s1;
            end

            s2: begin
                if (data_in == 0)
                    pulse_level2 = s3;
                else
                    pulse_level2 = s0;
            end

            s3: begin
                if (data_in == 1)
                    pulse_level2 = s2;
                else
                    pulse_level2 = s1;
            end
        endcase
    end

    always @(*) begin
        if (~rst_n)
            data_out = 0;
        else if (pulse_level1 == s2 && data_in == 0)
            data_out = 1;
        else
            data_out = 0;
    end

endmodule
