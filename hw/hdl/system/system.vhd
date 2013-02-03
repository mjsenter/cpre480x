-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- system.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the system-level logic (e.g. ddr2Interface, 
-- memInit, dragon)
--
-- NOTES:
-- 1/20/11 by JAZ::Design created. 
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.SGP_config.all;

entity system is
   generic(
	   SIM_MEM_FAST    : boolean := false);
	port(
	   -- Clocks and reset
	   sys_clk_p, sys_clk_n  : in  std_logic;
      clk200_p, clk200_n    : in  std_logic;
	   clk100				    : in	 std_logic;
      sys_rst_n             : in  std_logic;


      -- Logic reset
		logic_rst             : out std_logic;

		-- ddr2Cache signals
		cacheRead             : out cacheRead_t;
		cacheCmd              : in cacheCmd_t;
		cacheCmdFIFO_empty    : out std_logic;
		cacheCmdFIFO_full     : out std_logic;
		
		-- Display buffer address
		disp_fb_address		 : in  std_logic_vector(FB_BASE_ADDRESS_BITS-1 downto 0);

	   -- DDR2 ports
	   ddr2_dq               : inout std_logic_vector((DQ_WIDTH-1) downto 0);
      ddr2_a                : out std_logic_vector((ROW_WIDTH-1) downto 0);
      ddr2_ba               : out std_logic_vector((BANK_WIDTH-1) downto 0);
      ddr2_ras_n            : out std_logic;
      ddr2_cas_n            : out std_logic;
      ddr2_we_n             : out std_logic;
      ddr2_cs_n             : out std_logic_vector((CS_WIDTH-1) downto 0);
      ddr2_odt              : out std_logic_vector((ODT_WIDTH-1) downto 0);
      ddr2_cke              : out std_logic_vector((CKE_WIDTH-1) downto 0);
      ddr2_dm               : out std_logic_vector((DM_WIDTH-1) downto 0);
      ddr2_dqs              : inout std_logic_vector((DQS_WIDTH-1) downto 0);
      ddr2_dqs_n            : inout std_logic_vector((DQS_WIDTH-1) downto 0);
      ddr2_ck               : out std_logic_vector((CLK_WIDTH-1) downto 0);
      ddr2_ck_n             : out std_logic_vector((CLK_WIDTH-1) downto 0);
	
	   --DVI signals
      DVI_D                 : out std_logic_vector(11 downto 0);
	   DVI_XCLK_P            : out std_logic;
	   DVI_XCLK_N            : out std_logic;
	   DVI_HSYNC             : out std_logic;
	   DVI_VSYNC             : out std_logic;
	   DVI_DE                : out std_logic;
	   DVI_RESET_B           : out std_logic;
	   SDA                   : out std_logic;
	   SCL                   : out std_logic);
end system;


