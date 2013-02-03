-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- pipeFront.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of the front of the
-- pipeline, that stores the primitive queue data and packages it
-- for the later stages in the pipeline. 
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 10/12/10 by MAS::Design created.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.SGP_config.all;

entity pipeFront is
	  generic(BUS_ADDRESS : integer);
     port (clk100  : in std_logic;
		 	  rst		 : in std_logic;

		     -- Connections to the hostBus
			  hostBusMaster  : in hostBusMaster_t;
			  hostBusSlave   : out hostBusSlave_t;
			  
			  -- Downpipe connection for the vertex data
		     pipeFrontData  : out pipeFrontData_t;
			  pipeStall      : in std_logic);
end pipeFront;


architecture mixed of pipeFront is

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


   -- queue data RAM
	component queueRAM
      port (clka            : in std_logic;
            wea             : in std_logic_vector(0 downto 0);
            addra           : in std_logic_vector(4 downto 0);
            dina            : in std_logic_vector(31 downto 0);
            clkb            : in std_logic;
            addrb           : in std_logic_vector(4 downto 0);
            doutb           : out std_logic_vector(31 downto 0));
	end component;


	-- Signals for addressing the queueRAM for writing (with result after masking)
	signal queueRAMAddr       : std_logic_vector(4 downto 0);
	signal maskedqueueRAMaddr : std_logic_vector(4 downto 0);
	
	-- Signals for the write enables to queueRAM. The CoreGen BlockRAM requires
	-- a 0-dim array for each write enable. 
   type wea_a is array(0 to SGP_VERTEX_QUEUES-1) of std_logic_vector(0 downto 0);
	signal wea : wea_a;

	-- Signals for addressing the queueRAM for reading and output data
	type queueAddrArray_t is array(0 to SGP_VERTEX_QUEUES-1) of std_logic_vector(4 downto 0);
	type queueDataArray_t is array(0 to SGP_VERTEX_QUEUES-1) of std_logic_vector(31 downto 0);

	signal queueAddrArray : queueAddrArray_t;
	signal queueDataArray : queueDataArray_t;

   -- Signals to interface with the hostBus. 
	signal instrFIFORead     : instrFIFORead_t;
	signal instrFIFOReadEn   : std_logic;
   signal hostBusStall      : std_logic;

   -- 8-bit opcode for individual instructions
	signal opCode : std_logic_vector(7 downto 0);
	
	

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


   -- For now, we should stall the hostBus when flushing the queueRAMs.
   hostBusStall <= '0';

   -- Do not read next instruction while processing the current one
	instrFIFOReadEn <= not hostBusStall;


	-- This process stores the opcode from the last instruction
	P1: process(rst, clk100)
	begin
		if(rst='1') then
			opCode <= (others => '0');

		elsif(rising_edge(clk100)) then
		   
			-- If the start bit from the FIFO is high, then we have a new instruction.
			-- The opcode is defined as bits 11 downto 4 of a new instruction data packet.
			if(instrFIFORead.start = '1') then	     
				opCode <= instrFIFORead.packet(11 downto 4);
			end if;

		end if;
	end process;   


	-- Sets address to zero when starting a new packet
	maskedqueueRAMaddr <= queueRAMaddr when (instrFIFORead.start = '0')
	                      else (others => '0');
	
   -- Currently, there needs to be 8 queues for primitive data
   -- Queue    0: index array
	-- Queue    1: vertex color (ARGB)
   -- Queues 2-7: vertex data (2,3: x), (4,5: y), (6,7: z)
   G1: for i in 0 to SGP_VERTEX_QUEUES-1 generate
     u_queueRAM: queueRAM
      port map(clka         => clk100,
               wea          => wea(i),
               addra        => maskedqueueRAMaddr,		-- Address for writing
               dina         => instrFIFORead.packet,	-- Data to write
               clkb         => clk100,
               addrb        => queueAddrArray(i),		-- Address for reading
               doutb        => queueDataArray(i));		-- Data read
   end generate G1;


--==================================================================================
-- Logic used for writing bus data to the queueRAMs
--==================================================================================

	-- Assert the write enable signal for the queueRAM when the bus has valid data
	-- and the opCode equals the queueRAM number.
	-- NOTE: When the first packet is received, the opCode signal has not been set
	--       and we need to read the opcode directly from the bus packet.
   G2: for i in 0 to SGP_VERTEX_QUEUES-1 generate
      wea(i)(0) <= instrFIFORead.valid when (unsigned(opCode) = i and instrFIFORead.start='0') else
						 instrFIFORead.valid when (unsigned(instrFIFORead.packet(11 downto 4)) = i and instrFIFORead.start='1') else
						 '0';
	end generate G2;
	
	-- Increment input Address to next save value
	process(clk100, rst)
	begin
		if(rst='1') then
			queueRAMAddr <= (others=>'0');
		elsif(rising_edge(clk100)) then
			if(instrFIFORead.start = '1') then
				queueRAMAddr <= b"00001";
			elsif(instrFIFORead.valid = '1') then
				queueRAMAddr <= std_logic_vector(unsigned(queueRAMAddr) + 1);
			end if;
		end if;
	end process;

--==================================================================================
-- Logic used to flush queueRAM data down pipe
--==================================================================================
	
	-- Implement your code here
	
	-- Remember to change the logic for hostBusStall signal to stall the host bus when 
	-- flushing the queueRAM data
	
	-- The signals queueAddrArray and queueDataArray can be used to read from the queueRAMs


end mixed;


