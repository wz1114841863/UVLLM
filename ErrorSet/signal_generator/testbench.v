
`timescale 1ns/1ps

module signal_generator_tb();

    reg clk;
    reg rst_n;
    wire [4:0] wave;

    // DUT instance
    signal_generator uut (
        .clk(clk),
        .rst_n(rst_n),
        .wave(wave)
    );

	initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end


    // Reference model signals
    reg [4:0] ref_wave;
    reg [1:0] ref_state;

    integer error_count = 0;
    integer log_file;

    // Clock generation
    always #5 clk = ~clk;

    // Initialize log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Initialize signals
    initial begin
        clk = 0;
        rst_n = 0;
        ref_wave = 5'b0;
        ref_state = 2'b0;

        #10 rst_n = 1; // Release reset
    end

    // Reference model logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_state <= 2'b0;
            ref_wave <= 5'b0;
        end else begin
            case (ref_state)
                2'b00: begin
                    if (ref_wave == 5'b11111)
                        ref_state <= 2'b01;
                    else
                        ref_wave <= ref_wave + 1;
                end
                2'b01: begin
                    if (ref_wave == 5'b00000)
                        ref_state <= 2'b00;
                    else
                        ref_wave <= ref_wave - 1;
                end
            endcase
        end
    end

    // Directed test cases
    initial begin
        #20; // Wait for reset to be released

        // Test case 1: Observe ascending sequence
        rst_n = 1; #50; check_results();

        // Test case 2: Reset during ascending sequence
        rst_n = 0; #10; rst_n = 1; #20; check_results();

        // Test case 3: Observe descending sequence after reaching max
        while (ref_wave != 5'b11111) #10;
        #50; check_results();

        // Test case 4: Reset during descending sequence
        rst_n = 0; #10; rst_n = 1; #20; check_results();
    end

    // Random test cases
    initial begin
        #200; // Wait for directed tests to finish

        repeat(100) begin
            // Randomly assert reset
            rst_n = ($random % 2);
            #10;
            rst_n = 1;

            // Run random clock cycles and check results
            #20;
            check_results();
        end

    end

    // Result checking task
    task check_results;
        begin
            if (wave !== ref_wave) begin
                error_count = error_count + 1;
                // Log the mismatch details
                $fwrite(log_file, "Error Time: %g ns\n", $time);
				$fwrite(log_file, "DUT Input: clk = %b, rst_n = %b\n", clk, rst_n);
                $fwrite(log_file, "DUT Output: wave = 5'b%0b\n", wave);
                $fwrite(log_file, "Reference Model Input: clk = %b, rst_n = %b\n", clk, rst_n);
                $fwrite(log_file, "Reference Output: ref_wave = 5'b%0b\n", ref_wave);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask

    // Display test results at the end
    initial begin
        #5000; // End of simulation time
        if (error_count == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
            $fwrite(log_file, "=========== Your Design Failed ===========\n");
        end
        $finish;
    end

endmodule
