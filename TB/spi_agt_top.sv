# code for spi_agt.sv

  ...
  class spi_agt extends uvm_agent;
	`uvm_component_utils(spi_agt)

        function new(string name="spi_agt",uvm_component parent);
                super.new(name,parent);
        endfunction

	spi_driver drvh;
	spi_monitor monh;
	spi_sequencer seqrh;
	spi_agt_config spi_cfg;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(spi_agt_config)::get(this,"","spi_agt_config",spi_cfg))
			`uvm_fatal(get_type_name(),"getting cfgh has failed!")
		monh=spi_monitor::type_id::create("monh",this);
		if(spi_cfg.is_active==UVM_ACTIVE)
		begin
			drvh=spi_driver::type_id::create("drvh",this);
			seqrh=spi_sequencer::type_id::create("seqrh",this);
		end
	endfunction

	function void connect_phase(uvm_phase phase);
		if(spi_cfg.is_active==UVM_ACTIVE)
		drvh.seq_item_port.connect(seqrh.seq_item_export);
	endfunction
endclass

...

# code for spi_agt_cfg.sv

  ...
  class spi_agt_config extends uvm_object;
	`uvm_object_utils(spi_agt_config)

	uvm_active_passive_enum is_active;
	virtual spi_if spi_if;

	function new(string name="spi_agt_config");
		super.new(name);
	endfunction
endclass

...

# code for spi_agt_top.sv

  ...
  class spi_agt_top extends uvm_env;
	`uvm_component_utils(spi_agt_top)
	
	spi_agt agt[];
	spi_agt_config spi_cfg[]; 
	apb_spi_tb_config tb_cfg;

        function new(string name="spi_agt_top",uvm_component parent);
                super.new(name,parent);
        endfunction

	function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(apb_spi_tb_config)::get(this,"","apb_spi_tb_config",tb_cfg))
                        `uvm_fatal(get_type_name(),"getting tb_cfg failed!!")

                if(tb_cfg.has_spi_agt)
                begin
                        agt=new[tb_cfg.no_of_spi_agt];
                        foreach(agt[i])
                        begin
                                uvm_config_db#(spi_agt_config)::set(this,$sformatf("agt[%0d]*",i),"spi_agt_config",tb_cfg.spi_cfg[i]);
                                agt[i]=spi_agt::type_id::create($sformatf("agt[%0d]",i),this);
                        end
                end
        endfunction

endclass

...

# code for spi_driver.sv

  ...
  class spi_driver extends uvm_driver#(spi_trans);
	`uvm_component_utils(spi_driver)

	spi_agt_config spi_cfg;
	virtual spi_if.SPI_DRV_MP spi_if;
	bit [7:0]ctrl;
	bit cpol;
	bit cpha;
	bit lsbfe;

	function new(string name="spi_driver",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(spi_agt_config)::get(this,"","spi_agt_config",spi_cfg))
			`uvm_fatal(get_type_name(),"Getting agt_cfg has failed!!")
		super.build_phase(phase);
	endfunction
		
	function void connect_phase(uvm_phase phase);
		spi_if=spi_cfg.spi_if;
	endfunction

	task run_phase(uvm_phase phase);
		forever
		begin
			seq_item_port.get_next_item(req);	
			drive_to_dut(req);
			seq_item_port.item_done();
		end
	endtask
		
	task drive_to_dut(spi_trans xtn);
		if(!uvm_config_db #(bit[7:0])::get(this,"","bit",ctrl))
			`uvm_fatal(get_type_name(),"Getting the ctrl failed!!");
		cpol=ctrl[3];
		cpha=ctrl[2];
		lsbfe=ctrl[0];

		wait(!spi_if.spi_drv_cb.ss_o)
		begin
			if(lsbfe)
			begin
				if((!cpol)&&(!cpha))
				begin
					spi_if.spi_drv_cb.miso_i<=xtn.miso_i[0];
					for(int i=1;i<=7;i++)
					begin
						@(negedge spi_if.spi_drv_cb.SCLK_o)
						spi_if.spi_drv_cb.miso_i<=xtn.miso_i[i];
					end
				end
				else if((cpol)&&(!cpha))
				begin
					spi_if.spi_drv_cb.miso_i<=xtn.miso_i[0];
					for(int i=1;i<=7;i++)
					begin
						@(posedge spi_if.spi_drv_cb.SCLK_o)
						spi_if.spi_drv_cb.miso_i<=xtn.miso_i[i];
					end
				end
				else if((!cpol)&&(cpha))
				begin
					for(int i=0;i<=7;i++)
					begin
						@(posedge spi_if.spi_drv_cb.SCLK_o)
						spi_if.spi_drv_cb.miso_i<=xtn.miso_i[i];
					end
				end
				else
				begin
					for(int i=0;i<=7;i++)
					begin
						@(negedge spi_if.spi_drv_cb.SCLK_o)
						spi_if.spi_drv_cb.miso_i<=xtn.miso_i[i];
					end
				end
			end

			else
			begin
				if((!cpol)&&(!cpha))
				begin
					spi_if.spi_drv_cb.miso_i<=xtn.miso_i[7];
					for(int i=6;i>=0;i--)
					begin
						@(negedge spi_if.spi_drv_cb.SCLK_o)
						spi_if.spi_drv_cb.miso_i<=xtn.miso_i[i];
					end
				end
				else if((cpol)&&(!cpha))
				begin
					spi_if.spi_drv_cb.miso_i<=xtn.miso_i[7];
					for(int i=6;i>=0;i--)
					begin
						@(posedge spi_if.spi_drv_cb.SCLK_o)
						spi_if.spi_drv_cb.miso_i<=xtn.miso_i[i];
					end
				end
				else if((!cpol)&&(cpha))
				begin
					for(int i=7;i>=0;i--)
					begin
						@(posedge spi_if.spi_drv_cb.SCLK_o)
						spi_if.spi_drv_cb.miso_i<=xtn.miso_i[i];
					end
				end
				else
				begin
					for(int i=7;i>=0;i--)
					begin
						@(negedge spi_if.spi_drv_cb.SCLK_o)
						spi_if.spi_drv_cb.miso_i<=xtn.miso_i[i];
					end
				end
			end
		end
		`uvm_info(get_type_name(),xtn.sprint,UVM_LOW)
	endtask
endclass

...

# code for spi_monitor.sv

  ...
  class spi_monitor extends uvm_monitor;
	`uvm_component_utils(spi_monitor)

	uvm_analysis_port#(spi_trans)ap;
	spi_agt_config spi_cfg;
	spi_trans xtn;
	
	virtual spi_if.SPI_MON_MP spi_if;
	
	bit [7:0]ctrl;
	bit cpol;
	bit cpha;
	bit lsbfe;
	
        function new(string name="spi_monitor",uvm_component parent);
                super.new(name,parent);
		ap=new("ap",this);
		xtn=spi_trans::type_id::create("xtn");
        endfunction

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(spi_agt_config)::get(this,"","spi_agt_config",spi_cfg))
			`uvm_fatal(get_type_name(),"Getting spi_cfg has failed!!")
		super.build_phase(phase);
	endfunction

	function void connect_phase(uvm_phase phase);
		spi_if=spi_cfg.spi_if;
	endfunction
	
	task run_phase(uvm_phase phase);
		forever
		begin
			collect_data();
		end
	endtask

	task collect_data();
		if(!uvm_config_db #(bit[7:0])::get(this,"","bit",ctrl))
			`uvm_fatal(get_type_name(),"Getting the ctrl has failed!!")
		cpol=ctrl[3];
		cpha=ctrl[2];
		lsbfe=ctrl[0];	
		@(spi_if.spi_mon_cb);
		wait(!spi_if.spi_mon_cb.ss_o)
		begin
			if(lsbfe)
			begin
				for(int i=0;i<=7;i++)
				begin
					if(((!cpol)&&(!cpha)||(cpol)&&(cpha)))
					begin
						@(posedge spi_if.spi_mon_cb.SCLK_o)
						xtn.miso_i[i]=spi_if.spi_mon_cb.miso_i;
						xtn.mosi_o[i]=spi_if.spi_mon_cb.mosi_o;
						xtn.SCLK_o=spi_if.spi_mon_cb.SCLK_o;
					end
					else
					begin
						@(negedge spi_if.spi_mon_cb.SCLK_o)

						xtn.miso_i[i]=spi_if.spi_mon_cb.miso_i;
						xtn.mosi_o[i]=spi_if.spi_mon_cb.mosi_o;
						xtn.SCLK_o=spi_if.spi_mon_cb.SCLK_o;
					end
				end
			end
			else
			begin
				for(int i=7;i>=0;i--)
				begin
					if(((!cpol)&&(!cpha)||(cpol)&&(cpha)))
					begin
						@(posedge spi_if.spi_mon_cb.SCLK_o)
						xtn.miso_i[i]=spi_if.spi_mon_cb.miso_i;
						xtn.mosi_o[i]=spi_if.spi_mon_cb.mosi_o;
						xtn.SCLK_o=spi_if.spi_mon_cb.SCLK_o;
					end
					else
					begin
						@(negedge spi_if.spi_mon_cb.SCLK_o)
						xtn.miso_i[i]=spi_if.spi_mon_cb.miso_i;
						xtn.mosi_o[i]=spi_if.spi_mon_cb.mosi_o;
						xtn.SCLK_o=spi_if.spi_mon_cb.SCLK_o;
					end
				end
			end
		end
	 `uvm_info("SPI Monitor",xtn.sprint,UVM_LOW)
	        ap.write(xtn);
	endtask
endclass

...

# code for spi_seqs.sv

  ...
  class spi_seqs extends uvm_sequence#(spi_trans);
	`uvm_object_utils(spi_seqs)

	function new(string name="spi_seqs");
		super.new(name);
	endfunction
