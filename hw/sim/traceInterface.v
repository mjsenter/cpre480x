//-----------------------------------------------------------------------
// Justin Rilling
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//-----------------------------------------------------------------------


// traceInterface.v
//-----------------------------------------------------------------------
// DESCRIPTION: This file implements an interface optimized for fast 
// simulation, returning results in 4-byte blocks informally referred to 
// as the "instruction".
//
// NOTES:
// 07/24/10 by JRR::Design created.
//-----------------------------------------------------------------------

`timescale 1 us / 10 ns

module traceInterface(clk100, rst,  hostPacketFIFORead_packet, hostPacketFIFOReadEn, hostPacketFIFORead_empty, hostPacketFIFORead_valid);

	input 		  clk100;
	input 		  rst;

	input 		  hostPacketFIFOReadEn;
	output 		  hostPacketFIFORead_empty;
	output [31:0] hostPacketFIFORead_packet;
   output        hostPacketFIFORead_valid;
	
   
	wire [31:0]   wrongOrder;
	reg [7:0] 	  rec_data;
	wire [9:0]    rec_buffer_counter;
	wire 			  full;
	reg			  wr_en;
	
	integer file;
	reg [1:0]	  state;
	
	parameter LOAD_FILE = 2'd0, READ_FILE = 2'd1, CLOSE_FILE = 2'd2, DONE = 2'd3;
	

	hostpacketfifo u_hostpacketFIFO (.rst(rst),
	                 .wr_clk(clk100),
	                 .rd_clk(clk100),
	                 .din(rec_data),
	                 .wr_en(wr_en),
	                 .rd_en(hostPacketFIFOReadEn),
	                 .dout(wrongOrder),
	                 .full(full),
	                 .empty(hostPacketFIFORead_empty),
						  .valid(hostPacketFIFORead_valid),
	                 .rd_data_count(rec_buffer_counter));

   // Fix the byte ordering problem
	assign hostPacketFIFORead_packet[7:0]   = wrongOrder[31:24];
   assign hostPacketFIFORead_packet[15:8]  = wrongOrder[23:16];
   assign hostPacketFIFORead_packet[23:16] = wrongOrder[15:8];
   assign hostPacketFIFORead_packet[31:24] = wrongOrder[7:0];

	
  always @ (posedge clk100 or rst)
	   begin
			if(rst == 1'b1) begin
			   state = LOAD_FILE;
				wr_en = 1'b0;
			end
			else begin 
				wr_en = 1'b0;
				case (state) 
					LOAD_FILE: begin
						state = READ_FILE;
						file = $fopen("../sim/trace.sgb", "rb");
					end
				
					READ_FILE: begin
						if(!$feof(file))
						   begin
								if(!full)
									begin
										wr_en = 1'b1;
										if ($fscanf(file, "%c", rec_data) < 0)
                                begin
 											 state = CLOSE_FILE;
										    if ($feof(file))
											   begin
													$display("Warning:traceInterface/fscanf EOF reached");
												end
											 else
											   begin
		                                 $display("ERROR:traceInterface/fscanf failed");
												end
                                end										  
									end
							end
						else
							begin
								$display("Warning:traceInterface/fscanf EOF reached");
								state = CLOSE_FILE;
							end
					end
					
					CLOSE_FILE: begin
						state = DONE;
						$fclose(file);
					end
					
					DONE: begin
					
					end
					default: state = DONE;
				endcase
			end
		end

	
endmodule
