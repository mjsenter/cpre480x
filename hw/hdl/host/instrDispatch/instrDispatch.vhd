-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- instrDipatch.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the instruction dispatch module, which
-- takes instructions and outputs them on the hostBus at the appropriate
-- times.
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 1/15/11 by MAS::Design created.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;
use IEEE.std_logic_MISC.ALL;
use WORK.SGP_config.all;

entity instrDispatch is
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
			 
end instrDispatch;

architecture behavioral of instrDispatch is

	signal count : std_logic_vector(19 downto 0);
	signal internalAddress, address_hold : std_logic_vector(3 downto 0);
	
	signal instructionData : std_logic_vector(31 downto 0);
	signal instructionFull, instructionValid, instructionStart : std_logic;
	
	signal rd_en, rd_en_flow: std_logic;
	
	signal unit_stall, unit_fifo_full : std_logic;
	
	signal rd_stop_condition, rd_stop_condition_d1 : std_logic;


begin

	no_data <= not instructionFull and not hostPacketFIFORead.valid and count(19);

	-- First Stage (1 Entry FIFO)
	instructionData <= (others=>'0') when rst='1' else
							 hostPacketFIFORead.packet when rising_edge(clk) and hostPacketFIFORead.valid='1';
	
	instructionStart <= '0' when rst='1' else
							  hostPacketFIFORead.valid and count(19) when rising_edge(clk) and hostPacketFIFORead.valid='1';
						
	instructionFull <= '0' when rst='1' else
							  hostPacketFIFORead.valid when rising_edge(clk) and (hostPacketFIFORead.valid='1' or rd_en='1'); 
							  
	instructionValid <= ((instructionFull and not instructionValid) or hostPacketFIFORead.valid) and rd_en when rising_edge(clk);
	
	hostPacketFIFOReadEn <= rd_en or (not instructionFull and not hostPacketFIFORead.valid);
	
	-- Second Stage (Forward to units)

	-- Check if need to stall instruction fetch
		-- Stop only when we have start of packet and address does not match old address
		-- Contine when all unit stall signals are zero	
		
	P1: process(rst, hostBusSlaves)
		variable p,t : std_logic;
	begin
		if(rst='1') then
			unit_stall <= '0';
			unit_fifo_full <= '0';
			p := '0';
			t := '0';
		else
			p := '0';
			t := '0';
			for i in SGP_HOSTBUS_PES-1 downto 0 loop
				p := p or (hostBusSlaves(i).stall and stallMask(i));
				t := t or (hostBusSlaves(i).full and stallMask(i));
			end loop;
			unit_stall <= p;
			unit_fifo_full <= t;
		end if;
	end process;
	
	P2: process(clk, rst)
	begin
		if(rst='1') then
			rd_en_flow <= '1';	-- default allow flow
		elsif(rising_edge(clk)) then
			if(rd_en_flow <= '0') then
				-- start condition
				if(unit_stall='0' and enable_flow='1') then
					rd_en_flow <= '1';
				end if;
			else
				-- stop condition
				if(count(19)='1' and hostPacketFIFORead.valid='1' and internalAddress /= hostPacketFIFORead.packet(3 downto 0) ) then
					rd_en_flow <= '0';
				end if;
			end if;
		end if;
	end process;
	
	
	rd_stop_condition <= '1' when count(19)='1' and hostPacketFIFORead.valid='1' and internalAddress /= hostPacketFIFORead.packet(3 downto 0) else
								'0';
	rd_stop_condition_d1 <= rd_stop_condition when rising_edge(clk);
	
	rd_en <= not unit_fifo_full and (not (rd_stop_condition and not rd_stop_condition_d1)  ) when rd_en_flow='1' else
				'0';														
	
	-- Pass instructions onto bus
   hostBusMaster.busPacket <=   instructionData;
				
	hostBusMaster.busStartofPacket <= instructionStart and instructionValid;
				
   maskOut: for i in 0 to 3 generate
	  hostBusMaster.busAddress(i) <= instructionValid and address_hold(i);
   end generate maskOut;

	hostBusValid <= instructionValid;

	address_hold <=   (others=>'0') when rst='1' else
							internalAddress when rising_edge(clk) and rd_en='1' and instructionFull='1';
							
	P3: process(clk, rst)
	begin
		if(rst='1') then
			count <= (others=>'1');
		elsif(rising_edge(clk)) then
			if((hostPacketFIFORead.valid='1') and (count(19)='1') and (hostPacketFIFORead.packet(30 downto 12) > 0)) then
				count(19) <= '0';
				count(18 downto 0) <= hostPacketFIFORead.packet(30 downto 12)-1;
			elsif(hostPacketFIFORead.valid = '1' and count(19) = '0') then
				count <= count - 1;
			end if;
		end if;
	end process;
	
	P4: process(clk, rst)
	begin
		if(rst='1') then
			internalAddress <= (others=>'0');
		elsif(rising_edge(clk)) then
			if((hostPacketFIFORead.valid='1') and (count(19)='1')) then
				internalAddress <= hostPacketFIFORead.packet(3 downto 0);
			end if;
		end if;
	end process;

end behavioral;

