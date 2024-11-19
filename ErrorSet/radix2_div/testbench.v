
`timescale 1ns/1ps

module radix2_div_tb();

    reg clk;
    reg rst;
    reg [7:0] dividend;
    reg [7:0] divisor;
    reg sign;
    reg opn_valid;
    reg res_ready;
    wire res_valid;
    wire [15:0] result_dut;
    wire [15:0] result_ref;
    wire res_valid_ref;

    // Instantiate DUT
    radix2_div uut (
        .clk(clk),
        .rst(rst),
        .dividend(dividend),
        .divisor(divisor),
        .sign(sign),
        .opn_valid(opn_valid),
        .res_valid(res_valid),
        .res_ready(res_ready),
        .result(result_dut)
    );

    // Instantiate Reference Model
    reference_model ref_model (
        .clk(clk),
        .rst(rst),
        .dividend(dividend),
        .divisor(divisor),
        .sign(sign),
        .opn_valid(opn_valid),
        .res_ready(res_ready),
        .res_valid(res_valid_ref),
        .result(result_ref)
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

        // Directed test case 1: Simple division
        $display("Directed Test 1: Simple division");
        sign = 0;
        dividend = 8'd20;
        divisor = 8'd4;
        opn_valid = 1;
        res_ready = 1;
        #10;
        opn_valid = 0;
        wait(res_valid);
        check_results();

        // Directed test case 2: Signed division
        $display("Directed Test 2: Signed division");
        sign = 1;
        dividend = -8'd20;
        divisor = 8'd4;
        opn_valid = 1;
        #10;
        opn_valid = 0;
        wait(res_valid);
        check_results();
    end

    // Random test sequence
    initial begin
        #200;
        
        $display("Random Test: Random division operations");
        repeat(50) begin
            sign = $random % 2;
            dividend = $random;
            divisor = $random % 255 + 1; // Avoid division by zero
            opn_valid = 1;
            #10;
            opn_valid = 0;
            wait(res_valid);
            check_results();
        end
        
        $fclose(log_file);
        $finish;
    end

    // Check results and log any mismatches
    task check_results;
        if (result_dut !== result_ref || res_valid !== res_valid_ref) begin
            error = error + 1;
            $fwrite(log_file, "Error Time: %0t ns\n", $time);
            $fwrite(log_file, "DUT Input: dividend = %b, divisor = %b, sign = %b, opn_valid = %b, res_ready = %b\n", dividend, divisor, sign, opn_valid, res_ready);
            $fwrite(log_file, "DUT Output: result = %h, res_valid = %b\n", result_dut, res_valid);
            $fwrite(log_file, "Reference Model Input: dividend = %b, divisor = %b, sign = %b, opn_valid = %b, res_ready = %b\n", dividend, divisor, sign, opn_valid, res_ready);
            $fwrite(log_file, "Reference Model Output: result = %h, res_valid = %b\n", result_ref, res_valid_ref);
            $fwrite(log_file, "------------------------------------\n");
        end
    endtask

    // Reset task
    task reset;
    begin
        rst = 1;
        #10;
        rst = 0;
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
    input wire clk,
    input wire rst,
    input wire [7:0] dividend,
    input wire [7:0] divisor,
    input wire sign,
    input wire opn_valid,
    input wire res_ready,
    output reg res_valid,
    output reg [15:0] result
);

    reg [7:0] dividend_save, divisor_save;
    reg [15:0] SR;
    reg [8:0] NEG_DIVISOR;
    wire [7:0] REMAINER, QUOTIENT;
    assign REMAINER = SR[15:8];
    assign QUOTIENT = SR[7:0];

    wire [7:0] divident_abs;
    wire [8:0] divisor_abs;
    wire [7:0] remainer, quotient;

    assign divident_abs = (sign & dividend[7]) ? ~dividend + 1'b1 : dividend;
    assign remainer = (sign & dividend_save[7]) ? ~REMAINER + 1'b1 : REMAINER;
    assign quotient = sign & (dividend_save[7] ^ divisor_save[7]) ? ~QUOTIENT + 1'b1 : QUOTIENT;
    assign result = {remainer, quotient};

    wire CO;
    wire [8:0] sub_result;
    wire [8:0] mux_result;

    assign {CO, sub_result} = {1'b0, REMAINER} + NEG_DIVISOR;
    assign mux_result = CO ? sub_result : {1'b0, REMAINER};

    reg [3:0] cnt;
    reg start_cnt;
    always @(posedge clk) begin
        if (rst) begin
            SR <= 0;
            dividend_save <= 0;
            divisor_save <= 0;
            cnt <= 0;
            start_cnt <= 1'b0;
            res_valid <= 0;
        end
        else if (~start_cnt & opn_valid) begin
            cnt <= 1;
            start_cnt <= 1'b1;
            dividend_save <= dividend;
            divisor_save <= divisor;
            SR[15:0] <= {7'b0, divident_abs, 1'b0}; 
            NEG_DIVISOR <= (sign & divisor[7]) ? {1'b1, divisor} : ~{1'b0, divisor} + 1'b1; 
            res_valid <= 0;
        end
        else if (start_cnt) begin
            if (cnt[3]) begin    
                cnt <= 0;
                start_cnt <= 1'b0;
                SR[15:8] <= mux_result[7:0];
                SR[0] <= CO;
                res_valid <= 1;
            end
            else begin
                cnt <= cnt + 1;
                SR[15:0] <= {mux_result[6:0], SR[7:1], CO, 1'b0}; 
            end
        end
    end
endmodule
