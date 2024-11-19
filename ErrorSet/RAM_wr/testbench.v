`timescale 1ns/1ps

module RAM_wr_tb();

    reg clk;
    reg rst_n;
    reg write_en;
    reg [7:0] write_addr;
    reg [5:0] write_data;
    reg read_en;
    reg [7:0] read_addr;
    wire [5:0] read_data_dut;
    wire [5:0] read_data_ref;

    // Instantiate DUT
    RAM_wr uut (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_en(read_en),
        .read_addr(read_addr),
        .read_data(read_data_dut)
    );

    // Instantiate Reference Model
    reference_model ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_en(read_en),
        .read_addr(read_addr),
        .read_data(read_data_ref)
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
        reset();

        // Directed test case 1: Write and read back data
        $display("Directed Test 1: Write and read back data");
        write_en = 1;
        write_addr = 8'h01;
        write_data = 6'd15;
        #10;
        write_en = 0;
        read_en = 1;
        read_addr = 8'h01;
        #10;
        check_results();
        read_en = 0;

        // Directed test case 2: Check reset clears memory
        $display("Directed Test 2: Check reset clears memory");
        reset();
        read_en = 1;
        read_addr = 8'h01;
        #10;
        check_results();
        read_en = 0;
    end

    // Random test sequence
    initial begin
        #200;
        
        $display("Random Test: Random write and read operations");
        repeat(50) begin
            write_en = 1;
            write_addr = $random % 12;
            write_data = $random % 64;
            #10;
            write_en = 0;

            read_en = 1;
            read_addr = write_addr;
            #10;
            check_results();
            read_en = 0;
        end
        
        //$fclose(log_file);
        //$finish;
    end

    // Check results and log any mismatches
    task check_results;
        if (read_data_dut !== read_data_ref) begin
            error = error + 1;
            $fwrite(log_file, "Error Time: %0t ns\n", $time);

            $fwrite(log_file, "DUT Input: write_addr = %h, write_data = %h, read_addr = %h\n", write_addr, write_data, read_addr);
            $fwrite(log_file, "DUT Output: read_data = %h\n", read_data_dut);
            $fwrite(log_file, "Reference Model Input: write_addr = %h, write_data = %h, read_addr = %h\n", write_addr, write_data, read_addr);
            $fwrite(log_file, "Reference Model Output: read_data = %h\n", read_data_ref);
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
    input write_en,
    input [7:0] write_addr,
    input [5:0] write_data,
    input read_en,
    input [7:0] read_addr,
    output reg [5:0] read_data
);

    reg [7:0] RAM [11:0];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                RAM[i] <= 8'd0;
            end
        end else if (write_en) begin
            RAM[write_addr] <= write_data;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data <= 6'd0;
        end else if (read_en) begin
            read_data <= RAM[read_addr];
        end else begin
            read_data <= 6'd0;
        end
    end

endmodule
