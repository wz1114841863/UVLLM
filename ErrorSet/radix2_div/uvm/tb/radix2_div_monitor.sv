
class radix2_div_monitor extends uvm_monitor;
    `uvm_component_utils(radix2_div_monitor)
    radix2_div_transaction tr;

    virtual radix2_div_if vif;
    uvm_analysis_port#(radix2_div_transaction) mon_ap;
    
	function new(string name = "radix2_div_monitor",uvm_component parent = null);

       super.new(name, parent);
    endfunction

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        mon_ap=new("mon_ap",this);
	    if (!uvm_config_db#(virtual radix2_div_if)::get(this, "", "vif", vif)) begin
          `uvm_fatal("NOVIF", "Virtual interface not set")
        end
    endfunction

    task run_phase(uvm_phase phase);
		super.run_phase(phase);
        forever begin
            tr = radix2_div_transaction::type_id::create("tr");
            @(posedge vif.clk);
			if (vif.res_valid && vif.res_ready) begin
                tr.dividend = vif.dividend;
                tr.divisor = vif.divisor;
                tr.sign = vif.sign;
                tr.result = vif.result;
				//tr.print();
                mon_ap.write(tr);
            end
        end
    endtask
endclass
