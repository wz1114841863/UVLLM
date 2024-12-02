
class radix2_div_sequence extends uvm_sequence#(radix2_div_transaction);
    `uvm_object_utils(radix2_div_sequence)
    radix2_div_transaction tr;

    function new(string name = "radix2_div_sequence");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "Starting accu_sequence", UVM_MEDIUM)
		repeat(50)begin
            tr = radix2_div_transaction::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize());
            finish_item(tr);
        end
    endtask
endclass
