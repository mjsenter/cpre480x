//************************************************************************
// Michael Steffen
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//************************************************************************/


// h_sync.v
//************************************************************************
// DESCRIPTION: Modified version of Xiilnx's h_sync module, improved
// to support 1280x1024 resolution. 
//
// NOTES:
// 07/24/10 by MAS::Design created.
//************************************************************************

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
module h_sync(
    Clk,                    // Clock      
    Rst,                    // Reset
    HSYNC,                  // Horizontal Sync
    H_DE,                   // Horizontal Data enable
    VSYNC_Rst,              // Vsync reset
    H_bp_cnt_tc,            // Horizontal back porch terminal count delayed
    H_bp_cnt_tc2,           // Horizontal back porch terminal count 
    H_pix_cnt_tc,           // Horizontal pixel data terminal count delayed
    H_pix_cnt_tc2           // Horizontal pixel data terminal count
);
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
    input         Clk;
    input         Rst;
    output        VSYNC_Rst;
    output        HSYNC;
    output        H_DE;
    output        H_bp_cnt_tc;
    output        H_bp_cnt_tc2;
    output        H_pix_cnt_tc;
    output        H_pix_cnt_tc2; 

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
    reg           VSYNC_Rst;
    reg           HSYNC;
    reg           H_DE;
    reg [0:6]     h_p_cnt;    // 7-bit  counter (96 clocks for pulse time)
    reg [0:7]     h_bp_cnt;   // 6-bit  counter (48 clocks for back porch time) - changed to 8 bit counter and 144 clocks
    reg [0:10]    h_pix_cnt;  // 11-bit counter (640 clocks for pixel time)
    reg [0:4]     h_fp_cnt;   // 4-bit counter (16 clocks for front porch time) - changed to 5 bit counter and 27 clocks
    reg           h_p_cnt_clr;
    reg           h_bp_cnt_clr;
    reg           h_pix_cnt_clr;
    reg           h_fp_cnt_clr;
    reg           h_p_cnt_tc;
    reg           H_bp_cnt_tc;
    reg           H_bp_cnt_tc2;
    reg           H_pix_cnt_tc;
    reg           H_pix_cnt_tc2;
    reg           h_fp_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - State Declaration
///////////////////////////////////////////////////////////////////////////////

    parameter [0:4] SET_COUNTERS = 5'b00001;
    parameter [0:4] PULSE        = 5'b00010;
    parameter [0:4] BACK_PORCH   = 5'b00100;
    parameter [0:4] PIXEL        = 5'b01000;
    parameter [0:4] FRONT_PORCH  = 5'b10000;

    reg [0:4]       HSYNC_cs;
    reg [0:4]       HSYNC_ns;
    
    // set the initial value for reset 
    initial  VSYNC_Rst = 1'b1;
 
///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////
    always @(posedge Rst or posedge Clk) 
    begin : HSYNC_REG_STATE
      if (Rst) 
        begin
          HSYNC_cs  = SET_COUNTERS;
          VSYNC_Rst = 1;
        end
      else 
        begin
          HSYNC_cs  = HSYNC_ns;
          VSYNC_Rst = 0;
        end
    end

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - Combinatorial Block 
///////////////////////////////////////////////////////////////////////////////
    always @(HSYNC_cs or h_p_cnt_tc or H_bp_cnt_tc or H_pix_cnt_tc 
             or h_fp_cnt_tc) 
    begin : HSYNC_SM_CMB
       case (HSYNC_cs)
         //////////////////////////////////////////////////////////////
         //      SET COUNTERS STATE
         //////////////////////////////////////////////////////////////
         SET_COUNTERS: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 0;
           HSYNC_ns      = PULSE;
         end
         //////////////////////////////////////////////////////////////
         //      PULSE STATE
         // -- Enable pulse counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         PULSE: begin
           h_p_cnt_clr   = 0;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 0;
           H_DE          = 0;
           
           if (h_p_cnt_tc == 0) 
             HSYNC_ns = PULSE;                     
           else 
             HSYNC_ns = BACK_PORCH;
         end
         //////////////////////////////////////////////////////////////
         //      BACK PORCH STATE
         // -- Enable back porch counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         BACK_PORCH: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 0;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 0;
           
           if (H_bp_cnt_tc == 0) 
             HSYNC_ns = BACK_PORCH;                                            
           else 
             HSYNC_ns = PIXEL;
         end
         //////////////////////////////////////////////////////////////
         //      PIXEL STATE
         // -- Enable pixel counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         PIXEL: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 0;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 1;
           
           if (H_pix_cnt_tc == 0) 
             HSYNC_ns = PIXEL;                                                
           else 
             HSYNC_ns = FRONT_PORCH;
         end
         //////////////////////////////////////////////////////////////
         //      FRONT PORCH STATE
         // -- Enable front porch counter
         // -- De-enable others
         // -- Wraps to PULSE state
         //////////////////////////////////////////////////////////////
         FRONT_PORCH: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 0;
           HSYNC         = 1;      
           H_DE          = 0;
           
           if (h_fp_cnt_tc == 0) 
             HSYNC_ns = FRONT_PORCH;                                           
           else 
             HSYNC_ns = PULSE;
         end
         //////////////////////////////////////////////////////////////
         //      DEFAULT STATE
         //////////////////////////////////////////////////////////////
         // added coverage off to disable the coverage for default state
         // as state machine will never enter in defualt state while doing
         // verification. 
         // coverage off
         default: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 0;
           HSYNC         = 1;      
           H_DE          = 0;
           HSYNC_ns      = SET_COUNTERS;
         end
         // coverage on 
           
       endcase
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Pulse Counter - Counts 96 clocks for pulse time                                                                                                                              
///////////////////////////////////////////////////////////////////////////////
    always @(posedge Rst or posedge Clk)
    begin : HSYNC_PULSE_CNT
      if (Rst) 
        begin
          h_p_cnt = 7'b0;
          h_p_cnt_tc = 0;
        end
		else if(h_p_cnt_clr) 
        begin
          h_p_cnt = 7'b0;
          h_p_cnt_tc = 0;
        end
      else 
        begin
          if (h_p_cnt == 110) 
            begin
              h_p_cnt = h_p_cnt + 1;
              h_p_cnt_tc = 1;
            end
          else 
            begin
              h_p_cnt = h_p_cnt + 1;
              h_p_cnt_tc = 0;
            end
        end
    end
