
interface radix2_div_if(input logic clk, input logic rst);
    logic [7:0] dividend;
    logic [7:0] divisor;
    logic sign;
    logic opn_valid;
    logic res_ready;
    logic [15:0] result;
    logic res_valid;
endinterface
