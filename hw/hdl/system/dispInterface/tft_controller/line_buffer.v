//************************************************************************
// Michael Steffen
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//************************************************************************


// line_buffer.v
//************************************************************************
// DESCRIPTION: Modified version of Xiilnx's line_buffer module, improved
// to support 1280x1024 resolution. 
//
// NOTES:
// 07/24/10 by MAS::Design created.
//************************************************************************

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
module line_buffer(


  // BRAM_TFT READ PORT A clock and reset
  TFT_Clk,           // TFT Clock 
  TFT_Rst,           // TFT Reset

  // PLB_BRAM WRITE PORT B clock and reset
  sys_clk,           // PLB Clock
  sys_rst,           // PLB Reset
  
  Rd_start_line,		// Start of new line

  // BRAM_TFT READ Control
  BRAM_TFT_rd,       // TFT BRAM read   
  BRAM_TFT_oe,       // TFT BRAM output enable  

  // PLB_BRAM Write Control
  PLB_BRAM_data,     // PLB BRAM Data
  PLB_BRAM_we,       // PLB BRAM write enable

  // RGB Outputs
  RED,               // TFT Red pixel data  
  GREEN,             // TFT Green pixel data  
  BLUE               // TFT Blue pixel data  
);
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

  input        TFT_Clk;
  input        TFT_Rst;
  input        sys_clk;
  input        sys_rst;
  input        Rd_start_line;
  input        BRAM_TFT_rd;
  input        BRAM_TFT_oe;
  input [127:0] PLB_BRAM_data;
  input        PLB_BRAM_we;
  output [7:0] RED,GREEN,BLUE;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
  
  wire [7:0]  BRAM_TFT_R_data;
  wire [7:0]  BRAM_TFT_G_data;
  wire [7:0]  BRAM_TFT_B_data;  
  reg  [0:10]  BRAM_TFT_addr;
  reg  [0:8]  BRAM_PLB_addr;
  reg         tc;
  reg  [7:0]  RED,GREEN,BLUE;

///////////////////////////////////////////////////////////////////////////////
// READ Logic BRAM Address Generator TFT Side
///////////////////////////////////////////////////////////////////////////////

  // BRAM_TFT_addr Counter (0-1279d)
  always @(posedge TFT_Rst or posedge TFT_Clk)
  begin : TFT_ADDR_CNTR
    if (TFT_Rst) 
      begin
        BRAM_TFT_addr = 11'b0;
        tc = 1'b0;
      end
	 else if (~BRAM_TFT_rd) 
      begin
        BRAM_TFT_addr = 11'b0;
        tc = 1'b0;
      end
    else 
      begin
        if (tc == 0) 
          begin
            if (BRAM_TFT_addr == 11'd1279) 
              begin
                BRAM_TFT_addr = 11'b0;
                tc = 1'b1;
              end
            else 
              begin
                BRAM_TFT_addr = BRAM_TFT_addr + 1;
                tc = 1'b0;
              end
          end
      end
  end

///////////////////////////////////////////////////////////////////////////////
// WRITE Logic for the BRAM PLB Side
///////////////////////////////////////////////////////////////////////////////

  // BRAM_PLB_addr Counter (0-319d)
  always @(posedge sys_rst or posedge sys_clk)
  begin : PLB_ADDR_CNTR
    if (sys_rst) 
      begin
        BRAM_PLB_addr = 9'b0;
      end
    else 
      begin
        if (PLB_BRAM_we) 
          begin
            if (BRAM_PLB_addr == 9'd319) 
              begin
                BRAM_PLB_addr = 9'b0;
              end
            else 
              begin
                BRAM_PLB_addr = BRAM_PLB_addr + 1;
              end
          end
      end
  end

///////////////////////////////////////////////////////////////////////////////
// BRAM
///////////////////////////////////////////////////////////////////////////////

/*RAMB16_S18_S36 LINE_BUFFER (
  // TFT Side Port A
  .ADDRA (BRAM_TFT_addr),                                           // I [9:0]
  .CLKA  (TFT_Clk),                                                 // I
  .DIA   (16'b0),                                                   // I [15:0]
  .DIPA  (2'b0),                                                    // I [1:0]
  .DOA   ({BRAM_TFT_R_data, BRAM_TFT_G_data, BRAM_TFT_B_data[5:2]}),// O [15:0]
  .DOPA  (BRAM_TFT_B_data[1:0]),                                    // O [1:0]
  .ENA   (BRAM_TFT_rd),                                             // I
  .SSRA  (TFT_Rst | ~BRAM_TFT_rd | tc),                             // I 
  .WEA   (1'b0),                                                    // I
  // PLB Side Port B
  .ADDRB (BRAM_PLB_addr),                                           // I [8:0]
  .CLKB  (sys_clk),                                                 // I
  .DIB   ({PLB_BRAM_data[40:45], PLB_BRAM_data[48:53], PLB_BRAM_data[56:59],
           PLB_BRAM_data[8:13],  PLB_BRAM_data[16:21], PLB_BRAM_data[24:27]}),
                                                                    // I [31:0]
  .DIPB  ({PLB_BRAM_data[60:61], PLB_BRAM_data[28:29]}),            // I [3:0]
  .DOB   (),                                                        // O [31:0]
  .DOPB  (),                                                        // O [3:0]
  .ENB   (PLB_BRAM_we),                                             // I
  .SSRB  (1'b0),                                                    // I
  .WEB   (PLB_BRAM_we)                                              // I
  );
  */
  
  
  fblinec u_fblinec (
		// Memory Side
	   .clka(sys_clk),
		.wea(PLB_BRAM_we),
		.addra(BRAM_PLB_addr),
		.dina({PLB_BRAM_data[119:96], PLB_BRAM_data[87:64], PLB_BRAM_data[55:32], PLB_BRAM_data[23:0]}),
		.clkb(TFT_Clk),
		.addrb(/*11b'00000000000*/BRAM_TFT_addr),
		.doutb({BRAM_TFT_R_data, BRAM_TFT_G_data, BRAM_TFT_B_data})
  );
  

///////////////////////////////////////////////////////////////////////////////
// Register RGB BRAM output data
///////////////////////////////////////////////////////////////////////////////
  always @(posedge TFT_Rst or posedge TFT_Clk)
  begin : BRAM_OUT_DATA 
    if (TFT_Rst )
      begin
        RED   = 8'b0;
        GREEN = 8'b0;
        BLUE  = 8'b0; 
      end
	 else if (~BRAM_TFT_oe)
      begin
        RED   = 8'b0;
        GREEN = 8'b0;
        BLUE  = 8'b0; 
      end
    else
      begin
        RED   = BRAM_TFT_R_data;
        GREEN = BRAM_TFT_G_data;
        BLUE  = BRAM_TFT_B_data;
      end
   end   

endmodule