architecture structure of system is


  component ddr2Cache 
    port ( clk100   	: in  std_logic;
	        clk200   	: in  std_logic;
			  rst			: in  std_logic;
			  
			  -- cache FIFO interfaces
			  cacheRead     : out cacheRead_t;
			  cacheCmd      : in  cacheCmd_t;
           cmdFIFO_full  : out std_logic;
           cmdFIFO_empty : out std_logic;
			  
			  -- DDR2 interface
			  ddr2_valid				: in std_logic;
			  ddr2_data_cmd			: out ddr2app_cmd;
			  ddr2_data					: in std_logic_vector(127 downto 0);
			  ddr2_rd_cmd				: in std_logic);
  end component;


  component ddr2Arbiter
    port(clk200             : in std_logic;
		   rst                : in std_logic;
			
			-- Signals to/from ddr2
		   arb_ddr2app_cmd  : out ddr2app_cmd;
			af_afull         : in std_logic;
			wdf_afull        : in std_logic;
			data_valid       : in std_logic;
				
			--Signals to/from user logic

			cmd_fifo_rd_en		: out std_logic;
			cmd_fifo_data_cmd	: in ddr2app_cmd;
			data_fifo_data_valid	: out std_logic;
				
			--Signals from display
			disp_ddr2app_af_afull	: out std_logic;
			disp_ddr2app_data_valid	: out std_logic;
			disp_ddr2app_cmd_in 		: in ddr2app_cmd;
			disp_Rd_start_line		: in std_logic;
				
			--Signals from mem init
			init_ddr2app_cmd     	: in ddr2app_cmd;
			init_done			   	: in std_logic);
  end component;

 
  component dispInterface

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
  end component;


  component memInit
    generic (INIT_COLOR			  : std_logic_vector(31 downto 0) := (others=>'0');
	    	    NUM_ROWS	        : integer := 2048;	-- 1280 goes to higher power 2 = 2048
		       NUM_COLS           : integer := 1024);
    port(clk200	              : in std_logic;
	      rst		              : in std_logic;
         init_ddr2app_af_afull  : in std_logic;
	      init_ddr2app_wdf_afull : in std_logic;
         init_ddr2app_cmd       : out ddr2app_cmd;
	      init_done			     : out std_logic);
   end component;


	component ddr2Interface is
		port (	-- DDR2 Signals to Memory Device
				ddr2_dq               : inout  std_logic_vector((DQ_WIDTH-1) downto 0);
				ddr2_a                : out   std_logic_vector((ROW_WIDTH-1) downto 0);
				ddr2_ba               : out   std_logic_vector((BANK_WIDTH-1) downto 0);
				ddr2_ras_n            : out   std_logic;
				ddr2_cas_n            : out   std_logic;
				ddr2_we_n             : out   std_logic;
				ddr2_cs_n             : out   std_logic_vector((CS_WIDTH-1) downto 0);
				ddr2_odt              : out   std_logic_vector((ODT_WIDTH-1) downto 0);
				ddr2_cke              : out   std_logic_vector((CKE_WIDTH-1) downto 0);
				ddr2_dm               : out   std_logic_vector((DM_WIDTH-1) downto 0);
				ddr2_dqs              : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
				ddr2_dqs_n            : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
				ddr2_ck               : out   std_logic_vector((CLK_WIDTH-1) downto 0);
				ddr2_ck_n             : out   std_logic_vector((CLK_WIDTH-1) downto 0);
		
		      -- System Clocks and Reset
				sys_clk_p             : in    std_logic;
				sys_clk_n             : in    std_logic;
				clk200_p              : in    std_logic;
				clk200_n              : in    std_logic;
				sys_rst_n             : in    std_logic;
	
 	         -- User Application
				app_af_addr           : in std_logic_vector(30 downto 0);
				app_af_cmd            : in std_logic_vector(2 downto 0);
				app_af_wren		       : in std_logic;
				app_wdf_data		    : in std_logic_vector(APPDATA_WIDTH-1 downto 0);
				app_wdf_mask_data	    : in std_logic_vector(APPDATA_WIDTH/8-1 downto 0);
				app_wdf_wren          : in std_logic;
				app_wdf_afull         : out std_logic;
				app_af_afull          : out std_logic;
				rd_data_valid         : out std_logic;
				rd_data_fifo_out      : out std_logic_vector(APPDATA_WIDTH-1 downto 0);
				ddr2_clk200           : out std_logic;
				ddr2_rst              : out std_logic;
				ddr2_init_done        : out std_logic);
	end component;


	component ddr2Interface_fast is
		port (	-- DDR2 Signals to Memory Device
				ddr2_dq               : inout  std_logic_vector((DQ_WIDTH-1) downto 0);
				ddr2_a                : out   std_logic_vector((ROW_WIDTH-1) downto 0);
				ddr2_ba               : out   std_logic_vector((BANK_WIDTH-1) downto 0);
				ddr2_ras_n            : out   std_logic;
				ddr2_cas_n            : out   std_logic;
				ddr2_we_n             : out   std_logic;
				ddr2_cs_n             : out   std_logic_vector((CS_WIDTH-1) downto 0);
				ddr2_odt              : out   std_logic_vector((ODT_WIDTH-1) downto 0);
				ddr2_cke              : out   std_logic_vector((CKE_WIDTH-1) downto 0);
				ddr2_dm               : out   std_logic_vector((DM_WIDTH-1) downto 0);
				ddr2_dqs              : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
				ddr2_dqs_n            : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
				ddr2_ck               : out   std_logic_vector((CLK_WIDTH-1) downto 0);
				ddr2_ck_n             : out   std_logic_vector((CLK_WIDTH-1) downto 0);
		
		      -- System Clocks and Reset
				sys_clk_p             : in    std_logic;
				sys_clk_n             : in    std_logic;
				clk200_p              : in    std_logic;
				clk200_n              : in    std_logic;
				sys_rst_n             : in    std_logic;
	
 	         -- User Application
				app_af_addr           : in std_logic_vector(30 downto 0);
				app_af_cmd            : in std_logic_vector(2 downto 0);
				app_af_wren		       : in std_logic;
				app_wdf_data		    : in std_logic_vector(APPDATA_WIDTH-1 downto 0);
				app_wdf_mask_data	    : in std_logic_vector(APPDATA_WIDTH/8-1 downto 0);
				app_wdf_wren          : in std_logic;
				app_wdf_afull         : out std_logic;
				app_af_afull          : out std_logic;
				rd_data_valid         : out std_logic;
				rd_data_fifo_out      : out std_logic_vector(APPDATA_WIDTH-1 downto 0);
				ddr2_clk200           : out std_logic;
				ddr2_rst              : out std_logic;
				ddr2_init_done        : out std_logic);
	end component;

	
	-- Clock and reset signals
	signal ddr2_clk200                       : std_logic;
	signal rst_logic, rst_logic_d1,rst_logic_d2, rst_init_hw, ddr2_rst  : std_logic;
	
	-- Done signals
	signal mem_init_done, mem_init_done_d1	  : std_logic;
   signal ddr2_done                         : std_logic;
	
   -- ddr2 interface and arbitration
   signal arb_ddr2app_cmd    	        : ddr2app_cmd;
	signal arb_ddr2app_wdf_afull       : std_logic;
	signal arb_ddr2app_af_afull        : std_logic;
	signal arb_ddr2app_data_valid      : std_logic;
	signal ddr2app_data_out            : std_logic_vector(2*DQ_WIDTH-1 downto 0);
	
	
	-- ddr2 cache signals
	signal data_fifo_data_valid	: std_logic;
	signal cmd_fifo_data_cmd      : ddr2app_cmd;
	signal cmd_fifo_rd_en	      : std_logic;
	
	-- Display Reads to arbitration
	signal disp_af_full, disp_data_valid : std_logic;
	signal disp_cmd                      : ddr2app_cmd;
	signal disp_Rd_start_line            : std_logic;
	
	-- Memory init to arbitration
	signal init_cmd			: ddr2app_cmd;

