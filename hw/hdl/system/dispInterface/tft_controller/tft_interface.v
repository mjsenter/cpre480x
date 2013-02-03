//-----------------------------------------------------------------------
// Michael Steffen
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//-----------------------------------------------------------------------


// tft_interface.v
//-----------------------------------------------------------------------
// DESCRIPTION: This file implements the interface between the 
// chrontel video chip and the framebuffer design. 
//
// NOTES:
// 07/24/10 by MAS::Design created.
//-----------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
module tft_interface (
    TFT_Clk,                // TFT Clock
    TFT_Rst,                // TFT Reset
    sys_clk,	             // System Clock 200 Mhz
    sys_rst,             	 //  Reset
	 clk100,						 // 100MHz clock
    HSYNC,                  // Hsync input
    VSYNC,                  // Vsync input
    DE,                     // Data Enable
    RED,                    // RED pixel data 
    GREEN,                  // Green pixel data
    BLUE,                   // Blue pixel data
    TFT_HSYNC,              // TFT Hsync
    TFT_VSYNC,              // TFT Vsync
    TFT_DE,                 // TFT data enable
    TFT_VGA_CLK,            // TFT VGA clock
    TFT_VGA_R,              // TFT VGA Red pixel data 
    TFT_VGA_G,              // TFT VGA Green pixel data
    TFT_VGA_B,              // TFT VGA Blue pixel data
    TFT_DVI_CLK_P,          // TFT DVI differential clock
    TFT_DVI_CLK_N,          // TFT DVI differential clock
    TFT_DVI_DATA,           // TFT DVI pixel data
    
    //IIC init state machine for Chrontel CH7301C
    I2C_done,               // I2C configuration done
    TFT_IIC_SCL_I,          // I2C Clock input 
    TFT_IIC_SCL_O,          // I2C Clock output
    TFT_IIC_SCL_T,          // I2C Clock control
    TFT_IIC_SDA_I,          // I2C data input
    TFT_IIC_SDA_O,          // I2C data output 
    TFT_IIC_SDA_T           // I2C data control
);

///////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////////
    parameter         C_FAMILY         = "virtex5";
    parameter         C_I2C_SLAVE_ADDR = "1110110";
    parameter integer C_TFT_INTERFACE  = 1;
    parameter integer C_IOREG_STYLE    = 0;

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

// Inputs Ports
    input             TFT_Clk;
    input             TFT_Rst;
    input             sys_rst;
    input             sys_clk;
	 input				 clk100;
    input             HSYNC;                          
    input             VSYNC;                          
    input             DE;     
    input    [7:0]    RED;
    input    [7:0]    GREEN;
    input    [7:0]    BLUE;
    
// Output Ports    
    output            TFT_HSYNC;
    output            TFT_VSYNC;
    output            TFT_DE;
    output            TFT_VGA_CLK;
    output   [5:0]    TFT_VGA_R;
    output   [5:0]    TFT_VGA_G;
    output   [5:0]    TFT_VGA_B;
    output            TFT_DVI_CLK_P;
    output            TFT_DVI_CLK_N;
    output   [11:0]   TFT_DVI_DATA;

// I2C Ports
    output            I2C_done;
    input             TFT_IIC_SCL_I;
    output            TFT_IIC_SCL_O;
    output            TFT_IIC_SCL_T;
    input             TFT_IIC_SDA_I;
    output            TFT_IIC_SDA_O;
    output            TFT_IIC_SDA_T;


