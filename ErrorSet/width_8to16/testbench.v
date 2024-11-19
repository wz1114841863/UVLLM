

`timescale 1ns/1ps

module width_8to16_tb;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg [7:0] data_in;

    wire valid_out;
    wire [15:0] data_out;

    // Reference model signals
    reg [7:0] data_lock_ref;
    reg flag_ref;
    reg valid_out_ref;
    reg [15:0] data_out_ref;

    integer error = 0;
    integer log_file;

    // Instantiate DUT
    width_8to16 uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .data_out(data_out)
    );

	initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
    end


    // Generate clock signal
    always #5 clk = ~clk;

    // DUT reference model logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_lock_ref <= 8'd0;
            flag_ref <= 1'b0;
            valid_out_ref <= 1'b0;
            data_out_ref <= 16'd0;
        end else begin
            if (valid_in && !flag_ref) begin
                data_lock_ref <= data_in;
            end
            if (valid_in) begin
                flag_ref <= ~flag_ref;
            end
            valid_out_ref <= (valid_in && flag_ref);
            if (valid_in && flag_ref) begin
                data_out_ref <= {data_lock_ref, data_in};
            end
        end
    end

    // Initialize log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Initialize signals and apply reset
    initial begin
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        data_in = 0;

        // Apply reset
        reset_dut;

        // Directed stimulus
        $display("Starting directed stimulus...");
        directed_stimulus;
        
        // Random stimulus
        $display("Starting random stimulus...");
        random_stimulus;

        // Close log file and finish simulation
        $fclose(log_file);
        $finish;
    end

    // Reset task
    task reset_dut;
    begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end
    endtask

    // Directed stimulus
    task directed_stimulus;
    begin
        @(posedge clk);
        valid_in = 1;
        data_in = 8'hAA;  // First part of data
        #10 check_results;
        @(posedge clk);
        data_in = 8'h55;  // Second part of data
        #10 check_results;

        @(posedge clk);
        valid_in = 0;
        data_in = 8'd0;
        #10;
    end
    endtask

    // Random stimulus
    task random_stimulus;
        integer i;
    begin
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk);
            valid_in = $random % 2;
            data_in = $random % 256;
            #10;
            check_results;
        end
    end
    endtask

    // Check results and log mismatches
    task check_results;
    begin
        if (valid_out !== valid_out_ref || data_out !== data_out_ref) begin
            error = error + 1;
            // Log details of the mismatch
            $fwrite(log_file, "Error Time: %g ns\n", $time);
            $fwrite(log_file, "DUT Input: data_in = 8'b%0b, valid_in = %b\n", data_in, valid_in);
            $fwrite(log_file, "DUT Output: valid_out = %b, data_out = 16'b%0b\n", valid_out, data_out);
            $fwrite(log_file, "Reference Model Input: data_in = 8'b%0b, valid_in = %b\n", data_in, valid_in);
            $fwrite(log_file, "Reference Model Output: valid_out = %b, data_out = 16'b%0b\n", valid_out_ref, data_out_ref);
            $fwrite(log_file, "-----------------------------\n");
        end
    end
    endtask

    // Final display of test results
    initial begin
        #1000; // Simulation end time
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file,"=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
            $fwrite(log_file,"=========== Your Design Failed ===========\n");
        end
        $finish;
    end

endmodule
