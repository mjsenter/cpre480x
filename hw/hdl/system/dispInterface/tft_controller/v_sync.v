//************************************************************************
// Michael Steffen
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//************************************************************************/


// v_sync.v
//************************************************************************
// DESCRIPTION: Modified version of Xiilnx's v_sync module, improved
// to support 1280x1024 resolution. 
//
// NOTES:
// 07/24/10 by MAS::Design created.
//***********************************************************************

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
module v_sync(
    Clk,          // Clock 
    Clk_stb,      // Hsync clock strobe
    Rst,          // Reset
    VSYNC,        // Vertical Sync output
    V_DE,         // Vertical Data enable
    V_bp_cnt_tc,  // Vertical back porch terminal count pulse
    V_l_cnt_tc);  // Vertical line terminal count pulse

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
    input         Clk;
    input         Clk_stb;
    input         Rst;     
    output        VSYNC;
    output        V_DE;
    output        V_bp_cnt_tc;
    output        V_l_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
    reg           V_DE;
    reg           VSYNC;
    reg   [0:1]   v_p_cnt;  // 2-bit counter (2   HSYNCs for pulse time)
    reg   [0:5]   v_bp_cnt; // 5-bit counter (31  HSYNCs for back porch time) - changed to 6 bit counter and 38 HSYNCs
    reg   [0:10]   v_l_cnt;  // 9-bit counter (480 HSYNCs for line time) - changed to 11 bit counter and 1024 HSYNCs
    reg   [0:3]   v_fp_cnt; // 4-bit counter (12  HSYNCs for front porch time) 
    reg           v_p_cnt_clr;
    reg           v_bp_cnt_clr;
    reg           v_l_cnt_clr;
    reg           v_fp_cnt_clr;
    reg           v_p_cnt_tc;
    reg           V_bp_cnt_tc;
    reg           V_l_cnt_tc;
    reg           v_fp_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - State Declaration
///////////////////////////////////////////////////////////////////////////////

    parameter [0:4] SET_COUNTERS    = 5'b00001;
    parameter [0:4] PULSE           = 5'b00010;
    parameter [0:4] BACK_PORCH      = 5'b00100;
    parameter [0:4] LINE            = 5'b01000;
    parameter [0:4] FRONT_PORCH     = 5'b10000;     

    reg [0:4]       VSYNC_cs;
    reg [0:4]       VSYNC_ns;

///////////////////////////////////////////////////////////////////////////////
// clock enable State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////

    reg clk_stb_d1;
    reg clk_ce_neg;
    reg clk_ce_pos;

    // posedge and negedge of clock strobe
    always @ (posedge Clk)
    begin : CLOCK_STRB_GEN
      clk_stb_d1 <=  Clk_stb;
      clk_ce_pos <=  Clk_stb & ~clk_stb_d1;
      clk_ce_neg <= ~Clk_stb & clk_stb_d1;
    end

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////
    always @ (posedge Rst or posedge Clk)
    begin : VSYNC_REG_STATE
      if (Rst) 
        VSYNC_cs = SET_COUNTERS;
      else if (clk_ce_pos) 
        VSYNC_cs = VSYNC_ns;
    end

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - Combinatorial Block 
///////////////////////////////////////////////////////////////////////////////
    always @ (VSYNC_cs or v_p_cnt_tc or V_bp_cnt_tc or V_l_cnt_tc or v_fp_cnt_tc)
    begin : VSYNC_SM_CMB 
      case (VSYNC_cs)
        ///////////////////////////////////////////////////////////////////
        //      SET COUNTERS STATE
        // -- Clear and de-enable all counters on frame_start signal 
        ///////////////////////////////////////////////////////////////////
        SET_COUNTERS: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 1;
          VSYNC        = 1;
          V_DE         = 0;                               
          VSYNC_ns     = PULSE;
        end
        ///////////////////////////////////////////////////////////////////
        //      PULSE STATE
        // -- Enable pulse counter
        // -- De-enable others
        ///////////////////////////////////////////////////////////////////
        PULSE: begin
          v_p_cnt_clr  = 0;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 1;
          VSYNC        = 0;
          V_DE         = 0;
          
          if (v_p_cnt_tc == 0) 
            VSYNC_ns = PULSE;                     
          else 
            VSYNC_ns = BACK_PORCH;
        end
        ///////////////////////////////////////////////////////////////////
        //      BACK PORCH STATE
        // -- Enable back porch counter
        // -- De-enable others
        ///////////////////////////////////////////////////////////////////
        BACK_PORCH: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 0;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 1;
          VSYNC        = 1;
          V_DE         = 0;                               
          
          if (V_bp_cnt_tc == 0) 
            VSYNC_ns = BACK_PORCH;                                                 
          else 
            VSYNC_ns = LINE;
        end
        ///////////////////////////////////////////////////////////////////
        //      LINE STATE
        // -- Enable line counter
        // -- De-enable others
        ///////////////////////////////////////////////////////////////////
        LINE: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 0;
          v_fp_cnt_clr = 1;
          VSYNC        = 1;
          V_DE         = 1;  
          
          if (V_l_cnt_tc == 0) 
            VSYNC_ns = LINE;                                                      
          else 
            VSYNC_ns = FRONT_PORCH;
        end
        ///////////////////////////////////////////////////////////////////
        //      FRONT PORCH STATE
        // -- Enable front porch counter
        // -- De-enable others
        // -- Wraps to PULSE state
        ///////////////////////////////////////////////////////////////////
        FRONT_PORCH: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 0;
          VSYNC        = 1;
          V_DE         = 0;       
          
          if (v_fp_cnt_tc == 0) 
            VSYNC_ns = FRONT_PORCH;                                                
          else 
            VSYNC_ns = PULSE;
        end
        ///////////////////////////////////////////////////////////////////
        //      DEFAULT STATE
        ///////////////////////////////////////////////////////////////////
        // added coverage off to disable the coverage for default state
        // as state machine will never enter in defualt state while doing
        // verification. 
        // coverage off
        default: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 0;
          VSYNC        = 1;      
          V_DE         = 0;
          VSYNC_ns     = SET_COUNTERS;
        end
        // coverage on         
      endcase
    end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Pulse Counter - Counts 2 clocks(~HSYNC) for pulse time                                                                                                                                 
