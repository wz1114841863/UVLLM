`timescale 1ns/1ns

module tb_verified_asyn_fifo;

    parameter WIDTH = 8;
    parameter DEPTH = 16;
    parameter ADDR_WIDTH = $clog2(DEPTH);

    reg wclk, rclk;
    reg wrstn, rrstn;
    reg winc, rinc;
    reg [WIDTH-1:0] wdata;
    wire [WIDTH-1:0] r_dut;
    wire wfull_dut, rempty_dut;
    
    wire [WIDTH-1:0] r_ref;
    wire wfull_ref, rempty_ref;

    reg error_flag;
    integer test_num;
    integer f_log;

    // DUT instance
    asyn_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .wclk(wclk),
        .rclk(rclk),
        .wrstn(wrstn),
        .rrstn(rrstn),
        .winc(winc),
        .rinc(rinc),
        .wdata(wdata),
        .wfull(wfull_dut),
        .rempty(rempty_dut),
        .rdata(r_dut)
    );

    // Reference model instance
    ref_verified_asyn_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) ref_inst (
        .wclk(wclk),
        .rclk(rclk),
        .wrstn(wrstn),
        .rrstn(rrstn),
        .winc(winc),
        .rinc(rinc),
        .wdata(wdata),
        .wfull(wfull_ref),
        .rempty(rempty_ref),
        .rdata(r_ref)
    );

    initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
    end

    task check_results;
        input integer test_num;
        begin
            if (r_dut !== r_ref || wfull_dut !== wfull_ref || rempty_dut !== rempty_ref) begin
                $display("Test %0d Failed at time %0t", test_num, $time);
                error_flag = 1;
                if (f_log != 0) begin
                    $fwrite(f_log, "Error Time: %g ns\n", $time);
                    $fwrite(f_log, "DUT Input: wclk = %b, rclk = %b, wrstn = %b, rrstn = %b, winc = %b, rinc = %b, wdata = %h\n", wclk, rclk, wrstn, rrstn, winc, rinc, wdata);
                    $fwrite(f_log, "DUT Output: rdata = %h, wfull = %b, rempty = %b\n", r_dut, wfull_dut, rempty_dut);
                    $fwrite(f_log, "Reference Input: wclk = %b, rclk = %b, wrstn = %b, rrstn = %b, winc = %b, rinc = %b, wdata = %h\n", wclk, rclk, wrstn, rrstn, winc, rinc, wdata);
                    $fwrite(f_log, "Reference Output: rdata = %h, wfull = %b, rempty = %b\n", r_ref, wfull_ref, rempty_ref);
                    $fwrite(f_log, "-----------------------------\n");
                end
            end else begin
                $display("Test %0d Passed at time %0t", test_num, $time);
            end
        end
    endtask

    initial begin
        f_log = $fopen("test.txt", "w");
        if (f_log == 0) begin
            $display("Failed to open test.txt file");
            $finish;
        end

        wrstn = 0;
        rrstn = 0;
        winc = 0;
        rinc = 0;
        wdata = 0;
        error_flag = 0;
        #20 wrstn = 1;
        #20 rrstn = 1;

        test_num = 1;

        // Test 1: Simple write and read
        winc = 1;
        wdata = 8'hAA;
        #10;
        wdata = 8'hBB;
        #10;
        winc = 0;

        rinc = 1;
        #10;
        check_results(test_num);
        test_num = test_num + 1;
        #10;
        check_results(test_num);
        rinc = 0;
        #20;

        // Test 2: Write until full
        winc = 1;
        repeat (DEPTH) begin
            wdata = $random;
            #10;
        end
        winc = 0;
        check_results(test_num);
        test_num = test_num + 1;

        // Test 3: Read until empty
        rinc = 1;
        #10;
        repeat (DEPTH) begin
            check_results(test_num);
            test_num = test_num + 1;
            #10;
        end
        rinc = 0;

        // Test 4: Simultaneous write and read
        winc = 1;
        rinc = 1;
        repeat (DEPTH) begin
            wdata = $random;
            #10;
            check_results(test_num);
            test_num = test_num + 1;
        end
        winc = 0;
        rinc = 0;

		// Test 5: Near full write
        winc = 1;
        repeat (DEPTH-1) begin
            wdata = $random;
            #10;
        end
        winc = 0;
        check_results(test_num);
        test_num = test_num + 1;

        // Attempt to write when full
        winc = 1;
        wdata = $random;
        #10;
        check_results(test_num);
        test_num = test_num + 1;
        winc = 0;

        // Test 6: Near empty read
        rinc = 1;
        repeat (DEPTH-1) begin
            #10;
            check_results(test_num);
            test_num = test_num + 1;
        end
        rinc = 0;

        // Attempt to read when empty
        rinc = 1;
        #10;
        check_results(test_num);
        test_num = test_num + 1;
        rinc = 0;

        // Test 7: Random operation sequence
        repeat (100) begin
            if ($random % 2) begin
                winc = 1;
                wdata = $random;
            end else begin
                winc = 0;
            end

            if ($random % 2) begin
                rinc = 1;
            end else begin
                rinc = 0;
            end
            #10;
            check_results(test_num);
            test_num = test_num + 1;
        end
        winc = 0;
        rinc = 0;



        #1000;
        if (!error_flag) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(f_log, "=========== Your Design Passed ===========");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

    // Clock generation
    initial begin
        wclk = 0;
        forever #5 wclk = ~wclk; // 100 MHz
    end

    initial begin
        rclk = 0;
        forever #7 rclk = ~rclk; // ~71.4 MHz
    end

endmodule

module ref_verified_asyn_fifo#(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                   wclk,
    input                   rclk,
    input                   wrstn,
    input                   rrstn,
    input                   winc,
    input                   rinc,
    input       [WIDTH-1:0] wdata,

    output wire             wfull,
    output wire             rempty,
    output reg  [WIDTH-1:0] rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);

reg     [ADDR_WIDTH:0]    waddr_bin;
reg     [ADDR_WIDTH:0]    raddr_bin;

// Address generation logic
always @(posedge wclk or negedge wrstn) begin
    if(~wrstn) begin
        waddr_bin <= 'd0;
    end 
    else if(!wfull && winc) begin
        waddr_bin <= waddr_bin + 1'd1;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if(~rrstn) begin
        raddr_bin <= 'd0;
    end 
    else if(!rempty && rinc) begin
        raddr_bin <= raddr_bin + 1'd1;
    end
end

// Gray code conversion
wire    [ADDR_WIDTH:0]    waddr_gray;
wire    [ADDR_WIDTH:0]    raddr_gray;
reg     [ADDR_WIDTH:0]    wptr;
reg     [ADDR_WIDTH:0]    rptr;

assign waddr_gray = waddr_bin ^ (waddr_bin >> 1);
assign raddr_gray = raddr_bin ^ (raddr_bin >> 1);

always @(posedge wclk or negedge wrstn) begin 
    if(~wrstn) begin
        wptr <= 'd0;
    end 
    else begin
        wptr <= waddr_gray;
    end
end

always @(posedge rclk or negedge rrstn) begin 
    if(~rrstn) begin
        rptr <= 'd0;
    end 
    else begin
        rptr <= raddr_gray;
    end
end

// Pointer synchronization
reg     [ADDR_WIDTH:0]    wptr_buff;
reg     [ADDR_WIDTH:0]    wptr_syn;
reg     [ADDR_WIDTH:0]    rptr_buff;
reg     [ADDR_WIDTH:0]    rptr_syn;

always @(posedge wclk or negedge wrstn) begin 
    if(~wrstn) begin
        rptr_buff <= 'd0;
        rptr_syn <= 'd0;
    end 
    else begin
        rptr_buff <= rptr;
        rptr_syn <= rptr_buff;
    end
end

always @(posedge rclk or negedge rrstn) begin 
    if(~rrstn) begin
        wptr_buff <= 'd0;
        wptr_syn <= 'd0;
    end 
    else begin
        wptr_buff <= wptr;
        wptr_syn <= wptr_buff;
    end
end

// Full and empty flags
assign wfull = (wptr == {~rptr_syn[ADDR_WIDTH:ADDR_WIDTH-1], rptr_syn[ADDR_WIDTH-2:0]});
assign rempty = (rptr == wptr_syn);

// Integrated RAM logic
reg [WIDTH-1:0] mem [0:DEPTH-1];
wire    wen;
wire    ren;
wire    [ADDR_WIDTH-1:0]  waddr;
wire    [ADDR_WIDTH-1:0]  raddr;

assign wen = winc & !wfull;
assign ren = rinc & !rempty;
assign waddr = waddr_bin[ADDR_WIDTH-1:0];
assign raddr = raddr_bin[ADDR_WIDTH-1:0];

always @(posedge wclk) begin
    if (wen) begin
        mem[waddr] <= wdata;
    end
end

always @(posedge rclk) begin
    if (ren) begin
        rdata <= mem[raddr];
    end
end

endmodule
