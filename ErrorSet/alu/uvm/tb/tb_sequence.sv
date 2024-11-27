
class tb_sequence extends uvm_sequence#(tb_sequence_item);
  `uvm_object_utils(tb_sequence)
  tb_sequence_item item;

  function new(string name = "tb_sequence");
    super.new(name);
  endfunction

  task body();
    repeat (100) begin
      item = tb_sequence_item::type_id::create("item");
      start_item(item);
      assert(item.randomize());
      finish_item(item);
    end
  endtask
endclass
