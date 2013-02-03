-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- memOps.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the memOps module that handles memCpy
-- and memSet commands. 
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 10/15/10 by MAS::Design created.
-------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.SGP_config.all;


entity memOps is
  generic (BUS_ADDRESS : integer);
  port (clk100  : in std_logic;
  	     rst		: in std_logic;
			  
		  -- Connections to hostBus
		  hostBusMaster 		: in hostBusMaster_t;
		  hostBusSlave	      : out hostBusSlave_t;
			  
		  -- Direct connections to textureUnit
		  memOps_data			: out std_logic_vector(31 downto 0);
		  memOps_valid			: out std_logic;
		  memOps_count			: out std_logic_vector(31 downto 0);
		  memOps_full			: in std_logic;
			  
		  -- Connections to cacheArbiter
		  cacheArbiterReq    : out cacheArbiterReq_t;
		  cacheArbiterGrant  : in cacheArbiterGrant_t);
end memOps;


architecture mixed of memOps is

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

  -- Signals for memOps state machine
  type MEM_STATE_M is (MEM_CONFIG, SIZE, WRITE_ADDR, READ_ADDR, GET_SET_DATA, READ_DATA, WRITE_DATA, WAIT_FOR_BUS_WRITE, WAIT_FOR_BUS_READ);
  signal mem_state, mem_state_d1, mem_state_d2  : MEM_STATE_M;
  signal readAddr, writeAddr, cpySize : std_logic_vector(31 downto 0);
  signal memWidth, memDepth : std_logic_vector(15 downto 0);
  
  signal opCode : std_logic_vector(7 downto 0);
  
  signal setData : std_logic_vector(31 downto 0);
  signal done : std_logic;
  
  signal countXwrite, countXread : std_logic_vector(31 downto 0);
  signal countYwrite, countYread : std_logic_vector(15 downto 0);
  
  signal instrFIFORead    : instrFIFORead_t;
  signal instrFIFOReadEn  : std_logic;
  signal hostBusStall     : std_logic;
  
  signal isAlpha : std_logic;
  
  signal r_addressInc : std_logic_vector(31 downto 0);

