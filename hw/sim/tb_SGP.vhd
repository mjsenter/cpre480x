-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- tb_SGP.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the main testbench for the simple
-- graphics processor. The ddr2 simulation module requires specific 
-- configuration variables to work correctly - those are currently
-- defined in SGP_config.vhd. 
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 7/30/10 by JAZ::Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;
use WORK.SGP_config.ALL;

entity tb_SGP is
generic (SIM_MEM_FAST    : boolean := false;
         SIM_INST_FAST   : boolean := true);
end entity tb_SGP;

architecture testbench of tb_SGP is

  
  component ddr2_model is
    port (
      ck      : in    std_logic;
      ck_n    : in    std_logic;
      cke     : in    std_logic;
      cs_n    : in    std_logic;
      ras_n   : in    std_logic;
      cas_n   : in    std_logic;
      we_n    : in    std_logic;
      dm_rdqs : inout std_logic_vector((DEVICE_WIDTH/16) downto 0);
      ba      : in    std_logic_vector((BANK_WIDTH - 1) downto 0);
      addr    : in    std_logic_vector((ROW_WIDTH - 1) downto 0);
      dq      : inout std_logic_vector((DEVICE_WIDTH - 1) downto 0);
      dqs     : inout std_logic_vector((DEVICE_WIDTH/16) downto 0);
      dqs_n   : inout std_logic_vector((DEVICE_WIDTH/16) downto 0);
      rdqs_n  : out   std_logic_vector((DEVICE_WIDTH/16) downto 0);
      odt     : in    std_logic
      );
  end component;

  component WireDelay
    generic (
      Delay_g : time;
      Delay_rd : time);
    port (
      A : inout Std_Logic;
      B : inout Std_Logic;
     reset : in Std_Logic);
  end component;
  
	-- Component used to send test data to
	-- uart_top for testing before placing
	-- uart_top on the FPGA
	
	component cpu_uart
	port
	(
	  clk                : in  std_logic;  -- system clock
	  rst                : in  std_logic;  -- Active low
	  rxd                : in  std_logic;
	  txd                : out std_logic
	);
	end component;	

  
	----------------------------------------------
	--      Signal declarations for DVI         --
	----------------------------------------------
  signal dvi_temp0					 : std_logic_vector(11 downto 0);
  signal dvi_temp1					 : std_logic;
  signal dvi_temp2					 : std_logic;
  signal dvi_temp3					 : std_logic;
  signal dvi_temp4					 : std_logic;
  signal dvi_temp5					 : std_logic;
  signal dvi_temp6					 : std_logic;
  signal dvi_temp7					 : std_logic;
  signal dvi_temp8					 : std_logic;  
  
	----------------------------------------------
	--      Signal declarations for UART        --
	----------------------------------------------
  signal uart_rst  			 : std_logic;   -- system clock  
  signal uart_txd	  			 : std_logic;   -- input to the uart
  signal uart_rxd 		  	 : std_logic;   -- output from the uart
  signal led							 : std_logic_vector(7 downto 0) := (others=>'0');
  
   ----------------------------------------------
	--      Signal declarations for clk         --
	----------------------------------------------  
  signal sys_clk                  : std_logic := '0';
  signal sys_clk_n                : std_logic;
  signal sys_clk_p                : std_logic;
  signal sys_clk200               : std_logic:= '0';
  signal clk200_n                 : std_logic;
  signal clk200_p                 : std_logic;
  signal clk100    			       : std_logic;
  signal sys_rst_n                : std_logic := '0';
  signal sys_rst_out              : std_logic;
  signal sys_rst_i                : std_logic;
  signal gnd                      : std_logic_vector(1 downto 0);



  signal ddr2_dq_sdram            : std_logic_vector((DQ_WIDTH - 1) downto 0);
  signal ddr2_dqs_sdram           : std_logic_vector((DQS_WIDTH - 1) downto 0);
  signal ddr2_dqs_n_sdram         : std_logic_vector((DQS_WIDTH - 1) downto 0);
  signal ddr2_dm_sdram            : std_logic_vector((DM_WIDTH - 1) downto 0);
  signal ddr2_clk_sdram           : std_logic_vector((CLK_WIDTH - 1) downto 0);
  signal ddr2_clk_n_sdram         : std_logic_vector((CLK_WIDTH - 1) downto 0);
  signal ddr2_address_sdram       : std_logic_vector((ROW_WIDTH - 1) downto 0);
  signal ddr2_ba_sdram            : std_logic_vector((BANK_WIDTH - 1) downto 0);
  signal ddr2_ras_n_sdram         : std_logic;
  signal ddr2_cas_n_sdram         : std_logic;
  signal ddr2_we_n_sdram          : std_logic;
  signal ddr2_cs_n_sdram          : std_logic_vector((CS_WIDTH - 1) downto 0);
  signal ddr2_cke_sdram           : std_logic_vector((CKE_WIDTH - 1) downto 0);
  signal ddr2_odt_sdram           : std_logic_vector((ODT_WIDTH - 1) downto 0);
  signal phy_reset                : std_logic;
  

  -- Only RDIMM memory parts support the reset signal,
  -- hence the ddr2_reset_n_sdram and ddr2_reset_n_fpga signals can be
  -- ignored for other memory parts
  signal ddr2_reset_n_sdram       : std_logic;
  signal ddr2_reset_n_fpga        : std_logic;
  signal ddr2_address_reg         : std_logic_vector((ROW_WIDTH - 1) downto 0);
  signal ddr2_ba_reg              : std_logic_vector((BANK_WIDTH - 1) downto 0);
  signal ddr2_cke_reg             : std_logic_vector((CKE_WIDTH - 1) downto 0);
  signal ddr2_ras_n_reg           : std_logic;
  signal ddr2_cas_n_reg           : std_logic;
  signal ddr2_we_n_reg            : std_logic;
  signal ddr2_cs_n_reg            : std_logic_vector((CS_WIDTH - 1) downto 0);
  signal ddr2_odt_reg             : std_logic_vector((ODT_WIDTH - 1) downto 0);

  signal dq_vector                : std_logic_vector(15 downto 0);
  signal dqs_vector               : std_logic_vector(1 downto 0);
  signal dqs_n_vector             : std_logic_vector(1 downto 0);
  signal dm_vector                : std_logic_vector(1 downto 0);
  signal command                  : std_logic_vector(2 downto 0);
  signal enable                   : std_logic;
  signal enable_o                 : std_logic;
  signal ddr2_dq_fpga             : std_logic_vector((DQ_WIDTH - 1) downto 0);
  signal ddr2_dqs_fpga            : std_logic_vector((DQS_WIDTH - 1) downto 0);
  signal ddr2_dqs_n_fpga          : std_logic_vector((DQS_WIDTH - 1) downto 0);
  signal ddr2_dm_fpga             : std_logic_vector((DM_WIDTH - 1) downto 0);
  signal ddr2_clk_fpga            : std_logic_vector((CLK_WIDTH - 1) downto 0);
  signal ddr2_clk_n_fpga          : std_logic_vector((CLK_WIDTH - 1) downto 0);
  signal ddr2_address_fpga        : std_logic_vector((ROW_WIDTH - 1) downto 0);
  signal ddr2_ba_fpga             : std_logic_vector((BANK_WIDTH - 1) downto 0);
  signal ddr2_ras_n_fpga          : std_logic;
  signal ddr2_cas_n_fpga          : std_logic;
  signal ddr2_we_n_fpga           : std_logic;
  signal ddr2_cs_n_fpga           : std_logic_vector((CS_WIDTH - 1) downto 0);
  signal ddr2_cke_fpga            : std_logic_vector((CKE_WIDTH - 1) downto 0);
  signal ddr2_odt_fpga            : std_logic_vector((ODT_WIDTH - 1) downto 0);
  	
