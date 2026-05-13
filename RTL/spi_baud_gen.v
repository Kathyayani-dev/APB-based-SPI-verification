# code for spi_baud_generator.v

  ...
  module spi_baud_generator(PCLK, PRESET_n,spi_mode_i, spiswai_i, spr_i, sppr_i, cpol_i, cpha_i, ss_i, SCLK_o, miso_receive_sclk_o, miso_receive_sclk0_o, mosi_send_sclk_o, mosi_send_sclk0_o, BaudRateDivisor_o);

	input PCLK, PRESET_n;
	input [1:0] spi_mode_i;
	input spiswai_i;
	input [2:0] spr_i, sppr_i;
	input cpol_i, cpha_i;
	input ss_i;

	parameter mode_run = 2'b00, 
		mode_wait =2'b01, 
		mode_stop=2'b10;

	output reg SCLK_o;
	output reg miso_receive_sclk_o;
	output reg miso_receive_sclk0_o;
	output reg mosi_send_sclk_o;
	output reg mosi_send_sclk0_o;


	reg pre_sclk_s;
	reg [11:0]count_s;

	output reg [11:0]BaudRateDivisor_o;


	//Compute Baud Rate Divisor
	always@(*)
	begin
		BaudRateDivisor_o= (sppr_i+1'b1) * (2 ** (spr_i+1'b1));
	end

	//Generate Initial SCLK Polarity
	always@(*)
	begin
		pre_sclk_s = (cpol_i) ? 1'b1 : 1'b0;
	end
	
	

	//Generate SPI clock
	always@(posedge PCLK or negedge PRESET_n)
	begin

		if(!PRESET_n)
		begin
			count_s<=12'b0;
			SCLK_o<=pre_sclk_s;
		end
		
		else if((!ss_i) && (!spiswai_i) && ((spi_mode_i==mode_run) || (spi_mode_i==mode_wait)) )
			begin
					if(count_s ==  (((BaudRateDivisor_o)/2)-1'b1)   )
					begin
						SCLK_o<=~SCLK_o;
						count_s<=12'b0;
					end
					else
					begin
						count_s<=count_s+12'b1;
					end
			end
			
			
		else
		begin
				SCLK_o<=pre_sclk_s;
				count_s<=12'b0;				
		end
		
		/*else
		begin
			if((!ss_i) && (!spiswai_i) && ((spi_mode_i==mode_run) || (spi_mode_i==mode_wait)) )
			begin
				SCLK_o<=~SCLK_o;
				count_s<=12'b0;
			end
			else
			begin
				count_s<=count_s+12'b1;
			end	
		
		end*/
		
	end


	//Generate MISO Sample Flags
	always@(posedge PCLK or negedge PRESET_n)
	begin
		
		if(!PRESET_n)
		begin
			miso_receive_sclk_o<=1'b0;
			miso_receive_sclk0_o<=1'b0;
		end

		else if( ( (!(cpha_i)) && cpol_i) || (cpha_i && (!(cpol_i))) && (!ss_i))
		begin
			if(SCLK_o)
			begin
				if(count_s ==  (((BaudRateDivisor_o)/2)-1'b1)  )
					miso_receive_sclk0_o<=1'b1;
				else
					miso_receive_sclk0_o<=1'b0;
			end
			else
			begin
				miso_receive_sclk_o<=1'b0;
        	   miso_receive_sclk0_o<=1'b0;
			end
		end	

		else if( (((!cpha_i)&&(!cpol_i)) || (cpha_i && cpol_i))&& (!ss_i))
		begin
			if(!SCLK_o)
			begin		
				if(count_s ==  (((BaudRateDivisor_o)/2)-1'b1)  )
					miso_receive_sclk_o<=1'b1;
				else
					miso_receive_sclk_o<=1'b0;
			end	

			else
                        begin
                                miso_receive_sclk_o<=1'b0;
                                miso_receive_sclk0_o<=1'b0;
                        end 
		end	

		else
		begin
			miso_receive_sclk_o<=1'b0;
			miso_receive_sclk0_o<=1'b0;
		end

	end


	//Generate MOSI Sample flags
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
                begin
                        mosi_send_sclk_o<=1'b0;
                        mosi_send_sclk0_o<=1'b0;
                end

                else if(  ((!cpha_i && cpol_i) || (cpha_i && !cpol_i)) && (~ss_i) )
                begin
                        if(SCLK_o)
                        begin
                                if(count_s ==  (((BaudRateDivisor_o)/2)-2'b10)  )
                                       	mosi_send_sclk0_o<=1'b1;
                                else
                                        mosi_send_sclk0_o<=1'b0;
                        end
                        else
                        begin
                                mosi_send_sclk_o<=1'b0;
                                mosi_send_sclk0_o<=1'b0;
                        end
                end

					 else if( ( (!cpha_i && !cpol_i) || (cpha_i && cpol_i)) && (~ss_i) )
                begin
                        if(!SCLK_o)
                        begin
                                if(count_s ==  (((BaudRateDivisor_o)/2)-2'b10)  )
                                        mosi_send_sclk_o<=1'b1;
                                else
                                        mosi_send_sclk_o<=1'b0;
                        end

                        else
                        begin
                                mosi_send_sclk_o<=1'b0;
                                mosi_send_sclk0_o<=1'b0;
                        end
                end

                else
                begin
                        mosi_send_sclk_o<=1'b0;
                        mosi_send_sclk0_o<=1'b0;
                end

	end

endmodule

...

# code for spi_shifter.v

  ...
  module spi_shifter(PCLK,PRESET_n, ss_i, send_data_i, lsbfe_i, cpha_i, cpol_i, miso_receive_sclk_i, miso_receive_sclk0_i, mosi_send_sclk_i, mosi_send_sclk0_i, miso_i, receive_data_i, data_mosi_i, mosi_o, data_miso_o);

	input PCLK,PRESET_n, ss_i, send_data_i, lsbfe_i, cpha_i, cpol_i, miso_receive_sclk_i, miso_receive_sclk0_i, mosi_send_sclk_i, mosi_send_sclk0_i, miso_i, receive_data_i;
	
	input [7:0] data_mosi_i;

	output reg mosi_o;
	output reg [7:0] data_miso_o;

	reg [7:0]shift_register; //Holds the outgoing 8-bit data to shift on MOSI
	reg [7:0]temp_reg; //Collects incoming 8-bit data from MISO
	reg [2:0] count, count1; //3-Bit counters for MOSI shifting (LSB-first/MSB-first)
	reg [2:0]count2, count3; //3-Bit counters for MISO shifting (LSB-first/MSB-first)

	//assign temp_reg = data_mosi_i;

	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
			shift_register<=8'b0;
		else if(send_data_i)
			shift_register<=data_mosi_i;
		else 
			shift_register<=shift_register;
	end


	always@(*)
	begin
		if(receive_data_i)
			data_miso_o=temp_reg;
		else
			data_miso_o=8'h00;
	end
	
	//Transmit data Bit-by-bit (MOSI)
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
		begin
			mosi_o<=1'b0;
			count<=3'b000;
			count1<=3'b111;
		end
		else if(!ss_i)
		begin
			if( (!cpol_i && cpha_i) || (cpol_i && !cpha_i) ) //either of them are high
			begin
				if(lsbfe_i)
				begin
					if(count<=3'd7)
					begin
						if(mosi_send_sclk0_i)
						begin
							mosi_o<=shift_register[count];
							count<=count+3'b1;
						end
						/*else
						begin
							//mosi_o<=mosi_o;
							count<=count;
						end*/
					end

					else //else for count
					begin
						//mosi_o<=mosi_o;
						count<=3'd0;
					end
				end
				else  //lsbfe as 0
				begin
					if(count1>=3'd0)
					begin
						if(mosi_send_sclk0_i)
						begin
							mosi_o<=shift_register[count1];
							count1<=count1-3'b1;
						end

						/*else
						begin
							mosi_o<=mosi_o;
							count1<=count1;
						end*/
					end
					else
					begin
						//mosi_o<=mosi_o;
						count1<=3'd7;
					end
				end
			end

			else  //both of them are high
			begin
				if(lsbfe_i)
                                begin
                                        if(count<=3'd7)
                                        begin
                                                if(mosi_send_sclk_i)
                                                begin
                                                        mosi_o<=shift_register[count];
                                                        count<=count+3'b1;
                                                end
                                                /*else
                                                begin
                                                        mosi_o<=mosi_o;
                                                        count<=count;
                                                end*/
                                        end

                                        else //else for count
                                        begin
                                                //mosi_o<=mosi_o;
                                                count<=3'd0;
                                        end
                                end
                                else  //lsbfe as 0
                                begin
                                        if(count1>=3'd0)
                                        begin
                                                if(mosi_send_sclk_i)
                                                begin
                                                        mosi_o<=shift_register[count1];
                                                        count1<=count1-3'b1;
                                                end

                                                /*else
                                                begin
                                                        mosi_o<=mosi_o;
                                                        count1<=count1;
                                                end*/
                                        end
                                        else
                                        begin
                                                //mosi_o<=mosi_o;
                                                count1<=3'd7;
                                        end
                                end


			end

		end
		/*else
		begin
			mosi_o<=mosi_o;
                        count<=count;
                        count1<=count1;

		end*/

	end
	
	//Receive Data Bit-by-Bit (MISO)
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
		begin
			temp_reg<=1'b0;
			count2<=3'b000;
			count3<=3'b111;
		end
		else if(!ss_i)
		begin
			if( (!cpol_i && cpha_i) || (cpol_i && !cpha_i) ) //either of them are high
			begin
				if(lsbfe_i)
				begin
					if(count2<=3'd7)
					begin
						if(miso_receive_sclk0_i)
						begin
							temp_reg[count2]<=miso_i;
							count2<=count2+1'b1;

                        end
						else
						begin
							temp_reg<=temp_reg;
						end
					end

					else //else for count
					begin
						//mosi_o<=mosi_o;
						count2<=8'd0;
					end
				end
				else  //lsbfe as 0
				begin
					if(count3>=3'd0)
					begin
						if(miso_receive_sclk0_i)
						begin
							temp_reg[count3]<=miso_i;
							count3<=count3-1'b1;
						end

						else
						begin
							temp_reg<=temp_reg;
						end
					end
					else
					begin
						count3<=8'd7;
					end
				end
			end

			else  //both of them are high
			begin
				if(lsbfe_i)
                                begin
                                        if(count2<=3'd7)
                                        begin
                                                if(miso_receive_sclk_i)
                                                begin
                                                        temp_reg[count2]<=miso_i;
                                                        count2<=count2+3'b1;
                                                end
                                                else
                                                begin
                                                    temp_reg<=temp_reg;    
                                                end
                                        end

                                        else //else for count
                                        begin
                                                count2<=8'd0;
                                        end
                                end
                                else  //lsbfe as 0
                                begin
                                        if(count3>=3'd0)
                                        begin
                                                if(miso_receive_sclk_i)
                                                begin
                                                        temp_reg[count3]<=miso_i;
                                                        count3<=count3-3'b1;
                                                end

                                                else
                                                begin
                                                        temp_reg<=temp_reg;
                                                end
                                        end
                                        else
                                        begin
                                               count3<=8'd7;
                                        end
                                end


			end

		end
		/*else
		begin
			mosi_o<=mosi_o;
                        count2<=count2;
                        count3<=count3;

		end*/

	end

    ...

    # code for spi_slave_interface.v

      ...
      
`define SPI_APB_DATA_WIDTH 8;
`define SPI_REG_WIDTH 8;
`define SPI_APB_ADDR_WIDTH 3;


module spi_slave_interface(PCLK, PRESET_n, PWRITE_i, PSEL_i, PENABLE_i, PADDR_i, PWDATA_i, ss_i, miso_data_i,receive_data_i, tip_i, PRDATA_o, mstr_o, cpol_o, cpha_o, lsbfe_o, spiswai_o,sppr_o, spr_o,spi_interrupt_request_o, PREADY_o, PSLVERR_o, send_data_o, mosi_data_o, spi_mode_o);

	input PCLK, PRESET_n, PWRITE_i, PSEL_i, PENABLE_i;
	input [2:0] PADDR_i;
	input [7:0] PWDATA_i;
	input ss_i;
	input [7:0] miso_data_i;
	input receive_data_i, tip_i;

	output reg [7:0] PRDATA_o;
	output mstr_o, cpol_o, cpha_o, lsbfe_o, spiswai_o;
	output [2:0] sppr_o, spr_o;

	output reg  send_data_o;
	output reg [7:0]mosi_data_o;
	output reg [1:0] spi_mode_o;
	output spi_interrupt_request_o, PREADY_o, PSLVERR_o;

	
	//state for APB FSM are IDLE, SETUP, ENABLE
	reg [1:0]state, next_state;

	//states for SPI mode FSM are spi_run, spi_wait, spi_stop
	reg [1:0] next_mode;

	//Default registers of SPI Controller
	reg [7:0] SPI_CR_1, SPI_CR_2, SPI_BR, SPI_SR, SPI_DR;

	//Flags for interrupts and status
 	wire spif, sptef, modf,modfen,spe;

	//Write and read enable signals
	wire wr_enb, rd_enb;

	/*APB state FSM*/
	parameter IDLE=2'b00, SETUP=2'b01, ENABLE =2'b10;
	
	parameter BR_mask  = 8'b01110111;
	parameter CR2_mask  = 8'b00011011;

	// Present sequential block for APB State FSM
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
			state<=IDLE;
		else
			state<=next_state;
	end

	//Next state combinational block for APB State FSM
	always@(state, PSEL_i, PENABLE_i)
	begin
	
		case(state)
			IDLE: begin
				if(PSEL_i && (!PENABLE_i))
					next_state=SETUP;
				else
					next_state=IDLE;
			end

			SETUP:	begin
				if(PSEL_i && (!PENABLE_i))
					next_state=SETUP;
				else if(PSEL_i && PENABLE_i)
					next_state=ENABLE;
				else
					next_state=IDLE;
			end

			ENABLE:	begin
				if(PSEL_i)
					next_state=SETUP;
				else
					next_state=IDLE;
			end

			default: next_state=IDLE;
		endcase

	end

	//Output Assign Logic for APB state FSM
	assign PREADY_o = (state==ENABLE) ? 1'b1 : 1'b0;
	//assign PSLVERR_o = (state==ENABLE && (ss_i)) ? (tip_i) : 1'b0;
	assign PSLVERR_o = (state==ENABLE) ? (~tip_i) : 1'b0;
	assign wr_enb = ((state==ENABLE) && (PWRITE_i)) ? 1'b1 : 1'b0;
	assign rd_enb = ((state==ENABLE) && (!PWRITE_i)) ? 1'b1 : 1'b0;


	/* SPI Mode FSM */
	parameter spi_run=2'b00, spi_wait=2'b01, spi_stop=2'b10;

	//present sequential block for SPI mode FSM
	always@(posedge PCLK or negedge PRESET_n)
        begin
                if(!PRESET_n)
                        spi_mode_o<=spi_run;
                else
                        spi_mode_o<=next_mode;
        end

	//Next state combination block fo SPI Mode FSM
	always@(spi_mode_o, spe, spiswai_o)
	begin
		case(spi_mode_o)
			spi_run:begin
				if(!spe)	next_mode=spi_wait;
				else		next_mode=spi_run;
			end

			spi_wait:begin
				if(spiswai_o)	next_mode=spi_stop;
				else if (!spe)	next_mode=spi_wait;
				else		next_mode=spi_run;				
			end

			spi_stop:begin
				if(!spiswai_o)	next_mode=spi_wait;
				else if(spe)	next_mode=spi_run;
				else		next_mode=spi_stop;	
			end

			default: next_mode=spi_run;

		endcase

	end


	//register PWDATA_i to SPI_CR_1 register
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
			SPI_CR_1 <=8'h04;	
		else
		begin
				if( wr_enb && (PADDR_i == 3'b000) )
					SPI_CR_1 <=PWDATA_i;
				else
					SPI_CR_1 <=SPI_CR_1;

		end		
	end
	
	assign mstr_o = SPI_CR_1[4];
	assign cpol_o = SPI_CR_1[3];
	assign cpha_o = SPI_CR_1[2];
	assign lsbfe_o = SPI_CR_1[0];

	wire spie, sptie, ssoe;
	assign spie = SPI_CR_1[7];
	assign spe = SPI_CR_1[6];
	assign sptie = SPI_CR_1[5];
	assign ssoe= SPI_CR_1[1];


	//register PWDATA_i to SPI_CR_2 register
//	reg [7:0] CR2_mask;
	//reg [7:0] BR_mask;
	
	/*always@(*)
	begin
		BR_mask  = 8'b01110111;
		CR2_mask  = 8'b00011011;
	end*/


	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
			SPI_CR_2 <=8'h00;
		else
		begin
				if( wr_enb && (PADDR_i == 3'b001) )
					SPI_CR_2 <=PWDATA_i & CR2_mask;
				else
					SPI_CR_2 <=SPI_CR_2;
		end
	end
	
	/*
	else if((PADDR_i == 3'b001) && wr_enb)
         SPI_CR_2 <=PWDATA_i & CR2_mask;
   else
          SPI_CR_2<=SPI_CR_2;*/

	assign spiswai_o = SPI_CR_2[1];

	//reg bidire, spce;
	assign modfen = SPI_CR_2[4];

	/*always@(*)
	begin
		bidire = SPI_CR_2[3];
		spce = SPI_CR_2 [0];
	end*/


	//register PWDATA_i to SPI_BR register
       
	always@(posedge PCLK or negedge PRESET_n)
   begin
		if(!PRESET_n)
			SPI_BR <=8'h00;
		else
		begin
				if( wr_enb && (PADDR_i == 3'b010) )
					SPI_BR <=PWDATA_i & BR_mask;
				else
					SPI_BR <=SPI_BR;
		end
	end
		  
		  /*
		  else if((PADDR_i == 3'b010) && wr_enb)
             SPI_BR <=PWDATA_i & BR_mask;
        else
             SPI_BR<=SPI_BR;
		  */

	assign sppr_o=SPI_BR[6:4];
	assign spr_o=SPI_BR[2:0];

	//register PWDATA to Data register SPI_DR
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
			SPI_DR<=8'b00;
		
		else if(wr_enb)
		begin
			if(PADDR_i==3'b101)
				SPI_DR<=PWDATA_i;
			else
				SPI_DR<=SPI_DR;
		end
		
		else 
		begin
			if( (SPI_DR==PWDATA_i) & (SPI_DR !=miso_data_i) & ((spi_mode_o == spi_run)||(spi_mode_o==spi_wait))  )
				SPI_DR<=8'b0;
			else
			begin
				if( ((spi_mode_o == spi_run)||(spi_mode_o==spi_wait)) & (receive_data_i)) 
					SPI_DR<=miso_data_i;
				else
					SPI_DR<=SPI_DR;
			end

		end

	end

	//send data
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n) 
			send_data_o<=1'b0;
		else 
		begin
				if(wr_enb)
					send_data_o<=1'b0;
				else
					begin
						if( (SPI_DR==PWDATA_i) &&(SPI_DR!=miso_data_i) &&((spi_mode_o==spi_run) || (spi_mode_o == spi_wait))  )
							send_data_o<=1'b1;
						else
							send_data_o<=1'b0;
					end
		end
		
	end

	//Implement APB Read Data Path
	//To read data from spi_core to APB Master
	
	always@(*)
	begin
		if(!rd_enb)
			PRDATA_o=8'b0;
		else
		begin
			case(PADDR_i)
				3'b000: PRDATA_o=SPI_CR_1;
				3'b001: PRDATA_o=SPI_CR_2;
				3'b010: PRDATA_o=SPI_BR;
				3'b011: PRDATA_o=SPI_SR;
				3'b101: PRDATA_o=SPI_DR;
				default: PRDATA_o = 8'b0;
			endcase
		end
	end

	
	assign modf=( (!ss_i) && (mstr_o) && (modfen) && (!ssoe))?1'b1:1'b0;

	/*
	always@(*)
	begin
		if(!spie && !sptie)	
		begin
			spi_interrupt_request_o=1'b0;
			bidire=1'b0;
			spce=1'b0;
		end

		else
		begin
			if(spie && !sptie)
				spi_interrupt_request_o=spif||modf;
			else
			begin
				if(!spie && sptie)
					spi_interrupt_request_o=sptef;
				elsei
					spi_interrupt_request_o=sptef||modf||spif;
			end
		end
	end
	*/
   assign spi_interrupt_request_o = (spie) ? ((sptie)? (sptef||modf||spif) : (spif||modf) ) : ((sptie)?sptef:1'b0 );

	assign spif = (SPI_DR!=8'b00000000) ? 1'b1 : 1'b0;
   assign sptef = (SPI_DR==8'b00000000) ? 1'b1 : 1'b0;

       //assign respective values to SPI_SR
   always@(*)
	begin
		if(!PRESET_n)
			SPI_SR={spif,1'b0,sptef,modf,4'b0};
		else
			SPI_SR=8'b00100000;
	end

	//mosi_data
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
			mosi_data_o<=8'b0;
		else
		begin
			if( (SPI_DR == PWDATA_i) && (SPI_DR!=miso_data_i)  && ((spi_mode_o ==spi_run) || (spi_mode_o==spi_wait) ) )
				mosi_data_o<=SPI_DR;
			else
				mosi_data_o<=mosi_data_o;

		end

	end
	
	


endmodule

...

    # code for spi_slave_select.v

      ...
      module spi_slave_select(PCLK, PRESET_n, mstr_i, spiswai_i, spi_mode_i, send_data_i, BaudRateDivisor_i, receive_data_o, ss_o, tip_o);
					
	
	input PCLK, PRESET_n,mstr_i,spiswai_i;
	input [1:0]spi_mode_i;
	input send_data_i;
	input [11:0]BaudRateDivisor_i;

	output reg receive_data_o,ss_o;
	output tip_o;
	
	parameter mode_run=2'b00, mode_wait=2'b01, mode_stop=2'b10;

	/*wire SCLK;
	assign SCLK= (PCLK / BaudRateDivisor_i);*/
	reg [15:0]count_s;
	wire [15:0] target_s;
	reg rcv_s;

	assign target_s = BaudRateDivisor_i * 12'd8;
	assign tip_o = (~(ss_o));
	
	//control the slave selec signal and receive indicator
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
		begin
			count_s<=16'hFFFF;
			ss_o<=1'b1;
			rcv_s<=1'b0;
		end

		else if( (mstr_i) &&  ((spi_mode_i==mode_run) || (spi_mode_i==mode_wait)) && (!spiswai_i) )
		begin
			if(send_data_i == 1'b1)
			begin
				ss_o<=1'b0;
				count_s<=16'h0000;
			end

			
			else if(count_s < (target_s-1) )
			begin	
				count_s<=count_s+16'h1;
				ss_o<=1'b0;
			end
			
			else if(count_s == (target_s-1) )
			begin
				rcv_s <=1'b1;
				//ss_o<=1'b1;
				count_s <= 16'hFFFF;
			end
				

			else
			begin
				ss_o<=1'b1;
				rcv_s<=1'b0;
				count_s<=16'hFFFF;
			end
		end	
		
		else
		begin
			count_s<=16'hFFFF;
			ss_o<=1'b1;
			rcv_s<=1'b0;
		end
	end
	//generate the slave receive data signal
	always@(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
			receive_data_o<=1'b0;
		else
			receive_data_o<=rcv_s;
	end


endmodule

...

    # code for spi_top_module.v

      ...
      /*
`include "spi_baud_generator.v"
`include "spi_slave_select.v"
`include "spi_slave_interface.v"
`include "spi_shifter.v"
*/

module spi_top_module(PCLK, PRESET_n, PADDR_i, PWRITE_i, PSEL_i, PENABLE_i, PWDATA_i, miso_i, ss_o, SCLK_o, spi_interrupt_request_o, mosi_o, PRDATA_o, PREADY_o, PSLVERR_o);

	input PCLK, PRESET_n, PWRITE_i, PSEL_i, PENABLE_i, miso_i;
	input [2:0] PADDR_i;
	input [7:0] PWDATA_i;


	output ss_o, SCLK_o, spi_interrupt_request_o, mosi_o, PREADY_o, PSLVERR_o;
	output [7:0] PRDATA_o;

	wire [1:0] spi_mode;
	wire [2:0] spr, sppr;
	wire [11:0] BaudRateDivisor_o;
	wire [7:0] mosi_data, miso_data;

	spi_slave_interface DUT1si(PCLK, PRESET_n, PWRITE_i, PSEL_i, PENABLE_i, PADDR_i, PWDATA_i, ss_o, miso_data, receive_data, tip, PRDATA_o, mstr, cpol, cpha, lsbfe, spiswai, sppr, spr, spi_interrupt_request_o, PREADY_o, PSLVERR_o, send_data, mosi_data, spi_mode);
	//spi_slave_interface(PCLK, PRESET_n, PWRITE_i, PSEL_i, PENABLE_i, PADDR_i, PWDATA_i, ss_i, miso_data_i,receive_data_i, tip_i, PRDATA_o, mstr_o, cpol_o, cpha_o, lsbfe_o, spiswai_o,sppr_o, spr_o,spi_interrupt_request_o, PREADY_o, PSLVERR_o, send_data_o, mosi_data_o, spi_mode_o);
	
	spi_baud_generator DUT2bg(PCLK, PRESET_n, spi_mode, spiswai, spr, sppr, cpol, cpha, ss_o, SCLK_o,  miso_receive_sclk, miso_receive_sclk0, mosi_send_sclk, mosi_send_sclk0, BaudRateDivisor_o);
	//spi_baud_generator(PCLK, PRESET_n,spi_mode_i, spiswai_i, spr_i, sppr_i, cpol_i, cpha_i, ss_i, SCLK_o, miso_receive_sclk_o, miso_receive_sclk0_o, mosi_send_sclk_o, mosi_send_sclk0_o, BaudRateDivisor_o,count_s);

	spi_shifter DUT3s(PCLK,PRESET_n, ss_o, send_data, lsbfe, cpha, cpol, miso_receive_sclk, miso_receive_sclk0, mosi_send_sclk, mosi_send_sclk0, miso_i, receive_data, mosi_data, mosi_o, miso_data);
	
	spi_slave_select DUT4ss(PCLK, PRESET_n, mstr, spiswai, spi_mode, send_data, BaudRateDivisor_o, receive_data, ss_o, tip);
		
	
		
endmodule

...


	

endmodule



