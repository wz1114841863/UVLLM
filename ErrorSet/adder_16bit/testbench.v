
`timescale 1ns/1ps

module add16_tb();

    reg [15:0] a;
    reg [15:0] b;
    reg Cin;

    wire [15:0] y;
    wire Co;

    wire [16:0] tb_sum;
    wire tb_co;

    assign tb_sum = a + b + Cin;
    assign tb_co = tb_sum[16];

    integer i;
    integer error = 0;
    integer log_file;

    // Instantiate the 16-bit adder module under test
    adder_16bit uut (
        .a(a),
        .b(b),
        .Cin(Cin),
        .y(y),
        .Co(Co)
    );

    initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
    end

    // Initialize log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Directed and random stimulus
    initial begin
        // 1-bit, 2-bit, 4-bit, 8-bit, and 16-bit additions
        a = 16'b0;
        b = 16'b0;
        Cin = 1'b0;

        // Directed stimulus: Boundary condition tests to cover min and max values
        // 1-bit
        a = 1; b = 0; Cin = 1; #10; check_results();
        a = 1; b = 1; Cin = 1; #10; check_results();

        // 2-bit
        a = 2; b = 1; Cin = 0; #10; check_results();
        a = 3; b = 3; Cin = 1; #10; check_results();

        // 4-bit
        a = 8; b = 7; Cin = 0; #10; check_results();
        a = 15; b = 15; Cin = 1; #10; check_results();

        // 8-bit
        a = 128; b = 127; Cin = 0; #10; check_results();
        a = 255; b = 255; Cin = 1; #10; check_results();

        // 16-bit
        a = 16'h8000; b = 16'h7FFF; Cin = 0; #10; check_results();
        a = 16'hFFFF; b = 16'hFFFF; Cin = 1; #10; check_results();

        // Random stimulus to generate more combinations
        for (i = 0; i < 1000; i = i + 1) begin
            a = $random;
            b = $random;
            Cin = $random & 1'b1;
            #10;
            check_results();
        end

        $fclose(log_file); // Close the log file
        $finish; // End simulation
    end

    // Result checking task, compares DUT output with the reference model output, logs if there's a mismatch
    task check_results;
        begin
            if (y !== tb_sum[15:0] || Co !== tb_co) begin
                error = error + 1;
                // Log the time, inputs, and outputs when a mismatch occurs
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "DUT Input: a = 16'b%0b, b = 16'b%0b, Cin = %b\n", a, b, Cin);
                $fwrite(log_file, "DUT Output: y = 16'b%0b, Co = %b\n", y, Co);
                $fwrite(log_file, "Reference Model Input: a = 16'b%0b, b = 16'b%0b, Cin = %b\n", a, b, Cin);
                $fwrite(log_file, "Reference Model Output: y = 16'b%0b, Co = %b\n", tb_sum[15:0], tb_co);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask

    // Display test results at the end
    initial begin
        #10000; // End of simulation time
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file,"=========== Your Design Passed ===========");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule
