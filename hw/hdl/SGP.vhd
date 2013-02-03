-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- SGP.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the top-level entity for the simple
-- graphics processor. 
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 7/30/10 by JAZ::Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.SGP_config.all;

entity SGP is
   generic(
	   -- Simulation speedup variables. Change in tb_SGP.vhd
	   SIM_MEM_FAST    : boolean := false;
	   SIM_INST_FAST	 : boolean := false);
	port(
	   -- Clocks and reset
	   sys_clk_p, sys_clk_n  : in  std_logic;
      clk200_p, clk200_n    : in  std_logic;
	   clk100				    : in	 std_logic;
      sys_rst_n             : in  std_logic;
	   debug_LED             : out std_logic_vector(2 downto 0);

      -- Ethernet ports
      TXP_0, TXN_0          : out std_logic;
      RXP_0, RXN_0          : in  std_logic;
      MGTCLK_P, MGTCLK_N    : in  std_logic;
      PHY_RESET             : out std_logic;

	   --UART ports
  	   UART_TX               : out std_logic;
	   UART_RX               : in  std_logic;

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
end SGP;


architecture structure of SGP is

  component host 
	  generic(SIM_INST_FAST	 : boolean);
     port (clk100  : in std_logic;
		 	  rst		 : in std_logic;
			  
			  -- Connections to hostBus
			  hostBusSlaves	   : in hostBusSlave_a(SGP_HOSTBUS_PES-1 downto 0);
			  hostBusMaster  		: out hostBusMaster_t;
			  			  
			  -- Ethernet ports
           TXP_0, TXN_0          : out std_logic;
           RXP_0, RXN_0          : in  std_logic;
           MGTCLK_P, MGTCLK_N    : in  std_logic;
           PHY_RESET             : out std_logic;

	        --UART ports
  	        UART_TX               : out std_logic;
	        UART_RX               : in  std_logic;
			  
			  overflow					 : out std_logic);
  end component;


  component memOps 
	  generic (BUS_ADDRESS : integer);
     port (clk100  : in std_logic;
		 	  rst		: in std_logic;
			  
			  -- Connections to hostBus
			  hostBusMaster 		: in hostBusMaster_t;
			  hostBusSlave	      : out hostBusSlave_t;
			  
			  -- Direct connections to texture unit
			  memOps_data			: out std_logic_vector(31 downto 0);
			  memOps_valid			: out std_logic;
			  memOps_count			: out std_logic_vector(31 downto 0);
			  memOps_full			: in std_logic;
			  
			  -- Connections to cacheArbiter
			  cacheArbiterReq    : out cacheArbiterReq_t;
			  cacheArbiterGrant  : in cacheArbiterGrant_t);
  end component;


  component graphicsPipe 
     port (clk100  : in std_logic;
		 	  rst		 : in std_logic;
			  
			  -- Connections to hostBus
			  hostBusMaster      : in hostBusMaster_t;
			  hostBusSlaves	   : out hostBusSlave_a(SGP_HOSTBUS_PES-2 downto 0);
			  			  
			  -- Connections to cacheArbiter
			  cacheArbiterReqs   : out cacheArbiterReq_a(0 to SGP_CACHEARB_PES-2);
			  cacheArbiterGrants : in cacheArbiterGrant_a(0 to SGP_CACHEARB_PES-2);
			  
			  -- Texture unit memory interface to cache
			  memOps_data			: in std_logic_vector(31 downto 0);
			  memOps_valid			: in std_logic;
			  memOps_count			: in std_logic_vector(31 downto 0);
			  memOps_full			: out std_logic;
			  
			  -- Display buffer address
			  disp_fb_address		: out std_logic_vector(FB_BASE_ADDRESS_BITS-1 downto 0);
			  
			  packetError    : out std_logic);
  end component;


  component cacheArbiter is
    port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
			  
			  -- cacheArbiter signals
			  cacheArbiterReqs   : in cacheArbiterReq_a(SGP_CACHEARB_PES-1 downto 0);
			  cacheArbiterGrants : out cacheArbiterGrant_a(SGP_CACHEARB_PES-1 downto 0);  
			  				
			  -- ddr2Cache signals
			  cacheRead          : in cacheRead_t;
			  cacheCmd           : out cacheCmd_t;
			  cacheCmdFIFO_empty : in std_logic;
			  cacheCmdFIFO_full  : in std_logic);
   end component;



  component system 
     generic(SIM_MEM_FAST    : boolean := false);
     port (-- System Clocks and Reset
	        clk100                : in std_logic;
           sys_clk_p             : in std_logic;
           sys_clk_n             : in std_logic;
           clk200_p              : in std_logic;
           clk200_n              : in std_logic;
           sys_rst_n             : in std_logic;

           -- Logic reset
			  logic_rst             : out std_logic;

			  -- ddr2Cache signals
			  cacheRead             : out cacheRead_t;
			  cacheCmd              : in cacheCmd_t;
			  cacheCmdFIFO_empty    : out std_logic;
			  cacheCmdFIFO_full     : out std_logic;
			  
			  -- Display buffer address
			  disp_fb_address		 	: in std_logic_vector(FB_BASE_ADDRESS_BITS-1 downto 0);

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
			  
   end component;

	-- Reset signals
	signal logic_rst  : std_logic;
	
	signal packetError : std_logic;

   -- hostBus signals
	signal hostBusSlaves : hostBusSlave_a(SGP_HOSTBUS_PES-1 downto 0);
   signal hostBusMaster : hostBusMaster_t;
   	
	-- memOps direct connection to host signals
   signal memOps_data, memOps_count : std_logic_vector(31 downto 0);
	signal memOps_valid, memOps_full : std_logic;

   -- cacheArbiter signals
	signal cacheArbiterReqs   : cacheArbiterReq_a(0 to SGP_CACHEARB_PES-1);
	signal cacheArbiterGrants : cacheArbiterGrant_a(0 to SGP_CACHEARB_PES-1);

	-- ddr2Cache signals
	signal cacheRead          : cacheRead_t;
	signal cacheCmd           : cacheCmd_t;
	signal cacheCmdFIFO_empty : std_logic;
	signal cacheCmdFIFO_full  : std_logic;
	
	-- Display buffer address
	signal disp_fb_address	  : std_logic_vector(FB_BASE_ADDRESS_BITS-1 downto 0);
		
begin


  -- Set LEDs to zero
  debug_LED(0) <= packetError;
  debug_LED(1) <= '0';
  

  -- Connect the host to the hostBus, memOps, and the communication pins  
  u_host: host
	  generic map(SIM_INST_FAST	 => SIM_INST_FAST)
     port map(clk100  				 => clk100,
		 	     rst		 				 => logic_rst,
			     
			     -- Connections to hostBus
			     hostBusSlaves	    => hostBusSlaves,
			     hostBusMaster  		 => hostBusMaster,
			  
              -- Ethernet ports
              TXP_0               => TXP_0, 
				  TXN_0               => TXN_0,
              RXP_0               => RXP_0,
				  RXN_0               => RXN_0,
              MGTCLK_P            => MGTCLK_P, 
				  MGTCLK_N            => MGTCLK_N,
              PHY_RESET           => PHY_RESET,

	           --UART ports
  	           UART_TX             => UART_TX,
	           UART_RX             => UART_RX,
				  
				  overflow				=> debug_LED(2));


  -- Connect the memOps to the host, the hostBus, and the cacheArbiter
  u_memOps: memOps
	  generic map(BUS_ADDRESS	    => MEMOPS_BUS_ADDRESS)
     port map(clk100                 => clk100,
		 	     rst		                => logic_rst,
			  
			     -- Connections to hostBus
			     hostBusMaster 		    => hostBusMaster,
			     hostBusSlave	          => hostBusSlaves(SGP_HOSTBUS_PES-1),
			  
			     -- Direct connections to texture unit in graphicsPipe
			     memOps_data			    => memOps_data,
			     memOps_valid			    => memOps_valid,
				  memOps_count				 => memOps_count,
			     memOps_full			    => memOps_full,
			  
			     -- Connections to cacheArbiter
			     cacheArbiterReq        => cacheArbiterReqs(0),
			     cacheArbiterGrant      => cacheArbiterGrants(0));


  -- Connect the graphicsPipe to the hostBus and the cacheArbiter
  u_graphicsPipe: graphicsPipe
     port map(clk100                 => clk100,
		 	     rst		                => logic_rst,
			  
			     -- Connections to hostBus
			     hostBusMaster          => hostBusMaster,
			     hostBusSlaves	       => hostBusSlaves(SGP_HOSTBUS_PES-2 downto 0),
			  
			     -- Connections to cacheArbiter
			     cacheArbiterReqs        => cacheArbiterReqs(1 to SGP_CACHEARB_PES-1),
			     cacheArbiterGrants      => cacheArbiterGrants(1 to SGP_CACHEARB_PES-1),
				  
				  -- Direct connections to texture unit in graphicsPipe
			     memOps_data			    => memOps_data,
			     memOps_valid			    => memOps_valid,
				  memOps_count				 => memOps_count,
			     memOps_full			    => memOps_full,
				  
				  -- Display buffer address
				  disp_fb_address		 	  => disp_fb_address,
				  
				  packetError    => packetError);


  -- Connect the cacheArbiter from the memOps and graphicsPIpe to the system logic
  u_cacheArbiter: cacheArbiter
     port map(clk                    => clk100,
              rst                    => logic_rst,
			  
			     -- cacheArbiter connectors signals
			     cacheArbiterReqs       => cacheArbiterReqs,
			     cacheArbiterGrants     => cacheArbiterGrants,
			  				
              -- ddr2Cache connectors
				  cacheRead             => cacheRead,
				  cacheCmd              => cacheCmd,
				  cacheCmdFIFO_empty    => cacheCmdFIFO_empty,
				  cacheCmdFIFO_full     => cacheCmdFIFO_full);
			

  -- Connect the system logic to the cacheArbiter lines and system pins
  u_system: system
	  generic map(SIM_MEM_FAST     => SIM_MEM_FAST)
     port map(-- System Clocks and Reset
	           clk100                => clk100,
              sys_clk_p             => sys_clk_p,
              sys_clk_n             => sys_clk_n,
              clk200_p              => clk200_p,
              clk200_n              => clk200_n,
              sys_rst_n             => sys_rst_n,

              -- Logic reset
			     logic_rst             => logic_rst,

              -- ddr2Cache connectors
				  cacheRead             => cacheRead,
				  cacheCmd              => cacheCmd,
				  cacheCmdFIFO_empty    => cacheCmdFIFO_empty,
				  cacheCmdFIFO_full     => cacheCmdFIFO_full,
				  
				  -- Display buffer address
				  disp_fb_address		 	=> disp_fb_address,
				  
	           -- DDR2 ports
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
	
	           --DVI signals
              DVI_D                 => DVI_D,
	           DVI_XCLK_P            => DVI_XCLK_P,
	           DVI_XCLK_N            => DVI_XCLK_N,
	           DVI_HSYNC             => DVI_HSYNC,
	           DVI_VSYNC             => DVI_VSYNC,
	           DVI_DE                => DVI_DE,
	           DVI_RESET_B           => DVI_RESET_B,
	           SDA                   => SDA,
	           SCL                   => SCL);
	
			
end structure;