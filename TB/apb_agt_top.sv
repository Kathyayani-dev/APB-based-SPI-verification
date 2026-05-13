# code for apb_agt.sv

  ...
  class apb_agt extends uvm_agent;
	`uvm_component_utils(apb_agt)

	apb_driver drvh;
	apb_monitor monh;
	apb_sequencer seqrh;

	apb_agt_config apb_cfg;

        function new(string name="apb_agt",uvm_component parent);
                super.new(name,parent);
        endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if(!uvm_config_db #(apb_agt_config)::get(this,"","apb_agt_config",apb_cfg))
			`uvm_fatal(get_type_name(),"getting the apb_cfg has failed!!")

		monh=apb_monitor::type_id::create("monh",this);
		if(apb_cfg.is_active==UVM_ACTIVE)
		begin
			drvh=apb_driver::type_id::create("drvh",this);
			seqrh=apb_sequencer::type_id::create("seqrh",this);
		end
	endfunction

	function void connect_phase(uvm_phase phase);
		if(apb_cfg.is_active==UVM_ACTIVE)
		drvh.seq_item_port.connect(seqrh.seq_item_export);
	endfunction
endclass

...

# code for apb_agt_cfg.sv

  ...
  class apb_agt_config extends uvm_object;
	`uvm_object_utils(apb_agt_config)

	uvm_active_passive_enum is_active;
	virtual apb_if apb_if;
	function new(string name="apb_agt_config");
		super.new(name);
	endfunction
endclass

...

# code for apb_agt_top.sv

  ...
  class apb_agt_top extends uvm_env;
	`uvm_component_utils(apb_agt_top)
	
	apb_agt agt[];
	apb_agt_config apb_cfg[];
	apb_spi_tb_config tb_cfg;

        function new(string name="apb_agt_top",uvm_component parent);
                super.new(name,parent);
        endfunction

	function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(apb_spi_tb_config)::get(this,"","apb_spi_tb_config",tb_cfg))
                        `uvm_fatal(get_type_name(),"getting tb_cfg failed!!")

                if(tb_cfg.has_apb_agt)
                begin
                        agt=new[tb_cfg.no_of_apb_agt];
                        foreach(agt[i])
                        begin
				uvm_config_db#(apb_agt_config)::set(this,$sformatf("agt[%0d]*",i),"apb_agt_config",tb_cfg.apb_cfg[i]);

                                agt[i]=apb_agt::type_id::create($sformatf("agt[%0d]",i),this);
                        end
                end
        endfunction
	
endclass

...

# code for apb_driver.sv

  ...
  class apb_driver extends uvm_driver#(apb_trans);
	`uvm_component_utils(apb_driver)

	virtual apb_if.APB_DRV_MP apb_if;
	apb_agt_config apb_cfg;
	
	function new(string name="apb_driver",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(apb_agt_config)::get(this,"","apb_agt_config",apb_cfg))
			`uvm_fatal(get_type_name(),"getting apb_cfg has failed!!");
		//super.build_phase(phase);
	endfunction

	function void connect_phase(uvm_phase phase);
		apb_if=apb_cfg.apb_if;
	endfunction

	task run_phase(uvm_phase phase);
		reset_dut();
		forever
		begin
			seq_item_port.get_next_item(req);
			send_to_dut(req);
			seq_item_port.item_done();
		end
	endtask

	task reset_dut();
		@(apb_if.apb_drv_cb)
		apb_if.apb_drv_cb.PRESET_n<=1'b0;

		repeat(3)
		@(apb_if.apb_drv_cb)
		apb_if.apb_drv_cb.PRESET_n<=1'b1;
	endtask

	task send_to_dut(apb_trans xtn);
		@(apb_if.apb_drv_cb);
		apb_if.apb_drv_cb.PRESET_n<=1'b1;
		apb_if.apb_drv_cb.PADDR_i<=xtn.PADDR_i;
		apb_if.apb_drv_cb.PWRITE_i<=xtn.PWRITE_i;
		apb_if.apb_drv_cb.PSEL_i<=1'b1;
		apb_if.apb_drv_cb.PENABLE_i<=1'b0;
		
		if(xtn.PWRITE_i==1'b1)
		begin
            		apb_if.apb_drv_cb.PWDATA_i<=xtn.PWDATA_i;
        	end
        
        	@(apb_if.apb_drv_cb);
            	apb_if.apb_drv_cb.PENABLE_i<=1'b1;
            
        	wait(apb_if.apb_drv_cb.PREADY_o) 
        	if(xtn.PWRITE_i==1'b0)
            		xtn.PRDATA_o=apb_if.apb_drv_cb.PRDATA_o;

        	`uvm_info(get_type_name(),xtn.sprint,UVM_LOW)

        
		@(apb_if.apb_drv_cb);

        	apb_if.apb_drv_cb.PSEL_i<=1'b0;
	        apb_if.apb_drv_cb.PENABLE_i<=1'b0;
	endtask
