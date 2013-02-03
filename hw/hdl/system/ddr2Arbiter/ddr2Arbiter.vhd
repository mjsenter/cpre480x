-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-- ddr2Arbiter.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file implements the arbitrator to shift the R/W
-- access to memory between uart, user_logic and dvi
-- 
-- NOTES:
-- 08/14/10 by MAS::Redesign to non standard arb
-- 07/30/10 by JAZ::Design created.
-------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use WORK.SGP_config.all;
 
ENTITY ddr2Arbiter is
    port(				
				clk200             : in std_logic;
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
		
end ddr2Arbiter;

architecture behavior of ddr2Arbiter is

	signal afull	: std_logic;
	signal zeroCmd : ddr2app_cmd;
	
	signal nextInstCmd, useCmdData : std_logic;
	signal cmd_fifo_valid : std_logic;
	signal userCntGet, userCntPut, dispCntGet, dispCntPut : std_logic_vector(10 downto 0);
	
	signal disp_ddr2app_cmd_d1, disp_ddr2app_cmd : ddr2app_cmd;
	signal disp_select	: std_logic;
	
	-- State defs
	signal state 		  : std_logic_vector(1 downto 0);
	constant USER_LOGIC : std_logic_vector(1 downto 0) := b"01";
	constant DISP		  : std_logic_vector(1 downto 0) := b"10";
	constant NO_STATE	  : std_logic_vector(1 downto 0) := b"00";

begin

   -- Buffer display command
	disp_ddr2app_cmd_d1 <= ddr2app_cmd_zero when rst='1' else
								  disp_ddr2app_cmd_in when rising_edge(clk200);
	
	-- Signal to select between input disp cmd and buffer cmd
	process(clk200, rst)
	begin
		if(rst='1') then
			disp_select <= '0';
		elsif(rising_edge(clk200)) then
			if((disp_Rd_start_line='1') and (nextInstCmd='1')) then
				disp_select <= '1';
			elsif(disp_Rd_start_line='1') then
				disp_select <= '0';
			elsif(disp_ddr2app_cmd_in.af_wren = '0') then
				disp_select <= '0';
			end if;
		end if;
	end process;
	
	disp_ddr2app_cmd <= disp_ddr2app_cmd_d1 when ((disp_select='1') or (nextInstCmd='1')) else
							  disp_ddr2app_cmd_in;
	
	-- end display command buffer


  cmd_fifo_valid <= cmd_fifo_data_cmd.wdf_wren or cmd_fifo_data_cmd.af_wren;

	afull <= af_afull or wdf_afull;
	disp_ddr2app_af_afull <= afull;
	
	zeroCmd.wdf_wren <= '0';
	zeroCmd.af_wren <= '0';
	zeroCmd.af_cmd <= (others =>'0');
	zeroCmd.af_addr <= (others =>'0');
	zeroCmd.wdf_mask_data <= (others =>'0');
	zeroCmd.wdf_data <= (others => '0');

   process(clk200)
	begin
--	  if(rst='1') then
--		  arb_ddr2app_cmd <= zeroCmd;
--		  nextInstCmd <= '0';
		if(rising_edge(clk200)) then
			if(init_done = '0' and afull ='0') then
				arb_ddr2app_cmd <= init_ddr2app_cmd;
				nextInstCmd <= '0';
			elsif(disp_ddr2app_cmd.af_wren = '1') then
			   arb_ddr2app_cmd <= disp_ddr2app_cmd;
				nextInstCmd <= '0';
			elsif(((afull = '0') or (nextInstCmd='1')) and cmd_fifo_valid='1') then
				arb_ddr2app_cmd <= cmd_fifo_data_cmd;
				if(cmd_fifo_data_cmd.af_wren = '1' and cmd_fifo_data_cmd.wdf_wren = '1') then
					nextInstCmd <= '1';
				else
					nextInstCmd <= '0';
				end if;
			else
				arb_ddr2app_cmd <= zeroCmd;
				nextInstCmd <= '0';
			end if;
	    end if;
	end process;

--	arb_ddr2app_cmd <= init_ddr2app_cmd when (init_done = '0' and afull = '0') else
--							 disp_ddr2app_cmd when (disp_ddr2app_cmd.af_wren = '1' and afull = '0') else
--							 cmd_fifo_data_cmd when (useCmdData = '1') else
--							 zeroCmd;
							 
	useCmdData <=  cmd_fifo_valid when nextInstCmd='1' else
						init_done and not afull and not disp_ddr2app_cmd.af_wren and cmd_fifo_valid;
	cmd_fifo_rd_en <= useCmdData; --  when (rising_edge(clk200));
--	nextInstCmd <= useCmdData and cmd_fifo_data_cmd.af_wren and cmd_fifo_data_cmd.wdf_wren; -- when (rising_edge(clk200));
							
							 
	-- Valid outputs
	data_fifo_data_valid <= data_valid when (state = USER_LOGIC) else
									'0';
									
	disp_ddr2app_data_valid <= data_valid when (state = DISP) else
										'0';
	process(clk200, rst)
   begin
      if(rst='1') then
			state <= NO_STATE;
		elsif(rising_edge(clk200) and (init_done = '1')) then
			if((dispCntPut=dispCntGet) and (userCntPut=userCntGet)) then
				state <= NO_STATE;
			elsif((dispCntPut=dispCntGet) or (data_valid = '1' and dispCntPut = dispCntGet+1)) then
				state <= USER_LOGIC;
			elsif((userCntPut=userCntGet) or (data_valid = '1' and userCntPut = userCntGet+1)) then
				state <= DISP;
			else
				state <= state;
			end if;
		end if;
	end process;
--	state <= NO_STATE when (rst = '1') or ((dispCntPut=dispCntGet) and (userCntPut=userCntGet)) else
--	         DISP when (userCntPut=userCntGet) else
--				USER_LOGIC when (dispCntPut=dispCntGet) else
--				state;
										
	-- state machine for data output from memory
	process(clk200, rst)
	begin
		if(rst='1') then
			dispCntPut <= (others=>'0');
		elsif (rising_edge(clk200) and (init_done = '1')) then
			--if(disp_Rd_start_line = '1' and disp_ddr2app_cmd.af_wren = '1' ) then
			--	dispCntPut <= b"00000000010";
			--elsif(disp_Rd_start_line = '1') then
			--	dispCntPut <= (others=>'0');
			if(disp_ddr2app_cmd.af_wren = '1'  ) then
				dispCntPut <= dispCntPut + 2;
			end if;
		end if;
	end process;
	
	process(clk200, rst)
	begin
		if(rst='1') then
			dispCntGet <= (others=>'0');
		elsif (rising_edge(clk200) and (init_done = '1')) then
			--if(disp_Rd_start_line = '1') then
			--	dispCntGet <= (others=>'0');
			if((data_valid = '1') and (state = DISP)) then
				dispCntGet <= dispCntGet + 1;
			end if;
		end if;
	end process;
	
	process(clk200, rst)
	begin
		if(rst='1') then
			userCntPut <= (others=>'0');
		elsif (rising_edge(clk200) and (init_done = '1')) then
			if(useCmdData = '1' and cmd_fifo_data_cmd.af_cmd(0) = '1') then
				userCntPut <= userCntPut + 2;
			end if;
		end if;
	end process;
	
	process(clk200, rst)
	begin
		if(rst='1') then
			userCntGet <= (others=>'0');
		elsif (rising_edge(clk200) and (init_done = '1')) then
			if((data_valid = '1') and (state = USER_LOGIC)) then
				userCntGet <= userCntGet + 1;
			end if;
		end if;
	end process;

end behavior;