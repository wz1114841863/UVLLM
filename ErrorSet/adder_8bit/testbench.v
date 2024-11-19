`timescale 1ns/1ps

module adder_8bit_tb();

    reg [7:0] a;
    reg [7:0] b;
    reg cin;

    wire [7:0] sum;
    wire cout;

    wire [8:0] tb_sum;
    wire tb_cout;

    assign tb_sum = a + b + cin;
    assign tb_cout = tb_sum[8];

    integer i;
    integer error = 0;
    integer log_file;

    // Instantiate the 8-bit adder module under test
    adder_8bit uut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
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
        // Directed stimulus: Boundary condition tests to cover min and max values
        a = 8'b0;
        b = 8'b0;
        cin = 1'b0;

        // 1-bit tests
        a = 1; b = 0; cin = 1; #10; check_results();
        a = 1; b = 1; cin = 1; #10; check_results();

        // 2-bit tests
        a = 2; b = 1; cin = 0; #10; check_results();
        a = 3; b = 3; cin = 1; #10; check_results();

        // 4-bit tests
        a = 8; b = 7; cin = 0; #10; check_results();
        a = 15; b = 15; cin = 1; #10; check_results();

        // 8-bit tests
        a = 128; b = 127; cin = 0; #10; check_results();
        a = 255; b = 255; cin = 1; #10; check_results();

        // Random stimulus to generate more combinations
        for (i = 0; i < 1000; i = i + 1) begin
            a = $random;
            b = $random;
            cin = $random & 1'b1;
            #10;
            check_results();
        end

        $fclose(log_file); // Close the log file
        $finish; // End simulation
    end

    // Result checking task, compares DUT output with the reference model output, logs if there's a mismatch
    task check_results;
        begin
            if (sum !== tb_sum[7:0] || cout !== tb_cout) begin
                error = error + 1;
                // Log the time, inputs, and outputs when a mismatch occurs
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "DUT Input: a = 8'b%0b, b = 8'b%0b, cin = %b\n", a, b, cin);
                $fwrite(log_file, "DUT Output: sum = 8'b%0b, cout = %b\n", sum, cout);
                $fwrite(log_file, "Reference Model Input: a = 8'b%0b, b = 8'b%0b, cin = %b\n", a, b, cin);
                $fwrite(log_file, "Reference Model Output: sum = 8'b%0b, cout = %b\n", tb_sum[7:0], tb_cout);
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
