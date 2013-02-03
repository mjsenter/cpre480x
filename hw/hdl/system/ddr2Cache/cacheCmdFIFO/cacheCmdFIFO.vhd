--------------------------------------------------------------------------------
--     This file is owned and controlled by Xilinx and must be used           --
--     solely for design, simulation, implementation and creation of          --
--     design files limited to Xilinx devices or technologies. Use            --
--     with non-Xilinx devices or technologies is expressly prohibited        --
--     and immediately terminates your license.                               --
--                                                                            --
--     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"          --
--     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR                --
--     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION        --
--     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION            --
--     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS              --
--     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,                --
--     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE       --
--     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY               --
--     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE                --
--     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR         --
--     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF        --
--     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS        --
--     FOR A PARTICULAR PURPOSE.                                              --
--                                                                            --
--     Xilinx products are not intended for use in life support               --
--     appliances, devices, or systems. Use in such applications are          --
--     expressly prohibited.                                                  --
--                                                                            --
--     (c) Copyright 1995-2009 Xilinx, Inc.                                   --
--     All rights reserved.                                                   --
--------------------------------------------------------------------------------
-- You must compile the wrapper file cacheCmdFIFO.vhd when simulating
-- the core, cacheCmdFIFO. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

-- The synthesis directives "translate_off/translate_on" specified
-- below are supported by Xilinx, Mentor Graphics and Synplicity
-- synthesis tools. Ensure they are correct for your synthesis tool(s).

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- synthesis translate_off
Library XilinxCoreLib;
-- synthesis translate_on
ENTITY cacheCmdFIFO IS
	port (
	rst: IN std_logic;
	wr_clk: IN std_logic;
	rd_clk: IN std_logic;
	din: IN std_logic_VECTOR(66 downto 0);
	wr_en: IN std_logic;
	rd_en: IN std_logic;
	dout: OUT std_logic_VECTOR(66 downto 0);
	full: OUT std_logic;
	almost_full: OUT std_logic;
	empty: OUT std_logic;
	almost_empty: OUT std_logic;
	valid: OUT std_logic);
END cacheCmdFIFO;

ARCHITECTURE cacheCmdFIFO_a OF cacheCmdFIFO IS
-- synthesis translate_off
component wrapped_cacheCmdFIFO
	port (
	rst: IN std_logic;
	wr_clk: IN std_logic;
	rd_clk: IN std_logic;
	din: IN std_logic_VECTOR(66 downto 0);
	wr_en: IN std_logic;
	rd_en: IN std_logic;
	dout: OUT std_logic_VECTOR(66 downto 0);
	full: OUT std_logic;
	almost_full: OUT std_logic;
	empty: OUT std_logic;
	almost_empty: OUT std_logic;
	valid: OUT std_logic);
end component;

-- Configuration specification 
	for all : wrapped_cacheCmdFIFO use entity XilinxCoreLib.fifo_generator_v6_2(behavioral)
		generic map(
			c_has_int_clk => 0,
			c_wr_response_latency => 1,
			c_rd_freq => 1,
			c_has_srst => 0,
			c_enable_rst_sync => 1,
			c_has_rd_data_count => 0,
			c_din_width => 67,
			c_has_wr_data_count => 0,
			c_full_flags_rst_val => 1,
			c_implementation_type => 2,
			c_family => "virtex5",
			c_use_embedded_reg => 0,
			c_has_wr_rst => 0,
			c_wr_freq => 1,
			c_use_dout_rst => 1,
			c_underflow_low => 0,
			c_has_meminit_file => 0,
			c_has_overflow => 0,
			c_preload_latency => 0,
			c_dout_width => 67,
			c_msgon_val => 0,
			c_rd_depth => 64,
			c_default_value => "BlankString",
			c_mif_file_name => "BlankString",
			c_error_injection_type => 0,
			c_has_underflow => 0,
			c_has_rd_rst => 0,
			c_has_almost_full => 1,
			c_has_rst => 1,
			c_data_count_width => 6,
			c_has_wr_ack => 0,
			c_use_ecc => 0,
			c_wr_ack_low => 0,
			c_common_clock => 0,
			c_rd_pntr_width => 6,
			c_use_fwft_data_count => 0,
			c_has_almost_empty => 1,
			c_rd_data_count_width => 6,
			c_enable_rlocs => 0,
			c_wr_pntr_width => 6,
			c_overflow_low => 0,
			c_prog_empty_type => 0,
			c_optimization_mode => 0,
			c_wr_data_count_width => 6,
			c_preload_regs => 1,
			c_dout_rst_val => "0",
			c_has_data_count => 0,
			c_prog_full_thresh_negate_val => 62,
			c_wr_depth => 64,
			c_prog_empty_thresh_negate_val => 5,
			c_prog_empty_thresh_assert_val => 4,
			c_has_valid => 1,
			c_init_wr_pntr_val => 0,
			c_prog_full_thresh_assert_val => 63,
			c_use_fifo16_flags => 0,
			c_has_backup => 0,
			c_valid_low => 0,
			c_prim_fifo_type => "512x72",
			c_count_type => 0,
			c_prog_full_type => 0,
			c_memory_type => 1);
-- synthesis translate_on
BEGIN
-- synthesis translate_off
U0 : wrapped_cacheCmdFIFO
		port map (
			rst => rst,
			wr_clk => wr_clk,
			rd_clk => rd_clk,
			din => din,
			wr_en => wr_en,
			rd_en => rd_en,
			dout => dout,
			full => full,
			almost_full => almost_full,
			empty => empty,
			almost_empty => almost_empty,
			valid => valid);
-- synthesis translate_on

END cacheCmdFIFO_a;

