# code for spi_interface
  
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




    
