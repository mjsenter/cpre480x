-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-- cacheArbiter.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file implements the arbiter and interface between
-- the memOps, graphicsPipe, and the ddr2cache.
-- 
-- NOTES:
-- 1/20/10 by MAS::Design created.
-------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.SGP_config.all;


entity cacheArbiter is
    port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
			  
			  -- cacheArbiter signals
			  cacheArbiterReqs   : in cacheArbiterReq_a(SGP_CACHEARB_PES-1 downto 0);
			  cacheArbiterGrants : out cacheArbiterGrant_a(SGP_CACHEARB_PES-1 downto 0);  
			  				
			  -- cache signals
			  cacheRead          : in cacheRead_t;
			  cacheCmd           : out cacheCmd_t;
			  cacheCmdFIFO_empty : in std_logic;
			  cacheCmdFIFO_full  : in std_logic);
end cacheArbiter;


architecture behavioral of cacheArbiter is

	type ARB_STATE_M is (INIT, GRANTED, WAIT_SWITCh, HOLD);
   signal arb_state : ARB_STATE_M;

	signal selectedPE : integer range 0 to SGP_CACHEARB_PES-1;	--  selectedPE = SGP_CACHEARB_PES => no PE selected
   signal switching : std_logic;	-- Switching between PEs but having to wait for read req to finish
	
	signal upCounter	: std_logic_vector(SGP_CACHEARB_PES-1 downto 0);
	signal mask			: std_logic_vector(SGP_CACHEARB_PES-1 downto 0);
	signal readCounter : std_logic_vector(31 downto 0);

begin

   -- send data/full from cache to all PEs.  (valid signal is arbitrated)
   cache_output_data: for i in 0 to SGP_CACHEARB_PES-1 generate
		cacheArbiterGrants(i).cacheRead.readData <= cacheRead.readData;
		cacheArbiterGrants(i).cacheRead.readValid <= cacheRead.readValid when selectedPE=i else '0';
		cacheArbiterGrants(i).arbGrant <= not switching and not cacheCmdFIFO_full when selectedPE=i and arb_state = GRANTED else '0';
	end generate cache_output_data;

	cacheCmd.address <= cacheArbiterReqs(selectedPE).cacheCmd.address;
	cacheCmd.writeData <= cacheArbiterReqs(selectedPE).cacheCmd.writeData;
	cacheCmd.rd_en <= cacheArbiterReqs(selectedPE).cacheCmd.rd_en;
	cacheCmd.wr_en <= cacheArbiterReqs(selectedPE).cacheCmd.wr_en;
	cacheCmd.flush <= cacheArbiterReqs(selectedPE).cacheCmd.flush;
	
	-- Counter code
   counter_up_logic: for i in 1 to SGP_CACHEARB_PES-1 generate
		upCounter(i) <= '0' when rst='1' else upCounter(i-1) when rising_edge(clk);
	end generate counter_up_logic;
	upCounter(0) <= '1' when rst='1' else
						 upCounter(SGP_CACHEARB_PES-1) when rising_edge(clk);
	
	-- and req vector with counter
   create_mask: for i in 0 to SGP_CACHEARB_PES-1 generate
		mask(i) <= cacheArbiterReqs(i).arbReq and upCounter(i);
	end generate create_mask;
	
	
	process(clk, rst)
	begin
		if(rst='1') then
			readCounter <= (others=>'0');
		elsif(rising_edge(clk)) then
--			if(arb_state = INIT) then
--				readCounter <= (others=>'0');
			if(cacheArbiterReqs(selectedPE).cacheCmd.rd_en = '1' and cacheCmdFIFO_full='0' and switching = '0' and cacheRead.readValid='0') then
				readCounter <= readCounter + 1;
			elsif((cacheArbiterReqs(selectedPE).cacheCmd.rd_en = '0' or cacheCmdFIFO_full='1') and cacheRead.readValid='1') then
				readCounter <= readCounter - 1;
			end if;
		end if;
	end process;
	
	process(clk, rst)
	begin
		if(rst='1') then
			selectedPE <= 0;
			switching <= '0';
			arb_state <= INIT;
		elsif(rising_edge(clk)) then
			case arb_state is
				when INIT =>
					switching <= '0';
					if(mask /= 0) then
						for i in 0 to SGP_CACHEARB_PES-1 loop
							if(mask(i) = '1') then
								selectedPE <= i;
								arb_state <= GRANTED;
								exit;
							end if;
						end loop;
					end if;
				when GRANTED =>
					switching <= '0';
					if(cacheArbiterReqs(selectedPE).arbReq = '0') then
						arb_state <= HOLD;
					end if;
				when HOLD =>
					if(readCounter=0 and cacheCmdFIFO_empty='1') then
						arb_state <= INIT;
					else
						switching <= '1';
						arb_state <= WAIT_SWITCH;
					end if;
				when WAIT_SWITCH =>
					if(readCounter = 0) then
						switching <= '0';
						arb_state <= INIT;
					end if;
				when others =>
					arb_state <= INIT;
					switching <= '0';
				end case;
		end if;
	end process;
	
end behavioral;

