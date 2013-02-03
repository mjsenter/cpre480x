-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- SGP_config.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the configuration information and
-- type declarations for the Simple Graphics Processor (SGP). 
--
-- NOTES:
-- 7/30/10 by JAZ::Design created.
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- SGP configuration information

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

package SGP_config is

   -- Main configuration constants. 
	constant SGP_CACHEARB_PES        : integer := 2; -- # of cacheArbiter masters
	constant SGP_HOSTBUS_PES         : integer := 3; -- # of hostBus PEs (pipe stages)
	constant SGP_VERTEX_QUEUES       : integer := 10; -- # of vertex queues


   -- hostBus addresses (sync with utils/include/sgp.h)
	constant NOOP_BUS_ADDRESS        : integer := 0; -- Reserved for NOP, don't change
	constant MEMOPS_BUS_ADDRESS      : integer := 1; -- hostBus address for memOps
	constant PIXELOPS_BUS_ADDRESS    : integer := 2; -- hostBus address for pixelOps
	constant PIPEFRONT_BUS_ADDRESS   : integer := 3; -- hostBus address for pipeFrontOps
	constant VERTEXOPS_BUS_ADDRESS   : integer := 4; -- hostBus address for vertexOps


   -- DDR2 interface configuration. Don't change these. 
   constant BANK_WIDTH      : integer := 2;   -- # of memory bank addr bits.                             
   constant CKE_WIDTH       : integer := 1;   -- # of memory clock enable outputs.
   constant CLK_WIDTH       : integer := 2;   -- # of clock outputs.
   constant COL_WIDTH       : integer := 10;  -- # of memory column bits.
   constant CS_NUM          : integer := 1;   -- # of separate memory chip selects.
   constant CS_WIDTH        : integer := 1;   -- # of total memory chip selects.
   constant CS_BITS         : integer := 0;   -- set to log2(CS_NUM) (rounded up).
   constant DM_WIDTH        : integer := 8;   -- # of data mask bits.
   constant DQ_WIDTH        : integer := 64;  -- # of data width.
   constant DQ_PER_DQS      : integer := 8;   -- # of DQ data bits per strobe.
   constant DQS_WIDTH       : integer := 8;   -- # of DQS strobes.
   constant DQ_BITS         : integer := 6;   -- set to log2(DQS_WIDTH*DQ_PER_DQS).
   constant DQS_BITS        : integer := 3;   -- set to log2(DQS_WIDTH).
   constant ODT_WIDTH       : integer := 1;   -- # of memory on-die term enables.
   constant ROW_WIDTH       : integer := 13;  -- # of memory row and # of addr bits.
   constant ADDITIVE_LAT    : integer := 0;   -- additive write latency.
   constant BURST_LEN       : integer := 4;   -- burst length (in double words).
   constant BURST_TYPE      : integer := 0;   -- burst type (=0 seq; =1 interleaved).
   constant CAS_LAT         : integer := 3;   -- CAS latency.
   constant ECC_ENABLE      : integer := 0;   -- enable ECC (=1 enable).
   constant APPDATA_WIDTH   : integer := 128; -- # of usr read/write data bus bits.
   constant MULTI_BANK_EN   : integer := 1;   -- Keeps multiple banks open. (= 1 enable).
   constant TWO_T_TIME_EN   : integer := 1;   -- 2t timing for unbuffered dimms.
   constant ODT_TYPE        : integer := 1;   -- ODT (=0(none),=1(75),=2(150),=3(50)).
   constant REDUCE_DRV      : integer := 0;   -- reduced strength mem I/O (=1 yes).
   constant REG_ENABLE      : integer := 0;   -- registered addr/ctrl (=1 yes).
   constant TREFI_NS        : integer := 7800; -- auto refresh interval (ns).
   constant TRAS            : integer := 40000; -- active->precharge delay.
   constant TRCD            : integer := 15000; -- active->read/write delay.
   constant TRFC            : integer := 105000; -- refresh->refresh, refresh->active delay.
   constant TRP             : integer := 15000; -- precharge->command delay.
   constant TRTP            : integer := 7500; -- read->precharge delay.
   constant TWR             : integer := 15000; -- used to determine write->precharge.
   constant TWTR            : integer := 7500; -- write->read delay.
   constant HIGH_PERFORMANCE_MODE : boolean := TRUE; 
                              -- # = TRUE, the IODELAY performance mode is set
                              -- to high.
                              -- # = FALSE, the IODELAY performance mode is set
                              -- to low.
   constant SIM_ONLY        : integer := 1;   -- = 1 to skip SDRAM power up delay.
   constant DEBUG_EN        : integer := 0; 
                              -- Enable debug signals/controls.
                              -- When this parameter is changed from 0 to 1,
                              -- make sure to uncomment the coregen commands
                              -- in ise_flow.bat or create_ise.bat files in
                              -- par folder.
   constant CLK_PERIOD      : integer := 5000; -- Core/Memory clock period (in ps).
   constant DLL_FREQ_MODE   : string := "HIGH"; -- DCM Frequency range.
   constant CLK_TYPE        : string := "DIFFERENTIAL"; 
                              -- # = "DIFFERENTIAL " ->; Differential input clocks ,
                              -- # = "SINGLE_ENDED" -> Single ended input clocks.
   constant NOCLK200        : boolean := FALSE; -- clk200 enable and disable
   constant RST_ACT_LOW     : integer := 1;     -- =1 for active low reset, =0 for active high.

   constant CLK_PERIOD_NS   : real := 5000.0 / 1000.0;
   constant DEVICE_WIDTH    : integer := 16;      -- Memory device data width
   constant TCYC_SYS        : real := CLK_PERIOD_NS/2.0;
   constant TCYC_SYS_0      : time := CLK_PERIOD_NS * 1 ns;
   constant TCYC_SYS_DIV2   : time := TCYC_SYS * 1 ns;
   constant TEMP2           : real := 5.0/2.0;
   constant TCYC_200        : time := TEMP2 * 1 ns;
   constant TPROP_DQS          : time := 0.01 ns;  -- Delay for DQS signal during Write Operation
   constant TPROP_DQS_RD       : time := 0.01 ns;  -- Delay for DQS signal during Read Operation
   constant TPROP_PCB_CTRL     : time := 0.01 ns;  -- Delay for Address and Ctrl signals
   constant TPROP_PCB_DATA     : time := 0.01 ns;  -- Delay for data signal during Write operation
   constant TPROP_PCB_DATA_RD  : time := 0.01 ns;  -- Delay for data signal during Read operation

	constant FB_BASE_ADDRESS_BITS : integer := 12;		-- Number of bits for fb address (high bits)
	

   -- Basic primitive structures
   -- Q32.32 fixed-point data type
	subtype fixed_t is signed(63 downto 0);
   
   -- Vertex data type, with X, Y, Z, W coordinates
   type vertex_t is
      record
		   x : fixed_t;
			y : fixed_t;
			z : fixed_t;
			w : fixed_t;
      end record;		

	-- 32-bit color format (ARGB)
	subtype color_t is unsigned(31 downto 0);


	-- pipeFront interface to the downpipe modules
	type pipeFrontData_t is
      record
         vertex : vertex_t;
			color  : color_t;
			valid  : std_logic;
	   end record;


	-- instrFIFO in hostBusInterface
	type instrFIFORead_t is
		record
			start				: std_logic;
			packet			: std_logic_vector(31 downto 0);
			valid				: std_logic;
			empty				: std_logic;
		end record;

	  
	type cacheCmd_t is
		record
			address		: std_logic_vector(31 downto 0);
			writeData	: std_logic_vector(31 downto 0);
			rd_en			: std_logic;
			wr_en			: std_logic;
			flush			: std_logic;
		end record;

	type cacheArbiterReq_t is
		record
			arbReq		: std_logic;
			cacheCmd    : cacheCmd_t;
		end record;
	type cacheArbiterReq_a is array(natural range <>) of cacheArbiterReq_t;


	-- cacheArbiter interfaces
	type cacheRead_t is
	   record
		  readData    : std_logic_vector(31 downto 0);
		  readValid	  : std_logic;
	   end record;

		
	type cacheArbiterGrant_t is
		record
			arbGrant 	: std_logic;
			cacheRead	: cacheRead_t;
		end record; 		
	type cacheArbiterGrant_a is array(natural range <>) of cacheArbiterGrant_t;

	
	-- hostBus master interface
	type hostBusMaster_t is
		record
			busPacket 			: std_logic_vector(31 downto 0);
         busAddress			: std_logic_vector(3 downto 0);
         busStartofPacket 	: std_logic;
		end record;

	-- hostBus slave interface		
	type hostBusSlave_t is
		record
			stall				: std_logic;
			full				: std_logic;
		end record;
	type hostBusSlave_a is array(natural range <>) of hostBusSlave_t;


	-- hostPacketFIFO in ethInterface, uartInterface, and traceInterface
	type hostPacketFIFORead_t is
		record
			packet			: std_logic_vector(31 downto 0);
			valid				: std_logic;
			empty				: std_logic;
		end record;

	
	-- Data types for the DDR2 application interface
	type ddr2app_cmd is
	record
		af_cmd           : std_logic_vector(2 downto 0);
		af_addr          : std_logic_vector(30 downto 0);
		af_wren          : std_logic;
		wdf_data         : std_logic_vector(2*DQ_WIDTH-1 downto 0);
		wdf_mask_data    : std_logic_vector(2*DM_WIDTH-1 downto 0);
		wdf_wren         : std_logic;
	end record;
	constant ddr2app_cmd_zero : ddr2app_cmd := (af_cmd=>(others=>'0'), af_addr=>(others=>'0'), af_wren=>'0', wdf_data=>(others=>'0'), wdf_mask_data=>(others=>'0'), wdf_wren=>'0');

	-- 4x4 matrix signal type
	type matrix_t			 is array(15 downto 0) of fixed_t;

		 
end SGP_config;
