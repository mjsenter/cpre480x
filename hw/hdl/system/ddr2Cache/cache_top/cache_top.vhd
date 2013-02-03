-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-- cache_top.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file implements cache as well as the address 
-- translation from 32-bit virtual addresses to DDR2 physical addresses. 
-- 
-- NOTES:
-- 10/14/10 by MAS::Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.SGP_config.all;


entity cache_top is
    port ( clk    	: in  STD_LOGIC;
			  rst			: in  STD_LOGIC;
			  
			  -- cache FIFO interface
			  readFIFOFull	 : in  std_logic;
			  cacheRead     : out cacheRead_t;
			  
			  cmdFIFOReadEn : out std_logic;
			  cacheCmd      : in  cacheCmd_t;

			  
			  -- DDR2 interface
			  ddr2_valid				: in std_logic;
			  ddr2_data_cmd			: out ddr2app_cmd;
			  ddr2_data					: in std_logic_vector(127 downto 0);
			  ddr2_rd_cmd				: in std_logic);
end cache_top;

architecture behavioral of cache_top is

	-- Cache data storage
	component cacheBlock
      port(
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(6 downto 0);
        dina  : in std_logic_vector(31 downto 0);
        douta : out std_logic_vector(31 downto 0);
        clkb  : in std_logic;
        web   : in std_logic_vector(0 downto 0);
        addrb : in std_logic_vector(4 downto 0);
        dinb  : in std_logic_vector(127 downto 0);
        doutb : out std_logic_vector(127 downto 0));
   end component;
	
	-- Cache tag storage
	component cacheTag
      port(
        clka  : in std_logic;
        wea   : in std_logic_vector(0 downto 0);
        addra : in std_logic_vector(4 downto 0);
        dina  : in std_logic_vector(26 downto 0);
        douta : out std_logic_vector(26 downto 0));
   end component;

	
	-- State machine signals
   type CACHE_STATE_M is (RST_STATE, IDLE_STATE, RD_STATE, CMP_MATCH, RD_STATE_TAG, READ_DDR2_STATE, WRITE_DDR2_STATE_STAGE_1, WRITE_DDR2_STATE_STAGE_2, READ_DDR2_WAIT, READ_DDR2_WAIT2, WRITE_DELAY);
   signal state_cache : CACHE_STATE_M;
  
	signal address_low : std_logic_vector(6 downto 0);
	signal address_high: std_logic_vector(24 downto 0);
	signal address_pys: std_logic_vector(30 downto 0);
	signal writeData_store : std_logic_vector(31 downto 0);
	signal tagBits, tagData: std_logic_vector(26 downto 0);
	signal match, doneinit, iValid, iValid_d1 : std_logic;
	signal tagBits_0_d1 : std_logic;
	
	signal startAddress, tagAddress, dataAddrB : std_logic_vector(4 downto 0);
	
	signal webCnvt : std_logic_vector(0 downto 0);
	signal tagWea : std_logic_vector(0 downto 0);
	signal bram_data_we, bram_data_we_d1 : std_logic_vector(0 downto 0);
	signal we_en_d1, rd_en_d1, flush_d1 : std_logic;

	
begin

	writeData_store <= (others=>'0') when rst='1' else
							 cacheCmd.writeData when (cacheCmd.wr_en='1') and state_cache = IDLE_STATE and rising_edge(clk);

	process(clk, rst)
	begin
		if(rst='1') then
			address_low <= (others=>'0');
			address_high <= (others => '0');
			address_pys <= (others => '0');
		elsif(rising_edge(clk)) then
			if((cacheCmd.rd_en='1' or cacheCmd.wr_en='1') and state_cache=IDLE_STATE) then
				address_low <= cacheCmd.address(6 downto 0);
				address_high <= cacheCmd.address(31 downto 7);
				address_pys <= cacheCmd.address(31 downto 3) & b"00";
			end if;
		end if;
	end process;
	
