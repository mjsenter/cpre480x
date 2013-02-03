-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- ethInterface.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the ethernet interface module.
-- Contains portions (c) Copyright 2004-2010 Xilinx, Inc. All rights reserved.
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-------------------------------------------------------------------------
--
--
--    ---------------------------------------------------------------------
--    | EXAMPLE DESIGN WRAPPER                                            |
--    |           --------------------------------------------------------|
--    |           |LOCAL LINK WRAPPER                                     |
--    |           |              -----------------------------------------|
--    |           |              |BLOCK LEVEL WRAPPER                     |
--    |           |              |    ---------------------               |
--    | --------  |  ----------  |    | ETHERNET MAC      |               |
--    | |      |  |  |        |  |    | WRAPPER           |  ---------    |
--    | |      |->|->|        |--|--->| Tx            Tx  |--|       |--->|
--    | |      |  |  |        |  |    | client        PHY |  |       |    |
--    | | ADDR |  |  | LOCAL  |  |    | I/F           I/F |  |       |    |  
--    | | SWAP |  |  |  LINK  |  |    |                   |  | PHY   |    |
--    | |      |  |  |  FIFO  |  |    |                   |  | I/F   |    |
--    | |      |  |  |        |  |    |                   |  |       |    |
--    | |      |  |  |        |  |    | Rx            Rx  |  |       |    |
--    | |      |  |  |        |  |    | client        PHY |  |       |    |
--    | |      |<-|<-|        |<-|----| I/F           I/F |<-|       |<---|
--    | |      |  |  |        |  |    |                   |  ---------    |
--    | --------  |  ----------  |    ---------------------               |
--    |           |              -----------------------------------------|
--    |           --------------------------------------------------------|
--    ---------------------------------------------------------------------
--
-------------------------------------------------------------------------------


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.SGP_config.all;

entity ethInterface is
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
		   hostPacketFIFORead	  : out hostPacketFIFORead_t;				
		   hostPacketFIFOReadEn   : in std_logic;
			
			overflow					 : out std_logic);		  
end ethInterface;

architecture TOP_LEVEL of ethInterface is

