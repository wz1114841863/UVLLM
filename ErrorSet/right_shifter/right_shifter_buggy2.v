module right_shifter(clk, q,d);  

    input  clk;  
    input d;  
    output  [7:0] q;  
    reg   [7:0]  q; 
    initial q = 0;

    always @(posedge clk)
          begin
            Q <= (q >> 1);
            Q[7] <= d;
          end  

endmodule