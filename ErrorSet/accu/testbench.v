
`timescale 1ns/1ns

module tb_accu;
    reg clk;
    reg rst_n;
    reg [7:0] data_in;
    reg valid_in;
    wire valid_out;
    wire [9:0] data_out;

    wire [9:0] ref_data_out;
    wire ref_valid_out;

    reg error_flag;
    integer f_test, f_log;

    // Instantiate the DUT
    accu uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    // Instantiate the reference model
    ref_accumulator reference (
        .clk(clk),
        .rst_n(rst_n),
        .input_data(data_in),
        .input_valid(valid_in),
        .output_valid(ref_valid_out),
        .output_data(ref_data_out)
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    task check_result;
        input [31:0] test_num;
        begin
            if (data_out !== ref_data_out || valid_out !== ref_valid_out) begin
                $display("Test %0d Failed. Expected: %d, Got: %d (Valid: %b, Expected Valid: %b)", 
                         test_num, ref_data_out, data_out, valid_out, ref_valid_out);
                error_flag = 1;
                if (f_log != 0) begin

					
				   $fwrite(f_log, "Error Time: %g ns\n", $time);
                   $fwrite(f_log, "DUT Input: clk = %b, rst_n = %b, data_in = %b, valid_in = %b\n", clk, rst_n, data_in, valid_in);
                   $fwrite(f_log, "DUT Output: data_out = %b, valid_out = %b\n", data_out, valid_out);
                   $fwrite(f_log, "Reference Model Input: clk = %b, rst_n = %b, data_in = %b, valid_in = %b\n", clk, rst_n, data_in, valid_in);
                   $fwrite(f_log, "Reference Model Output: data_out = %b, valid_out = %b\n", ref_data_out, ref_valid_out);
                   $fwrite(f_log, "-----------------------------\n");

				end
				
            end else begin
                $display("Test %0d Passed.", test_num);
            end
        end
    endtask

    initial begin
        rst_n = 0;
        data_in = 0;
        valid_in = 0;
        error_flag = 0;
        #20 rst_n = 1;

        // Test 1: Accumulate 4 values
        #10;
        valid_in = 1;
        data_in = 8'd10;
        #10;
        data_in = 8'd20;
        #10;
        data_in = 8'd30;
        #10;
        data_in = 8'd40;
        #10;
        valid_in = 0;

        // Wait for valid_out with timeout
        wait_for_valid_out(1);

        // Test 2: Reset and accumulate another set of data
        #10;
        rst_n = 0;
        #10;
        rst_n = 1;
        valid_in = 1;
        data_in = 8'd5;
        #10;
        data_in = 8'd15;
        #10;
        data_in = 8'd25;
        #10;
        data_in = 8'd35;
        #10;
        valid_in = 0;

        // Wait for valid_out with timeout
        wait_for_valid_out(2);

        // Randomized Test
        repeat (10) begin
            rst_n = 0;
            #10;
            rst_n = 1;
            valid_in = 1;
            data_in = $random % 256;
            #10;
            data_in = $random % 256;
            #10;
            data_in = $random % 256;
            #10;
            data_in = $random % 256;
            #10;
            valid_in = 0;

            // Wait for valid_out with timeout
            wait_for_valid_out(3);
        end
	end

	
    initial begin
            f_log = $fopen("test.txt", "w");
            if (f_log == 0) begin
                 $display("Failed to open test.txt file");
                 $finish;
            end

            #1000; 
            if (!error_flag) begin
               $display("===========Your Design Passed===========");
               $fwrite(f_log,"===========Your Design Passed===========");
            end else begin
               $display("===========Your Design Failed===========");
            end
            $finish;
    end

    
    task wait_for_valid_out;
        input [31:0] test_num;
        integer timeout;
        begin
            timeout = 0;
            while (!valid_out && timeout < 100) begin
                #10;
                timeout = timeout + 1;
            end

            if (timeout >= 100) begin
                $display("Timeout waiting for valid_out in Test %0d", test_num);
                error_flag = 1;
            end else begin
                #10;
                check_result(test_num);
            end
        end
    endtask
   
endmodule

module ref_accumulator(
    input               clk         ,   
    input               rst_n       ,
    input       [7:0]   input_data  ,
    input               input_valid , 
 
    output  reg         output_valid, 
    output  reg [9:0]   output_data
);
    
   reg [1:0] count_stage; 
   wire stage_increment; 
   wire process_ready; 
   wire stage_reset; 
   reg [9:0]   sum_data; 

   assign stage_increment = process_ready; 
   assign stage_reset = process_ready && (count_stage == 'd3); 
   
   //count_stage
   always @(posedge clk or negedge rst_n) begin
       if(!rst_n) begin
          count_stage <= 0;
       end
       else if(stage_reset) begin
          count_stage <= 0;
       end
       else if(stage_increment) begin
          count_stage <= count_stage + 1;
       end
   end

    //sum_data and output_data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_data <= 0;
            output_data <= 0;
        end
        else if (stage_increment && count_stage == 0) begin
            sum_data <= input_data;
            output_data <= input_data;
        end
        else if (stage_increment) begin
            sum_data <= sum_data + input_data;
            output_data <= sum_data + input_data;
        end
    end

   //process_ready
   assign process_ready = !output_valid | input_valid;

   //output_valid
   always @(posedge clk or negedge rst_n) begin
       if(!rst_n) begin
           output_valid <= 0;
       end
       else if(stage_reset) begin
           output_valid <= 1;
       end
       else begin
           output_valid <= 0;
       end
   end  
     
endmodule

