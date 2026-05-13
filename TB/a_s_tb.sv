# code for top.sv

  ...
  module top();
	import uvm_pkg::*;
	import apb_spi_pkg::*;
	`include "uvm_macros.svh"

	bit clk;
	always #5 clk=~clk;

	apb_if APB_IF(clk);
	spi_if SPI_IF(clk);
	
	spi_top_module DUT(.PCLK(APB_IF.PCLK),
				.PRESET_n(APB_IF.PRESET_n),
				.PADDR_i(APB_IF.PADDR_i),
				.PWRITE_i(APB_IF.PWRITE_i),
				.PSEL_i(APB_IF.PSEL_i),
				.PENABLE_i(APB_IF.PENABLE_i),
				.PWDATA_i(APB_IF.PWDATA_i),
				.miso_i(SPI_IF.miso_i),
				.PRDATA_o(APB_IF.PRDATA_o),
				.PREADY_o(APB_IF.PREADY_o),
				.PSLVERR_o(APB_IF.PSLVERR_o),
				.SCLK_o(SPI_IF.SCLK_o),
				.mosi_o(SPI_IF.mosi_o),
				.ss_o(SPI_IF.ss_o),
				.spi_interrupt_request_o(spi_interrupt_request_o));

	initial
	begin
		uvm_config_db#(virtual apb_if)::set(null,"*","apb_if",APB_IF);
		uvm_config_db#(virtual spi_if)::set(null,"*","spi_if",SPI_IF);
		run_test("test");
	end
endmodule

...

# code for apb_spi_tb.sv

  ...
   class apb_spi_tb extends uvm_env;
	`uvm_component_utils(apb_spi_tb)
	
	spi_agt_top spi_agt;
	apb_agt_top apb_agt;
	apb_spi_tb_config tb_cfg;
	apb_spi_sb sb;
	
	function new(string name="apb_spi_tb",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(apb_spi_tb_config)::get(this,"","apb_spi_tb_config",tb_cfg))
			`uvm_fatal(get_type_name(),"getting tb_cfg is failed!!")
		spi_agt=spi_agt_top::type_id::create("spi_agt",this);
		apb_agt=apb_agt_top::type_id::create("apb_agt",this);
		sb=apb_spi_sb::type_id::create("sb",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		apb_agt.agt[0].monh.ap.connect(sb.fifo_apb[0].analysis_export);
		spi_agt.agt[0].monh.ap.connect(sb.fifo_spi[0].analysis_export);
	endfunction

endclass

...

# code apb_spi_tb_cfg.sv

...
class apb_spi_tb_config extends uvm_object;
	`uvm_object_utils(apb_spi_tb_config)
	
	spi_agt_config spi_cfg[];
	apb_agt_config apb_cfg[];

	int no_of_spi_agt;
	int no_of_apb_agt;
	int has_apb_agt=1;
        int has_spi_agt=1;

	function new(string name="apb_spi_tb_config");
		super.new(name);
	endfunction
endclass

...

