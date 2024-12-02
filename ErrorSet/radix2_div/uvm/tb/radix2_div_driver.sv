

class radix2_div_driver extends uvm_driver #(radix2_div_transaction);
    `uvm_component_utils(radix2_div_driver)

    virtual radix2_div_if vif;
	radix2_div_transaction tr;

    function new(string name="radix2_div_driver",uvm_component parent = null);
        super.new(name, parent);
    endfunction

	function void build_phase (uvm_phase phase);
        super.build_phase(phase);
	     if (!uvm_config_db#(virtual radix2_div_if)::get(this, "", "vif", vif)) begin
          `uvm_fatal("NOVIF", "Virtual interface not set")
        end

    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
        tr = radix2_div_transaction::type_id::create("tr");
        seq_item_port.get_next_item(tr);
		   
		   vif.res_ready = 0;
           vif.dividend = tr.dividend;
           vif.divisor = tr.divisor;
           vif.sign = tr.sign;
           vif.opn_valid = 1;
           
           wait(vif.res_valid);
           vif.opn_valid = 0;
           
           vif.res_ready = 1;
           @(posedge vif.clk);
           vif.res_ready = 0;
	
        seq_item_port.item_done();
    end
endtask



    endclass
