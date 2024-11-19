
`timescale 1ns/1ps

module serial2parallel_tb();

    reg clk;
    reg rst_n;
    reg din_serial;
    reg din_valid;
    wire [7:0] dout_parallel_dut;
    wire dout_valid_dut;

    // Instantiate DUT
    serial2parallel uut (
        .clk(clk),
        .rst_n(rst_n),
        .din_serial(din_serial),
        .din_valid(din_valid),
        .dout_parallel(dout_parallel_dut),
        .dout_valid(dout_valid_dut)
    );

    // Instantiate Reference Model
    wire [7:0] dout_parallel_ref;
    wire dout_valid_ref;
    
    reference_model ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .din_serial(din_serial),
        .din_valid(din_valid),
        .dout_parallel(dout_parallel_ref),
        .dout_valid(dout_valid_ref)
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

    // Reset generation
    initial begin
        rst_n = 0;
        #15 rst_n = 1;
    end

    // Test sequence
    initial begin
        #20;
        
        // Test 1: Send a sequence of 8 din_serial bits with din_valid high
        din_valid = 1;
        din_serial = 1;
        repeat(8) @(posedge clk);
        #10;
        check_results();

        // Test 2: Interrupt sequence with din_valid low
        din_valid = 1;
        din_serial = 1;
        repeat(4) @(posedge clk);
        
        din_valid = 0;  // Set din_valid low mid-sequence
        repeat(4) @(posedge clk);
        #10;
        check_results();
    end

    // Random test sequence
    initial begin
        #200;
        
        repeat(50) begin
            din_valid = $random % 2;
            din_serial = $random % 2;
            #10;
            check_results();
        end
        
    end

    // Check results and log any mismatches
    task check_results;
        if ((dout_parallel_dut !== dout_parallel_ref) || (dout_valid_dut !== dout_valid_ref)) begin
            error = error + 1;
            
			$fwrite(log_file, "Error Time: %0t ns\n", $time); 
			$fwrite(log_file, "DUT Input: din_serial = %b, din_valid = %b\n", din_serial, din_valid);
            $fwrite(log_file, "DUT Output: dout_parallel = %b, dout_valid = %b\n", uut.dout_parallel, uut.dout_valid);
            $fwrite(log_file, "Reference Model Input: din_serial = %b, din_valid = %b\n", din_serial, din_valid);
            $fwrite(log_file, "Reference Model Output: dout_parallel = %b, dout_valid = %b\n", dout_parallel_ref, dout_valid_ref);
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
    input rst_n,
    input din_serial,
    input din_valid,
    output reg [7:0] dout_parallel,
    output reg dout_valid
);

    reg [7:0] din_tmp;
    reg [3:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else if (din_valid)
            cnt <= (cnt == 4'd8) ? 0 : cnt + 1'b1;
        else
            cnt <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            din_tmp <= 8'b0;
        else if (din_valid && cnt <= 4'd7)
            din_tmp <= {din_tmp[6:0], din_serial};
    end 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_valid <= 1'b0;
            dout_parallel <= 8'b0;
        end
        else if (cnt == 4'd8) begin
            dout_valid <= 1'b1;
            dout_parallel <= din_tmp;
        end
        else begin
            dout_valid <= 1'b0;
        end
    end

endmodule