# code for apb_spi_scoreboard.sv

  ...
  class apb_spi_sb extends uvm_scoreboard;
	`uvm_component_utils(apb_spi_sb)

	uvm_tlm_analysis_fifo #(apb_trans) fifo_apb[];
	uvm_tlm_analysis_fifo #(spi_trans) fifo_spi[];

	apb_spi_tb_config env_cfg;
	
	apb_trans a_xtn;
	spi_trans s_xtn;

	apb_trans apb_cov_data;
	spi_trans spi_cov_data;

	int data_verified_cnt;
	static int data_same, data_not_same;

	covergroup apb_cover_group;
		option.per_instance=1;
		RESET: coverpoint apb_cov_data.PRESET_n{bins rst={0,1};}
		ADDR: coverpoint apb_cov_data.PADDR_i{bins addr[]={0,1,2,3,5};}
		SELX: coverpoint apb_cov_data.PSEL_i{bins sel={0,1};}
		ENABLE: coverpoint apb_cov_data.PENABLE_i{bins enb={0,1};}
		WRITE: coverpoint apb_cov_data.PWRITE_i{bins wrt[]={0,1};}
		READY: coverpoint apb_cov_data.PREADY_o{bins rdy={0,1};}
		ERROR: coverpoint apb_cov_data.PSLVERR_o{bins err={0,1};}
		WDATA: coverpoint apb_cov_data.PWDATA_i{bins wdata_low={[8'h00:8'h7f]};
							bins wdata_high={[8'h80:8'hff]};}
		RDATA: coverpoint apb_cov_data.PRDATA_o{bins rdata_low={[8'h00:8'h7f]};
							bins rdata_high={[8'h80:8'hff]};}
		SELX_ENABLE: cross SELX,ENABLE;
		SELX_ENABLE_READY: cross SELX,ENABLE,READY;
	endgroup

	covergroup spi_cover_group;
		option.per_instance=1;
		SLAVE_SELECT: coverpoint spi_cov_data.ss_o{bins ss={0,1};}
		MISO_DATA: coverpoint spi_cov_data.miso_i{bins miso_low={[8'h00:8'h7f]};
						bins miso_high={[8'h80:8'hff]};}
		MOSI_DATA: coverpoint spi_cov_data.mosi_o{bins mosi_low={[8'h00:8'h7f]};
						bins mosi_high={[8'h80:8'hff]};}
	endgroup

	function new(string name="apb_spi_sb",uvm_component parent);
		super.new(name,parent);
		apb_cover_group=new();
		spi_cover_group=new();
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);	
	
		if(!uvm_config_db #(apb_spi_tb_config)::get(this,"","apb_spi_tb_config",env_cfg))
			`uvm_fatal(get_type_name(),"Getting env_cfg in scoreboard has failed!!")
		fifo_apb=new[env_cfg.no_of_apb_agt];
		fifo_spi=new[env_cfg.no_of_spi_agt];
		
		foreach(fifo_apb[i])
			fifo_apb[i]=new($sformatf("fifo_apb[%0d]",i),this);
		foreach(fifo_spi[i])
			fifo_spi[i]=new($sformatf("fifo_spi[%0d]",i),this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);	
	endfunction

	task run_phase(uvm_phase phase);
		fork
		begin
			forever
			begin
				fifo_apb[0].get(a_xtn);
				apb_cov_data=new a_xtn;
				apb_cover_group.sample();
				compare_data1();
			end
		end
		begin
			forever
			begin
				fifo_spi[0].get(s_xtn);
				spi_cov_data=new s_xtn;
				spi_cover_group.sample();
				compare_data();
			end
		end
		join
	endtask

	task compare_data();
		wait(s_xtn!=null);
		wait(a_xtn!=null);
		if(a_xtn.PWRITE_i && (a_xtn.PADDR_i==3'b101))
		begin
						if(a_xtn.PWDATA_i==s_xtn.mosi_o)
			begin
				data_same++;
				$display("PWDATA MOSI data comparision successfull");
				
			end
			else
			begin
				data_not_same++;
				$display("PWDATA MOSI data comparision failed");
				
			end
		end
	endtask

	task compare_data1();
		wait(s_xtn!=null);
		wait(a_xtn!=null);
		if(!a_xtn.PWRITE_i && (a_xtn.PADDR_i==3'b101))
		begin
			$display("--------------------*SCOREBOARD*-----------------------");
			if(a_xtn.PRDATA_o==s_xtn.miso_i)
			begin
				data_same++;
				$display("PRDATA MISO data comparision successfull");
			end
			else
			begin
				data_not_same++;
				$display("PRDATA MISO data comparision failed");
			
			end
		end
		data_verified_cnt++;
	endtask	

	function void report_phase(uvm_phase phase);
		$display("\n----------------------------------------*SCOREBOARD*--------------------------");	
		$display("Data same : %0d | Data not same: %0d", data_same, data_not_same);
	endfunction
endclass

...
