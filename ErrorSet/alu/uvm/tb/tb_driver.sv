
class tb_driver extends uvm_driver#(tb_sequence_item);
  `uvm_component_utils(tb_driver)

  virtual alu_if vif;

  function new(string name="tb_driver",uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase (uvm_phase phase);
        super.build_phase(phase);
	     if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
          `uvm_fatal("NOVIF", "Virtual interface not set")
        end

    endfunction

  task run_phase(uvm_phase phase);
	super.run_phase(phase);

    forever begin
	  req = tb_sequence_item::type_id::create("req");
      `uvm_info("ALU_Driver","ALU_Driver is requesting an item", UVM_LOW)
      
	  seq_item_port.get_next_item(req);
	  
	  `uvm_info("ALU_Driver","ALU_Driver got the requested item", UVM_LOW)
      
	  vif.a = req.a;
      vif.b = req.b;
      vif.aluc = req.aluc;
	  @(negedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass
