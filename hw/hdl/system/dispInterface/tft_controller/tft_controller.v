//************************************************************************
// Michael Steffen
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//************************************************************************


// tft_controller.v
//************************************************************************
// DESCRIPTION: Modified version of Xiilnx's tft_controller module, using
// a custom bus interface for the line buffer.
//
// NOTES:
// 07/24/10 by MAS::Design created.
//************************************************************************

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
module tft_controller(

  // Interfaces
  sys_clk,							// Basic Clock Signal
  sys_rst,							// System wide reset
  
  clk100,							// 100MHz clock
  
  // Memory Interface
  Rd_req_af,						// Memory Read FIFO Alomost Full
  Rd_Req,							// Read Enable
  Rd_start_line,					// First read for a line
  Rd_Addr,							// Read Memory Address
  Rd_eof_n, 						// End of burst read
  Rd_data_in, 						// input data
  Rd_data_in_valid,				// input data is valid
  
  // TFT Interface  
  SYS_TFT_Clk,                // TFT Input Clock
  TFT_HSYNC,                  // TFT Horizontal Sync    
  TFT_VSYNC,                  // TFT Vertical Sync
  TFT_DE,                     // TFT Data Enable
  TFT_VGA_CLK,                // TFT VGA Clock
  TFT_VGA_R,                  // TFT VGA Red data 
  TFT_VGA_G,                  // TFT VGA Green data 
  TFT_VGA_B,                  // TFT VGA Blue data
  TFT_DVI_CLK_P,              // TFT DVI differential clock
  TFT_DVI_CLK_N,              // TFT DVI differential clock
  TFT_DVI_DATA,               // TFT DVI DATA
  TFT_FB_BASE_ADDR,				// Memory Address of fram buffer
  TFT_ON,							// Enable TFT controller

  //IIC Interface for Chrontel CH7301C
  TFT_IIC_SCL_I,              // I2C clock input 
  TFT_IIC_SCL_O,              // I2C clock output
  TFT_IIC_SCL_T,              // I2C clock control
  TFT_IIC_SDA_I,              // I2C data input
  TFT_IIC_SDA_O,              // I2C data output 
  TFT_IIC_SDA_T,              // I2C data control

); 


// -- parameters definition 
parameter  integer C_DCR_SPLB_SLAVE_IF      = 1;          
parameter  integer C_TFT_INTERFACE          = 1;          
parameter          C_I2C_SLAVE_ADDR         = "1110110";          
parameter          C_DEFAULT_TFT_BASE_ADDR  = "000000000000";
parameter          C_DCR_BASEADDR           = "0010000000"; 
parameter          C_DCR_HIGHADDR           = "0010000001"; 
parameter  integer C_IOREG_STYLE            = 1;

parameter          C_FAMILY                 = "virtex5";
parameter  integer C_SLV_DWIDTH             = 32;
parameter  integer C_MEM_AWIDTH             = 32;
parameter  integer C_MEM_DWIDTH             = 64;
parameter  integer C_NUM_REG                = 4;
parameter  integer C_TRANS_INIT             = 159;  //?? or minus one?
parameter  integer C_LINE_INIT              = 1023;

//Constraint added to get rid of multiple clock buffers
input										  sys_clk;
input										  sys_rst;

input										  clk100;

// Memory Signals
input 									  Rd_req_af;
output									  Rd_Req;
output									  Rd_start_line;
output	[0 : C_MEM_AWIDTH-1]		  Rd_Addr;
input										  Rd_eof_n;
input		[0 : 127]		  Rd_data_in;
input										  Rd_data_in_valid;

// TFT SIGNALS
input                              SYS_TFT_Clk;
output                             TFT_HSYNC;
output                             TFT_VSYNC;
output                             TFT_DE;  
output                             TFT_VGA_CLK; 
output    [5:0]                    TFT_VGA_R; 
output    [5:0]                    TFT_VGA_G; 
output    [5:0]                    TFT_VGA_B; 
output                             TFT_DVI_CLK_P; 
output                             TFT_DVI_CLK_N; 
output    [11:0]                   TFT_DVI_DATA; 
input		 [11:0]						  TFT_FB_BASE_ADDR;
input										  TFT_ON;

