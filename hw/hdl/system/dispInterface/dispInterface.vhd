-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- dispInterface.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file is a wrapper for the interface between the frame
-- buffer in DDR2 memory, the line buffer in BlockRAM, and the TFT 
-- display chip.
--
-- NOTES:
-- 07/24/10 by MAS::Design created.
-------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use WORK.SGP_config.all;
 
entity dispInterface IS

	port( 

	  -- System Inputs
	  clk200  : in std_logic;
	  clk100  : in std_logic;
	  rst     : in std_logic;	

	  -- DVI Signals
	  DVI_D       : out std_logic_vector(11 downto 0);
	  DVI_XCLK_P  : out std_logic;
	  DVI_XCLK_N  : out std_logic;
	  DVI_HSYNC   : out std_logic;
	  DVI_VSYNC   : out std_logic;
	  DVI_DE      : out std_logic;
	  DVI_RESET_B : out std_logic;

	  -- IIC Serial Signals
	  SDA : out std_logic;
	  SCL : out std_logic;

	  -- DDR2 Interface Signals
	  disp_ddr2app_af_afull		: in std_logic;
     disp_ddr2app_data_valid	: in std_logic;
	  disp_ddr2app_data_in		: in std_logic_vector(2*DQ_WIDTH-1 downto 0);
	  disp_ddr2app_cmd  			: out ddr2app_cmd;
	  disp_Rd_start_line			: out std_logic;
	  
	  -- High bits for fb address, support dynamic change
	  disp_fb_address				: in  std_logic_vector(FB_BASE_ADDRESS_BITS-1 downto 0));	
	  
END dispInterface;
 
ARCHITECTURE behavior OF dispInterface is


    COMPONENT tft_controller
    PORT(
         sys_clk : IN  std_logic;
         sys_rst : IN  std_logic;
			clk100  : IN  std_logic;

			Rd_req_af : IN std_logic;
			Rd_Req : out std_logic;
			Rd_start_line : out std_logic;
			Rd_Addr : out std_logic_vector(31 downto 0);
			Rd_eof_n : in std_logic;
			Rd_data_in : in std_logic_vector(127 downto 0);
			Rd_data_in_valid : in std_logic;
			
			SYS_TFT_Clk : in std_logic;
         TFT_HSYNC : OUT  std_logic;
         TFT_VSYNC : OUT  std_logic;
         TFT_DE : OUT  std_logic;
         TFT_VGA_CLK : OUT  std_logic;
         TFT_VGA_R : OUT  std_logic_vector(5 downto 0);
         TFT_VGA_G : OUT  std_logic_vector(5 downto 0);
         TFT_VGA_B : OUT  std_logic_vector(5 downto 0);
         TFT_DVI_CLK_P : OUT  std_logic;
         TFT_DVI_CLK_N : OUT  std_logic;
         TFT_DVI_DATA : OUT  std_logic_vector(11 downto 0);
			TFT_FB_BASE_ADDR : in std_logic_vector(11 downto 0);
			TFT_ON : in std_logic;
			
         TFT_IIC_SCL_I : IN  std_logic;
         TFT_IIC_SCL_O : OUT  std_logic;
         TFT_IIC_SCL_T : OUT  std_logic;
         TFT_IIC_SDA_I : IN  std_logic;
         TFT_IIC_SDA_O : OUT  std_logic;
         TFT_IIC_SDA_T : OUT  std_logic
        );
    END COMPONENT;
	 

	-- TFT Controller Outputs / inputs
	signal TFT_IIC_SCL_O : std_logic;
	signal TFT_IIC_SDA_O : std_logic;
	signal TFT_VGA_R, TFT_VGA_G, TFT_VGA_B : std_logic_vector(5 downto 0);
	signal TFT_VGA_CLK : std_logic;
	
	signal TFT_IIC_SCL_I : std_logic := '0';
	signal TFT_IIC_SDA_I : std_logic := '0';
	
	-- DDR2 signals
	signal Rd_Req           : std_logic;
	signal Rd_Addr          : std_logic_vector(31 downto 0);
	signal Rd_eof_n         : std_logic;
	
BEGIN
	
	DVI_RESET_B <= not rst;   -- active low reset for Chrontel chip


	disp_ddr2app_cmd.af_cmd <= "001";
	disp_ddr2app_cmd.af_addr <= Rd_Addr(30 downto 0);
	disp_ddr2app_cmd.af_wren <= Rd_req;
	disp_ddr2app_cmd.wdf_data <= (others => '0');
	disp_ddr2app_cmd.wdf_mask_data <= (others => '0');
	disp_ddr2app_cmd.wdf_wren <= '0';

	-- The TFT controller woud like an EOF signal every other successful read transaction
	process(clk200, rst)
	begin
		if(rst='1') then
			Rd_eof_n <= '0';
		elsif (rising_edge(clk200)) then
         if (disp_ddr2app_data_valid = '1') then
				Rd_eof_n <= not Rd_eof_n;
			end if;
      end if;
	end process;

	
   tft_cont: tft_controller 
	  PORT MAP (
             sys_clk => clk200, 
	          sys_rst => rst,
				 clk100	=> clk100,
			 
	          Rd_req_af => disp_ddr2app_af_afull,
	          Rd_Req => Rd_Req,
				 Rd_start_line => disp_Rd_start_line,
	          Rd_Addr => Rd_Addr,
	          Rd_eof_n => Rd_eof_n,
	          Rd_data_in => disp_ddr2app_data_in,
	          Rd_data_in_valid => disp_ddr2app_data_valid,
			 
             SYS_TFT_Clk => clk100,
             TFT_HSYNC => DVI_HSYNC,
             TFT_VSYNC => DVI_VSYNC,
             TFT_DE => DVI_DE,
             TFT_VGA_CLK => TFT_VGA_CLK,
             TFT_VGA_R => TFT_VGA_R,
             TFT_VGA_G => TFT_VGA_G,
             TFT_VGA_B => TFT_VGA_B,
             TFT_DVI_CLK_P => DVI_XCLK_P,
             TFT_DVI_CLK_N => DVI_XCLK_N,
             TFT_DVI_DATA => DVI_D,
	          TFT_FB_BASE_Addr => disp_fb_address, 
	          TFT_ON => '1',
			 			 
             TFT_IIC_SCL_I => TFT_IIC_SCL_I,
             TFT_IIC_SCL_O => TFT_IIC_SCL_O,
	          TFT_IIC_SCL_T => SCL,
             TFT_IIC_SDA_I => TFT_IIC_SDA_I,
             TFT_IIC_SDA_O => TFT_IIC_SDA_O,
             TFT_IIC_SDA_T => SDA);
		  
end behavior;
