
class accu_sequence extends uvm_sequence#(accu_transaction);
  `uvm_object_utils(accu_sequence)
  accu_transaction item;
  
  function new(string name = "accu_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "Starting accu_sequence", UVM_MEDIUM)
    repeat (100) begin
      item = accu_transaction::type_id::create("item");
      start_item(item);
	  assert(item.randomize());
      finish_item(item);
    end
  endtask
endclass
