//-----------------------------------------------------------------------
// Justin Rilling
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//-----------------------------------------------------------------------


// cpu_uart.v
//-----------------------------------------------------------------------
// DESCRIPTION: This file implements a CPU UART interface that reads 
// from a file. Use either this module or traceInterface (which writes
// directly into the host FIFOs. 
//
// NOTES:
// 07/24/10 by JRR::Design created.
//-----------------------------------------------------------------------

`timescale 1 us / 10 ns

module cpu_uart(clk, rst, rxd, txd);

    input         clk;
    input         rst;
	 input 			rxd;
	 output 	      txd;

    //reg [7:0] send_buffer [1048576:0];
	 reg [7:0] send_data;
	 integer send_buffer;
	 reg [7:0] rec_buffer [1024:0];
	 reg [2:0] send_state, next_send_state, rec_state, next_rec_state;    
	 //reg [19:0] send_counter;
	 reg [9:0] rec_counter;
	 reg inc_send_counter_flag;
	 reg inc_rec_counter_flag; 
	 reg latch_rec_data_flag;		
	 reg wr_n, rd_n, xmit_en;

	 wire rst_send_counter_flag;	
	 wire rst_rec_counter_flag;
	 wire txd, rxd;
	 wire tx_busy_n, rx_full, rec_buffer_read_en, rec_buff_empty;
	 wire [7:0] rec_data;
	 wire [31:0] rec_buffer_dout;

    parameter [19:0] NUM_BYTES_TO_SEND = 19'd59904;
	 parameter READ_MEM = 3'd0, SEND_DATA = 3'd1, SEND_IDLE = 3'd2;
	 parameter REC_DATA = 3'd3, WRITE_MEM = 3'd4, WAIT_FOR_XON_CMD = 3'd5;	
	 parameter XOFF = 8'h13;
	 parameter XON = 8'h11;	 	

	 mmu_uart_top UART (.Clk(clk),
		 					  .Reset_n(!rst),
	    					  .TXD(txd),
       					  .RXD(rxd),
							  .ck_div(16'd289),
							  .CE_N(1'b0),
							  .WR_N(wr_n),
	 						  .RD_N(rd_n),
                       .A0(1'b0),
							  .D_IN(send_data),
                       .D_OUT(rec_data),
                       .RX_full(rx_full),
                       .TX_busy_n(tx_busy_n));		

	assign rst_send_counter_flag = 1'b0;
	assign rst_rec_counter_flag = 1'b0;

	// state machine to send data in "send_data.txt" over uart
	always @ (posedge clk, rst)
	   begin
			if(rst) 
				begin
					send_state = READ_MEM;
				end
			else 
				begin 
					send_state = next_send_state;
				end
		end

	always @ (*)
		begin 

		// defaults 
		next_send_state = send_state;
		inc_send_counter_flag = 1'b0;
		wr_n = 1'b1;

		case (send_state) 

			READ_MEM: begin 
				//$readmemb("../sim/send_data.txt", send_buffer);
				send_buffer = $fopen("../sim/trace.sgb", "rb");
				send_data = 8'b0;
				#200;
				next_send_state = SEND_DATA;

			end
			
			SEND_DATA: begin 
				if((tx_busy_n == 1'b1) && (xmit_en == 1'b1))
					begin 
					   if(!$feof(send_buffer))
						   begin
								wr_n = 1'b0;
								inc_send_counter_flag = 1'b1;	
								if ($fscanf(send_buffer, "%c", send_data) == -1)
                           $display("ERROR:cpu_uart/fscanf failed");								
								//if(send_counter >= NUM_BYTES_TO_SEND-1) 
							end
						else
							begin
								next_send_state = SEND_IDLE;
							end
					end	
			end
		
			SEND_IDLE: begin 
			end
		
			default: next_send_state = READ_MEM;

		endcase
	end

	// state machine to recieve data over uart and write it to "receive_data.txt"
	always @ (posedge clk, rst)
   	begin
			if(rst) 
				begin
					rec_state = REC_DATA;
				end
			else 
				begin 
					rec_state = next_rec_state;
				end
		end

	always @ (*)
		begin 

		// defaults 
		next_rec_state = rec_state;
		latch_rec_data_flag = 1'b0;
		inc_rec_counter_flag = 1'b0;
		rd_n = 1'b1;
		xmit_en = 1'b1;

		case(rec_state) 
		
			REC_DATA: begin

				if(rx_full == 1'b1)
					begin 
						rd_n = 1'b0;

						if(rec_data == XOFF)
							begin
								xmit_en = 1'b0;
								next_rec_state = WAIT_FOR_XON_CMD;
							end
						else
							begin
								latch_rec_data_flag = 1'b1;
								next_rec_state = WRITE_MEM;
							end
					end	
			end

			WRITE_MEM: begin
				$writememb("receive_data.txt", rec_buffer);
				inc_rec_counter_flag = 1'b1;		
				next_rec_state = REC_DATA;
			end	

			WAIT_FOR_XON_CMD : begin 

				xmit_en = 1'b0;

				if(rx_full == 1'b1)
					begin 
						rd_n = 1'b0;

						if(rec_data == XON)
							begin
								next_rec_state = REC_DATA;
							end
					end
			end	

			default: next_rec_state = REC_DATA;
	
		endcase
	end 

  	always @ (posedge clk, rst)
		begin
			if(rst)
				begin 
					//send_counter = 20'd0;
					rec_counter = 10'd0;
				end
			else
				begin 
					if(rst_send_counter_flag == 1'b1)
						begin
							//send_counter = 20'd0;
						end
					else if(inc_send_counter_flag == 1'b1)
						begin
							//send_counter = send_counter + 20'd1; 
						end

					if(rst_rec_counter_flag == 1'b1)
						begin
							rec_counter = 10'd0;
						end
					else if(inc_rec_counter_flag == 1'b1)
						begin
							rec_counter = rec_counter + 10'd1;
						end
				end
		end	

	always @ (posedge clk)
		begin
			if(latch_rec_data_flag == 1'b1)
				begin
					rec_buffer[rec_counter] = rec_data;
				end
		end

endmodule
