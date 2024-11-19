

`timescale 1ns/1ns

module freq_div_tb();

    reg CLK_in;
    reg RST;
    wire CLK_50;
    wire CLK_10;
    wire CLK_1;

    // Instantiate DUT
    freq_div uut (
        .CLK_in(CLK_in),
        .CLK_50(CLK_50),
        .CLK_10(CLK_10),
        .CLK_1(CLK_1),
        .RST(RST)
    );

    // Reference signals
    reg ref_CLK_50;
    reg ref_CLK_10;
    reg ref_CLK_1;

    integer error_count = 0;
    integer log_file;
    integer clk_period;
    
	initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end

    initial begin
        log_file = $fopen("test.txt", "w");
    end

   
    // Clock generation with frequency control
    initial begin
        clk_period = 10; // Default 100MHz
        CLK_in = 0;
        forever #(clk_period/2) CLK_in = ~CLK_in;
    end

    // Reference model
    always @(posedge CLK_in or posedge RST) begin
        if (RST) begin
            ref_CLK_50 <= 0;
        end else begin
            ref_CLK_50 <= ~ref_CLK_50;
        end
    end

    reg [3:0] ref_cnt_10;
    always @(posedge CLK_in or posedge RST) begin
        if (RST) begin
            ref_CLK_10 <= 0;
            ref_cnt_10 <= 0;
        end else if (ref_cnt_10 == 4) begin
            ref_CLK_10 <= ~ref_CLK_10;
            ref_cnt_10 <= 0;
        end else begin
            ref_cnt_10 <= ref_cnt_10 + 1;
        end
    end

    reg [6:0] ref_cnt_100;
    always @(posedge CLK_in or posedge RST) begin
        if (RST) begin
            ref_CLK_1 <= 0;
            ref_cnt_100 <= 0;
        end else if (ref_cnt_100 == 49) begin
            ref_CLK_1 <= ~ref_CLK_1;
            ref_cnt_100 <= 0;
        end else begin
            ref_cnt_100 <= ref_cnt_100 + 1;
        end
    end

    // Check results and log any mismatches
    task check_results;
        begin
            if (CLK_50 !== ref_CLK_50 || CLK_10 !== ref_CLK_10 || CLK_1 !== ref_CLK_1) begin
                error_count = error_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Input: CLK_in = %b, RST = %b\n", CLK_in, RST);
                $fwrite(log_file, "DUT Output: CLK_50 = %b, CLK_10 = %b, CLK_1 = %b\n", CLK_50, CLK_10, CLK_1);
                $fwrite(log_file, "Reference Input: CLK_in = %b, RST = %b\n", CLK_in, RST);
                $fwrite(log_file, "Reference Output: CLK_50 = %b, CLK_10 = %b, CLK_1 = %b\n", ref_CLK_50, ref_CLK_10, ref_CLK_1);
                $fwrite(log_file, "------------------------------------\n");
            end
        end
    endtask

    // Test sequence
    initial begin
        reset();

        // Directed Test: Verify frequency division
        $display("Directed Test: Frequency Division");
        repeat(100) begin
            @(posedge CLK_in);
            check_results();
        end

		// Directed Test: Boundary Conditions
        $display("Directed Test: Boundary Conditions");
        reset();
        repeat(100) @(posedge CLK_in);
        check_results();

        // Random Test: Random reset application
        $display("Random Test: Random Reset");
        repeat(5) begin
			#($random % 50 + 50); // Random delay between 50 and 100 ns
            reset();
            repeat(20) @(posedge CLK_in);
            check_results();
        end
        // Random Test: Random Input Patterns
        $display("Random Test: Random Input Patterns");
        repeat(10) begin
            clk_period = $random % 20 + 5; // Random period between 5 and 25 ns
            repeat(50) @(posedge CLK_in);
            check_results();
        end


        // Display final result
        #1000;
        if (error_count == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
            $fwrite(log_file, "=========== Your Design Failed ===========\n");
        end
        //$fclose(log_file);
        $finish;
    end

    // Reset task
    task reset;
    begin
        RST = 1;
        #10;
        RST = 0;
    end
    endtask

endmodule
