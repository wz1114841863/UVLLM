`timescale 1ns/1ps

module add32_tb();

    reg [31:0] A;
    reg [31:0] B;

    wire [31:0] S;
    wire C32;

    wire [32:0] tb_sum;
    wire tb_co;

    assign tb_sum = A + B;
    assign tb_co = tb_sum[32];

    integer i;
    integer error = 0;
    integer log_file;

    // 实例化 32 位加法器
    adder_32bit uut (
        .A(A),
        .B(B),
        .S(S),
        .C32(C32)
    );

    initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
    end

    // 初始化日志文件
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // 指定和随机测试
    initial begin
        // 边界条件测试：覆盖 1 位、4 位、8 位、16 位和 32 位的情况
        A = 32'b0;
        B = 32'b0;

        // 1-bit
        A = 1; B = 0; #10; check_results();
        A = 1; B = 1; #10; check_results();

        // 4-bit
        A = 4; B = 3; #10; check_results();
        A = 7; B = 7; #10; check_results();

        // 8-bit
        A = 128; B = 127; #10; check_results();
        A = 255; B = 255; #10; check_results();

        // 16-bit
        A = 16'h8000; B = 16'h7FFF; #10; check_results();
        A = 16'hFFFF; B = 16'hFFFF; #10; check_results();

        // 32-bit
        A = 32'h80000000; B = 32'h7FFFFFFF; #10; check_results();
        A = 32'hFFFFFFFF; B = 32'hFFFFFFFF; #10; check_results();

        // 随机生成更多组合
        for (i = 0; i < 1000; i = i + 1) begin
            A = $random;
            B = $random;
            #10;
            check_results();
        end

        $fclose(log_file); 
        $finish;
    end

    // 结果检查任务，比较 DUT 输出和参考模型输出，记录不匹配情况
    task check_results;
        begin
            if (S !== tb_sum[31:0] || C32 !== tb_co) begin
                error = error + 1;
                // Log the time, inputs, and outputs when a mismatch occurs
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "DUT Input: A = 32'b%0b, B = 32'b%0b\n", A, B);
                $fwrite(log_file, "DUT Output: S = 32'b%0b, C32 = %b\n", S, C32);
                $fwrite(log_file, "Reference Model Output: S = 32'b%0b, C32 = %b\n", tb_sum[31:0], tb_co);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask


    // 测试结束时显示结果
    initial begin
        #10000;
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file,"=========== Your Design Passed ===========");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule
