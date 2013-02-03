-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- hostBusInterface.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the hostBus Interface module that is 
-- used in memOps and graphicsPipe. 
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 1/12/11 by MAS::Design created.
-------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use WORK.SGP_config.all;

entity hostBusInterface is
	generic (BUS_ADDRESS : integer);
	port (clk : in  STD_LOGIC;
			rst : in  STD_LOGIC;
		  
			-- Hus Interface
			hostBusMaster 		: in hostBusMaster_t;
			hostBusSlave 	   : out hostBusSlave_t;
		  
			-- User Interface
			instrFIFORead 	   : out instrFIFORead_t;
			instrFIFOReadEn  	: in std_logic;
			unitStall			: in std_logic);
end hostBusInterface;

architecture mixed of hostBusInterface is

   -- FIFO for the hostBusInterface
	component hostBusInterfaceFIFO
      port (clk          : in std_logic;
            rst          : in std_logic;
            din          : in std_logic_vector(32 downto 0);
            wr_en        : in std_logic;
            rd_en        : in std_logic;
            dout         : out std_logic_vector(32 downto 0);
            full         : out std_logic;
		      almost_full  : out std_logic;
            empty        : out std_logic;
            valid        : out std_logic);
	end component;


	signal busValid, empty, valid : std_logic;
	signal din, dout  : std_logic_vector(32 downto 0);
	signal almost_full, full : std_logic;
	
	signal unitStall_d1, unitStall_d2, unitStall_d3,   unitStall_d4 : std_logic;
	signal unitStall_or : std_logic;

begin

  -- Add the fifo empty case for stalling instruction fetch
  hostBusSlave.stall <= unitStall_or or valid or not empty;
  
  unitStall_or <= unitStall or unitStall_d1 or unitStall_d2;
  
  unitStall_d1 <= '0' when rst='1' else
                  unitStall when rising_edge(clk);
  unitStall_d2 <= '0' when rst='1' else
                  unitStall_d1 when rising_edge(clk);
  unitStall_d3 <= '0' when rst='1' else
                  unitStall_d2 when rising_edge(clk);
  unitStall_d4 <= '0' when rst='1' else
                  unitStall_d3 when rising_edge(clk);

  -- Is the current packet on the bus for me?
  busValid <= 	'1' when hostBusMaster.busAddress = conv_std_logic_vector(BUS_ADDRESS, 4) else
					'0';
  
  -- Format packet and start packet signal into one data type for fifo
  din <= hostBusMaster.busPacket & hostBusMaster.busStartofPacket;
  
  -- Extract fifo data format
  instrFIFORead.start  <= dout(0) and valid;
  instrFIFORead.packet <= dout(32 downto 1);
  instrFIFORead.empty  <= empty;
  instrFIFORead.valid  <= valid;
  
  hostBusSlave.full <= almost_full or full;
  
  u_hostBusInterfaceFIFO: hostBusInterfaceFIFO
       port map (clk    => clk,
                 rst    => rst,
                 din    => din,
                 wr_en  => busValid,
                 rd_en  => instrFIFOReadEn,
                 dout   => dout,
                 full   => full,
					  almost_full => almost_full,
                 empty  => empty,
                 valid  => valid);

end mixed;

