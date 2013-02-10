-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- pixelOps.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of the pixel 
-- processing stage of the 3D rendering pipeline. 
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 10/13/10 by MAS::Design created.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.SGP_config.all;

entity pixelOps is
	  generic(BUS_ADDRESS : integer);
     port (clk100  : in std_logic;
		 	  rst		 : in std_logic;

		     -- Connections to the hostBus
			  hostBusMaster  : in hostBusMaster_t;
			  hostBusSlave   : out hostBusSlave_t;
			  
			  -- Uppipe connection for the vertex data
		     pipeFrontData  : in pipeFrontData_t;
			  pipeStall      : out std_logic;
			  
			  -- Downpipe connection to the cacheArbiter
			  cacheArbiterReq    : out cacheArbiterReq_t;
			  cacheArbiterGrant  : in cacheArbiterGrant_t);			  
			  
			  
end pixelOps;


architecture mixed of pixelOps is


	-- hostBus interface
	component hostBusInterface
		generic (BUS_ADDRESS : integer);
		port (clk : in  std_logic;
				rst : in  std_logic;
			  
				-- Bus Interface
				hostBusMaster 		: in hostBusMaster_t;
				hostBusSlave 	   : out hostBusSlave_t;
			  
				-- User Interface
				instrFIFORead 	   : out instrFIFORead_t;
				instrFIFOReadEn  	: in std_logic;
				unitStall			: in std_logic);
	end component;


   -- Signals to interface with the hostBus. 
	signal instrFIFORead     : instrFIFORead_t;
	signal instrFIFOReadEn   : std_logic;
   	signal hostBusStall      : std_logic;

	--signals to calculon addresses
	signal xAddOne   : std_logic_vector(63 downto 0);
	signal yAddOne   : std_logic_vector(63 downto 0);
	signal xTimesDim : std_logic_vector(31 downto 0);
	signal yTimesDim : std_logic_vector(31 downto 0);
	signal memAddr   : std_logic_vector(31 downto 0);


begin

   -- Connect the vertexOps module to the hostBus
	u_hostBusInterface: hostBusInterface
	  generic map(BUS_ADDRESS      => BUS_ADDRESS)
		port map(clk                => clk100,
				   rst                => rst,
			  
				   -- Bus Interface
				   hostBusMaster 		 => hostBusMaster,
				   hostBusSlave 	    => hostBusSlave,
			  
				   -- User Interface
				   instrFIFORead 	    => instrFIFORead,
				   instrFIFOReadEn  	 => instrFIFOReadEn,
				   unitStall			 => hostBusStall);
					
	-- Remember to drive the following signals
	-- Signals for hostBusInterface
	--   hostBusStall      <= ?
	--   instrFIFOReadEn   <= ?
	-- Entity signals
	--   cacheArbiterReq.* <= ?
	--   pipeStall         <=
	
	-- Delete this code when implementing your design. The signals below are only driven to 
	-- make sure that other components work correctly
	hostBusStall <= '0' when (pipeFrontData.valid = '0') else '1';
	
	instrFIFOReadEn <= not hostBusStall;
	P1 : process(clk100, rst)
	begin
		if(rst = '1') then
			hostBusStall <= '0';
		elsif(rising_edge(clk100)) then
			
			cacheArbiterReq.arbReq <= '0';-- when (pipeFrontData.valid = '0') else '1';
			cacheArbiterReq.cacheCmd.address <= memAddr;

			pipeStall <= '0';
		
		end if;
	end process;

	-- End Delete section ======================================================================


end mixed;


