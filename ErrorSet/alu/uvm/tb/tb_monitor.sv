
class tb_monitor extends uvm_monitor;
  `uvm_component_utils(tb_monitor)
   
  tb_sequence_item item;
  virtual alu_if vif;
  uvm_analysis_port#(tb_sequence_item) mon_ap;

  function new(string name = "alu_monitor",uvm_component parent = null);

    super.new(name, parent);
  endfunction

  function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        mon_ap=new("mon_ap",this);
	    if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
          `uvm_fatal("NOVIF", "Virtual interface not set")
        end
  endfunction

  task run_phase(uvm_phase phase);
	super.run_phase(phase);
    forever begin
      item = tb_sequence_item::type_id::create("item", this);
	  @(negedge vif.clk); 
      item.a = vif.a;
      item.b = vif.b;
      item.aluc = vif.aluc;
      item.r = vif.r;
      item.zero = vif.zero;
      item.flag = vif.flag;
	  `uvm_info("ALU_MONITOR", $sformatf("active"), UVM_LOW);
	  //item.print();
      mon_ap.write(item);
    end
  endtask
endclass