-------------------------------------------------------------------------------
-- Component Declarations for lower hierarchial level entities
-------------------------------------------------------------------------------
  -- Component Declaration for the TEMAC wrapper with 
  -- Local Link FIFO.
  component v5_emac_v1_7_locallink is
   port(
      -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                       : out std_logic;
      -- 125MHz clock input from BUFG
      CLK125                           : in  std_logic;
      -- Tri-speed clock output from EMAC0
      CLIENT_CLK_OUT_0                 : out std_logic;
      -- EMAC0 Tri-speed clock input from BUFG
      client_clk_0                     : in  std_logic;

      -- Local link Receiver Interface - EMAC0
      RX_LL_CLOCK_0                   : in  std_logic; 
      RX_LL_RESET_0                   : in  std_logic;
      RX_LL_DATA_0                    : out std_logic_vector(7 downto 0);
      RX_LL_SOF_N_0                   : out std_logic;
      RX_LL_EOF_N_0                   : out std_logic;
      RX_LL_SRC_RDY_N_0               : out std_logic;
      RX_LL_DST_RDY_N_0               : in  std_logic;
      RX_LL_FIFO_STATUS_0             : out std_logic_vector(3 downto 0);

      -- Local link Transmitter Interface - EMAC0
      TX_LL_CLOCK_0                   : in  std_logic;
      TX_LL_RESET_0                   : in  std_logic;
      TX_LL_DATA_0                    : in  std_logic_vector(7 downto 0);
      TX_LL_SOF_N_0                   : in  std_logic;
      TX_LL_EOF_N_0                   : in  std_logic;
      TX_LL_SRC_RDY_N_0               : in  std_logic;
      TX_LL_DST_RDY_N_0               : out std_logic;

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        : out std_logic;
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                : out std_logic;

 
      -- Clock Signals - EMAC0

      -- SGMII Interface - EMAC0
      TXP_0                           : out std_logic;
      TXN_0                           : out std_logic;
      RXP_0                           : in  std_logic;
      RXN_0                           : in  std_logic;
      PHYAD_0                         : in  std_logic_vector(4 downto 0);
      RESETDONE_0                     : out std_logic;

      -- unused transceiver
      TXN_1_UNUSED                    : out std_logic;
      TXP_1_UNUSED                    : out std_logic;
      RXN_1_UNUSED                    : in  std_logic;
      RXP_1_UNUSED                    : in  std_logic;

      -- SGMII RocketIO Reference Clock buffer inputs 
      CLK_DS                          : in  std_logic;

      -- RocketIO Reset input
      GTRESET                         : in  std_logic;      

        
        
      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
  end component;
 
   ---------------------------------------------------------------------
   --  Component Declaration for 8-bit address swapping module
   ---------------------------------------------------------------------
   component address_swap_module_8
   port (
      rx_ll_clock             : in  std_logic;                     -- Input CLK from MAC Reciever
      rx_ll_reset             : in  std_logic;                     -- Synchronous reset signal
      rx_ll_data_in_scn       : in  std_logic_vector(7 downto 0);  -- Input data
      rx_ll_sof_in_n_scn      : in  std_logic;                     -- Input start of frame
      rx_ll_eof_in_n_scn      : in  std_logic;                     -- Input end of frame
      rx_ll_src_rdy_in_n_scn  : in  std_logic;                     -- Input source ready
      rx_ll_data_out          : out std_logic_vector(7 downto 0);  -- Modified output data
      rx_ll_sof_out_n         : out std_logic;                     -- Output start of frame
      rx_ll_eof_out_n         : out std_logic;                     -- Output end of frame
      rx_ll_src_rdy_out_n     : out std_logic;                     -- Output source ready

		--FIFO Interface
	   clk100                  : in std_logic;
		hostPacketFIFORead	   : out hostPacketFIFORead_t;				
		hostPacketFIFOReadEn    : in std_logic;

      -- Flow control
      flow_ctr_flag           : out std_logic; -- New, indicate MP2 FIFO almost full, send pause packet
      rx_ll_dst_rdy_in_n_scn  : in  std_logic;                      -- Input destination ready
		
		overflow					 : out std_logic
      );
   end component;

-----------------------------------------------------------------------
-- Signal Declarations
-----------------------------------------------------------------------

    -- Global asynchronous reset
    signal reset_i               : std_logic;

    -- client interface clocking signals - EMAC0
    signal ll_clk_0_i            : std_logic;

    -- address swap transmitter connections - EMAC0
    signal tx_ll_data_0_i      : std_logic_vector(7 downto 0);
    signal tx_ll_sof_n_0_i     : std_logic;
    signal tx_ll_eof_n_0_i     : std_logic;
    signal tx_ll_src_rdy_n_0_i : std_logic;
    signal tx_ll_dst_rdy_n_0_i : std_logic;

   -- address swap receiver connections - EMAC0
    signal rx_ll_data_0_i           : std_logic_vector(7 downto 0);
    signal rx_ll_sof_n_0_i          : std_logic;
    signal rx_ll_eof_n_0_i          : std_logic;
    signal rx_ll_src_rdy_n_0_i      : std_logic;
    signal rx_ll_dst_rdy_n_0_i      : std_logic;

    -- create a synchronous reset in the transmitter clock domain
    signal ll_pre_reset_0_i          : std_logic_vector(5 downto 0);
    signal ll_reset_0_i              : std_logic;

    attribute async_reg : string;
    attribute async_reg of ll_pre_reset_0_i : signal is "true";

    signal resetdone_0_i             : std_logic;


    -- EMAC0 Clocking signals

    -- Transceiver output clock (REFCLKOUT at 125MHz)
    signal clk125_o                  : std_logic;
    -- 125MHz clock input to wrappers
    signal clk125                    : std_logic;
    -- Input 125MHz differential clock for transceiver
    signal clk_ds                    : std_logic;

    -- 1.25/12.5/125MHz clock signals for tri-speed SGMII
    signal client_clk_0_o            : std_logic;
    signal client_clk_0              : std_logic;


    -- GT reset signal
   signal gtreset                    : std_logic;
   signal reset_r                    : std_logic_vector(3 downto 0);
   attribute async_reg of reset_r    : signal is "TRUE";

signal      EMAC0CLIENTRXDVLD               : std_logic;
signal      EMAC0CLIENTRXFRAMEDROP          : std_logic;
signal      EMAC0CLIENTRXSTATS              : std_logic_vector(6 downto 0);
signal      EMAC0CLIENTRXSTATSVLD           : std_logic;
signal     EMAC0CLIENTRXSTATSBYTEVLD       : std_logic;

      -- Client Transmitter Interface - EMAC0
signal      CLIENTEMAC0TXIFGDELAY           : std_logic_vector(7 downto 0);
signal      EMAC0CLIENTTXSTATS              : std_logic;
signal      EMAC0CLIENTTXSTATSVLD           : std_logic;
signal      EMAC0CLIENTTXSTATSBYTEVLD       : std_logic;

      -- MAC Control Interface - EMAC0
signal      CLIENTEMAC0PAUSEREQ             : std_logic;
signal      CLIENTEMAC0PAUSEVAL             : std_logic_vector(15 downto 0);

      --EMAC-MGT link status
signal      EMAC0CLIENTSYNCACQSTATUS        : std_logic;
      -- EMAC0 Interrupt
signal      EMAC0ANINTERRUPT                : std_logic;

signal      TXN_1_UNUSED                    : std_logic;
signal      TXP_1_UNUSED                    : std_logic;
signal      RXN_1_UNUSED                    : std_logic;
signal      RXP_1_UNUSED                    : std_logic;



signal PHYAD_0 : std_logic_vector(4 downto 0);
signal reset_inv : std_logic;

-- quick test flow control
signal flow_ctr_cnt : std_logic_vector(31 downto 0);
signal flow_ctr_flag : std_logic;
--signal flow_ctr_flag_test : std_logic;


-------------------------------------------------------------------------------
-- Main Body of Code
-------------------------------------------------------------------------------


begin


PHYAD_0 <= "00111"; -- phjones: Address for phy0

CLIENTEMAC0TXIFGDELAY   <= (others => '0');
CLIENTEMAC0PAUSEREQ     <= flow_ctr_flag; --or flow_ctr_flag_test; -- '0';
CLIENTEMAC0PAUSEVAL     <= (others => '1');   --(others => '0');
-- Note: change this value to modify wait frequency (currently at max value)



  
    ---------------------------------------------------------------------------
    -- Reset Input Buffer
    ---------------------------------------------------------------------------
--    reset_ibuf : BUFG port map (I => RESET, O => reset_i);  -- in MP2 IBUF

    reset_i <= rst;          -- phjones
    PHY_RESET <= not reset_i;  -- phjones

  
    -- EMAC0 Clocking

    -- Generate the clock input to the GTP
    -- clk_ds can be shared between multiple MAC instances.
    clkingen : IBUFDS port map (
      I  => MGTCLK_P,
      IB => MGTCLK_N,
      O  => clk_ds);

    -- 125MHz from transceiver is routed through a BUFG and 
    -- input to the MAC wrappers.
    -- This clock can be shared between multiple MAC instances.
    bufg_clk125 : BUFG port map (I => clk125_o, O => clk125);

    
    ll_clk_0_i <= clk125; 

    -- 1.25/12.5/125MHz clock from the MAC is routed through a BUFG and  
    -- input to the MAC wrappers to clock the client interface.
    bufg_client_0 : BUFG port map (I => client_clk_0_o, O => client_clk_0);

   --------------------------------------------------------------------
   -- RocketIO PMA reset circuitry
   --------------------------------------------------------------------
   process(reset_i, clk125)
   begin
     if (reset_i = '1') then
       reset_r <= "1111";
     elsif clk125'event and clk125 = '1' then
       reset_r <= reset_r(2 downto 0) & reset_i;
     end if;
   end process;
  
   gtreset <= reset_r(3);



    ------------------------------------------------------------------------
    -- Instantiate the EMAC Wrapper with LL FIFO 
    -- (v5_emac_v1_7_locallink.v)
    ------------------------------------------------------------------------
    v5_emac_ll : v5_emac_v1_7_locallink
    port map (
      -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                      => clk125_o,
      -- 125MHz clock input from BUFG
      CLK125                          => clk125,
      -- Tri-speed clock output from EMAC0
      CLIENT_CLK_OUT_0                => client_clk_0_o,
      -- EMAC0 Tri-speed clock input from BUFG
      CLIENT_CLK_0                    => client_clk_0,
      -- Local link Receiver Interface - EMAC0
      RX_LL_CLOCK_0                   => ll_clk_0_i,
      RX_LL_RESET_0                   => ll_reset_0_i,
      RX_LL_DATA_0                    => rx_ll_data_0_i,
      RX_LL_SOF_N_0                   => rx_ll_sof_n_0_i,
      RX_LL_EOF_N_0                   => rx_ll_eof_n_0_i,
      RX_LL_SRC_RDY_N_0               => rx_ll_src_rdy_n_0_i,
      RX_LL_DST_RDY_N_0               => rx_ll_dst_rdy_n_0_i,
      RX_LL_FIFO_STATUS_0             => open,

      -- Unused Receiver signals - EMAC0
      EMAC0CLIENTRXDVLD               => EMAC0CLIENTRXDVLD,
      EMAC0CLIENTRXFRAMEDROP          => EMAC0CLIENTRXFRAMEDROP,
      EMAC0CLIENTRXSTATS              => EMAC0CLIENTRXSTATS,
      EMAC0CLIENTRXSTATSVLD           => EMAC0CLIENTRXSTATSVLD,
      EMAC0CLIENTRXSTATSBYTEVLD       => EMAC0CLIENTRXSTATSBYTEVLD,

      -- Local link Transmitter Interface - EMAC0
      TX_LL_CLOCK_0                   => ll_clk_0_i,
      TX_LL_RESET_0                   => ll_reset_0_i,
      TX_LL_DATA_0                    => tx_ll_data_0_i,
      TX_LL_SOF_N_0                   => tx_ll_sof_n_0_i,
      TX_LL_EOF_N_0                   => tx_ll_eof_n_0_i,
      TX_LL_SRC_RDY_N_0               => tx_ll_src_rdy_n_0_i,
      TX_LL_DST_RDY_N_0               => tx_ll_dst_rdy_n_0_i,

      -- Unused Transmitter signals - EMAC0
      CLIENTEMAC0TXIFGDELAY           => CLIENTEMAC0TXIFGDELAY,
      EMAC0CLIENTTXSTATS              => EMAC0CLIENTTXSTATS,
      EMAC0CLIENTTXSTATSVLD           => EMAC0CLIENTTXSTATSVLD,
      EMAC0CLIENTTXSTATSBYTEVLD       => EMAC0CLIENTTXSTATSBYTEVLD,

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             => CLIENTEMAC0PAUSEREQ,
      CLIENTEMAC0PAUSEVAL             => CLIENTEMAC0PAUSEVAL,

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        => EMAC0CLIENTSYNCACQSTATUS,
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                => EMAC0ANINTERRUPT,

 
      -- Clock Signals - EMAC0
      -- SGMII Interface - EMAC0
      TXP_0                           => TXP_0,
      TXN_0                           => TXN_0,
      RXP_0                           => RXP_0,
      RXN_0                           => RXN_0,
      PHYAD_0                         => PHYAD_0,
      RESETDONE_0                     => resetdone_0_i,

      -- unused transceiver
      TXN_1_UNUSED                    => TXN_1_UNUSED,
      TXP_1_UNUSED                    => TXP_1_UNUSED,
      RXN_1_UNUSED                    => RXN_1_UNUSED,
      RXP_1_UNUSED                    => RXP_1_UNUSED,

      -- SGMII RocketIO Reference Clock buffer inputs 
      CLK_DS                          => clk_ds,

      -- RocketIO Reset input
      GTRESET                         => gtreset,

        
        
      -- Asynchronous Reset
      RESET                           => reset_i
    );

    ---------------------------------------------------------------------
    --  Instatiate the address swapping module
    ---------------------------------------------------------------------
    client_side_asm_emac0 : address_swap_module_8
      port map (
        rx_ll_clock             => ll_clk_0_i,
        rx_ll_reset             => ll_reset_0_i,
        rx_ll_data_in_scn       => rx_ll_data_0_i,
        rx_ll_sof_in_n_scn      => rx_ll_sof_n_0_i,
        rx_ll_eof_in_n_scn      => rx_ll_eof_n_0_i,
        rx_ll_src_rdy_in_n_scn  => rx_ll_src_rdy_n_0_i,
        rx_ll_data_out          => tx_ll_data_0_i,
        rx_ll_sof_out_n         => tx_ll_sof_n_0_i,
        rx_ll_eof_out_n         => tx_ll_eof_n_0_i,
        rx_ll_src_rdy_out_n     => tx_ll_src_rdy_n_0_i,

		  --FIFO Interface
	     clk100                  => clk100,
		  hostPacketFIFORead	     => hostPacketFIFORead,				
		  hostPacketFIFOReadEn    => hostPacketFIFOReadEn,

        flow_ctr_flag           => flow_ctr_flag,
        -- rx_ll_dst_rdy_in_n_scn  => tx_ll_dst_rdy_n_0_i,
        -- MLM
        rx_ll_dst_rdy_in_n_scn  => '0',
		  
		  overflow					  => overflow);

    -- rx_ll_dst_rdy_n_0_i     <= tx_ll_dst_rdy_n_0_i;
    -- MLM
    rx_ll_dst_rdy_n_0_i     <= '0';


    -- Create synchronous reset in the transmitter clock domain.
    gen_ll_reset_emac0 : process (ll_clk_0_i, reset_i)
    begin
      if reset_i = '1' then
        ll_pre_reset_0_i <= (others => '1');
        ll_reset_0_i     <= '1';
      elsif ll_clk_0_i'event and ll_clk_0_i = '1' then
      if resetdone_0_i = '1' then
        ll_pre_reset_0_i(0)          <= '0';
        ll_pre_reset_0_i(5 downto 1) <= ll_pre_reset_0_i(4 downto 0);
        ll_reset_0_i                 <= ll_pre_reset_0_i(5);
      end if;
      end if;
    end process gen_ll_reset_emac0;
 



 
end TOP_LEVEL;
