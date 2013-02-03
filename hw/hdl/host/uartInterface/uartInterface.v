//-----------------------------------------------------------------------
// Justin Rilling
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//-----------------------------------------------------------------------


// uartInterface.v
//-----------------------------------------------------------------------
// DESCRIPTION: This file implements the UART interface, returning
// results in 4-byte blocks informally referred to as the "instruction".
//
// NOTES:
// 07/24/10 by JRR::Design created.
//-----------------------------------------------------------------------


module uartInterface(clk100, rst, RxD, TxD, hostPacketFIFORead_packet, hostPacketFIFOReadEn, hostPacketFIFORead_empty, hostPacketFIFORead_valid);

	input 		  clk100;
	input 		  rst;
   input         RxD;
   output        TxD;

	input 		  hostPacketFIFOReadEn;
	output 		  hostPacketFIFORead_empty;
	output [31:0] hostPacketFIFORead_packet;
   output        hostPacketFIFORead_valid;
	
   reg           flow_ctrl_wr_n, debug_wr_n, debug_RB_read_en;
   reg           rst_byte_counter_flag, inc_byte_counter_flag;
   reg  [2:0]    flow_ctrl_state, flow_ctrl_next_state, debug_state, debug_next_state;
	reg  [1:0]    xmit_data_sel, byte_counter;
	wire [7:0] 	  rec_data, xmit_data, rec_buffer_data;
	wire [9:0]    rec_buffer_counter;
	wire 			  rx_full, tx_busy_n, rd_en, wr_n;
	
	parameter     WAIT_TO_SEND_XOFF_CMD = 3'd0, WAIT_TO_SEND_XON_CMD = 3'd1;
	parameter     DEBUG_IDLE = 3'd2, READ_REC_BUFFER = 3'd3, SEND_REC_BUFFER_DATA = 3'd4; 
	parameter     REC_BUFFER_SIZE = 512;
	parameter     REC_BUFFER_DATA_LIMIT = REC_BUFFER_SIZE - 16;
	parameter     XOFF = 8'h13;
	parameter 	  XON = 8'h11;
	//parameter     XOFF = 8'h58; // the letter 'X'
	//parameter 	  XON = 8'h5A; // the letter 'Z'
   parameter     DEBUG_FLAG = 1'b0;

	mmu_uart_top UART (.Clk(clk100),.Reset_n(!rst),
	    					 .TXD(TxD),
       					 .RXD(RxD),
							 .ck_div(16'd289),
							 .CE_N(1'b0),
							 .WR_N(wr_n),//.WR_N(!rx_full),//.WR_N(wr_n),
	 						 .RD_N(!rx_full),
                      .A0(1'b0),
							 .D_IN(rec_data),//.D_IN(xmit_data),
                      .D_OUT(rec_data),
                      .RX_full(rx_full),
                      .TX_busy_n(tx_busy_n));	

	hostpacketfifo u_hostPacketFIFO (.rst(rst),
	                 .wr_clk(clk100),
	                 .rd_clk(clk100),
	                 .din(rec_data),
	                 .wr_en(rx_full),
	                 .rd_en(rd_en),
	                 .dout(hostPacketFIFORead_packet),
	                 .full(),
	                 .empty(hostPacketFIFORead_empty),
						  .valid(hostPacketFIFORead_valid),
	                 .rd_data_count(rec_buffer_counter));

	assign xmit_data = xmit_data_sel[1] ? XON : (xmit_data_sel[0] ? XOFF : rec_buffer_data);
   assign rec_buffer_data = byte_counter[1] ? (byte_counter[0] ? hostPacketFIFORead_packet[7:0] : hostPacketFIFORead_packet[15:8]) : (byte_counter[0] ? hostPacketFIFORead_packet[23:16] : hostPacketFIFORead_packet[31:24]);
	assign wr_n = flow_ctrl_wr_n & debug_wr_n;
	assign rd_en = hostPacketFIFOReadEn | debug_RB_read_en;

  always @ (posedge clk100 or posedge rst)
	   begin
			if(rst == 1'b1) begin
			   flow_ctrl_state = WAIT_TO_SEND_XOFF_CMD;
			   debug_state = DEBUG_IDLE;
			end
			else begin 
		      flow_ctrl_state = flow_ctrl_next_state;
			   debug_state = debug_next_state;
			end
		end

	always @ (*)
		begin 

		// defaults 
		flow_ctrl_next_state = flow_ctrl_state; 		
      flow_ctrl_wr_n = 1'b1;
		xmit_data_sel = 2'd0;

		case (flow_ctrl_state) 
			
			WAIT_TO_SEND_XOFF_CMD: begin
			  
			   if((rec_buffer_counter >= REC_BUFFER_DATA_LIMIT) && (tx_busy_n == 1'b1)) begin  
			      flow_ctrl_wr_n = 1'b0;
				   xmit_data_sel = 2'd1;
				   flow_ctrl_next_state = WAIT_TO_SEND_XON_CMD;
			   end
			end	
			
			WAIT_TO_SEND_XON_CMD: begin 

				 if((rec_buffer_counter < REC_BUFFER_SIZE/2) && (tx_busy_n == 1'b1)) begin 
				    flow_ctrl_wr_n = 1'b0;
					 xmit_data_sel = 2'd2;
					 flow_ctrl_next_state = WAIT_TO_SEND_XOFF_CMD;
				 end
			end

			default: flow_ctrl_next_state = WAIT_TO_SEND_XOFF_CMD;

		endcase
	end

	always @ (*)
		begin 

		// defaults 
		debug_next_state = debug_state;
		inc_byte_counter_flag = 1'b0; 
		rst_byte_counter_flag = 1'b0; 		
		debug_RB_read_en = 1'b0;
		debug_wr_n = 1'b1;

		case (debug_state) 
			
			DEBUG_IDLE: begin 
				if((DEBUG_FLAG == 1'b1) && (hostPacketFIFORead_empty == 1'b0)) begin//(send_back_RB_data == 1'b1) && (rec_buff_empty == 1'b0)) begin
				   debug_next_state = READ_REC_BUFFER;
				end
			end

			READ_REC_BUFFER: begin 
				debug_RB_read_en = 1'b1;
				rst_byte_counter_flag = 1'b1;
				debug_next_state = SEND_REC_BUFFER_DATA;
			end

			SEND_REC_BUFFER_DATA: begin
				if(tx_busy_n == 1'b1) begin
			      
               debug_wr_n = 1'b0;
					inc_byte_counter_flag = 1'b1;
						
               if(byte_counter >= 2'd3) begin
					   if(hostPacketFIFORead_empty == 1'b0) begin
						   debug_next_state = READ_REC_BUFFER;
						end
						else begin
						   debug_next_state = DEBUG_IDLE;
						end
					end
				end
			end

			default: debug_next_state = DEBUG_IDLE;

		endcase
	end

	always @ (posedge clk100 or posedge rst) begin
	   if(rst == 1'b1) begin
		   byte_counter = 2'd0;
		end
		else begin 
		   if(rst_byte_counter_flag == 1'b1) begin
		      byte_counter = 2'd0;
		   end
		   else if(inc_byte_counter_flag == 1'b1) begin
		      byte_counter = byte_counter + 2'd1;
			end
			else begin
			   byte_counter = byte_counter;
			end
		end
	end	

endmodule