///////////////////////////////////////////////////////////////////////////////
        always @(posedge Rst or posedge Clk)
        begin : VSYNC_PULSE_CNTR
          if (Rst  ) 
            begin
              v_p_cnt = 2'b0;
              v_p_cnt_tc = 0;
            end
			 else if (v_p_cnt_clr ) 
            begin
              v_p_cnt = 2'b0;
              v_p_cnt_tc = 0;
            end
          else if (clk_ce_neg) 
            begin
              if (v_p_cnt == 2) 
                begin
                  v_p_cnt = v_p_cnt + 1;
                  v_p_cnt_tc = 1;
                end
              else 
                begin
                  v_p_cnt = v_p_cnt + 1;
                  v_p_cnt_tc = 0;
                end
            end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Back Porch Counter - Counts 31 clocks(~HSYNC) for pulse time                                                                   
///////////////////////////////////////////////////////////////////////////////
        always @(posedge Rst or posedge Clk)
        begin : VSYNC_BP_CNTR
          if (Rst ) 
            begin
              v_bp_cnt = 5'b0;
              V_bp_cnt_tc = 0;
            end
		    else if (v_bp_cnt_clr) 
            begin
              v_bp_cnt = 5'b0;
              V_bp_cnt_tc = 0;
            end
          else if (clk_ce_neg) 
            begin
              if (v_bp_cnt == 37)
                begin
                  v_bp_cnt = v_bp_cnt + 1;
                  V_bp_cnt_tc = 1;
                end
              else 
                begin
                  v_bp_cnt = v_bp_cnt + 1;
                  V_bp_cnt_tc = 0;
                end
            end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Line Counter - Counts 480 clocks(~HSYNC) for pulse time                                                                                                                                
///////////////////////////////////////////////////////////////////////////////                                                                                                                                 
        always @(posedge Rst or posedge Clk)
        begin : VSYNC_LINE_CNTR
          if (Rst ) 
            begin
              v_l_cnt = 9'b0;
              V_l_cnt_tc = 0;
            end
			 else if (v_l_cnt_clr) 
            begin
              v_l_cnt = 9'b0;
              V_l_cnt_tc = 0;
            end
          else if (clk_ce_neg) 
            begin
              if (v_l_cnt == 1023) 
                begin
                  v_l_cnt = v_l_cnt + 1;
                  V_l_cnt_tc = 1;
                end
              else 
                begin
                  v_l_cnt = v_l_cnt + 1;
                  V_l_cnt_tc = 0;
                end
            end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Front Porch Counter - Counts 12 clocks(~HSYNC) for pulse time
///////////////////////////////////////////////////////////////////////////////
        always @(posedge Rst or posedge Clk)
        begin : VSYNC_FP_CNTR
          if (Rst ) 
            begin
              v_fp_cnt = 4'b0;
              v_fp_cnt_tc = 0;
            end
			 else if (v_fp_cnt_clr) 
            begin
              v_fp_cnt = 4'b0;
              v_fp_cnt_tc = 0;
            end
          else if (clk_ce_neg) 
            begin
              if (v_fp_cnt == 0) 
                begin
                  v_fp_cnt = v_fp_cnt + 1;
                  v_fp_cnt_tc = 1;
                end
              else 
                begin
                  v_fp_cnt = v_fp_cnt + 1;
                  v_fp_cnt_tc = 0;
                end
            end
        end
endmodule