// IIC init signals
input                              TFT_IIC_SCL_I;
output                             TFT_IIC_SCL_O;
output                             TFT_IIC_SCL_T;
input                              TFT_IIC_SDA_I;
output                             TFT_IIC_SDA_O;
output                             TFT_IIC_SDA_T;

//////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////

    // PLB_IF to RGB_BRAM  
  reg    [0:127]                    PLB_BRAM_data_i;
  reg                              PLB_BRAM_we_i;

  // HSYNC and VSYNC to TFT_IF
  wire                             HSYNC_i;
  wire                             VSYNC_i;

  // DE GENERATION
  wire                             H_DE_i;
  wire                             V_DE_i;
  wire                             DE_i;

  // RGB_BRAM to TFT_IF
  wire   [7:0]                     RED_i;
  wire   [7:0]                     GREEN_i;
  wire   [7:0]                     BLUE_i;
  wire                             I2C_done;

  // VSYNC RESET
  wire                             vsync_rst;

  // TFT READ FROM BRAM
  wire                             BRAM_TFT_rd;
  wire                             BRAM_TFT_oe;

  // Hsync|Vsync terminal counts                                   
  wire                             h_bp_cnt_tc;
  wire                             h_bp_cnt_tc2;  
  wire                             h_pix_cnt_tc;
  wire                             h_pix_cnt_tc2;
  reg    [0:7]                     trans_cnt;
  reg    [0:7]                     trans_cnt_i;
  wire                             trans_cnt_tc;
  reg    [0:9]                     line_cnt;
  reg    [0:9]                     line_cnt_i;
  wire                             line_cnt_ce;
  wire                             mn_request_set;
  wire                             trans_cnt_tc_pulse;

  // get line pulse
  reg                              get_line;
  
  // TFT controller Registers
  wire   [0:11]                    tft_base_addr_i;
  reg    [0:11]                    tft_base_addr_d1;
  reg    [0:11]                    tft_base_addr_d2;
  reg    [0:11]                    tft_base_addr;
  reg                              tft_on_reg;
  wire                             tft_on_reg_i;

  // TFT control signals
  reg                              tft_on_reg_d1;
  reg                              v_bp_cnt_tc_d1; 
  reg                              v_bp_cnt_tc_d2;
  reg                              tft_on_reg_bram_d1;
  reg                              tft_on_reg_bram_d2;
  wire                             v_bp_cnt_tc;
  wire                             get_line_start;
  reg                              get_line_start_d1;
  reg                              get_line_start_d2;
  reg                              get_line_start_d3;
  wire                             v_l_cnt_tc;
                                   
  // TFT Reset signals                   
  wire                             tft_rst;   
 /* reg                              tft_rst_d1; 
  reg                              tft_rst_d2; 
  */

  // reset signals
  /*wire                             rst_d1;    
  wire                             rst_d2;    
  wire                             rst_d3;    
  wire                             rst_d4;    
  wire                             rst_d5;    
  wire                             rst_d6; 
*/  
  reg                              Rd_Req;
  reg										  Rd_start_line;
  reg                              eof_n;
  reg                              trans_cnt_tc_pulse_i;
  wire                             eof_pulse;
  wire                             master_rst;
  
  // set the initial value for reset 
  //initial tft_rst_d1 = 1'b1;
  //initial tft_rst_d2 = 1'b1;
  

  //assign Rd_Addr[0:10]      = tft_base_addr; 
  //assign Rd_Addr[11:20]     = line_cnt_i;
  //assign Rd_Addr[21:28]     = trans_cnt_i;
  //assign Rd_Addr[29:31]     = 3'b000; 
  
  //line_cnt_i = 10 bits
  //trans_cnt_i = 8 bits
  assign Rd_Addr = {tft_base_addr, line_cnt_i, trans_cnt_i, 2'b0};
  
  //trans_cnt max 160

 

  /////////////////////////////////////////////////////////////////////////////                                                   
  // REQUEST LOGIC for PLB 
  /////////////////////////////////////////////////////////////////////////////
  assign mn_request_set = ((get_line & (trans_cnt == 0) ) | 
                           (trans_cnt != 0));
									//(Rd_req_af == 0 & trans_cnt != 0));
   
  
  /////////////////////////////////
  // Generate Master read request 
  // for master burst interface
  /////////////////////////////////
  always @(posedge master_rst or posedge sys_clk)
  begin : MST_REQ
    if (master_rst ) 
      begin
        Rd_Req <= 1'b0;
		  Rd_start_line <= 1'b0;
      end
	 else if (trans_cnt_tc_pulse) 
      begin
        Rd_Req <= 1'b0;
		  Rd_start_line <= 1'b0;
      end
    else if (mn_request_set) 
      begin
        Rd_Req <= 1'b1;
		  Rd_start_line <= get_line;
      end 
	 else
		begin
			Rd_Req <=1'b0;
			Rd_start_line <= 1'b0;
		end
   end   

  /////////////////////////////////////////////////////////////////////////////
  // Generate control signals for line count and trans count
  /////////////////////////////////////////////////////////////////////////////    
  // Generate end of frame from Master burst interface 
  always @(posedge master_rst or posedge sys_clk)
  begin : EOF_GEN
    if (master_rst) 
      begin
        eof_n <= 1'b1;
      end
    else     
      begin
        eof_n <= Rd_eof_n; //Bus2IP_MstRd_eof_n;
      end
  end 
 
  // Generate one shot pulse for end of frame  
  assign eof_pulse = ~eof_n & Rd_eof_n; //Bus2IP_MstRd_eof_n;
  
  
  // Registering trans_cnt_tc to generate one shot pulse 
  // for trans_counter terminal count  
  always @(posedge master_rst or posedge sys_clk)
  begin : TRANS_CNT_TC
    if (master_rst) 
      begin
        trans_cnt_tc_pulse_i <= 1'b0;
      end
    else     
      begin 
        trans_cnt_tc_pulse_i <= trans_cnt_tc;
      end
  end 

  // Generate one shot pulse for trans_counter terminal count  
  assign trans_cnt_tc_pulse = trans_cnt_tc_pulse_i & ~trans_cnt_tc;  
                          

  /////////////////////////////////////////////////////////////////////////////
  // Generate PLB memory addresses
  /////////////////////////////////////////////////////////////////////////////    

  // load tft_base_addr from tft address register after completing 
  // the current frame only
  always @(posedge master_rst or posedge sys_clk)
  begin : MST_BASE_ADDR_GEN
    if (master_rst) 
      begin
        tft_base_addr <= C_DEFAULT_TFT_BASE_ADDR;
      end
    else if (v_bp_cnt_tc_d2) 
      begin
        tft_base_addr <= tft_base_addr_d2;
      end
  end 

  // Load line counter nad trans counter if the master request is set
  always @(posedge master_rst or posedge sys_clk)
  begin : MST_LINE_ADDR_GEN
    if (master_rst) 
      begin 
        line_cnt_i      <= 10'b0;
        trans_cnt_i     <= 8'b0;
      end  
    else if (mn_request_set) 
      begin
        line_cnt_i      <= line_cnt;
        trans_cnt_i     <= trans_cnt;
      end 
  end 
                             
							  
  
  ///////////////////////////////////////////////////////////////////////////////
  // Transaction Counter - Counts 0-19 (d) C_TRANS_INIT
  ///////////////////////////////////////////////////////////////////////////////      

  // Generate trans_count_tc 
  assign trans_cnt_tc = (trans_cnt == C_TRANS_INIT);

  // Trans_count counter.
  // Update the counter after every 128 byte frame 
  // received from the master burst interface.
  always @(posedge master_rst or posedge sys_clk)
  begin : TRANS_CNT
    if(master_rst)
      begin
        trans_cnt = 8'b0;
      end   
    else if (mn_request_set) 
      begin
        if (trans_cnt_tc)
          begin
            trans_cnt = 8'b0;
          end  
        else 
          begin 
            trans_cnt = trans_cnt + 1;
          end  
      end
  end

  /////////////////////////////////////////////////////////////////////////////
  // Line Counter - Counts 0-479 (d)  C_LINE_INIT
  /////////////////////////////////////////////////////////////////////////////      

  // Generate trans_count_tc 
  assign line_cnt_ce = trans_cnt_tc_pulse;
  
  // Line_count counter.
  // Update the counter after every line is received 
  // from the master burst interface.
  always @(posedge master_rst or posedge sys_clk)
  begin : LINE_CNT
    if (master_rst)
      begin 
        line_cnt = 10'b0; 
      end  
    else if (line_cnt_ce) 
      begin
        if (line_cnt == C_LINE_INIT)
          begin 
            line_cnt = 10'b0;
          end  
        else
          begin 
            line_cnt = line_cnt + 1;
          end  
      end
  end

  // BRAM_TFT_rd and BRAM_TFT_oe start the read process. These are constant
  // signals through out a line read.  
  assign BRAM_TFT_rd = ((DE_i ^ h_bp_cnt_tc ^ h_bp_cnt_tc2 ) & V_DE_i);
  assign BRAM_TFT_oe = ((DE_i ^ h_bp_cnt_tc) & V_DE_i);  
  
  /////////////////////////////////////////////////////////////////////////////
  // Generate line buffer write enable signal and register the PLB data
  /////////////////////////////////////////////////////////////////////////////    
  always @(posedge master_rst or posedge sys_clk)
  begin : BRAM_DATA_WE
    if(master_rst)
      begin
        PLB_BRAM_data_i  <= 128'b0;
        PLB_BRAM_we_i    <= 1'b0;
      end
    else
      begin
        PLB_BRAM_data_i  <= Rd_data_in;  			//Bus2IP_MstRd_d;
        PLB_BRAM_we_i    <= Rd_data_in_valid;	//~Bus2IP_MstRd_src_rdy_n;
      end                             
  end
  
  /////////////////////////////////////////////////////////////////////////////
  // Generate Get line start signal to fetch the video data from attached
  // video memory
  /////////////////////////////////////////////////////////////////////////////
  // get line start logic
  assign get_line_start = ((h_pix_cnt_tc && v_bp_cnt_tc) || // 1st get line
                           (h_pix_cnt_tc && DE_i) &&     // 2nd,3rd,...get line
                           (~v_l_cnt_tc));               // No get_line on last 
                                                           //line      

  // Generate DE for HW
  assign DE_i = (H_DE_i & V_DE_i);
  
      
  // Synchronize the get line signal w.r.t. clock
  always @(posedge tft_rst or posedge SYS_TFT_Clk)
  begin : GET_LINE_START
    if (tft_rst)
      begin
        get_line_start_d1 <= 1'b0;
      end
    else
      begin
        get_line_start_d1 <= get_line_start;
      end
  end
  
  // Synchronize the get line signal w.r.t. clock
  always @(posedge master_rst or posedge sys_clk)
  begin : GET_LINE_REG
    if (master_rst)
      begin
        get_line_start_d2 <= 1'b0;
        get_line_start_d3 <= 1'b0;
        get_line          <= 1'b0;
      end
    else
      begin
        get_line_start_d2 <= get_line_start_d1;
        get_line_start_d3 <= get_line_start_d2;
        get_line          <= get_line_start_d2 & ~get_line_start_d3;
      end  
  end 
  
  /////////////////////////////////////////////////////////////////////////////
  // Synchronize all the signals crossing the clock domains
  // video memory
  /////////////////////////////////////////////////////////////////////////////

  // Synchronize the TFT clock domain signals w.r.t. MPLB clock
  always @(posedge master_rst or posedge sys_clk)
  begin : V_BP_CNT_TC 
    if (master_rst)
      begin
        v_bp_cnt_tc_d1  <= 1'b0;
        v_bp_cnt_tc_d2  <= 1'b0;
      end 
    else
      begin 
        v_bp_cnt_tc_d1  <= v_bp_cnt_tc;
        v_bp_cnt_tc_d2  <= v_bp_cnt_tc_d1;
      end
  end


  // Synchronize the slave register signals w.r.t. MPLB clock
  always @(posedge sys_clk)
  begin : SLAVE_REG_SYNC 
      tft_on_reg_d1 <= tft_on_reg_i;
      tft_on_reg        <= tft_on_reg_d1;
      tft_base_addr_d1  <= tft_base_addr_i;
      tft_base_addr_d2  <= tft_base_addr_d1;
  end


  // Synchronize the tft_on_reg signal w.r.t. SYS_TFT_Clk
  always @(posedge SYS_TFT_Clk)
  begin :ON_REG_SYNC
      tft_on_reg_bram_d1 <= tft_on_reg_i;
      tft_on_reg_bram_d2 <= tft_on_reg_bram_d1;
  end
  /////////////////////////////////////////////////////////////////////////////

  
  // Generate master interface reset from the MPLB reset and tft_on_reg
  assign master_rst = sys_rst | ~tft_on_reg;
  
/*  // Generate TFT reset from the master reset,I2C done
  // Increase the pulse width of the Reset to match with TFT clock
  FDS FD_PLB_RST1 (.Q(rst_d1), .C(sys_clk), .S(sys_rst), .D(sys_rst)); 
  FDS FD_PLB_RST2 (.Q(rst_d2), .C(sys_clk), .S(sys_rst), .D(rst_d1));
  FDS FD_PLB_RST3 (.Q(rst_d3), .C(sys_clk), .S(sys_rst), .D(rst_d2));
  FDS FD_PLB_RST4 (.Q(rst_d4), .C(sys_clk), .S(sys_rst), .D(rst_d3));
  FDS FD_PLB_RST5 (.Q(rst_d5), .C(sys_clk), .S(sys_rst), .D(rst_d4));
  FDS FD_PLB_RST6 (.Q(rst_d6), .C(sys_clk), .S(sys_rst), .D(rst_d5));
 
  // Synchronize the MPLB reset with SYS_TFT_CLK
  always @(posedge SYS_TFT_Clk)
  begin : RST_SYNC
      tft_rst_d1  <= rst_d6 | ~I2C_done;
      tft_rst_d2  <= tft_rst_d1;
  end
    
  // Generate TFT reset
  assign tft_rst = tft_rst_d2 | ~tft_on_reg_bram_d2;
*/

  assign tft_rst = sys_rst | ~I2C_done | ~tft_on_reg_bram_d2;

  /////////////////////////////////////////////////////////////////////////////
  // DCR_IF COMPONENT INSTANTIATION (Know comes from direct input)
  /////////////////////////////////////////////////////////////////////////////
  assign tft_base_addr_i = TFT_FB_BASE_ADDR;
  assign tft_on_reg_i = TFT_ON;
                  
  /////////////////////////////////////////////////////////////////////////////
  // RGB_BRAM COMPONENT INSTANTIATION
  /////////////////////////////////////////////////////////////////////////////              
  line_buffer u_line_buffer
    (
    .TFT_Clk(SYS_TFT_Clk),
    .TFT_Rst(tft_rst),
    .sys_clk(sys_clk),
    .sys_rst(master_rst),
	 .Rd_start_line(Rd_start_line),
    .BRAM_TFT_rd(BRAM_TFT_rd), 
    .BRAM_TFT_oe(BRAM_TFT_oe), 
    .PLB_BRAM_data(PLB_BRAM_data_i),
    .PLB_BRAM_we(PLB_BRAM_we_i),
    .RED(RED_i),.GREEN(GREEN_i), .BLUE(BLUE_i)
  );              
                  
  /////////////////////////////////////////////////////////////////////////////
  //HSYNC COMPONENT INSTANTIATION
  /////////////////////////////////////////////////////////////////////////////  
  h_sync u_h_sync (
    .Clk(SYS_TFT_Clk), 
    .Rst(tft_rst), 
    .HSYNC(HSYNC_i), 
    .H_DE(H_DE_i), 
    .VSYNC_Rst(vsync_rst), 
    .H_bp_cnt_tc(h_bp_cnt_tc),    
    .H_bp_cnt_tc2(h_bp_cnt_tc2), 
    .H_pix_cnt_tc(h_pix_cnt_tc),  
    .H_pix_cnt_tc2(h_pix_cnt_tc2) 
  );              
                 
  /////////////////////////////////////////////////////////////////////////////
  // VSYNC COMPONENT INSTANTIATION
  ///////////////////////////////////////////////////////////////////////////// 
  v_sync u_vsync (
    .Clk(SYS_TFT_Clk),
    .Clk_stb(~HSYNC_i), 
    .Rst(vsync_rst), 
    .VSYNC(VSYNC_i), 
    .V_DE(V_DE_i),
    .V_bp_cnt_tc(v_bp_cnt_tc),
    .V_l_cnt_tc(v_l_cnt_tc)
  );            
               

  /////////////////////////////////////////////////////////////////////////////
  // TFT_IF COMPONENT INSTANTIATION
  /////////////////////////////////////////////////////////////////////////////
  tft_interface 
    #(
      .C_FAMILY          (C_FAMILY),
      .C_TFT_INTERFACE   (C_TFT_INTERFACE), 
      .C_I2C_SLAVE_ADDR  (C_I2C_SLAVE_ADDR),
      .C_IOREG_STYLE     (C_IOREG_STYLE) 

    )
    u_tft_interface
    (
      .TFT_Clk           (SYS_TFT_Clk),
      .TFT_Rst           (tft_rst),
      .sys_clk 	       (sys_clk),
      .sys_rst    	    (sys_rst),
		.clk100				 (clk100),
      .HSYNC             (HSYNC_i),
      .VSYNC             (VSYNC_i),
      .DE                (DE_i),   
      .RED               (RED_i),
      .GREEN             (GREEN_i),
      .BLUE              (BLUE_i),
      .TFT_HSYNC         (TFT_HSYNC),
      .TFT_VSYNC         (TFT_VSYNC),
      .TFT_DE            (TFT_DE),
      .TFT_VGA_CLK       (TFT_VGA_CLK),
      .TFT_VGA_R         (TFT_VGA_R),
      .TFT_VGA_G         (TFT_VGA_G),
      .TFT_VGA_B         (TFT_VGA_B), 
      .TFT_DVI_CLK_P     (TFT_DVI_CLK_P),
      .TFT_DVI_CLK_N     (TFT_DVI_CLK_N),
      .TFT_DVI_DATA      (TFT_DVI_DATA),
      .I2C_done          (I2C_done),
      .TFT_IIC_SCL_I     (TFT_IIC_SCL_I),
      .TFT_IIC_SCL_O     (TFT_IIC_SCL_O),
      .TFT_IIC_SCL_T     (TFT_IIC_SCL_T),
      .TFT_IIC_SDA_I     (TFT_IIC_SDA_I),
      .TFT_IIC_SDA_O     (TFT_IIC_SDA_O),
      .TFT_IIC_SDA_T     (TFT_IIC_SDA_T)
  );
  
  
endmodule
