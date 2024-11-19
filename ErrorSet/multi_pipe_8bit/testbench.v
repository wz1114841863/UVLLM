
`timescale 1ns/1ns

module multi_pipe_8bit_tb();

    reg clk;
    reg rst_n;
    reg [7:0] mul_a;
    reg [7:0] mul_b;
    reg mul_en_in;
    wire mul_en_out;
    wire [15:0] mul_out;

    wire mul_en_out_ref;
    wire [15:0] mul_out_ref;

    // Instantiate DUT
    multi_pipe_8bit uut (
        .clk(clk),
        .rst_n(rst_n),
        .mul_a(mul_a),
        .mul_b(mul_b),
        .mul_en_in(mul_en_in),
        .mul_en_out(mul_en_out),
        .mul_out(mul_out)
    );

    // Instantiate Reference Model
    ref_multi_pipe_8bit ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .mul_a(mul_a),
        .mul_b(mul_b),
        .mul_en_in(mul_en_in),
        .mul_en_out(mul_en_out_ref),
        .mul_out(mul_out_ref)
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
        apply_test(8'hFF, 8'h01); // Test pattern 1
        apply_test(8'hAA, 8'h55); // Test pattern 2
        apply_test(8'h0F, 8'hF0); // Test pattern 3

		// Additional Directed Tests
        $display("Additional Directed Tests");
        apply_test(8'h00, 8'h00); // Zero input
        apply_test(8'h01, 8'h01); // Single bit input
        apply_test(8'hFF, 8'hFF); // Max value input
        apply_test(8'hF0, 8'h0F); // Half full input
        apply_test(8'h80, 8'h01); // Boundary value input
        apply_test(8'h01, 8'h80); // Boundary value input

        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(20) begin
            apply_test($random, $random);
        end

    end

    // Apply a test vector
    task apply_test(input [7:0] test_a, input [7:0] test_b);
        begin
            mul_a = test_a;
            mul_b = test_b;
            mul_en_in = 1;
            @(posedge clk);  // Enable input
            mul_en_in = 0;

            // Check results over several cycles
            repeat (5) begin
                @(posedge clk);
                check_results(test_a, test_b);
            end
        end
    endtask

    // Check results and log any mismatches
    task check_results(input [7:0] test_a, input [7:0] test_b);
        begin
            if (mul_out !== mul_out_ref || mul_en_out !== mul_en_out_ref) begin
                error_count = error_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Inputs: clk = %b, rst_n = %b, mul_a = %h, mul_b = %h, mul_en_in = %b\n", clk, rst_n, test_a, test_b, mul_en_in);
                $fwrite(log_file, "DUT Output: mul_out = %h, mul_en_out = %b\n", mul_out, mul_en_out);
                $fwrite(log_file, "Reference Inputs: clk = %b, rst_n = %b, mul_a = %h, mul_b = %h, mul_en_in = %b\n", clk, rst_n, test_a, test_b, mul_en_in);
                $fwrite(log_file, "Reference Output: mul_out = %h, mul_en_out = %b\n", mul_out_ref, mul_en_out_ref);
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
module ref_multi_pipe_8bit#(
    parameter size = 8
)(
    clk,      
    rst_n,       
    mul_a,       
    mul_b, 
    mul_en_in,
    mul_en_out,      
    mul_out    
);

    input clk;           
    input rst_n; 
    input mul_en_in;      
    input [size-1:0] mul_a;       
    input [size-1:0] mul_b;       

    output reg mul_en_out;  
    output reg [size*2-1:0] mul_out;    

    reg [2:0] mul_en_out_reg;
    always@(posedge clk or negedge rst_n)
        if(!rst_n)begin
            mul_en_out_reg <= 'd0;             
            mul_en_out     <= 'd0;                           
        end
        else begin
            mul_en_out_reg <= {mul_en_out_reg[1:0],mul_en_in};            
            mul_en_out     <= mul_en_out_reg[2];                  
        end

    reg [7:0] mul_a_reg;
    reg [7:0] mul_b_reg;
    always @(posedge clk or negedge rst_n)
        if(!rst_n) begin
            mul_a_reg <= 'd0;
            mul_b_reg <= 'd0;
        end
        else begin
            mul_a_reg <= mul_en_in ? mul_a :'d0;
            mul_b_reg <= mul_en_in ? mul_b :'d0;
        end

    wire [15:0] temp [size-1:0];
    assign temp[0] = mul_b_reg[0]? {8'b0,mul_a_reg} : 'd0;
    assign temp[1] = mul_b_reg[1]? {7'b0,mul_a_reg,1'b0} : 'd0;
    assign temp[2] = mul_b_reg[2]? {6'b0,mul_a_reg,2'b0} : 'd0;
    assign temp[3] = mul_b_reg[3]? {5'b0,mul_a_reg,3'b0} : 'd0;
    assign temp[4] = mul_b_reg[4]? {4'b0,mul_a_reg,4'b0} : 'd0;
    assign temp[5] = mul_b_reg[5]? {3'b0,mul_a_reg,5'b0} : 'd0;
    assign temp[6] = mul_b_reg[6]? {2'b0,mul_a_reg,6'b0} : 'd0;
    assign temp[7] = mul_b_reg[7]? {1'b0,mul_a_reg,7'b0} : 'd0; 

    reg [15:0] sum [3:0];
    always @(posedge clk or negedge rst_n) 
        if(!rst_n) begin
            sum[0]  <= 'd0;
            sum[1]  <= 'd0;
            sum[2]  <= 'd0;
            sum[3]  <= 'd0;
        end 
        else begin
            sum[0] <= temp[0] + temp[1];
            sum[1] <= temp[2] + temp[3];
            sum[2] <= temp[4] + temp[5];
            sum[3] <= temp[6] + temp[7];
        end

    reg [15:0] mul_out_reg;
    always @(posedge clk or negedge rst_n) 
        if(!rst_n)
            mul_out_reg <= 'd0;
        else 
            mul_out_reg <= sum[0] + sum[1] + sum[2] + sum[3];

    always @(posedge clk or negedge rst_n) 
        if(!rst_n)
            mul_out <= 'd0;
        else if(mul_en_out_reg[2])
            mul_out <= mul_out_reg;
        else
            mul_out <= 'd0;

endmodule
