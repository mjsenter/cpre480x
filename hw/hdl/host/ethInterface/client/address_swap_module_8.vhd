-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- address_swap_module_8.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the address swap module.
-- Contains portions (c) Copyright 2004-2010 Xilinx, Inc. All rights reserved.
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use WORK.SGP_config.all;

entity address_swap_module_8 is
   port (
      rx_ll_clock             : in  std_logic; -- Input CLK from TRIMAC Reciever
      rx_ll_reset             : in  std_logic; -- Synchronous reset signal
      rx_ll_data_in_scn       : in  std_logic_vector(7 downto 0); -- Input data
      rx_ll_sof_in_n_scn      : in  std_logic; -- Input start of frame
      rx_ll_eof_in_n_scn      : in  std_logic; -- Input end of frame
      rx_ll_src_rdy_in_n_scn  : in  std_logic; -- Input source ready
      rx_ll_data_out          : out std_logic_vector(7 downto 0); -- Modified output data
      rx_ll_sof_out_n         : out std_logic; -- Output start of frame
      rx_ll_eof_out_n         : out std_logic; -- Output end of frame
      rx_ll_src_rdy_out_n     : out std_logic; -- Output source ready

		--FIFO Interface
	   clk100                  : in std_logic;
		hostPacketFIFORead	   : out hostPacketFIFORead_t;				
		hostPacketFIFOReadEn    : in std_logic;

      flow_ctr_flag           : out std_logic;
      rx_ll_dst_rdy_in_n_scn  : in  std_logic;  -- Input destination ready
		
		overflow					 : out std_logic
      );

end address_swap_module_8;

architecture arch1 of address_swap_module_8 is


   component udpRead
   port (
        -- input
      rx_ll_clock             : in  std_logic;                     -- Input CLK from MAC Reciever
      rx_ll_reset             : in  std_logic;                     -- Synchronous reset signal
      rx_ll_data_in_scn       : in  std_logic_vector(7 downto 0);  -- Input data
      rx_ll_sof_in_n_scn      : in  std_logic;                     -- Input start of frame
      rx_ll_eof_in_n_scn      : in  std_logic;                     -- Input end of frame
      rx_ll_src_rdy_in_n_scn  : in  std_logic;                     -- Input source ready
      rx_ll_dst_rdy_in_n_scn  : in  std_logic;                      -- Input destination ready

		--FIFO Interface
	   clk100                  : in std_logic;
		hostPacketFIFORead	   : out hostPacketFIFORead_t;				
		hostPacketFIFOReadEn    : in std_logic;

        --output
      flow_ctr_flag           : out std_logic;
      rx_ll_data_in           : out  std_logic_vector(7 downto 0);  -- Input data
      rx_ll_sof_in_n          : out  std_logic;                     -- Input start of frame
      rx_ll_eof_in_n          : out  std_logic;                     -- Input end of frame
      rx_ll_src_rdy_in_n      : out  std_logic;                     -- Input source ready
      rx_ll_dst_rdy_in_n      : out  std_logic;                      -- Input destination ready
		
		overflow					 : out std_logic
      );
   end component;


  
   --Signal declarations
   signal sel_delay_path   : std_logic;   -- controls mux in Process data_out_mux
   signal enable_data_sr   : std_logic;   -- clock enable for data shift register
   signal data_sr5         : std_logic_vector(7 downto 0);  -- data after 6 cycle delay
   signal mux_out          : std_logic_vector(7 downto 0);  -- data to output register
   signal rx_enable        : std_logic;
   
   
   --fsm type and signals
   type state_type is (wait_sf,
                       bypass_sa1,
                       bypass_sa2,
                       bypass_sa3,
                       bypass_sa4,
                       bypass_sa5,
                       bypass_sa6,
                       pass_rof);

   signal control_fsm_state : state_type;  -- holds state of control fsm

   --6 stage shift register type and signals
   type   sr6by8 is array (0 to 5) of std_logic_vector(7 downto 0);
   signal data_sr_content : sr6by8;  -- holds contents of data sr

   --7 stage shift register type and signals
   type   sr7by1 is array (0 to 6) of std_logic;
   signal eof_sr_content   : sr7by1;  -- holds contents of end of frame sr
   signal sof_sr_content   : sr7by1;  -- holds contents of start of frame sr
   signal rdy_sr_content   : sr7by1;

    -- Small delay for simulation purposes.
   constant dly : time := 1 ps;

   -- MP2 scanner output signals (Note: inputs come directly from the entity)
   signal rx_ll_data_in      : std_logic_vector(7 downto 0);
   signal rx_ll_sof_in_n     : std_logic;
   signal rx_ll_eof_in_n     : std_logic;
   signal rx_ll_src_rdy_in_n : std_logic;
   signal rx_ll_dst_rdy_in_n : std_logic;