--	match <= '1' when (tagBits(26 downto 2) = address_high) and state_cache/=IDLE_STATE and state_cache/=RD_STATE_TAG else
--				'0';
   process(clk,rst)
	begin
	   if(rst='1') then
			match <= '0';
		elsif(rising_edge(clk))then
			if((tagBits(26 downto 2) = address_high) and state_cache/=IDLE_STATE and state_cache/=RD_STATE_TAG) then
				match <= '1';
			else
				match <= '0';
			end if;
		end if;
	end process;
				
	tagBits_0_d1 <= tagBits(0) when rising_edge(clk);
				
	iValid <= '0' when state_cache = IDLE_STATE else
				 match and tagBits_0_d1 and doneinit;
	iValid_d1 <= iValid  when rising_edge(clk);
	cacheRead.readValid <= iValid and not iValid_d1 and rd_en_d1;
	cmdFIFOReadEn <= not readFifoFull when state_cache = IDLE_STATE else
						  '0';
	
	ddr2_data_cmd.af_cmd <= b"001" when state_cache = READ_DDR2_STATE else
									b"000";
									
	ddr2_data_cmd.af_addr <= address_pys;
	ddr2_data_cmd.af_wren <= '1' when state_cache = READ_DDR2_STATE or state_cache = WRITE_DDR2_STATE_STAGE_1 else
									 '0';
   ddr2_data_cmd.wdf_mask_data <= x"fff0" when (state_cache = WRITE_DDR2_STATE_STAGE_1) and (address_low(2 downto 0)="000") else
											 x"ff0f" when (state_cache = WRITE_DDR2_STATE_STAGE_1) and (address_low(2 downto 0)="001") else
											 x"f0ff" when (state_cache = WRITE_DDR2_STATE_STAGE_1) and (address_low(2 downto 0)="010") else
											 x"0fff" when (state_cache = WRITE_DDR2_STATE_STAGE_1) and (address_low(2 downto 0)="011") else
											 x"fff0" when (state_cache = WRITE_DDR2_STATE_STAGE_2) and (address_low(2 downto 0)="100") else
											 x"ff0f" when (state_cache = WRITE_DDR2_STATE_STAGE_2) and (address_low(2 downto 0)="101") else
											 x"f0ff" when (state_cache = WRITE_DDR2_STATE_STAGE_2) and (address_low(2 downto 0)="110") else
											 x"0fff" when (state_cache = WRITE_DDR2_STATE_STAGE_2) and (address_low(2 downto 0)="111") else
											 (others => '1');
	ddr2_data_cmd.wdf_data <= writeData_store & writeData_store & writeData_store & writeData_store;
	
									  
									  
	ddr2_data_cmd.wdf_wren <= '1' when state_cache = WRITE_DDR2_STATE_STAGE_1 or state_cache = WRITE_DDR2_STATE_STAGE_2 else
									  '0';
									 
	process(rst, clk, cacheCmd.flush, cacheCmd.rd_en)
	begin
		if(rst = '1') then
			state_cache <= RST_STATE;
			rd_en_d1 <= '0';
			we_en_d1 <= '0';
			flush_d1 <= '0';
		elsif(rising_edge(clk)) then
			case state_cache is
				when RST_STATE =>
					flush_d1 <= '0';
					if(doneinit = '1') then
						state_cache <= IDLE_STATE;
					end if;
				when IDLE_STATE =>
					if(cacheCmd.flush = '1') then
						rd_en_d1 <= '0';
						we_en_d1 <= '0';
						flush_d1 <= '1';
						state_cache <= RST_STATE;
					elsif(cacheCmd.rd_en = '1') then
						state_cache <= RD_STATE_TAG;
						rd_en_d1 <= '1';
						we_en_d1 <= '0';
						flush_d1 <= '0';
					elsif(cacheCmd.wr_en = '1') then
						state_cache <= RD_STATE_TAG;
						we_en_d1 <= '1';
						rd_en_d1 <= '0';
						flush_d1 <= '0';
					end if;
				when RD_STATE_TAG =>
					state_cache <= CMP_MATCH;
				when CMP_MATCH =>
					state_cache <= RD_STATE;
				when RD_STATE =>
					if(iValid = '1' and rd_en_d1 = '1' ) then
						state_cache <= IDLE_STATE;
					elsif(rd_en_d1 = '1') then
						state_cache <= READ_DDR2_STATE;
					else
						state_cache <= WRITE_DDR2_STATE_STAGE_1;
					end if;
				when WRITE_DDR2_STATE_STAGE_1 =>
					if(ddr2_rd_cmd = '1') then
						state_cache <= WRITE_DDR2_STATE_STAGE_2;
					end if;
				when WRITE_DDR2_STATE_STAGE_2 =>
					if(ddr2_rd_cmd = '1') then
						state_cache <= WRITE_DELAY;
					end if;
				when READ_DDR2_STATE =>
					if(ddr2_rd_cmd = '1') then
						state_cache <= READ_DDR2_WAIT;
					end if;
				when READ_DDR2_WAIT =>
					if(ddr2_valid = '1') then
						state_cache <= READ_DDR2_WAIT2;
					end if;
				when READ_DDR2_WAIT2 =>
					if(ddr2_valid = '1') then
						state_cache <= RD_STATE_TAG; -- IDLE_STATE
					end if;
				when WRITE_DELAY =>
					state_cache <= IDLE_STATE;
				when others =>
					state_cache <= IDLE_STATE;
			end case;
		end if;
	end process;
	
	-- reset logic
	process(rst, clk)
	begin
		if(rst = '1' or flush_d1 = '1') then	-- rising edge of rst
			startAddress <= (others =>'0');
			doneinit <= '0';
		elsif (rising_edge(clk) and state_cache = RST_STATE) then
			startAddress <= startAddress + 1;
			if(startAddress = 31) then
				doneinit <= '1';
			end if;
		end if;
	end process;
	
	dataAddrB <= (address_low(6 downto 3) & '1') when (state_cache = READ_DDR2_WAIT2) else
					  address_low(6 downto 3) & '0';
	
	webCnvt(0) <= ddr2_valid;
	
	bram_data_we(0) <= iValid and not iValid_d1 and we_en_d1;
	bram_data_we_d1 <= bram_data_we when rising_edge(clk);
	
	u_cacheBlock: cacheBlock
	  port map (clka    => clk,
		         wea     => bram_data_we,
		         addra   => address_low,
		         dina    => writeData_store,
		         douta   => cacheRead.readData,
		         clkb    => clk,
		         web     => webCnvt,
		         addrb   => dataAddrB,
		         dinb    => ddr2_data,
		         doutb   => open);
		
	tagData <= (others =>'0') when doneinit = '0' else
					address_high & b"11" when bram_data_we(0) = '1' else
					address_high & b"01";	-- not dirty and valid tags
	tagWea(0) <= '0' when rst='1' else
					 '1' when doneinit = '0' or bram_data_we(0) = '1' else
					 ddr2_valid when state_cache = READ_DDR2_WAIT2 else
				    '0';
	tagAddress <= startAddress when doneinit = '0' else
					  '0' & address_pys(5 downto 2);
		
	u_cacheTag: cacheTag
	   port map (clka   => clk,
		          wea    => tagWea,
		          addra  => tagAddress,
		          dina   => tagData,
		          douta  => tagBits);


end behavioral;

