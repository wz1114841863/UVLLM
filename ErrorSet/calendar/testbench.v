
`timescale 1ns/1ns

module calendar_tb();

    reg CLK;
    reg RST;
    wire [5:0] Hours;
    wire [5:0] Mins;
    wire [5:0] Secs;
    wire [5:0] Hours_ref;
    wire [5:0] Mins_ref;
    wire [5:0] Secs_ref;

    // Instantiate DUT
    calendar uut (
        .CLK(CLK),
        .RST(RST),
        .Hours(Hours),
        .Mins(Mins),
        .Secs(Secs)
    );

    // Instantiate Reference Model
    calendar_ref ref_model (
        .CLK(CLK),
        .RST(RST),
        .Hours(Hours_ref),
        .Mins(Mins_ref),
        .Secs(Secs_ref)
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
        CLK = 0;
        forever #5 CLK = ~CLK; // 10 time units clock period
    end

    // Test sequence
    initial begin
        // Directed Test: Known patterns
        $display("Directed Test: Known patterns");
        apply_test(1, 0, 0); // After 1 hour
        apply_test(0, 1, 0); // After 1 minute
        apply_test(0, 0, 1); // After 1 second
        apply_test(23, 59, 59); // Edge case before reset
        apply_test(0, 0, 0);    // Reset check
        apply_test(12, 0, 0);   // Noon
        apply_test(18, 0, 0);   // Evening
        apply_test(12, 30, 0);  // Half past noon



        // Random Test: Random sequences
        $display("Random Test: Random sequences");
        repeat(100) begin
            apply_random_test();
        end
    end

    // Apply a test vector
    task apply_test(input [5:0] expected_hours, input [5:0] expected_mins, input [5:0] expected_secs);
        begin
            RST = 1;
            #10;
            RST = 0;
            repeat(3600 * expected_hours + 60 * expected_mins + expected_secs) @(posedge CLK);
            check_results();
        end
    endtask

    // Apply random test
    task apply_random_test;
        reg [5:0] random_hours;
        reg [5:0] random_mins;
        reg [5:0] random_secs;
        begin
            random_hours = $random % 24;
            random_mins = $random % 60;
            random_secs = $random % 60;
            //apply_test(random_hours, random_mins, random_secs);
			RST = 1;
            #10;
            RST = 0;
            repeat(3600 * random_hours + 60 * random_mins + random_secs) @(posedge CLK);
            RST = 1;
            #10;
            RST = 0;
            check_results();
        end
    endtask

    // Check results and log any mismatches
    task check_results;
        begin
            if (Hours !== Hours_ref || Mins !== Mins_ref || Secs !== Secs_ref) begin
                error_count = error_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Input: CLK = %d, RST = %d\n", CLK, RST);
                $fwrite(log_file, "DUT Output: Hours = %d, Mins = %d, Secs = %d\n", Hours, Mins, Secs);
                $fwrite(log_file, "Reference Input: CLK = %d, RST = %d\n", CLK, RST);
                $fwrite(log_file, "Reference Output: Hours = %d, Mins = %d, Secs = %d\n", Hours_ref, Mins_ref, Secs_ref);
                $fwrite(log_file, "------------------------------------\n");
            end
        end
    endtask

    // Display final result
    initial begin
        #100000; // Adjust time based on test length
        if (error_count == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule

// Reference model definition
module calendar_ref(
    input CLK,
    input RST,
    output reg [5:0] Hours,
    output reg [5:0] Mins,
    output reg [5:0] Secs
);
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            Hours <= 0;
            Mins <= 0;
            Secs <= 0;
        end else begin
            if (Secs == 59) begin
                Secs <= 0;
                if (Mins == 59) begin
                    Mins <= 0;
                    if (Hours == 23) begin
                        Hours <= 0;
                    end else begin
                        Hours <= Hours + 1;
                    end
                end else begin
                    Mins <= Mins + 1;
                end
            end else begin
                Secs <= Secs + 1;
            end
        end
    end


	
endmodule