endclass

...

# apb_monitor.sv

...
class apb_monitor extends uvm_monitor;
	`uvm_component_utils(apb_monitor)
	
	apb_agt_config apb_cfg;
	uvm_analysis_port #(apb_trans) ap;
	apb_trans xtn;

	virtual apb_if.APB_MON_MP apb_if;

        function new(string name="apb_monitor",uvm_component parent);
                super.new(name,parent);
		ap=new("ap",this);
		xtn=apb_trans::type_id::create("xtn");
        endfunction

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(apb_agt_config)::get(this,"","apb_agt_config",apb_cfg))
			`uvm_fatal(get_type_name(),"Getting the apb_cfg has failed!!");
		super.build_phase(phase);
	endfunction

	function void connect_phase(uvm_phase phase);
		apb_if=apb_cfg.apb_if;
	endfunction

	task run_phase(uvm_phase phase);
		forever
		begin
			collect_data();
		end
	endtask

	task collect_data();
			
		wait(apb_if.apb_mon_cb.PENABLE_i && apb_if.apb_mon_cb.PREADY_o)
			xtn.PRESET_n=apb_if.apb_mon_cb.PRESET_n;
			xtn.PADDR_i=apb_if.apb_mon_cb.PADDR_i;
			xtn.PWRITE_i=apb_if.apb_mon_cb.PWRITE_i;
			xtn.PSEL_i=apb_if.apb_mon_cb.PSEL_i;
			xtn.PENABLE_i=apb_if.apb_mon_cb.PENABLE_i;
		
		if(apb_if.apb_mon_cb.PWRITE_i)
			xtn.PWDATA_i=apb_if.apb_mon_cb.PWDATA_i;
		else
		begin
			xtn.PRDATA_o=apb_if.apb_mon_cb.PRDATA_o;
			xtn.PREADY_o=apb_if.apb_mon_cb.PREADY_o;
			xtn.PSLVERR_o=apb_if.apb_mon_cb.PSLVERR_o;
		end
		ap.write(xtn);
		@(apb_if.apb_mon_cb);
	endtask
endclass

...

