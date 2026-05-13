# code for apb_if.sv

  ...
  interface apb_if(input bit clock);
	bit PCLK;
	logic PRESET_n;
	logic PSEL_i,PENABLE_i,PWRITE_i,PREADY_o,PSLVERR_o;
	logic [2:0]PADDR_i;
	logic [7:0]PWDATA_i,PRDATA_o;
	assign PCLK=clock;


	clocking apb_drv_cb@(posedge clock);
		default input #1 output #1;
		output PRESET_n,PSEL_i,PENABLE_i,PWRITE_i,PADDR_i,PWDATA_i;
		input PREADY_o,PRDATA_o,PSLVERR_o;
	endclocking:apb_drv_cb

	clocking apb_mon_cb@(posedge clock);
		default input#1 output#1;
		input PRESET_n,PSEL_i,PENABLE_i,PWRITE_i,PADDR_i,PWDATA_i;
		input PREADY_o,PRDATA_o,PSLVERR_o;
	endclocking:apb_mon_cb


	modport APB_DRV_MP(clocking apb_drv_cb);
	modport APB_MON_MP(clocking apb_mon_cb);

endinterface

    ...

#code for spi_if.sv

  ...
  interface spi_if(input bit clock);
	logic ss_o;
	logic SCLK_o;
	logic mosi_o;
	logic miso_i;

	clocking spi_drv_cb@(posedge clock);
		default input#1 output #1;
			input ss_o;
			input SCLK_o;
			input mosi_o;
			output miso_i;
	endclocking:spi_drv_cb


	clocking spi_mon_cb@(posedge clock);
		default input #1 output #1;
			input ss_o;
			input SCLK_o;
			input mosi_o;
			input miso_i;
	endclocking:spi_mon_cb


	modport SPI_DRV_MP(clocking spi_drv_cb);
	modport SPI_MON_MP(clocking spi_mon_cb);

endinterface

  ...
