
`timescale 1ns/1ps

module synchronizer_tb();

    reg         clk_a;
    reg         clk_b;
    reg         arstn;
    reg         brstn;
    reg  [3:0]  data_in;
    reg         data_en;
    
    wire [3:0]  dataout;

    reg  [3:0]  ref_dataout;
    integer     error_count = 0;
    integer     log_file;

    // Instantiate the DUT
    synchronizer uut (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .arstn(arstn),
        .brstn(brstn),
        .data_in(data_in),
        .data_en(data_en),
        .dataout(dataout)
    );

    initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
    end


    // Reference model signals
    reg [3:0] ref_data_reg;
    reg ref_en_data_reg;
    reg ref_en_clap_one;
    reg ref_en_clap_two;

    // Clock generation
    always #5 clk_a = ~clk_a;
    always #7 clk_b = ~clk_b;

    // Initialize log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Initialize signals
    initial begin
        clk_a = 0;
        clk_b = 0;
        arstn = 0;
        brstn = 0;
        data_in = 4'b0;
        data_en = 0;
        ref_dataout = 4'b0;
        ref_data_reg = 4'b0;
        ref_en_data_reg = 0;
        ref_en_clap_one = 0;
        ref_en_clap_two = 0;

        #10 arstn = 1; // Release asynchronous reset for clk_a domain
        #10 brstn = 1; // Release asynchronous reset for clk_b domain
    end

    // Reference model logic
    always @(posedge clk_a or negedge arstn) begin
        if (!arstn) ref_data_reg <= 0;
        else        ref_data_reg <= data_in;
    end

    always @(posedge clk_a or negedge arstn) begin
        if (!arstn) ref_en_data_reg <= 0;
        else        ref_en_data_reg <= data_en;
    end

    always @(posedge clk_b or negedge brstn) begin
        if (!brstn) ref_en_clap_one <= 0;
        else        ref_en_clap_one <= ref_en_data_reg;
    end

    always @(posedge clk_b or negedge brstn) begin
        if (!brstn) ref_en_clap_two <= 0;
        else        ref_en_clap_two <= ref_en_clap_one;
    end

    always @(posedge clk_b or negedge brstn) begin
        if (!brstn) ref_dataout <= 0;
        else        ref_dataout <= (ref_en_clap_two) ? ref_data_reg : ref_dataout;
    end

    // Directed stimulus
    initial begin
        #20; // Wait for reset

        // Test case 1: Simple enable and data transfer
        data_in = 4'b1010; data_en = 1; #20; check_results();

        // Test case 2: Disable data transfer
        data_en = 0; #20; check_results();

        // Test case 3: Change data_in without enabling transfer
        data_in = 4'b1100; #20; check_results();

        // Test case 4: Enable data transfer with new data
        data_en = 1; #20; check_results();

        // Test case 5: Reset condition
        arstn = 0; brstn = 0; #20;
        arstn = 1; brstn = 1; #20; check_results();
    end

    // Random stimulus
    initial begin
        #100; // Wait for directed tests to finish
        repeat(100) begin
            data_in = $random;
            data_en = $random % 2;
            #20;
            check_results();
        end

    end



    // Result checking task
    task check_results;
        begin
            if (dataout !== ref_dataout) begin
                error_count = error_count + 1;
                // Log the mismatch details
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "DUT Input: data_in = 4'b%0b, data_en = %b, arstn = %b, brstn = %b\n", data_in, data_en, arstn, brstn);
                $fwrite(log_file, "DUT Output: dataout = 4'b%0b\n", dataout);
                $fwrite(log_file, "Reference Input: data_in = 4'b%0b, data_en = %b, arstn = %b, brstn = %b\n", data_in, data_en, arstn, brstn);
                $fwrite(log_file, "Reference Output: ref_dataout = 4'b%0b\n", ref_dataout);
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