begin


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

  -- one cycle delayed state signal
  mem_state_d1 <= mem_state when rising_edge(clk100);
  mem_state_d2 <= mem_state_d1 when rising_edge(clk100);

  -- never need to flush the cache
  cacheArbiterReq.cacheCmd.flush <= '0';
  
  -- req bus when not in mem_config state
  cacheArbiterReq.arbReq <= '0' when mem_state=MEM_CONFIG else
						  not memOps_full when opCode(2)='0' else
						  '1';

  -- need new stall logic
  hostBusStall <= opCode(3) or not opCode(0) when     mem_state=READ_DATA
																	or mem_state=WRITE_DATA
																	or mem_state=WAIT_FOR_BUS_WRITE
																	or mem_state=WAIT_FOR_BUS_READ 
																	or (mem_state=GET_SET_DATA and instrFIFORead.valid='1')
																	or (instrFIFORead.valid='1' and mem_state=SIZE and opCode(0)='1') else
						 '0';
  instrFIFOReadEn <= not hostBusStall when mem_state=MEM_CONFIG or mem_state=WRITE_ADDR or (opCode(3)='1' or opCode(0)='0') else
									   not hostBusStall when mem_state=WRITE_DATA or (mem_state=SIZE and instrFIFORead.valid='0') else
										'0';
  
  -- Drive cache address signal
  cacheArbiterReq.cacheCmd.address <= (others=>'0') when rst='1' else
											  readAddr when mem_state = READ_DATA else
											  writeAddr;
						 
  -- cache read enable
  cacheArbiterReq.cacheCmd.rd_en <= '0' when rst='1' else
										  not done when mem_state = READ_DATA else
										  '0';
		
  -- cache write enable
  cacheArbiterReq.cacheCmd.wr_en <= '0' when rst='1' else
										  '1' when (mem_state=WRITE_DATA) and (done='0') and (opCode(0)='0') else
										  cacheArbiterGrant.cacheRead.readValid and (not isAlpha) when (mem_state=WRITE_DATA) and (done='0') and (opCode(2)='1') and (opCode(3)='1') else
										  instrFIFORead.valid when (mem_state=WRITE_DATA) and (done='0') and (opCode(3)='0') else
										  '0';
	isAlpha <= opCode(4) when  cacheArbiterGrant.cacheRead.readData(31 downto 24) = 0 else
				  '0';
											
    
  -- Set opCode depending on instruction packet
  P1: process(clk100, rst)
	begin
		if(rst='1') then
			opCode <= (others=>'0');
		elsif(rising_edge(clk100)) then
			if(instrFIFORead.start = '1') then
				opCode <= instrFIFORead.packet(11 downto 4);
			end if;
		end if;
  end process;


  -- Define chunk size
  memWidth <= cpySize(15 downto 0);
  memDepth <= cpySize(31 downto 16);


  -- This process computes the write address
  P2: process(clk100, rst)
  begin
    if(rst='1') then
		writeAddr <= (others=>'0');
		countXwrite <= (others=>'0');
		countYwrite <= (others=>'0');
	 elsif(rising_edge(clk100)) then
		if(mem_state = WRITE_ADDR) then
			writeAddr <= instrFIFORead.packet;
		elsif(mem_state = SIZE) then
			countXwrite <= (others => '0');
			countYwrite <= (others =>'0');
		elsif(mem_state = WRITE_DATA) then
			if(done='0' and ( opCode(0)='0' or (opCode(3)='1' and cacheArbiterGrant.cacheRead.readValid='1') or (opCode(3)='0' and instrFIFORead.valid='1'  ))) then
				-- update address
				if(opCode(1) = '1') then		-- if linear address
					writeAddr <= writeAddr + 1;
					countXwrite <= countXwrite + 1;
				else
					if(countXwrite < memWidth-1 ) then
						writeAddr <= writeAddr + 1;
						countXwrite <= countXwrite + 1;
					else
						writeAddr <= writeAddr+1 - memWidth + 2048;
						countYwrite <= countYwrite + 1;
						countXwrite <= (others=>'0');
					end if;
				end if;
			end if;
		end if;
	end if;
  end process;
  
  -- set done signal
  done <= '1' when ((countYwrite = (memDepth)) and (opCode(1)='0') ) else
			 '1' when (countXwrite = cpySize) and (opCode(1)='1') else
			 '0';
  
  -- This process sets the read address
  P3: process(clk100, rst)
  begin
    if(rst='1') then
		readAddr <= (others=>'0');
		countXread <= (others=>'0');
		countYread <= (others=>'0');
	 elsif(rising_edge(clk100)) then
		if(mem_state = READ_ADDR) then
			readAddr <= instrFIFORead.packet;
		elsif(mem_state = SIZE) then
			countXread <= (others =>'0');
			countYread <= (others =>'0');
		elsif(mem_state = READ_DATA) then
			if(cacheArbiterGrant.arbGrant = '1') then
				-- update address
				if(opCode(1) = '1') then		-- linear address
					readAddr <= readAddr + 1;
					countXread <= countXread + 1;
				else
					if(countXread < memWidth-1 ) then
						readAddr <= readAddr + 1;
						countXread <= countXread + 1;
					else
						readAddr <= readAddr+1 - memWidth + 2048;
						countYread <= countYread + 1;
						countXread <= (others=>'0');
					end if;
				end if;
			end if;
		end if;
	end if;
  end process;

  -- Write data to the host
  memOps_valid <= '0' when rst='1' else
						'1' when (cacheArbiterGrant.cacheRead.readValid='1' and mem_state=WRITE_DATA and done='0' and opCode(2)='0' and opCode(3)='1') else
						'0';
  
  memOps_data <= (others=>'0') when rst='1' else
					  cacheArbiterGrant.cacheRead.readData;
					 
  memOps_count <= (others=>'0') when rst='1' else
						r_addressInc;
					
	process(clk100, rst)
	begin
		if(rst='1') then
			r_addressInc <= (others=>'0');
		elsif(rising_edge(clk100)) then
			-- general clear to zero for new memcpy execution
			if(mem_state = SIZE) then
				r_addressInc <= (others=>'0');
			-- Incrment valid when we read another data value
			elsif (cacheArbiterGrant.cacheRead.readValid='1' and mem_state=WRITE_DATA and done='0' and opCode(2)='0' and opCode(3)='1') then
				r_addressInc <= r_addressInc + 1;
			end if;
		end if;
	end process;					   
  
  -- write data to the cacheArbiter
  cacheArbiterReq.cacheCmd.writeData <= (others=>'0') when rst='1' else
												setData when (opCode(0)='0') else
												instrFIFORead.packet when (opCode(0)='1') and (opCode(3)='0') else
												cacheArbiterGrant.cacheRead.readData;

  -- Main memOps state machine
  P4: process(clk100, rst)
	begin
		if (rst='1') then
		    mem_state <= MEM_CONFIG;
			 cpySize <= (others=> '0');
			 setData <= (others=>'0');
		elsif(rising_edge(clk100)) then
			case mem_state is
			   when MEM_CONFIG =>
					if(instrFIFORead.start='1') then
						mem_state <= WRITE_ADDR;
					end if;
				when WRITE_ADDR =>
					if(instrFIFORead.valid='1') then
						if(opCode(3) = '1') then	-- if memCpy
							mem_state <= READ_ADDR;
						else 
							mem_state <= SIZE;
						end if;
					end if;
				when READ_ADDR =>
					if(instrFIFORead.valid='1') then
						mem_state <= SIZE;
					end if;
				when SIZE =>
					if(instrFIFORead.valid='1') then
						cpySize <= instrFIFORead.packet;
						if(opCode(3) = '1') then
							if(cacheArbiterGrant.arbGrant='1') then
								mem_state <= READ_DATA;
							else
								mem_state <= WAIT_FOR_BUS_READ;
							end if;
						elsif(opCode(0)='0') then
							mem_state <= GET_SET_DATA;
						else
							if(cacheArbiterGrant.arbGrant='1') then
								mem_state <= WRITE_DATA;
							else
								mem_state <= WAIT_FOR_BUS_WRITE;
							end if;
						end if;
					end if;
				when GET_SET_DATA =>
					if(instrFIFORead.valid='1') then
						setData <= instrFIFORead.packet;
						if(cacheArbiterGrant.arbGrant='1') then
							mem_state <= WRITE_DATA;
						else
							mem_state <= WAIT_FOR_BUS_WRITE;
						end if;
					end if;
				when WAIT_FOR_BUS_WRITE =>
					if(cacheArbiterGrant.arbGrant='1') then
						mem_state <= WRITE_DATA;
					end if;
				when WAIT_FOR_BUS_READ =>
					if(cacheArbiterGrant.arbGrant='1') then
						mem_state <= READ_DATA;
					end if;
				when READ_DATA =>
						if(cacheArbiterGrant.arbGrant='1') then
							mem_state <= WRITE_DATA;
						else
							mem_state <= WAIT_FOR_BUS_WRITE;
						end if;
				when WRITE_DATA =>
					if(done = '0') then
 						  if(opCode(3)='0') then	
								if(cacheArbiterGrant.arbGrant='1') then
									mem_state <= WRITE_DATA;
								else 
									mem_state <= WAIT_FOR_BUS_WRITE;
								end if;
							else
								-- Req read from memory
								if(cacheArbiterGrant.cacheRead.readValid='1') then
									if(cacheArbiterGrant.arbGrant='1') then
										mem_state <= READ_DATA;
									else
										mem_state <= WAIT_FOR_BUS_READ;
									end if;
								end if;
							end if;
					else
						mem_state <= MEM_CONFIG;
					end if;
				when others =>
					mem_state <= MEM_CONFIG;
			end case;
		end if;
	end process;
	

end mixed;

