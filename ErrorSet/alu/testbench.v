
`timescale 1ns / 1ps

module alu_tb;

    reg [31:0] a;
    reg [31:0] b;
    reg [5:0] aluc;
    wire [31:0] r_dut;
    wire zero_dut;
    wire carry_dut;
    wire negative_dut;
    wire overflow_dut;
    wire flag_dut;

    reg [31:0] r_ref;
    reg zero_ref;
    reg carry_ref;
    reg negative_ref;
    reg overflow_ref;
    reg flag_ref;

    reg rst_n;
    reg error_flag;
    integer f_log;
    integer test_num;

    // DUT instance
    alu uut (
        .a(a),
        .b(b),
        .aluc(aluc),
        .r(r_dut),
        .zero(zero_dut),
        .carry(carry_dut),
        .negative(negative_dut),
        .overflow(overflow_dut),
        .flag(flag_dut)
    );

    // Reference model
    ref_alu ref_model (
        .a(a),
        .b(b),
        .aluc(aluc),
        .r(r_ref),
        .zero(zero_ref),
        .carry(carry_ref),
        .negative(negative_ref),
        .overflow(overflow_ref),
        .flag(flag_ref)
    );

	initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
    end
 

    task check_results;
        input integer test_num;
        begin
            if (r_dut !== r_ref || zero_dut !== zero_ref || carry_dut !== carry_ref || 
                negative_dut !== negative_ref || overflow_dut !== overflow_ref || 
                flag_dut !== flag_ref) begin
                $display("Test %0d Failed.", test_num);
                error_flag = 1;
                if (f_log != 0) begin
                    $fwrite(f_log, "Error Time: %g ns\n", $time);
                    $fwrite(f_log, "DUT Input: a = %h, b = %h, aluc = %b\n", a, b, aluc);
                    $fwrite(f_log, "DUT Output: r = %h, zero = %b, carry = %b, negative = %b, overflow = %b, flag = %b\n", r_dut, zero_dut, carry_dut, negative_dut, overflow_dut, flag_dut);
                    $fwrite(f_log, "Reference Input: a = %h, b = %h, aluc = %b\n", a, b, aluc);
                    $fwrite(f_log, "Reference Output: r = %h, zero = %b, carry = %b, negative = %b, overflow = %b, flag = %b\n", r_ref, zero_ref, carry_ref, negative_ref, overflow_ref, flag_ref);
                    $fwrite(f_log, "-----------------------------\n");
                end
            end else begin
                $display("Test %0d Passed.", test_num);
            end
        end
    endtask

    initial begin
        f_log = $fopen("test.txt", "w");
        if (f_log == 0) begin
            $display("Failed to open test.txt file");
            $finish;
        end

        rst_n = 0;
        a = 0;
        b = 0;
        aluc = 0;
        error_flag = 0;
        #20 rst_n = 1;

        test_num = 1;
    
    // Test 1: Addition (ADD)
    a = 32'h00000005; b = 32'h00000003; aluc = 6'b100000; // ADD
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 2: Addition Unsigned (ADDU)
    a = 32'hFFFFFFFF; b = 32'h00000001; aluc = 6'b100001; // ADDU
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 3: Subtraction (SUB)
    a = 32'h00000005; b = 32'h00000003; aluc = 6'b100010; // SUB
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 4: Subtraction Unsigned (SUBU)
    a = 32'hFFFFFFFF; b = 32'h00000001; aluc = 6'b100011; // SUBU
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 5: AND
    a = 32'hFFFFFFFF; b = 32'h0F0F0F0F; aluc = 6'b100100; // AND
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 6: OR
    a = 32'h00000000; b = 32'hF0F0F0F0; aluc = 6'b100101; // OR
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 7: XOR
    a = 32'hAAAAAAAA; b = 32'h55555555; aluc = 6'b100110; // XOR
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 8: NOR
    a = 32'h00000000; b = 32'hFFFFFFFF; aluc = 6'b100111; // NOR
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 9: Set Less Than (SLT)
    a = 32'h00000001; b = 32'h00000002; aluc = 6'b101010; // SLT
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 10: Set Less Than Unsigned (SLTU)
    a = 32'h00000001; b = 32'hFFFFFFFF; aluc = 6'b101011; // SLTU
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 11: Shift Left Logical (SLL)
    a = 32'h00000002; b = 32'h00000001; aluc = 6'b000000; // SLL
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 12: Shift Right Logical (SRL)
    a = 32'h00000002; b = 32'h80000000; aluc = 6'b000010; // SRL
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 13: Shift Right Arithmetic (SRA)
    a = 32'h00000002; b = 32'h80000000; aluc = 6'b000011; // SRA
    #10;
    check_results(test_num);
    test_num = test_num + 1;

	// Test 14: Shift Right Logical Variable (SRLV)
    a = 32'h00000004; b = 32'hFFFFFFFF; aluc = 6'b000110; // SRLV
    #10;
    check_results(test_num);
    test_num = test_num + 1;

	// Test 15: Shift Right Arithmetic Variable (SRAV)
    a = 32'h00000004; b = 32'hFFFFFFFF; aluc = 6'b000111; // SRAV
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Test 16: Load Upper Immediate (LUI)
    a = 32'h0000FFFF; aluc = 6'b001111; // LUI
    #10;
    check_results(test_num);
    test_num = test_num + 1;

    // Additional tests can be added as needed for comprehensive coverage

    // Randomized tests
    repeat (20) begin
        a = $random;
        b = $random;
        aluc = $random % 16;
        #10;
        check_results(test_num);
        test_num = test_num + 1;
    end

        #1000;
        if (!error_flag) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(f_log, "=========== Your Design Passed ===========");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule

module ref_alu(
    input [31:0] a,
    input [31:0] b,
    input [5:0] aluc,
    output reg [31:0] r,
    output reg zero,
    output reg carry,
    output reg negative,
    output reg overflow,
    output reg flag
    );

    parameter ADD = 6'b100000;
    parameter ADDU = 6'b100001;
    parameter SUB = 6'b100010;
    parameter SUBU = 6'b100011;
    parameter AND = 6'b100100;
    parameter OR = 6'b100101;
    parameter XOR = 6'b100110;
    parameter NOR = 6'b100111;
    parameter SLT = 6'b101010;
    parameter SLTU = 6'b101011;
    parameter SLL = 6'b000000;
    parameter SRL = 6'b000010;
    parameter SRA = 6'b000011;
    parameter SLLV = 6'b000100;
    parameter SRLV = 6'b000110;
    parameter SRAV = 6'b000111;
    parameter LUI = 6'b001111;

    wire signed [31:0] a_signed = a;
    wire signed [31:0] b_signed = b;
    reg [32:0] res;
 
    assign a_signed = a;
    assign b_signed = b;
    assign r = res[31:0];
    
    assign flag = (aluc == SLT || aluc == SLTU) ? ((aluc == SLT) ? (a_signed < b_signed) : (a < b)) : 1'bz; 
    assign zero = (res == 32'b0) ? 1'b1 : 1'b0;
    
    always @ (a or b or aluc)
    begin
        case(aluc)
            ADD: begin
                res <= a_signed + b_signed;
            end
            ADDU: begin
                res <= a + b;
            end
            SUB: begin 
                res <= a_signed - b_signed;
            end
            SUBU: begin 
                res <= a - b;
            end
            AND: begin
                res <= a & b;
            end
            OR: begin
                res <= a | b;
            end
            XOR: begin
                res <= a ^ b;
            end
            NOR: begin
                res <= ~(a | b);
            end
            SLT: begin
                res <= a_signed < b_signed ? 1 : 0;
            end
            SLTU: begin
                res <= a < b ? 1 : 0;
            end
            SLL: begin
                res <= b << a;
            end
            SRL: begin
                res <= b >> a;
            end
            SRA: begin
                res <= b_signed >>> a_signed;
            end
            SLLV: begin
                res <= b << a[4:0];
            end
            SRLV: begin
                res <= b >> a[4:0];
            end
            SRAV: begin
                res <= b_signed >>> a_signed[4:0];
            end
            LUI: begin
                res <= {a[15:0], 16'h0000};
            end
            default:
            begin
                res <= 32'bz;
            end
        endcase
		carry <= 1'bz;
		negative <= 1'bz;
		overflow <= 1'bz;
    end


endmodule