endclass

class spi_miso_seqs extends spi_seqs;
	`uvm_object_utils(spi_miso_seqs)
	function new(string name="spi_miso_seqs");
		super.new(name);
	endfunction

	task body();
		repeat(1)
		begin
			req=spi_trans::type_id::create("req");
			start_item(req);
			assert(req.randomize());
			finish_item(req);
		end
	endtask
endclass

...

# code for spi_sequencer.sv

  ...
  class spi_sequencer extends uvm_sequencer#(spi_trans);
	`uvm_component_utils(spi_sequencer)

        function new(string name="spi_sequencer",uvm_component parent);
                super.new(name,parent);
        endfunction
endclass

...

# code for spi_trans.sv

  ...
  class spi_trans extends uvm_sequence_item;
	`uvm_object_utils(spi_trans)

	bit ss_o,SCLK_o;
	bit [7:0]mosi_o;
	rand bit [7:0]miso_i;

	function new(string name="spi_trans");
		super.new(name);
	endfunction

	function void do_print(uvm_printer printer);
		super.do_print(printer);
		printer.print_field("ss_o",this.ss_o,1,UVM_BIN);
		printer.print_field("mosi_o",this.mosi_o,8,UVM_BIN);
		printer.print_field("miso_i",this.miso_i,8,UVM_BIN);
	endfunction
endclass

...
  
