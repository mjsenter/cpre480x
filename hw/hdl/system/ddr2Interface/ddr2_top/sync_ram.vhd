-- Simple generic RAM Model
--
-- +-----------------------------+
-- |    Copyright 2008 DOULOS    |
-- |   designer :  JK            |
-- +-----------------------------+

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity sync_ram is
generic(C_DATA_WIDTH : integer := 64;
C_FAMILY : string := "virtex5");
  port (
    rst      : in std_logic;
    clk    : in  std_logic;
	 cmd		 : in  std_logic;
	 valid    : out  std_logic;
    we       : in  std_logic;
    addressA : in  std_logic_vector(30 downto 0);
    addressB : in  std_logic_vector(30 downto 0);	 
    datainA  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    datainB  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
	 dataoutA : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
	 dataoutB : out std_logic_vector(C_DATA_WIDTH-1 downto 0)	 
  );
end entity sync_ram;

architecture arch of sync_ram is

   type ram_type is array (0 to (2**18)-1) of std_logic_vector(datainA'range);
   signal ram : ram_type;
  -- signal read_addressA : std_logic_vector(addressA'range);
  -- signal read_addressB : std_logic_vector(addressA'range);		

begin
   		  
  RamWrite: process(clk) is
   variable read_addressA : natural := 0;
   variable read_addressB : natural := 0;
  begin
    if rising_edge(clk) then
	   if (rst = '1') then
		 ram <= (others=>(others => '1'));
      else
         read_addressA :=  to_integer(unsigned(addressA));
			read_addressB :=  to_integer(unsigned(addressB));
			
			--Write
			if (we = '1') and (cmd = '0') then
			 ram(read_addressA) <= datainA;
			 ram(read_addressB) <= datainB; 		 
			end if;
			
			--Read
			valid  <= '0';
			if (We = '0') and (cmd = '1') then
			  valid   <= '1';
			end if;
			dataoutA <= ram(read_addressA);
			dataoutB <= ram(read_addressB);
    end if;
  end if;
  end process RamWrite;
 
end architecture arch;
