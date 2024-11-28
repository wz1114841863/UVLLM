
class accu_monitor extends uvm_monitor;
  `uvm_component_utils(accu_monitor)
  accu_transaction item;

  virtual accu_if vif;
  uvm_analysis_port#(accu_transaction) mon_ap;

  function new(string name = "accu_monitor",uvm_component parent = null);

    super.new(name, parent);
  endfunction
 
  function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        mon_ap=new("mon_ap",this);
	    if (!uvm_config_db#(virtual accu_if)::get(this, "", "vif", vif)) begin
          `uvm_fatal("NOVIF", "Virtual interface not set")
        end
  endfunction

  task run_phase(uvm_phase phase);
	  super.run_phase(phase);
      forever begin
      item = accu_transaction::type_id::create("item", this);
	  @(posedge vif.clk); 
      item.data_in = vif.data_in;
      item.valid_in = vif.valid_in;
      item.rst_n = vif.rst_n;
      item.data_out = vif.data_out;
      item.valid_out = vif.valid_out;
      `uvm_info("ACCU_MONITOR", $sformatf("\ndata_in=%0d\nvalid_in=%0b\ndata_out=%0d\nvalid_out=%0b", item.data_in, item.valid_in, item.data_out, item.valid_out), 
          UVM_LOW)
	  
      mon_ap.write(item);
    end
  endtask

endclass
