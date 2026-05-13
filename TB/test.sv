# code for apb_spi_pkg.sv

  ...
  package apb_spi_pkg;
	import uvm_pkg::*;
        `include "uvm_macros.svh"

        `include "apb_agt_config.sv"
        `include "spi_agt_config.sv"
        `include "apb_spi_tb_config.sv"

        `include "apb_trans.sv"
        `include "apb_seqs.sv"
        `include "apb_sequencer.sv"
        `include "apb_driver.sv"
        `include "apb_monitor.sv"
        `include "apb_agt.sv"
        `include "apb_agt_top.sv"

        `include "spi_trans.sv"
        `include "spi_seqs.sv"
        `include "spi_sequencer.sv"
        `include "spi_driver.sv"
        `include "spi_monitor.sv"
        `include "spi_agt.sv"
        `include "spi_agt_top.sv"

        `include "apb_spi_scoreboard.sv"

        `include "apb_spi_tb.sv"
        `include "apb_spi_test.sv"
endpackage

...

# code for apb_spi_test.sv

  ...
  class apb_spi_test extends uvm_test;
	`uvm_component_utils(apb_spi_test)

	function new(string name="apb_spi_test",uvm_component parent);
		super.new(name,parent);
	endfunction

	apb_spi_tb envh;
	apb_spi_tb_config env_cfg;
	spi_agt_config spi_cfg[];
	apb_agt_config apb_cfg[];

	int no_of_spi_agt=1;
	int no_of_apb_agt=1;
	
	int has_scoreboard=1;
	
	int has_apb_agt=1;
        int has_spi_agt=1;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		env_cfg=apb_spi_tb_config::type_id::create("env_cfg");
	
	if(env_cfg.has_spi_agt)
	begin
		env_cfg.spi_cfg=new[no_of_spi_agt];
		spi_cfg=new[no_of_spi_agt];
		foreach(spi_cfg[i])
			begin
				spi_cfg[i]=spi_agt_config::type_id::create($sformatf("spi_cfg[%0d]",i));
				spi_cfg[i].is_active=UVM_ACTIVE;
				if(!uvm_config_db#(virtual spi_if)::get(this,"","spi_if",spi_cfg[i].spi_if))
                    			`uvm_fatal(get_type_name(),"getting spi_if has failed in test!!")
				env_cfg.spi_cfg[i]=spi_cfg[i];
			//	uvm_config_db#(spi_agt_config)::set(this,"*","spi_agt_config",spi_cfg[i]);
			end
	end

	if(env_cfg.has_apb_agt)
	begin
		env_cfg.apb_cfg=new[no_of_apb_agt];
		apb_cfg=new[no_of_apb_agt];
		foreach(apb_cfg[i])
			begin
				apb_cfg[i]=apb_agt_config::type_id::create($sformatf("apb_cfg[%0d]",i));
				apb_cfg[i].is_active=UVM_ACTIVE;
				if(!uvm_config_db#(virtual apb_if)::get(this,"","apb_if",apb_cfg[i].apb_if))
					`uvm_fatal(get_type_name(),"getting apb_if has failed in test!!")
				env_cfg.apb_cfg[i]=apb_cfg[i];
			//	uvm_config_db#(apb_agt_config)::set(this,"*","apb_agt_config",apb_cfg[i]);
			end
	end
		

		uvm_config_db#(apb_spi_tb_config)::set(this,"*","apb_spi_tb_config",env_cfg);
		env_cfg.no_of_spi_agt=this.no_of_spi_agt;
		env_cfg.no_of_apb_agt=this.no_of_apb_agt;
		env_cfg.has_apb_agt=this.has_apb_agt;
                env_cfg.has_spi_agt=this.has_spi_agt;
		envh=apb_spi_tb::type_id::create("envh",this);
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction
endclass


//reset test
class apb_reset_test extends apb_spi_test;
    `uvm_component_utils(apb_reset_test)
    function new(string name="apb_reset_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    apb_reset_seqs re;

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        re=apb_reset_seqs::type_id::create("re");
        re.start(envh.apb_agt.agt[0].seqrh);
        #1000;
        phase.drop_objection(this);
    endtask

endclass


//cpol,cpha,lsbfe 000
class apb_000 extends apb_spi_test;
	`uvm_component_utils(apb_000)
	function new(string name="apb_000",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_0010;
	apb_write_seqs w1;
	apb_read_seqs r1;

	function void build_phase(uvm_phase phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		super.build_phase(phase);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
		w1.start(envh.apb_agt.agt[0].seqrh);
		r1.start(envh.apb_agt.agt[0].seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

//cpol,cpha,lsbfe 001
class apb_001 extends apb_spi_test;
	`uvm_component_utils(apb_001)
	function new(string name="apb_001",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_0011;
	apb_write_seqs w1;
	apb_read_seqs r1;

	function void build_phase(uvm_phase phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		super.build_phase(phase);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
		w1.start(envh.apb_agt.agt[0].seqrh);
		r1.start(envh.apb_agt.agt[0].seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

//cpol,cpha,lsbfe 010
class apb_010 extends apb_spi_test;
	`uvm_component_utils(apb_010)
	function new(string name="apb_000",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_0110;
	apb_write_seqs w1;
	apb_read_seqs r1;

	function void build_phase(uvm_phase phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		super.build_phase(phase);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
		w1.start(envh.apb_agt.agt[0].seqrh);
		r1.start(envh.apb_agt.agt[0].seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

//cpol,cpha,lsbfe 011
class apb_011 extends apb_spi_test;
	`uvm_component_utils(apb_011)
	function new(string name="apb_011",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_0111;
	apb_write_seqs w1;
	apb_read_seqs r1;

	function void build_phase(uvm_phase phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		super.build_phase(phase);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
		w1.start(envh.apb_agt.agt[0].seqrh);
		r1.start(envh.apb_agt.agt[0].seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

//cpol,cpha,lsbfe 100
class apb_100 extends apb_spi_test;
	`uvm_component_utils(apb_100)
	function new(string name="apb_100",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_1010;
	apb_write_seqs w1;
	apb_read_seqs r1;

	function void build_phase(uvm_phase phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		super.build_phase(phase);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
		w1.start(envh.apb_agt.agt[0].seqrh);
		r1.start(envh.apb_agt.agt[0].seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

//cpol,cpha,lsbfe 101
class apb_101 extends apb_spi_test;
	`uvm_component_utils(apb_101)
	function new(string name="apb_101",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_1011;
	apb_write_seqs w1;
	apb_read_seqs r1;

	function void build_phase(uvm_phase phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		super.build_phase(phase);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
		w1.start(envh.apb_agt.agt[0].seqrh);
		r1.start(envh.apb_agt.agt[0].seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

//cpol,cpha,lsbfe 110
class apb_110 extends apb_spi_test;
	`uvm_component_utils(apb_110)
	function new(string name="apb_110",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_1110;
	apb_write_seqs w1;
	apb_read_seqs r1;

	function void build_phase(uvm_phase phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		super.build_phase(phase);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
		w1.start(envh.apb_agt.agt[0].seqrh);
		r1.start(envh.apb_agt.agt[0].seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

//cpol,cpha,lsbfe 111
class apb_111 extends apb_spi_test;
	`uvm_component_utils(apb_111)
	function new(string name="apb_111",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_1111;
	apb_write_seqs w1;
	apb_read_seqs r1;

	function void build_phase(uvm_phase phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		super.build_phase(phase);
	endfunction
	
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
		w1.start(envh.apb_agt.agt[0].seqrh);
		r1.start(envh.apb_agt.agt[0].seqrh);
		#1000;
		phase.drop_objection(this);
	endtask
endclass

//spi_miso_test
class spi_miso_test extends apb_spi_test;
	`uvm_component_utils(spi_miso_test)
	function new(string name="spi_miso_test",uvm_component parent);
		super.new(name,parent);
	endfunction

	bit [7:0]ctrl=8'b1111_1111;
	apb_write_seqs w1;
	apb_read_seqs r1;
	spi_miso_seqs m1;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		uvm_config_db #(bit[7:0])::set(this,"*","bit",ctrl);
		m1=spi_miso_seqs::type_id::create("m1");
		w1=apb_write_seqs::type_id::create("w1");
		r1=apb_read_seqs::type_id::create("r1");
	endfunction
	
	/*function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction*/
		
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		w1.start(envh.apb_agt.agt[0].seqrh);
		m1.start(envh.spi_agt.agt[0].seqrh);
		#1000;
		r1.start(envh.apb_agt.agt[0].seqrh);
		phase.drop_objection(this);
	endtask
endclass

...
