-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-- ddr2Cache.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file implements the ddr2Cache that translates 
-- data requests between the cacheArbiter and the ddr2Arbiter.
-- 
-- NOTES:
-- 1/20/10 by MAS::Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.SGP_config.all;


entity ddr2Cache is

    port ( clk100   	: in  std_logic;
	        clk200   	: in  std_logic;
			  rst			: in  std_logic;
			  
			  -- cache FIFO interfaces
			  cacheRead     : out cacheRead_t;
			  cacheCmd      : in  cacheCmd_t;
           cmdFIFO_full  : out std_logic;
           cmdFIFO_empty : out std_logic;
			  
			  -- DDR2 interface
			  ddr2_valid				: in std_logic;
			  ddr2_data_cmd			: out ddr2app_cmd;
			  ddr2_data					: in std_logic_vector(127 downto 0);
			  ddr2_rd_cmd				: in std_logic);
end ddr2Cache;

architecture mixed of ddr2Cache is


	-- Main cache implementation
	component cache_top
      port ( clk    	   : in  STD_LOGIC;
			    rst			: in  STD_LOGIC;
			  
			    -- cache FIFO interface
			    readFIFOFull	: in  std_logic;
			    cacheRead     : out cacheRead_t;
			  
			    cmdFIFOReadEn : out std_logic;
			    cacheCmd      : in  cacheCmd_t;
			  
			    -- DDR2 interface
			    ddr2_valid				: in std_logic;
			    ddr2_data_cmd			: out ddr2app_cmd;
			    ddr2_data				: in std_logic_vector(127 downto 0);
			    ddr2_rd_cmd			: in std_logic);
	end component;

   -- cache command (write) FIFO
   component cacheCmdFIFO
      port (rst         : in std_logic;
            wr_clk      : in std_logic;
            rd_clk      : in std_logic;
            din         : in std_logic_vector(66 downto 0);
            wr_en       : in std_logic;
            rd_en       : in std_logic;
            dout        : out std_logic_vector(66 downto 0);
            full        : out std_logic;
            almost_full : out std_logic;
            empty       : out std_logic;
		      almost_empty: out std_logic;
            valid       : out std_logic);
   end component;
  
   -- cache result (read) FIFO
   component cacheReadFIFO
      port (rst         : in std_logic;
            wr_clk      : in std_logic;
            rd_clk      : in std_logic;
            din         : in std_logic_vector(31 downto 0);
            wr_en       : in std_logic;
            rd_en       : in std_logic;
            dout        : out std_logic_vector(31 downto 0);
            full        : out std_logic;
            almost_full : out std_logic;
            empty       : out std_logic;
		      almost_empty: out std_logic;
            valid       : out std_logic);
   end component;

   -- Signals to connect the FIFOs with the cache_top
	signal readFIFOFull, cmdFIFOReadEn : std_logic;
	signal r_cacheRead, r_cacheRead_d1  : cacheRead_t;
	signal r_cacheCmd   : cacheCmd_t;
   signal cacheCmdFIFO_din : std_logic_vector(66 downto 0);
   signal cacheCmdFIFO_dout : std_logic_vector(66 downto 0);
   signal cacheCmdFIFO_wr_en : std_logic;
   signal cacheCmdFIFO_full, cacheCmdFIFO_afull : std_logic;
	signal cacheCmdFIFO_valid : std_logic;
	signal cacheReadFIFO_full, cacheReadFIFO_afull : std_logic;
  
begin

   u_cache_top: cache_top
	  port map(clk    	     => clk200,
			     rst			     => rst,
			  
			      -- cache FIFO interface
			      readFIFOFull  => readFIFOFull,
			      cacheRead     => r_cacheRead,
			  
			      cmdFIFOReadEn => cmdFIFOReadEn,
			      cacheCmd      => r_cacheCmd,
			  
			      -- DDR2 interface
			      ddr2_valid	  => ddr2_valid,
			      ddr2_data_cmd => ddr2_data_cmd,
			      ddr2_data	  => ddr2_data,
			      ddr2_rd_cmd	  => ddr2_rd_cmd);

   -- Glue the cacheCmd structure to the FIFO interface
	cacheCmdFIFO_din <= cacheCmd.address & cacheCmd.writeData & cacheCmd.rd_en & cacheCmd.wr_en & cacheCmd.flush;

   -- Write to the cacheCmdFIFO when there is any valid command
   cacheCmdFIFO_wr_en <= cacheCmd.wr_en or cacheCmd.rd_en or cacheCmd.flush;

   -- Glue the cacheCmdFIFO output to the cacheCmd data structure
	r_cacheCmd.flush     <= cacheCmdFIFO_dout(0) and cacheCmdFIFO_valid;
	r_cacheCmd.wr_en     <= cacheCmdFIFO_dout(1) and cacheCmdFIFO_valid;
	r_cacheCmd.rd_en     <= cacheCmdFIFO_dout(2) and cacheCmdFIFO_valid;
	r_cacheCmd.writeData <= cacheCmdFIFO_dout(34 downto 3);
	r_cacheCmd.address   <= cacheCmdFIFO_dout(66 downto 35);
	cmdFIFO_full <= cacheCmdFIFO_full or cacheCmdFIFO_afull;

   u_cacheCmdFIFO: cacheCmdFIFO
	  port map(rst          => rst,
              wr_clk       => clk100,
              rd_clk       => clk200,
              din          => cacheCmdFIFO_din,
              wr_en        => cacheCmdFIFO_wr_en,
              rd_en        => cmdFIFOReadEn,
              dout         => cacheCmdFIFO_dout,
              full         => cacheCmdFIFO_full,
              almost_full  => cacheCmdFIFO_afull,
              empty        => cmdFIFO_empty,
		        almost_empty => open,
              valid        => cacheCmdFIFO_valid);



	readFIFOFull <= cacheReadFIFO_full or cacheReadFIFO_afull;
	r_cacheRead_d1 <= r_cacheRead when rising_edge(clk200);

   u_cacheReadFIFO: cacheReadFIFO
	  port map(rst          => rst,
              wr_clk       => clk200,
              rd_clk       => clk100,
              din          => r_cacheRead_d1.readData,
              wr_en        => r_cacheRead_d1.readValid,
              rd_en        => '1',
              dout         => cacheRead.readData,
              full         => cacheReadFIFO_full,
              almost_full  => cacheReadFIFO_afull,
              empty        => open,
		        almost_empty => open,
              valid        => cacheRead.readValid);


end mixed;
