
`timescale 1ns/1ns

module counter_12_tb;

  reg clk, rst_n, valid_count;
  wire [3:0] out;
  wire [3:0] out_ref;
  
  // Instantiate DUT
  counter_12 uut (
    .rst_n(rst_n),
    .clk(clk),
    .valid_count(valid_count),
    .out(out)
  );

  // Instantiate Reference Model
  ref_counter_12 ref_model (
    .rst_n(rst_n),
    .clk(clk),
    .valid_count(valid_count),
    .out(out_ref)
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

  // Generate clock
  always #5 clk = ~clk;

  // Test sequence
  initial begin
    clk = 0;
    rst_n = 0;
    valid_count = 0;

    #20 rst_n = 1;

    // Directed Tests: Known patterns
    $display("Directed Tests: Known patterns");

    // Testcase1: Resetting the counter
    apply_test(0, 0, "Reset Test - Expect out=0");
    #20 rst_n = 1;

    // Testcase2: Valid_count low, counter should hold at 0
    valid_count = 0;
    repeat(5) apply_test(rst_n, valid_count, "Counter Hold Test - Expect out=0");

    // Testcase3: Counter increments from 0 with valid_count high
    valid_count = 1;
    repeat(12) apply_test(rst_n, valid_count, "Counting Up Test");

    // Boundary Tests: Test counter rollover behavior
    $display("Boundary Tests: Counter rollover");
    apply_test(1, 1, "Boundary Test - Expect rollover to 0 after 15");

    // Random Tests: Random sequences
    $display("Random Tests: Random valid_count patterns");
    repeat(10) begin
      apply_test(1, $random % 2, "Random Test");
    end

    // Final Verification
    verify_results();
    $finish;
  end

  // Apply a test vector
  task apply_test(input rst_val, input valid_val, input [80*8:1] test_name);
    begin
      rst_n = rst_val;
      valid_count = valid_val;
      #10;
      check_results(test_name);
    end
  endtask

  // Check results and log any mismatches
  task check_results(input [80*8:1] test_name);
    begin
      if (out !== out_ref) begin
        error_count = error_count + 1;
        $fwrite(log_file, "Error Time: %0t ns\n", $time);
        $fwrite(log_file, "DUT Input: clk = %d, rst_n = %d, valid_count = %d\n", clk, rst_n, valid_count);
        $fwrite(log_file, "DUT Output: out = %h\n", out);
        $fwrite(log_file, "Reference Input: clk = %d, rst_n = %d, valid_count = %d\n", clk, rst_n, valid_count);
        $fwrite(log_file, "Reference Output: out = %h\n", out_ref);
        $fwrite(log_file, "------------------------------------\n");
      end
    end
  endtask

  // Display final result
  task verify_results;
    begin
      if (error_count == 0) begin
        $display("=========== Your Design Passed ===========");
        $fwrite(log_file, "=========== Your Design Passed ===========\n");
      end else begin
        $display("=========== Your Design Failed  ===========");
        $fwrite(log_file, "=========== Your Design  ===========\n");
      end
    end
  endtask

endmodule

// Reference model definition (same as DUT for simulation comparison)
module ref_counter_12 (
  input rst_n,
  input clk,
  input valid_count,
  output reg [3:0] out
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      out <= 4'b0;
    else if (valid_count)
      out <= (out == 4'd11) ? 4'b0 : out + 1;
  end
endmodule
