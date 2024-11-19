`timescale 1ns/1ns

module traffic_light_tb;
    reg clk;
    reg rst_n;
    reg pass_request;
    wire [7:0] clock;
    wire dut_red, dut_yellow, dut_green;
    wire ref_red, ref_yellow, ref_green;
    reg error_flag;
    integer f_log;

    traffic_light uut (
        .clk(clk),
        .rst_n(rst_n),
        .pass_request(pass_request),
        .clock(clock),
        .red(dut_red),
        .yellow(dut_yellow),
        .green(dut_green)
    );

    traffic_light_ref reference (
        .clk(clk),
        .rst_n(rst_n),
        .pass_request(pass_request),
        .ref_red(ref_red),
        .ref_yellow(ref_yellow),
        .ref_green(ref_green)
    );

    // DUT VCD Dump
    initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
    end

  
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Simulation control
    initial begin
        rst_n = 0;
        pass_request = 0;
        error_flag = 0;
        #20 rst_n = 1; 

        repeat (1) begin
            #($random % 200 + 100); 
            pass_request = $random % 2; 
        end

        repeat (1) begin
            #($random % 500 + 500); 
            rst_n = 0;
            #10 rst_n = 1;
        end

        #5000; 
        $finish;
    end

    // Compare DUT and reference model output, log mismatches
    always @(posedge clk) begin
        if (dut_red !== ref_red || dut_yellow !== ref_yellow || dut_green !== ref_green) begin
            $display("Error at time %t: Expected (R,Y,G) = (%b,%b,%b), Got (R,Y,G) = (%b,%b,%b)",
                     $time, ref_red, ref_yellow, ref_green, dut_red, dut_yellow, dut_green);
            error_flag = 1;

            if (f_log != 0) begin
           


				   $fwrite(f_log, "Error Time: %g ns\n", $time);
                   $fwrite(f_log, "DUT Input: clk = %b, rst_n = %b, pass_request = %b, clock = %b\n", clk, rst_n, pass_request, clock);
                   $fwrite(f_log, "DUT Output: red = %b, yellow = %b, green = %b\n", dut_red, dut_yellow, dut_green);
                   $fwrite(f_log, "Reference Model Input: clk = %b, rst_n = %b, pass_request = %b, clock = %b\n", clk, rst_n, pass_request, clock);
                   $fwrite(f_log, "Reference Model Output: red = %b, yellow = %b, green = %b\n", ref_red, ref_yellow, ref_green);
                   $fwrite(f_log, "-----------------------------\n");


            end
        end

    end

    // Log file initialization and final reporting
    initial begin
        f_log = $fopen("test.txt", "w");
        if (f_log == 0) begin
            $display("Failed to open test.txt file");
            $finish;
        end

        #5536; 
        if (!error_flag) begin
            $display("===========Your Design Passed===========");
            $fwrite(f_log,"===========Your Design Passed===========");
        end else begin
            $display("===========Your Design Failed===========");
        end
    end
endmodule

module traffic_light_ref(
    input wire clk,
    input wire rst_n,
    input wire pass_request,
    output reg ref_red,
    output reg ref_yellow,
    output reg ref_green
);
    reg [1:0] state;
    reg [7:0] cnt;
    reg p_red, p_yellow, p_green;
    localparam IDLE = 2'd0, S1_RED = 2'd1, S2_YELLOW = 2'd2, S3_GREEN = 2'd3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            p_red <= 1'b0;
            p_green <= 1'b0;
            p_yellow <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    p_red <= 1'b0;
                    p_green <= 1'b0;
                    p_yellow <= 1'b0;
                    state <= S1_RED;
                end
                S1_RED: begin
                    p_red <= 1'b1;
                    p_green <= 1'b0;
                    p_yellow <= 1'b0;
                    if (cnt == 3)
                        state <= S3_GREEN;
                end
                S2_YELLOW: begin
                    p_red <= 1'b0;
                    p_green <= 1'b0;
                    p_yellow <= 1'b1;
                    if (cnt == 3)
                        state <= S1_RED;
                end
                S3_GREEN: begin
                    p_red <= 1'b0;
                    p_green <= 1'b1;
                    p_yellow <= 1'b0;
                    if (cnt == 3)
                        state <= S2_YELLOW;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 7'd10;
        else if (pass_request && ref_green && (cnt > 10))
            cnt <= 7'd10;
        else if (!ref_green && p_green)
            cnt <= 7'd60;
        else if (!ref_yellow && p_yellow)
            cnt <= 7'd5;
        else if (!ref_red && p_red)
            cnt <= 7'd10;
        else
            cnt <= cnt - 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_yellow <= 1'd0;
            ref_red <= 1'd0;
            ref_green <= 1'd0;
        end else begin
            ref_yellow <= p_yellow;
            ref_red <= p_red;
            ref_green <= p_green;
        end
    end
endmodule


