
interface alu_if(input bit clk);
  logic [31:0] a, b;
  logic [5:0] aluc;
  logic [31:0] r;
  logic zero, carry, negative, overflow, flag;

  modport DUT (
    input a, b, aluc,
    output r, zero, carry, negative, overflow, flag
  );
endinterface