begin
  gnd <= "00";
    uart_rst    <= not sys_rst_out;
  --***************************************************************************
   -- Clock generation and reset
   --***************************************************************************
  process
  begin
    sys_clk <= not sys_clk;
    wait for (TCYC_SYS_DIV2);
  end process;

   sys_clk_p <= sys_clk;
   sys_clk_n <= not sys_clk;

   process
   begin
     sys_clk200 <= not sys_clk200;
     wait for (TCYC_200);
   end process;

   clk200_p <= sys_clk200;
   clk200_n <= not sys_clk200;

   process
   begin
      sys_rst_n <= '0';
      wait for 200 ns;
      sys_rst_n <= '1';
      wait;
   end process;

  sys_rst_i   <=  not sys_rst_n;
  sys_rst_out <= (sys_rst_n) when (RST_ACT_LOW = 1) else (not sys_rst_n);

   -------------------------------------------
	--        UART testbench clock gen       --
	-------------------------------------------  
	clk100_gen : process
	begin
	  clk100  <= '0';
	  wait for 10 ns;
		 loop
			wait for 5 ns;
			clk100  <= '1';
			wait for 5 ns;
			clk100  <= '0';
		 end loop;
	end process clk100_gen ;
	
  u_SGP: entity work.SGP(structure) 
    generic map (
		--Do not change values here, but at top of this file!
	   SIM_MEM_FAST          => SIM_MEM_FAST,
		SIM_INST_FAST			 => SIM_INST_FAST
	 )
    port map (
      sys_clk_p         => sys_clk_p,
      sys_clk_n         => sys_clk_n,
      clk200_p          => clk200_p,
      clk200_n          => clk200_n,
		clk100				=> clk100,
      sys_rst_n         => sys_rst_out,
		
		
		-- ethernet ports
		TXP_0      			=> open,
		TXN_0             => open,
		RXP_0             => '1',
		RXN_0             => '0',
		MGTCLK_P          => clk200_p,
		MGTCLK_N          => clk200_n,
		PHY_RESET         => phy_reset,
		
  	   --UART ports
	   UART_TX           => uart_rxd,
	   UART_RX           => uart_txd,
	
      ddr2_ras_n        => ddr2_ras_n_fpga,
      ddr2_cas_n        => ddr2_cas_n_fpga,
      ddr2_we_n         => ddr2_we_n_fpga,
      ddr2_cs_n         => ddr2_cs_n_fpga,
      ddr2_cke          => ddr2_cke_fpga,
      ddr2_odt          => ddr2_odt_fpga,
      ddr2_dm           => ddr2_dm_fpga,
      ddr2_dq           => ddr2_dq_fpga,
      ddr2_dqs          => ddr2_dqs_fpga,
      ddr2_dqs_n        => ddr2_dqs_n_fpga,
      ddr2_ck           => ddr2_clk_fpga,
      ddr2_ck_n         => ddr2_clk_n_fpga,
      ddr2_ba           => ddr2_ba_fpga,
      ddr2_a            => ddr2_address_fpga,
		
		--DVI--		
		DVI_D 	  			=> dvi_temp0,
		DVI_XCLK_P 			=> dvi_temp1,
		DVI_XCLK_N 			=> dvi_temp2,
		DVI_HSYNC  			=> dvi_temp3,
		DVI_VSYNC  			=> dvi_temp4,
		DVI_DE     			=> dvi_temp5,
		DVI_RESET_B 		=> dvi_temp6,
		SDA  		   		=> dvi_temp7,
		SCL  					=> dvi_temp8		
  );
  
   -- This module should only be used if we're not using the traceInterface
	-- (set using SIM_INST_FAST)
	G1: if (not SIM_INST_FAST) generate
	  u_cpu_uart: cpu_uart 
	    port map(clk                => clk100,
	             rst                => uart_rst,
	             RXD                => uart_rxd,
	             TXD                => uart_txd);
   end generate;

  --***************************************************************************
  -- Delay insertion modules for each signal
  --***************************************************************************
  -- Use standard non-inertial (transport) delay mechanism for unidirectional
  -- signals from FPGA to SDRAM
  
  ddr2_address_sdram  <= TRANSPORT ddr2_address_fpga after TPROP_PCB_CTRL;
  ddr2_ba_sdram       <= TRANSPORT ddr2_ba_fpga      after TPROP_PCB_CTRL;
  ddr2_ras_n_sdram    <= TRANSPORT ddr2_ras_n_fpga   after TPROP_PCB_CTRL;
  ddr2_cas_n_sdram    <= TRANSPORT ddr2_cas_n_fpga   after TPROP_PCB_CTRL;
  ddr2_we_n_sdram     <= TRANSPORT ddr2_we_n_fpga    after TPROP_PCB_CTRL;
  ddr2_cs_n_sdram     <= TRANSPORT ddr2_cs_n_fpga    after TPROP_PCB_CTRL;
  ddr2_cke_sdram      <= TRANSPORT ddr2_cke_fpga     after TPROP_PCB_CTRL;
  ddr2_odt_sdram      <= TRANSPORT ddr2_odt_fpga     after TPROP_PCB_CTRL;
  ddr2_clk_sdram      <= TRANSPORT ddr2_clk_fpga     after TPROP_PCB_CTRL;
  ddr2_clk_n_sdram    <= TRANSPORT ddr2_clk_n_fpga   after TPROP_PCB_CTRL;
  ddr2_reset_n_sdram  <= TRANSPORT ddr2_reset_n_fpga after TPROP_PCB_CTRL;
  ddr2_dm_sdram       <= TRANSPORT ddr2_dm_fpga      after TPROP_PCB_DATA;

  dq_delay_sim_slow: if (not SIM_MEM_FAST) generate
  dq_delay: for i in 0 to DQ_WIDTH - 1 generate
    u_delay_dq: WireDelay
      generic map (
        Delay_g => TPROP_PCB_DATA,
        Delay_rd => TPROP_PCB_DATA_RD)
      port map(
        A => ddr2_dq_fpga(i),
        B => ddr2_dq_sdram(i),
        reset => sys_rst_n);
  end generate;
  end generate;
  
  dqs_delay_sim_slow: if (not SIM_MEM_FAST) generate
  dqs_delay: for i in 0 to DQS_WIDTH - 1 generate
    u_delay_dqs: WireDelay
      generic map (
        Delay_g => TPROP_DQS,
        Delay_rd => TPROP_DQS_RD)
      port map(
        A => ddr2_dqs_fpga(i),
        B => ddr2_dqs_sdram(i),
        reset => sys_rst_n);
  end generate;
  end generate;
  
  dqs_n_delay_sim_slow: if (not SIM_MEM_FAST) generate
  dqs_n_delay: for i in 0 to DQS_WIDTH - 1 generate
    u_delay_dqs: WireDelay
      generic map (
        Delay_g => TPROP_DQS,
        Delay_rd => TPROP_DQS_RD)
      port map(
        A => ddr2_dqs_n_fpga(i),
        B => ddr2_dqs_n_sdram(i),
        reset => sys_rst_n);
  end generate;
  end generate;
  
  
  -- Extra one clock pipelining for RDIMM address and
  -- control signals is implemented here (Implemented external to memory model)
  process (ddr2_clk_sdram)
  begin
    if (rising_edge(ddr2_clk_sdram(0))) then
      if ( ddr2_reset_n_sdram = '0' ) then
        ddr2_ras_n_reg    <= '1';
        ddr2_cas_n_reg    <= '1';
        ddr2_we_n_reg     <= '1';
        ddr2_cs_n_reg     <= (others => '1');
        ddr2_odt_reg      <= (others => '0');
      else
        ddr2_address_reg  <= TRANSPORT ddr2_address_sdram after TCYC_SYS_DIV2;
        ddr2_ba_reg       <= TRANSPORT ddr2_ba_sdram      after TCYC_SYS_DIV2;
        ddr2_ras_n_reg    <= TRANSPORT ddr2_ras_n_sdram   after TCYC_SYS_DIV2;
        ddr2_cas_n_reg    <= TRANSPORT ddr2_cas_n_sdram   after TCYC_SYS_DIV2;
        ddr2_we_n_reg     <= TRANSPORT ddr2_we_n_sdram    after TCYC_SYS_DIV2;
        ddr2_cs_n_reg     <= TRANSPORT ddr2_cs_n_sdram    after TCYC_SYS_DIV2;
        ddr2_odt_reg      <= TRANSPORT ddr2_odt_sdram     after TCYC_SYS_DIV2;
      end if;
    end if;
  end process;

  -- to avoid tIS violations on CKE when reset is deasserted
  process (ddr2_clk_n_sdram)
  begin
    if (rising_edge(ddr2_clk_n_sdram(0))) then
      if ( ddr2_reset_n_sdram = '0' ) then
        ddr2_cke_reg      <= (others => '0');
      else
        ddr2_cke_reg      <= TRANSPORT ddr2_cke_sdram after TCYC_SYS_0;
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Memory model instances
  --***************************************************************************
  
  comp_16: if ((DEVICE_WIDTH = 16) and (not SIM_MEM_FAST)) generate	 
    comp16_mul16: if (((DQ_WIDTH mod 16) = 0) and (REG_ENABLE = 0)) generate
      -- if the data width is multiple of 16
      gen_cs: for j in 0 to (CS_NUM - 1) generate
        gen: for i in 0 to ((DQS_WIDTH/2) - 1) generate
          u_mem0: ddr2_model
            port map (
              ck        => ddr2_clk_sdram(CLK_WIDTH*i/DQS_WIDTH),
              ck_n      => ddr2_clk_n_sdram(CLK_WIDTH*i/DQS_WIDTH),
              cke       => ddr2_cke_sdram(j),
              cs_n      => ddr2_cs_n_sdram(CS_WIDTH*i/DQS_WIDTH),
              ras_n     => ddr2_ras_n_sdram,
              cas_n     => ddr2_cas_n_sdram,
              we_n      => ddr2_we_n_sdram,
              dm_rdqs   => ddr2_dm_sdram((2*(i+1))-1 downto i*2),
              ba        => ddr2_ba_sdram,
              addr      => ddr2_address_sdram,
              dq        => ddr2_dq_sdram((16*(i+1))-1 downto i*16),
              dqs       => ddr2_dqs_sdram((2*(i+1))-1 downto i*2),
              dqs_n     => ddr2_dqs_n_sdram((2*(i+1))-1 downto i*2),
              rdqs_n    => open,
              odt       => ddr2_odt_sdram(ODT_WIDTH*i/DQS_WIDTH)
              );
        end generate gen;
      end generate gen_cs;
    end generate comp16_mul16;
  end generate comp_16;

end architecture testbench;