begin

  -- ==== Reset signals ====
  -- Connect system logic_rst signal to rst_logic
  logic_rst <= rst_logic;
  
  -- Reset Signals
  rst_init_hw <= (not sys_rst_n) or ddr2_rst or (not ddr2_done);
  rst_logic_d1 <= (not sys_rst_n) or rst_init_hw or (not mem_init_done_d1);
  rst_logic_d2 <= rst_logic_d1 when rising_edge(ddr2_clk200);
  rst_logic <= rst_logic_d2 when rising_edge(ddr2_clk200);


  u_ddr2Cache: ddr2Cache 
    port map( clk100   	         => clk100,
	        clk200   	            => ddr2_clk200,
			  rst			            => rst_init_hw,
			  
			  -- cache FIFO interfaces
			  cacheRead             => cacheRead,
			  cacheCmd              => cacheCmd,
           cmdFIFO_full          => cacheCmdFIFO_full,
           cmdFIFO_empty         => cacheCmdFIFO_empty,
			  
			  -- DDR2 interface
			  ddr2_valid				=> data_fifo_data_valid,
			  ddr2_data_cmd	      => cmd_fifo_data_cmd,
			  ddr2_data		         => ddr2app_data_out,
			  ddr2_rd_cmd		      => cmd_fifo_rd_en);


	 
  u_ddr2Arbiter:  ddr2Arbiter
		port map( -- Memory interface
				    clk200             => ddr2_clk200,
                rst                => rst_init_hw,		         
			
					 -- Signals to/from ddr2Interface
		          arb_ddr2app_cmd    => arb_ddr2app_cmd,
					 af_afull           => arb_ddr2app_af_afull,
					 wdf_afull          => arb_ddr2app_wdf_afull,
					 data_valid         => arb_ddr2app_data_valid,
					
					 -- Signals to/from ddr2Cache
					 cmd_fifo_rd_en		=> cmd_fifo_rd_en,
					 cmd_fifo_data_cmd	=> cmd_fifo_data_cmd,
					 data_fifo_data_valid	=> data_fifo_data_valid,
				
					 -- Signals from dispInterface
					 disp_ddr2app_af_afull		=> disp_af_full,
					 disp_ddr2app_data_valid	=> disp_data_valid,
					 disp_ddr2app_cmd_in			=> disp_cmd,
					 disp_Rd_start_line			=> disp_Rd_start_line,
					 
					 -- Signals from memInit
					 init_ddr2app_cmd			=> init_cmd,
					 init_done              => mem_init_done_d1);


  u_dispInterface: dispInterface
		port map( clk200 	  => ddr2_clk200,
					 clk100	  => clk100,
					 rst       => rst_logic,
						
					 -- DVI Signal Outputs
					 DVI_D 	    => DVI_D,
					 DVI_XCLK_P  => DVI_XCLK_P,
					 DVI_XCLK_N  => DVI_XCLK_N,
					 DVI_HSYNC   => DVI_HSYNC,
					 DVI_VSYNC   => DVI_VSYNC,
					 DVI_DE      => DVI_DE,
					 DVI_RESET_B => DVI_RESET_B,
					 SDA  		 => SDA,
					 SCL         => SCL,	

					 disp_ddr2app_af_afull		=> disp_af_full,
					 disp_ddr2app_data_valid	=> disp_data_valid,
					 disp_ddr2app_data_in		=> ddr2app_data_out,
					 disp_ddr2app_cmd  			=> disp_cmd,
					 disp_Rd_start_line			=> disp_Rd_start_line,
	  
					 -- High bits for fb address, support dynamic change
					 disp_fb_address		=> disp_fb_address);	


  u_memInit: memInit
		generic map (
				INIT_COLOR		=> x"00000000",
				NUM_ROWS			=> 2048,	--1280 goes to higher power of 2
				NUM_COLS			=> 4096 )
		port map (
		      clk200              => ddr2_clk200,
            rst                 => rst_init_hw,
            
			   init_ddr2app_af_afull	=> arb_ddr2app_af_afull,
				init_ddr2app_wdf_afull	=> arb_ddr2app_wdf_afull,
				init_ddr2app_cmd			=> init_cmd,

			   init_done           => mem_init_done);

				
	 mem_init_done_d1 <= mem_init_done when rising_edge(ddr2_clk200) else
							   mem_init_done_d1;


    -- Instantiate either the fast (for simulation) or the slow ddr2Interface module
    G1: if (not SIM_MEM_FAST) generate
     u_ddr2Interface: ddr2Interface   
		port map(	-- DDR2 Signals to Memory Device
					 ddr2_dq               => ddr2_dq,
					 ddr2_a                => ddr2_a, 
					 ddr2_ba               => ddr2_ba,
					 ddr2_ras_n            => ddr2_ras_n,
					 ddr2_cas_n            => ddr2_cas_n,
					 ddr2_we_n             => ddr2_we_n,
					 ddr2_cs_n             => ddr2_cs_n,
					 ddr2_odt              => ddr2_odt,
					 ddr2_cke              => ddr2_cke,
					 ddr2_dm               => ddr2_dm,
					 ddr2_dqs              => ddr2_dqs,
					 ddr2_dqs_n            => ddr2_dqs_n,
					 ddr2_ck               => ddr2_ck,
					 ddr2_ck_n             => ddr2_ck_n,
	 	
					 -- System Clocks and Reset
					 sys_clk_p             => sys_clk_p,
					 sys_clk_n             => sys_clk_n,
					 clk200_p              => clk200_p,
					 clk200_n              => clk200_n,
					 sys_rst_n             => sys_rst_n,

					 -- User Application
					 app_af_addr       => arb_ddr2app_cmd.af_addr,
					 app_af_cmd        => arb_ddr2app_cmd.af_cmd,
					 app_af_wren       => arb_ddr2app_cmd.af_wren,
					 app_wdf_data	    => arb_ddr2app_cmd.wdf_data,
					 app_wdf_mask_data => arb_ddr2app_cmd.wdf_mask_data,
					 app_wdf_wren		 => arb_ddr2app_cmd.wdf_wren,
					 app_wdf_afull		 => arb_ddr2app_wdf_afull,
					 app_af_afull		 => arb_ddr2app_af_afull,
					 rd_data_valid		 => arb_ddr2app_data_valid,
					 rd_data_fifo_out	 => ddr2app_data_out,
					 
					 ddr2_clk200		 => ddr2_clk200,
					 ddr2_rst			 => ddr2_rst,
					 ddr2_init_done    => ddr2_done);
    end generate;

    G2: if (SIM_MEM_FAST) generate
     u_ddr2Interface_fast: ddr2Interface_fast   
		port map(	-- DDR2 Signals to Memory Device
					 ddr2_dq               => ddr2_dq,
					 ddr2_a                => ddr2_a, 
					 ddr2_ba               => ddr2_ba,
					 ddr2_ras_n            => ddr2_ras_n,
					 ddr2_cas_n            => ddr2_cas_n,
					 ddr2_we_n             => ddr2_we_n,
					 ddr2_cs_n             => ddr2_cs_n,
					 ddr2_odt              => ddr2_odt,
					 ddr2_cke              => ddr2_cke,
					 ddr2_dm               => ddr2_dm,
					 ddr2_dqs              => ddr2_dqs,
					 ddr2_dqs_n            => ddr2_dqs_n,
					 ddr2_ck               => ddr2_ck,
					 ddr2_ck_n             => ddr2_ck_n,
	 	
					 -- System Clocks and Reset
					 sys_clk_p             => sys_clk_p,
					 sys_clk_n             => sys_clk_n,
					 clk200_p              => clk200_p,
					 clk200_n              => clk200_n,
					 sys_rst_n             => sys_rst_n,

					 -- User Application
					 app_af_addr       => arb_ddr2app_cmd.af_addr,
					 app_af_cmd        => arb_ddr2app_cmd.af_cmd,
					 app_af_wren       => arb_ddr2app_cmd.af_wren,
					 app_wdf_data	    => arb_ddr2app_cmd.wdf_data,
					 app_wdf_mask_data => arb_ddr2app_cmd.wdf_mask_data,
					 app_wdf_wren		 => arb_ddr2app_cmd.wdf_wren,
					 app_wdf_afull		 => arb_ddr2app_wdf_afull,
					 app_af_afull		 => arb_ddr2app_af_afull,
					 rd_data_valid		 => arb_ddr2app_data_valid,
					 rd_data_fifo_out	 => ddr2app_data_out,
					 
					 ddr2_clk200		 => ddr2_clk200,
					 ddr2_rst			 => ddr2_rst,
					 ddr2_init_done    => ddr2_done);
    end generate;


end structure;