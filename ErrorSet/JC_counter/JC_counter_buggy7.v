`timescale 1ns/1ns

module JC_counter(clk, rst_n, Q);
    input                clk ;
   input                rst_n;
  
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) Q <= 'd0;
        else if(!Q[0]) Q <= {1'b1, Q[63 : 1]};
        else Q <= {1'b0, Q[63 : 1]};
    end
endmodule