///////////////////////////////////////////////////////////////////////////////
// Implementation
///////////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // FDS/FDR COMPONENT INSTANTIATION FOR IOB OUTPUT REGISTERS
    // -- All output to TFT are registered
    ///////////////////////////////////////////////////////////////////////////
    
    // Generate TFT HSYNC
    FDS FDS_HSYNC (.Q(TFT_HSYNC), 
                   .C(~TFT_Clk), 
                   .S(TFT_Rst), 
                   .D(HSYNC)); 


    // Generate TFT VSYNC
    FDS FDS_VSYNC (.Q(TFT_VSYNC), 
                   .C(~TFT_Clk), 
                   .S(TFT_Rst), 
                   .D(VSYNC));
                     
    // Generate TFT DE
    FDR FDR_DE    (.Q(TFT_DE),    
                   .C(~TFT_Clk), 
                   .R(TFT_Rst), 
                   .D(DE));

    
      
    generate
      if (C_TFT_INTERFACE == 1) // Selects DVI interface
        begin : gen_dvi_if
        
          wire        tft_iic_sda_t_i;
          wire        tft_iic_scl_t_i;
          wire [11:0] dvi_data_a;
          wire [11:0] dvi_data_b;
          genvar i;

          
          assign dvi_data_b[0]  = BLUE[0];
          assign dvi_data_b[1]  = BLUE[1];
          assign dvi_data_b[2]  = BLUE[2];
          assign dvi_data_b[3]  = BLUE[3];
          assign dvi_data_b[4]  = BLUE[4];
          assign dvi_data_b[5]  = BLUE[5];
          assign dvi_data_b[6]  = BLUE[6];
          assign dvi_data_b[7]  = BLUE[7];
          assign dvi_data_b[8]  = GREEN[0];
          assign dvi_data_b[9]  = GREEN[1];
          assign dvi_data_b[10] = GREEN[2];
          assign dvi_data_b[11] = GREEN[3];
			 
          assign dvi_data_a[0]  = GREEN[4];
          assign dvi_data_a[1]  = GREEN[5];
          assign dvi_data_a[2]  = GREEN[6];
          assign dvi_data_a[3]  = GREEN[7];
          assign dvi_data_a[4]  = RED[0];
          assign dvi_data_a[5]  = RED[1];
          assign dvi_data_a[6]  = RED[2];
          assign dvi_data_a[7]  = RED[3];
          assign dvi_data_a[8]  = RED[4];
          assign dvi_data_a[9]  = RED[5];
          assign dvi_data_a[10] = RED[6];
          assign dvi_data_a[11] = RED[7];
                                                                                   
       
          /////////////////////////////////////////////////////////////////////
          // ODDR COMPONENT INSTANTIATION FOR IOB OUTPUT REGISTERS
          // -- All output to TFT are registered
          // (C_FAMILY == "virtex5" || "virtex4")
          /////////////////////////////////////////////////////////////////////           
 //         if (C_IOREG_STYLE == 0)   // Virtex-4 style IO generation
 //           begin : gen_v4_v5       // Uses ODDR  

              // DVI Clock P
              ODDR TFT_CLKP_ODDR (.Q(TFT_DVI_CLK_P), 
                                  .C(TFT_Clk), 
                                  .CE(1'b1), 
                                  .R(TFT_Rst), 
                                  .D1(1'b1), 
                                  .D2(1'b0), 
                                  .S(1'b0));
                                  
              // DVI Clock N                    
              ODDR TFT_CLKN_ODDR (.Q(TFT_DVI_CLK_N), 
                                  .C(TFT_Clk), 
                                  .CE(1'b1), 
                                  .R(TFT_Rst), 
                                  .D1(1'b0), 
                                  .D2(1'b1), 
                                  .S(1'b0));

              /////////////////////////////////////////////////////////////////
              // Generate DVI data 
              /////////////////////////////////////////////////////////////////
              for (i=0;i<12;i=i+1) begin : replicate_tft_dvi_data
         
                ODDR ODDR_TFT_DATA (.Q(TFT_DVI_DATA[i]),  
                                    .C(TFT_Clk), 
                                    .CE(1'b1), 
                                    .R(~DE|TFT_Rst), 
                                    .D2(dvi_data_b[i]),      
                                    .D1(dvi_data_a[i]),  
                                    .S(1'b0));
               end 
              /////////////////////////////////////////////////////////////////
                 
 //           end        
				
          // All TFT ports are grounded
          assign TFT_VGA_CLK = 1'b0;
          assign TFT_VGA_R   = 6'b0;
          assign TFT_VGA_G   = 6'b0;
          assign TFT_VGA_B   = 6'b0;
          
          /////////////////////////////////////////////////////////////////////
          // IIC INIT COMPONENT INSTANTIATION for Chrontel CH-7301
          /////////////////////////////////////////////////////////////////////
          iic_init 
            # (.C_I2C_SLAVE_ADDR(C_I2C_SLAVE_ADDR))
            iic_init
              (
                .Clk     (clk100),
                .Reset_n (~sys_rst), 
                .SDA     (tft_iic_sda_t_i),
                .SCL     (tft_iic_scl_t_i),
                .Done    (I2C_done)
               );
                       
          assign TFT_IIC_SCL_O = 1'b0;
          assign TFT_IIC_SDA_O = 1'b0;
          assign TFT_IIC_SDA_T = tft_iic_sda_t_i ;
          assign TFT_IIC_SCL_T = tft_iic_scl_t_i ;
          /////////////////////////////////////////////////////////////////////
          
           
       end // End DVI Interface
    endgenerate    

endmodule