///////////////////////////////////////////////////////////////////////////////
//      Horizontal Back Porch Counter - Counts 48 clocks for back porch time                                                                    
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Rst or posedge Clk )
    begin : HSYNC_BP_CNTR
      if (Rst ) 
        begin
          h_bp_cnt = 6'b0;
          H_bp_cnt_tc = 0;
          H_bp_cnt_tc2 = 0;
        end
		else if (h_bp_cnt_clr) 
        begin
          h_bp_cnt = 6'b0;
          H_bp_cnt_tc = 0;
          H_bp_cnt_tc2 = 0;
        end
      else 
        begin
          if (h_bp_cnt == 141) 
            begin
              h_bp_cnt = h_bp_cnt + 1;
              H_bp_cnt_tc2 = 1;
              H_bp_cnt_tc = 0;
            end
          else if (h_bp_cnt == 142) 
            begin
              h_bp_cnt = h_bp_cnt + 1;
              H_bp_cnt_tc = 1;
              H_bp_cnt_tc2 = 0;
            end
          else 
            begin
              h_bp_cnt = h_bp_cnt + 1;
              H_bp_cnt_tc = 0;
              H_bp_cnt_tc2 = 0;
            end
        end
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Pixel Counter - Counts 640 clocks for pixel time                                                                                                                     
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Rst or posedge Clk)
    begin : HSYNC_PIX_CNTR
        if (Rst ) 
          begin
            h_pix_cnt = 11'b0;
            H_pix_cnt_tc = 0;
            H_pix_cnt_tc2 = 0;
          end
		  else if (h_pix_cnt_clr) 
          begin
            h_pix_cnt = 11'b0;
            H_pix_cnt_tc = 0;
            H_pix_cnt_tc2 = 0;
          end
        else 
          begin
            if (h_pix_cnt == 1277) 
              begin
                h_pix_cnt = h_pix_cnt + 1;
                H_pix_cnt_tc2 = 1;
              end
            else if (h_pix_cnt == 1278)
              begin
                h_pix_cnt = h_pix_cnt + 1;
                H_pix_cnt_tc = 1;
              end
            else 
              begin
                h_pix_cnt = h_pix_cnt + 1;
                H_pix_cnt_tc = 0;
                H_pix_cnt_tc2 = 0;
              end
            end
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Front Porch Counter - Counts 16 clocks for front porch time
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Rst or posedge Clk)
    begin : HSYNC_FP_CNTR
        if (Rst ) 
            begin
            h_fp_cnt = 5'b0;
            h_fp_cnt_tc = 0;
            end
		  else if (h_fp_cnt_clr) 
            begin
            h_fp_cnt = 5'b0;
            h_fp_cnt_tc = 0;
            end
        else 
            begin
                if (h_fp_cnt == 25) 
                    begin
                    h_fp_cnt = h_fp_cnt + 1;
                    h_fp_cnt_tc = 1;
                    end
                else 
                    begin
                    h_fp_cnt = h_fp_cnt + 1;
                    h_fp_cnt_tc = 0;
                    end
            end
    end
endmodule
