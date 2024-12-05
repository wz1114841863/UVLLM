
`ifndef TB_SEQUENCE_SV
`define TB_SEQUENCE_SV

class tb_sequence extends uvm_sequence#(sequence_item);
  `uvm_object_utils(tb_sequence)
  sequence_item seq_item;

  function new(string name = "sequence");
    super.new(name);
  endfunction


  task body();

    for (int i = 0; i < 10; i++) begin
      req = sequence_item::type_id::create("req");
      req.in_signal = $urandom_range(0, 1); // random
      start_item(req);
      finish_item(req);
    end

    req = sequence_item::type_id::create("req");
    req.in_signal = 1; // s1
    start_item(req);
    finish_item(req);

    req = sequence_item::type_id::create("req");
    req.in_signal = 0; // s2
    start_item(req);
    finish_item(req);

    req = sequence_item::type_id::create("req");
    req.in_signal = 0; // s3
    start_item(req);
    finish_item(req);

    req = sequence_item::type_id::create("req");
    req.in_signal = 1; // s4
    start_item(req);
    finish_item(req);

    req = sequence_item::type_id::create("req");
    req.in_signal = 1; 
    start_item(req);
    finish_item(req);
  endtask
endclass

`endif
