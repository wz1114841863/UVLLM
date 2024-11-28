
class accu_driver extends uvm_driver#(accu_transaction);
  `uvm_component_utils(accu_driver)

  virtual accu_if vif;

  function new(string name="tb_driver",uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase (uvm_phase phase);
        super.build_phase(phase);
	     if (!uvm_config_db#(virtual accu_if)::get(this, "", "vif", vif)) begin
          `uvm_fatal("NOVIF", "Virtual interface not set")
        end

  endfunction


  task run_phase(uvm_phase phase);
	super.run_phase(phase);
    
	forever begin
	  req = accu_transaction::type_id::create("req");
	  `uvm_info("ACCU_Driver","ACCU_Driver is requesting an item", UVM_LOW)

      seq_item_port.get_next_item(req);

      // Drive inputs to DUT
      vif.data_in = req.data_in;
      vif.valid_in = req.valid_in;
	  `uvm_info("ACCU_Driver","ACCU_Driver got the requested item", UVM_LOW)

	  @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass
