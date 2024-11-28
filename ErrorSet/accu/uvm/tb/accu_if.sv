
interface accu_if(input bit clk, input bit rst_n);
  logic [7:0] data_in;
  logic valid_in;
  logic valid_out;
  logic [9:0] data_out;

  modport DUT (input data_in, valid_in, output valid_out, data_out);
  modport MONITOR (input data_in, valid_in, valid_out, data_out);
endinterface
