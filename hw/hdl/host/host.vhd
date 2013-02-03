-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- host.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the host module implementation.
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 11/15/10 by MAS::Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use WORK.SGP_config.all;

entity host is

	generic(SIM_INST_FAST	 : boolean);
   port (clk100  : in std_logic;
	 	   rst	  : in std_logic;
			  
			-- Connections to hostBus
			hostBusSlaves	   : in hostBusSlave_a(SGP_HOSTBUS_PES-1 downto 0);
			hostBusMaster  	: out hostBusMaster_t;
			  
         -- Ethernet ports
         TXP_0, TXN_0          : out std_logic;
         RXP_0, RXN_0          : in  std_logic;
         MGTCLK_P, MGTCLK_N    : in  std_logic;
         PHY_RESET             : out std_logic;

	      --UART ports
  	      UART_TX               : out std_logic;
	      UART_RX               : in  std_logic;
			
			overflow					 : out std_logic);

end host;


architecture structure of host is

   -- Ethernet Controller
  component ethInterface
    port(clk100                 : in std_logic;
	      rst                    : in std_logic; 

         -- SGMII Interface - EMAC0
         TXP_0                  : out std_logic;
         TXN_0                  : out std_logic;
         RXP_0                  : in  std_logic;
         RXN_0                  : in  std_logic;
         MGTCLK_P               : in  std_logic;
         MGTCLK_N               : in  std_logic;

        -- PHY_RESET
        PHY_RESET              : out std_logic;
	
		  --FIFO Interface
		  hostPacketFIFORead	   : out hostPacketFIFORead_t;				
		  hostPacketFIFOReadEn  : in std_logic;
		  
		  overflow					 : out std_logic);		  
  end component;


  -- UART Controller
  component uartInterface is
		port(clk100	: in std_logic;
			  rst		: in std_logic;
	
			  -- Serial Comm Lines
			  RxD		: in std_logic;
			  TxD		: out std_logic;
	
		     --FIFO Interface
			  hostPacketFIFORead_packet : out std_logic_vector(31 downto 0);
			  hostPacketFIFORead_valid  : out std_logic;
			  hostPacketFIFORead_empty  : out std_logic;
		     hostPacketFIFOReadEn      : in std_logic);		  
	end component;


	-- Simulation (trace) interface
	component traceInterface is
		port(clk100	: in std_logic;
			  rst		: in std_logic;
	
	        --FIFO Interface
			  hostPacketFIFORead_packet : out std_logic_vector(31 downto 0);
			  hostPacketFIFORead_valid  : out std_logic;
			  hostPacketFIFORead_empty  : out std_logic;			
		     hostPacketFIFOReadEn  : in std_logic);		  
	end component;


   component instrDispatch
	 generic (stallMask : std_logic_vector(SGP_HOSTBUS_PES-1 downto 0) := (others=>'1'));
    port (clk                  : in  std_logic;
          rst                  : in  std_logic;
			 enable_flow          : in std_logic;
			  
			 hostPacketFIFORead   : in hostPacketFIFORead_t;
			 hostPacketFIFOReadEn : out std_logic;
			  
			 -- General State
			 no_data			       : out std_logic;
			 hostBusValid		    : out std_logic;
			 
			 -- bus data
			 hostBusMaster 		 : out hostBusMaster_t;
			 hostBusSlaves 	    : in hostBusSlave_a(SGP_HOSTBUS_PES-1 downto 0));		 		 
   end component;


	constant ONES_MASK : std_logic_vector(SGP_HOSTBUS_PES-2 downto 0) := (others=>'1');
	
	-- Multiplixed FIFO signals
	signal uartHostPacketFIFORead    : hostPacketFIFORead_t;
   signal ethHostPacketFIFORead     : hostPacketFIFORead_t;
   signal instrPacketFIFORead       : hostPacketFIFORead_t;
   signal instrPacketFIFOReadEn     : std_logic;  
   signal memOpsPacketFIFOFull      : std_logic;
	signal memOpsPacketFIFOAFull     : std_logic;

   -- Multiplexed hostBus signals
	signal instrBusMaster  : hostBusMaster_t;

   -- Instruction dispatch flow control signals
	signal instrDispatch_no_data        : std_logic;
	signal instrDispatch_valid          : std_logic;


begin

  -- Instruction input over UART
  G1: if (not SIM_INST_FAST) generate
    u_uartInterface : uartInterface
		  port map(clk100	=> clk100,
			        rst		=> rst,
	
  			        -- Serial Comm Lines
			        RxD		=> UART_RX,
			        TxD		=> UART_TX,
	
		           --FIFO Interface
                 hostPacketFIFORead_packet => uartHostPacketFIFORead.packet,
                 hostPacketFIFORead_valid  => uartHostPacketFIFORead.valid,
                 hostPacketFIFORead_empty  => uartHostPacketFIFORead.empty,
		           hostPacketFIFOReadEn      => instrPacketFIFOReadEn);

  end generate;

  -- For simulation, read from a .sgb trace file
  G2: if (SIM_INST_FAST) generate
    u_traceInterface : traceInterface
		  port map(clk100	=> clk100,
			        rst		=> rst,
		
		           --FIFO Interface
                 hostPacketFIFORead_packet => uartHostPacketFIFORead.packet,
                 hostPacketFIFORead_valid  => uartHostPacketFIFORead.valid,
                 hostPacketFIFORead_empty  => uartHostPacketFIFORead.empty,			
		           hostPacketFIFOReadEn      => instrPacketFIFOReadEn);

  end generate;

  -- Ethernet interface
  u_ethInterface : ethInterface
    port map (clk100      => clk100,
	           rst         => rst,
				  TXP_0       => TXP_0,
				  TXN_0       => TXN_0,
				  RXP_0       => RXP_0,
				  RXN_0       => RXN_0,

              MGTCLK_P    =>  mgtclk_p,
              MGTCLK_N    =>  mgtclk_n,
              PHY_RESET   =>  PHY_RESET,

		        --FIFO Interface
		        hostPacketFIFORead	  => ethHostPacketFIFORead,			
		        hostPacketFIFOReadEn => instrPacketFIFOReadEn,
				  
				  overflow					=> overflow);


  -- Mux the output from the 2 possible hostPacketFIFOs
  instrPacketFIFORead.empty <= uartHostPacketFIFORead.empty and ethHostPacketFIFORead.empty;
  instrPacketFIFORead.valid <= uartHostPacketFIFORead.valid or ethHostPacketFIFORead.valid;
  instrPacketFIFORead.packet <= uartHostPacketFIFORead.packet when ethHostPacketFIFORead.valid = '0' and uartHostPacketFIFORead.valid = '1' else
                               ethHostPacketFIFORead.packet;


  -- instDispatch from the instrPacketFIFO
  u_instrDipatch : instrDispatch
    generic map (stallMask     => (others => '1'))
    port map    (clk           => clk100,
                 rst           => rst,
			        enable_flow   => '1', 
			  
			        hostPacketFIFORead   => instrPacketFIFORead, 
			        hostPacketFIFOReadEn => instrPacketFIFOReadEn,
			  
			        -- General State
			        no_data		  => instrDispatch_no_data,
			        hostBusValid	  => instrDispatch_valid,
			 
			        -- bus data
			        hostBusMaster  => instrBusMaster,
			        hostBusSlaves   => hostBusSlaves);		 		 
   

   -- Set the hostBusMaster to memOps output if there is valid data
	hostBusMaster <= instrBusMaster; 		 		 		  
				  
end structure;