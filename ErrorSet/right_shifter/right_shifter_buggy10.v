module right_shifter(clk, q,d);  

    input  clk;  
    input d;  
    output  reg q;  
    initial q = 0;

    always @(posedge clk)
          begin
            q <= (q >> 1);
            q[0] <= d;
          end  

endmodule