# code for apb_seqs.sv

  ...
  class apb_seqs extends uvm_sequence#(apb_trans);
	`uvm_object_utils(apb_seqs)

	function new(string name="apb_seqs");
		super.new(name);
	endfunction
endclass

//write sequence
class apb_write_seqs extends apb_seqs;
	`uvm_object_utils(apb_write_seqs)
	function new(string name="apb_write_seqs");
		super.new(name);
	endfunction
	
	bit [7:0]ctrl;

	task body();
		if(!uvm_config_db#(bit[7:0])::get(null,get_full_name(),"bit",ctrl))
	            `uvm_fatal(get_type_name(), "Not getting ctrl from test")
		repeat(1)
		begin
			req=apb_trans::type_id::create("req");
		
			start_item(req);
			assert(req.randomize() with{PRESET_n; PWRITE_i==1'b0; PADDR_i==3'b101;}); //Dummy read
			finish_item(req);
	
			start_item(req);
		        assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b1; PADDR_i==3'b000; PWDATA_i==ctrl;}); //CR1
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b1; PADDR_i==3'b001; PWDATA_i==8'b0001_1000;}); //CR2
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b1; PADDR_i==3'b010; PWDATA_i==8'b0001_0001;}); //BR
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b1; PADDR_i==3'b101;}); //DR
			finish_item(req);
		end
	endtask
endclass

//read sequence
class apb_read_seqs extends apb_seqs;
	`uvm_object_utils(apb_read_seqs)
	function new(string name="apb_read_seqs");
		super.new(name);
	endfunction

	task body();
		repeat(1)
		begin
			req=apb_trans::type_id::create("req");

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b0; PADDR_i==3'b000;}); //CR1
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b0; PADDR_i==3'b001;}); //CR2
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b0; PADDR_i==3'b010;}); //BR
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b0; PADDR_i==3'b011;}); //SR
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b1; PWRITE_i==1'b0; PADDR_i==3'b101;}); //DR
			finish_item(req);
	        end
	endtask   
endclass

//reset sequence
class apb_reset_seqs extends apb_seqs;
	`uvm_object_utils(apb_reset_seqs)
	function new(string name="apb_reset_seqs");
		super.new(name);
	endfunction

	task body();
		repeat(1)
		begin
			req=apb_trans::type_id::create("req");

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b0; PWRITE_i==1'b0; PADDR_i==3'b000;}); //CR1
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b0; PWRITE_i==1'b0; PADDR_i==3'b001;}); //CR2
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b0; PWRITE_i==1'b0; PADDR_i==3'b010;}); //BR
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b0; PWRITE_i==1'b0; PADDR_i==3'b011;}); //SR
			finish_item(req);

			start_item(req);
			assert(req.randomize() with {PRESET_n==1'b0; PWRITE_i==1'b0; PADDR_i==3'b101;}); //DR
			finish_item(req);
	        end
	endtask   
endclass

...

# code for apb_sequencer.sv

  ...
  class apb_sequencer extends uvm_sequencer#(apb_trans);
	  `uvm_component_utils(apb_sequencer)

        function new(string name="apb_sequencer",uvm_component parent);
                super.new(name,parent);
        endfunction
  endclass

 ...

# code for apb_trans.sv

  ...
  class apb_trans extends uvm_sequence_item;
	  `uvm_object_utils(apb_trans)
	
	rand bit PRESET_n;
	rand bit PWRITE_i;
	bit PSEL_i,PENABLE_i;
	rand bit [2:0]PADDR_i;
	rand bit [7:0]PWDATA_i;
	bit [7:0]PRDATA_o;
	bit PSLVERR_o,PREADY_o;
	
	function new(string name="apb_trans");
		super.new(name);
	endfunction

	function void do_print(uvm_printer printer);
		super.do_print(printer);
		printer.print_field("PRESET_n",this.PRESET_n,1,UVM_BIN);
		printer.print_field("PWRITE_i",this.PWRITE_i,1,UVM_BIN);
		printer.print_field("PSEL_i",this.PSEL_i,1,UVM_BIN);
		printer.print_field("PENABLE_i",this.PENABLE_i,1,UVM_BIN);
		printer.print_field("PADDR_i",this.PADDR_i,3,UVM_BIN);
		printer.print_field("PWDATA_i",this.PWDATA_i,8,UVM_BIN);
		printer.print_field("PRDATA_o",this.PRDATA_o,8,UVM_BIN);
		printer.print_field("PSLVERR_o",this.PSLVERR_o,1,UVM_BIN);
		printer.print_field("PREADY_o",this.PREADY_o,1,UVM_BIN);
	endfunction
endclass

...