begin  -- arch1


   ---------------------------------------------------------------------
   --  Instatiate udpRead module
   ---------------------------------------------------------------------
   u_udpRead : udpRead
      port map (
        -- inputs
        rx_ll_clock              => rx_ll_clock,
        rx_ll_reset              => rx_ll_reset,
        rx_ll_data_in_scn        => rx_ll_data_in_scn,
        rx_ll_sof_in_n_scn       => rx_ll_sof_in_n_scn,
        rx_ll_eof_in_n_scn       => rx_ll_eof_in_n_scn,
        rx_ll_src_rdy_in_n_scn   => rx_ll_src_rdy_in_n_scn,
        rx_ll_dst_rdy_in_n_scn   => rx_ll_dst_rdy_in_n_scn,

		  --FIFO Interface
	     clk100                  => clk100,
		  hostPacketFIFORead	     => hostPacketFIFORead,				
		  hostPacketFIFOReadEn    => hostPacketFIFOReadEn,

        -- outputs
        flow_ctr_flag       => flow_ctr_flag,
        rx_ll_data_in       => rx_ll_data_in,
        rx_ll_sof_in_n      => rx_ll_sof_in_n,
        rx_ll_eof_in_n      => rx_ll_eof_in_n,
        rx_ll_src_rdy_in_n  => rx_ll_src_rdy_in_n,
        rx_ll_dst_rdy_in_n  => rx_ll_dst_rdy_in_n,
		  
		  overflow			    => overflow);


   ----------------------------------------------------------------------------
   --Process data_sr_p
   --A six stage shift register to hold six bytes of incoming data.
   --Clock enable signal enable_data_sr allows destination address to be stored
   --in shift register while the source address is being transmitted.
   ----------------------------------------------------------------------------
   data_sr_p : process(rx_ll_clock)
   begin
      if rising_edge(rx_ll_clock) then
         if enable_data_sr = '1' and rx_enable = '1' then
             data_sr_content <= rx_ll_data_in & data_sr_content (0 to 4);
         end if;
      end if;
   end process;  -- data_sr_p
   data_sr5 <= data_sr_content(5);
   

   ----------------------------------------------------------------------------
   --Process data_out_mux_p
   --Selects data_out from the data shift register or from data_in, allowing
   --destination address to be bypassed
   ----------------------------------------------------------------------------
   data_out_mux_p : process(rx_ll_data_in, data_sr5, sel_delay_path)
   begin
      if sel_delay_path = '1' then
         mux_out <= rx_ll_data_in;
      else
         mux_out <= data_sr5;
      end if;
   end process;  -- data_out_mux_p


   ----------------------------------------------------------------------------
   --Process data_out_reg_p
   --Registers data output from output mux
   ----------------------------------------------------------------------------
   data_out_reg_p : process(rx_ll_clock)
   begin
      if rising_edge(rx_ll_clock) then
        if rx_enable = '1' then
          rx_ll_data_out <= mux_out after dly;
        end if;
      end if;
   end process;  -- data_out_reg_p

   rx_enable <= not(rx_ll_dst_rdy_in_n);

   ----------------------------------------------------------------------------
   --Process data_sof_sr_p
   --Delays start of frame by 7 clock cycles
   ----------------------------------------------------------------------------
   data_sof_sr_p : process(rx_ll_clock)
   begin
      if rising_edge(rx_ll_clock) then
        if rx_enable = '1' then
          sof_sr_content <= not rx_ll_sof_in_n & sof_sr_content(0 to 5);
        end if;
      end if;          
   end process;  -- data_sof_sr_p
   rx_ll_sof_out_n <= not sof_sr_content(6) after dly;

   ----------------------------------------------------------------------------
   --Process data_eof_sr_p
   --Delays end of frame by 7 clock cycles
   ----------------------------------------------------------------------------
   data_eof_sr_p : process(rx_ll_clock)
   begin
      if rising_edge(rx_ll_clock) then
        if rx_enable = '1' then
          eof_sr_content <= not rx_ll_eof_in_n & eof_sr_content(0 to 5);
        end if;
      end if;          
   end process;  -- data_eof_sr_p
   rx_ll_eof_out_n <= not eof_sr_content(6) after dly;

   ----------------------------------------------------------------------------
   --Process src_rdy_sr_p
   --Delays source ready by 7 clock cycles
   ----------------------------------------------------------------------------
   src_rdy_sr_p : process(rx_ll_clock)
   begin
      if rising_edge(rx_ll_clock) then
        if rx_enable = '1' then
           rdy_sr_content <= not rx_ll_src_rdy_in_n & rdy_sr_content(0 to 5);
        end if;
      end if;          
   end process;  -- src_rdy_sr_p
   rx_ll_src_rdy_out_n <= not rdy_sr_content(6) after dly;
   

   ----------------------------------------------------------------------------
   --Process control_fsm_sync_p
   --Synchronous update of next state of control_fsm
   ----------------------------------------------------------------------------
   control_fsm_sync_p : process(rx_ll_clock)
   begin
      if rising_edge(rx_ll_clock) then
         if rx_ll_reset = '1' then
            control_fsm_state <= wait_sf;
         else
           if rx_enable = '1' then
             case control_fsm_state is
                when wait_sf =>
                   if sof_sr_content(4) = '1' then
                      control_fsm_state <= bypass_sa1;
                   else
                      control_fsm_state <= wait_sf;
                   end if;

                when bypass_sa1 =>
                   if not(sof_sr_content(4) = '0' and eof_sr_content(4) = '1') then           
                      control_fsm_state <= bypass_sa2;
                   else
                      control_fsm_state <= wait_sf;
                   end if;

                when bypass_sa2 =>
                   if not(sof_sr_content(4) = '0' and eof_sr_content(4) = '1') then 
                      control_fsm_state <= bypass_sa3;
                   else
                      control_fsm_state <= wait_sf;
                   end if;
                   
                when bypass_sa3 =>
                   if not(sof_sr_content(4) = '0' and eof_sr_content(4) = '1') then 
                      control_fsm_state <= bypass_sa4;
                   else
                      control_fsm_state <= wait_sf;
                   end if;
                   
                when bypass_sa4 =>
                   if not(sof_sr_content(4) = '0' and eof_sr_content(4) = '1') then 
                      control_fsm_state <= bypass_sa5;
                   else
                      control_fsm_state <= wait_sf;
                   end if;
                   
                when bypass_sa5 =>
                   if not(sof_sr_content(4) = '0' and eof_sr_content(4) = '1') then 
                      control_fsm_state <= bypass_sa6;
                   else
                      control_fsm_state <= wait_sf;
                   end if;
                   
                when bypass_sa6 =>
                   if not(sof_sr_content(4) = '0' and eof_sr_content(4) = '1') then 
                      control_fsm_state <= pass_rof;
                   else
                      control_fsm_state <= wait_sf;
                   end if;
                   
                when pass_rof =>
                   if not(sof_sr_content(4) = '0' and eof_sr_content(4) = '1') then 
                      control_fsm_state <= pass_rof;
                   else
                      control_fsm_state <= wait_sf;
                   end if;

                when others =>
                   control_fsm_state <= wait_sf;

                end case;
             end if;
           end if;
      end if;
   end process;  -- control_fsm_sync_p


   ----------------------------------------------------------------------------
   --Process control_fsm_comb_p
   --Determines control signals from control_fsm state
   ----------------------------------------------------------------------------
   control_fsm_comb_p : process(control_fsm_state)
   begin
      case control_fsm_state is
         when wait_sf    => 
            sel_delay_path <= '0';  -- output data from data shift register
            enable_data_sr <= '1';  -- enable data to be loaded into shift register

         when bypass_sa1 => 
            sel_delay_path <= '1';  -- output data directly from input
            enable_data_sr <= '0';  -- hold current data in shift register

         when bypass_sa2 => 
            sel_delay_path <= '1';  -- output data directly from input
            enable_data_sr <= '0';  -- hold current data in shift register

         when bypass_sa3 => 
            sel_delay_path <= '1';  -- output data directly from input
            enable_data_sr <= '0';  -- hold current data in shift register

         when bypass_sa4 => 
            sel_delay_path <= '1';  -- output data directly from input
            enable_data_sr <= '0';  -- hold current data in shift register

         when bypass_sa5 => 
            sel_delay_path <= '1';  -- output data directly from input
            enable_data_sr <= '0';  -- hold current data in shift register

         when bypass_sa6 => 
            sel_delay_path <= '1';  -- output data directly from input
            enable_data_sr <= '0';  -- hold current data in shift register

         when pass_rof   => 
            sel_delay_path <= '0';  -- output data from data shift register
            enable_data_sr <= '1';  -- enable data to be loaded into shift register

         when others     => 
            sel_delay_path <= '0';
            enable_data_sr <= '1';

      end case;
   end process;  -- control_fsm_comb_p
   
end arch1;  --arch1

