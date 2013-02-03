library IEEE;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

use WORK.SGP_config.all;

entity ddr2Interface_fast is
    -- DDR2 Signals to Memory Device
   port(

   -- DDR2 Signals to Memory Device
   ddr2_dq               : inout  std_logic_vector((DQ_WIDTH-1) downto 0);
   ddr2_a                : out   std_logic_vector((ROW_WIDTH-1) downto 0);
   ddr2_ba               : out   std_logic_vector((BANK_WIDTH-1) downto 0);
   ddr2_ras_n            : out   std_logic;
   ddr2_cas_n            : out   std_logic;
   ddr2_we_n             : out   std_logic;
   ddr2_cs_n             : out   std_logic_vector((CS_WIDTH-1) downto 0);
   ddr2_odt              : out   std_logic_vector((ODT_WIDTH-1) downto 0);
   ddr2_cke              : out   std_logic_vector((CKE_WIDTH-1) downto 0);
   ddr2_dm               : out   std_logic_vector((DM_WIDTH-1) downto 0);
   ddr2_dqs              : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
   ddr2_dqs_n            : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
   ddr2_ck               : out   std_logic_vector((CLK_WIDTH-1) downto 0);
   ddr2_ck_n             : out   std_logic_vector((CLK_WIDTH-1) downto 0);

   -- System Clocks and Reset
   sys_clk_p             : in    std_logic;
   sys_clk_n             : in    std_logic;
   clk200_p              : in    std_logic;
   clk200_n              : in    std_logic;
   sys_rst_n             : in    std_logic;

   -- User Application
   app_af_addr		       : in std_logic_vector(30 downto 0);
   app_af_cmd		       : in std_logic_vector(2 downto 0);
   app_af_wren		       : in std_logic;
   app_wdf_data		    : in std_logic_vector(APPDATA_WIDTH-1 downto 0);
   app_wdf_mask_data	    : in std_logic_vector(APPDATA_WIDTH/8-1 downto 0);
   app_wdf_wren		    : in std_logic;
   app_wdf_afull	       : out std_logic;
   app_af_afull		    : out std_logic;
   rd_data_valid	       : out std_logic;
   rd_data_fifo_out	    : out std_logic_vector(APPDATA_WIDTH-1 downto 0);
   ddr2_clk200		       : out std_logic;
   ddr2_rst		          : out std_logic;
   ddr2_init_done        : out std_logic);
end entity ddr2Interface_fast;

architecture behavioral of ddr2Interface_fast is
--constant C_DATA_WIDTH : integer := 64;
--constant C_FAMILY : string := "virtex5";

--Component Declaration
component sync_ram is
generic(C_DATA_WIDTH : integer;
		  C_FAMILY : string);
  port (
    rst       : in std_logic;
    clk     : in  std_logic;
	 cmd		  : in  std_logic;
	 valid     : out  std_logic;
    we        : in  std_logic;
    addressA  : in  std_logic_vector(30 downto 0);
	 addressB  : in  std_logic_vector(30 downto 0);
    datainA   : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    datainB   : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);	 
    dataoutA  : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
	 dataoutB  : out std_logic_vector(C_DATA_WIDTH-1 downto 0)
  );
end component;

--Signal Declaration
signal ddr2_rst_i : std_logic;
signal data_valid : std_logic;
signal data_fifo_out : std_logic_vector (APPDATA_WIDTH - 1 downto 0);

--af_fifo signals
signal af_fifo_in_data, af_fifo_out_data                      : std_logic_vector (63 downto 0);
signal af_fifo_in_we, af_fifo_in_re 								  : std_logic ;
signal af_fifo_out_full, af_fifo_out_afull, af_fifo_out_empty : std_logic;
signal s_app_af_addr														  : std_logic_vector (30 downto 0);	


--wdf_fifo signals
signal wdf_fifo_in_data, wdf_fifo_out_data                      : std_logic_vector (APPDATA_WIDTH + APPDATA_WIDTH/8 - 1 downto 0);
signal wdf_fifo_in_we, wdf_fifo_in_re 								    : std_logic ;
signal wdf_fifo_out_full, wdf_fifo_out_afull, wdf_fifo_out_empty: std_logic;
signal rd_cnt                                                   : integer range 0 to 3;

--memory input signals
signal cmd, we, valid : std_logic;
signal addressA, addressB: std_logic_vector(30 downto 0);
signal datainA, datainB: std_logic_vector(63 downto 0);
signal dataoutA, dataoutB: std_logic_vector(63 downto 0);

--bit-masking signals
signal bit_mask        : std_logic_vector((APPDATA_WIDTH-1) downto 0);
signal bit_mask_dataA  : std_logic_vector(APPDATA_WIDTH/2-1 downto 0);
signal bit_mask_dataB  : std_logic_vector(APPDATA_WIDTH/2-1 downto 0);

type statetype is (state_1, state_2, state_3, state_4, state_5);
signal pr_state : statetype;

constant   C_DATA_WIDTH : integer := 64;
constant   C_FAMILY : string  := "virtex5"; 
  
--Component Declaration
component addr_fifo
	port (
	clk: IN std_logic;
	rst: IN std_logic;
	din: IN std_logic_VECTOR(63 downto 0);
	wr_en: IN std_logic;
	rd_en: IN std_logic;
	dout: OUT std_logic_VECTOR(63 downto 0);
	full: OUT std_logic;
	almost_full: OUT std_logic;
	empty: OUT std_logic;
	prog_full: OUT std_logic);
end component;

component data_fifo IS
	port (
	clk: IN std_logic;
	rst: IN std_logic;
	din: IN std_logic_VECTOR(APPDATA_WIDTH + APPDATA_WIDTH/8-1 downto 0);
	wr_en: IN std_logic;
	rd_en: IN std_logic;
	dout: OUT std_logic_VECTOR(APPDATA_WIDTH + APPDATA_WIDTH/8-1 downto 0);
	full: OUT std_logic;
	almost_full: OUT std_logic;
	empty: OUT std_logic;
	prog_full: OUT std_logic);
END component;

begin
ddr2_rst      <= ddr2_rst_i;
ddr2_clk200      <= sys_clk_p;
app_af_afull	  <= af_fifo_out_afull;
app_wdf_afull	  <= wdf_fifo_out_afull;
rd_data_fifo_out           <= DataOutB & DataOutA;
rd_data_valid    <= data_valid;

  --Instances
  U1: sync_ram
  generic map(
  C_DATA_WIDTH =>  C_DATA_WIDTH,
  C_FAMILY  =>   C_FAMILY)
  port map (
    rst	   => ddr2_rst_i,
    clk   => sys_clk_p,
	 cmd		=> cmd,
	 valid   => valid,
    we      => we,	 
    addressA => AddressA,
    addressB => AddressB,	 
    datainA  => DataInA,
    datainB  => DataInB,
    DataOutA => DataOutA,	 
    DataOutB => DataOutB
  );

	U2 : addr_fifo
		port map(
		clk   		=> sys_clk_p,
		rst   		=> ddr2_rst_i,
		din   		=> af_fifo_in_data,
		wr_en 		=> af_fifo_in_we,
		rd_en 		=> af_fifo_in_re,
		dout  		=> af_fifo_out_data,
		full  		=> af_fifo_out_full,
		almost_full => open,
		empty       => af_fifo_out_empty,
		prog_full   => af_fifo_out_afull);

	U3 : data_fifo
		port map(
		clk   		=> sys_clk_p,
		rst   		=> ddr2_rst_i,
		din   		=> wdf_fifo_in_data,
		wr_en 		=> wdf_fifo_in_we,
		rd_en 		=> wdf_fifo_in_re,
		dout  		=> wdf_fifo_out_data,
		full  		=> wdf_fifo_out_full,
		almost_full => open,
		empty       => wdf_fifo_out_empty,
		prog_full   => wdf_fifo_out_afull);

ddr2_rst_gen: process(sys_clk_p)
begin
   if (rising_edge(sys_clk_p)) then
	  if (sys_rst_n = '0') then
	    ddr2_rst_i <= '1';
			ddr2_dq  <= (others=>'0');
			ddr2_a   <= (others=>'0');
			ddr2_ba  <= (others=>'0');
			ddr2_ras_n  <= '0';
			ddr2_cas_n  <= '0';
			ddr2_we_n    <= '0';
			ddr2_cs_n  <= (others=>'0');
			ddr2_odt  <= (others=>'0');
			ddr2_cke  <= (others=>'0');
			ddr2_dm    <= (others=>'0');
			ddr2_dqs   <= (others=>'0');
			ddr2_dqs_n <= (others=>'0');
			ddr2_ck    <= (others=>'0');
			ddr2_ck_n  <= (others=>'0');	 
	  else
	    ddr2_rst_i   <= '0';	    
	  end if;
	end if;
end process;	

af_fifo: process(sys_clk_p)
begin
   if (rising_edge(sys_clk_p)) then
      if (ddr2_rst_i = '1') then
		af_fifo_in_we    <= '0';
		af_fifo_in_data  <= (others=>'0');
		s_app_af_addr <= (others=>'0');
		else			
			--Check If the address enable is high
			if (app_af_wren = '1') then--and (af_fifo_out_afull = '0') and (wdf_fifo_out_afull = '0') then			
				--Write address in the fifo. The lowest 2 bits of the 2 addresses 
				--have to be 00,01,10 and 11. If the address starts from 01, the 
				--second address will be 10
				af_fifo_in_we   <= '1';
				af_fifo_in_data(30 downto 0)  <= app_af_addr;
				af_fifo_in_data(32 downto 31) <= std_logic_vector(unsigned(app_af_addr(1 downto 0))+1);
				af_fifo_in_data(61 downto 33) <= app_af_addr(30 downto 2);
				
				--Latch the address for the next cycle
				s_app_af_addr						<= app_af_addr;
				
				--Latch the app_af_cmd 
				if (app_af_cmd(0) ='0') and (app_af_wren = '1') and (app_wdf_wren ='1') then
					af_fifo_in_data(63 downto 62) <= "01"; --bit 63 is cmd(write) and bit 62 is we(enable) for memory
				elsif (app_af_cmd(0) ='1') and (app_af_wren='1') and (app_wdf_wren='0') then
					af_fifo_in_data(63 downto 62) <= "10"; --bit 63 is cmd(read) and bit 62 is we(disable) for memory				
				end if;--app_af_cmd
				
			else 
					af_fifo_in_we   <= '0';
			end if; --app_af_addr
			
		end if; --rst
	end if; --sys_clk_p
end process;


wdf_fifo: process(sys_clk_p)
begin 
   if (rising_edge(sys_clk_p)) then
      if (ddr2_rst_i = '1') then
			wdf_fifo_in_we    <= '0';
			wdf_fifo_in_data  <= (others=>'0');
		else	
			if (app_wdf_wren = '1') then 
				wdf_fifo_in_we     <= '1';
			   wdf_fifo_in_data 	 <= app_wdf_mask_data & app_wdf_data;
			else
				wdf_fifo_in_we     <= '0';
			end if; --app_wdf_wren
		end if; --rst
	end if; --sys_clk_p		
end process;


	

ctrl_logic: process(sys_clk_p)
begin
   if (rising_edge(sys_clk_p)) then
    if (ddr2_rst_i = '1') then
		wdf_fifo_in_re					<= '0';
      af_fifo_in_re					<= '0';		
		cmd								<= '0';
		we									<= '0';
		addressA							<= (others=>'0');
		addressB							<= (others=>'0');	
		datainA							<= (others=>'0');
		datainB							<= (others=>'0');
		bit_mask_dataA				<= (others=>'0');
		bit_mask_dataB				<= (others=>'0');		
      pr_state							<= state_1;
		ddr2_init_done          <= '0';
 	 else
	
		--Default values for the signals
		ddr2_init_done             <= '1';
		wdf_fifo_in_re					<= '0';
		af_fifo_in_re              <= '0';
		cmd								<= '0';
		we									<= '0';
      data_valid              <= cmd and not we and af_fifo_out_data(63);
     -- rd_data_fifo_out           <= data_fifo_out;
		-- Generate bit-mask. Extend each mask bit to 8 bits and 
		-- construct a 64-bit mask for the 64-bit data
		g1: for i in (APPDATA_WIDTH/8-1) downto 0 loop
			 bit_mask(8*(i+1)-1 downto 8*i) <= (others => wdf_fifo_out_data(APPDATA_WIDTH + i));
		end loop;	
		
		--Read the address fifo if it is not empty
       case (pr_state) is			
			when state_1 =>
				if (af_fifo_out_empty /= '1') then
					--if the (63,64) = 01, write to the memory. But first read to apply masking
					--Read valid 144 bits (data+mask) from the data fifo, and do a read request for next 144-bit
					--Do not increment the addr fifo							
					--Generate the mask data using mask bits stored in 144 downto 129.
					--if the (63,64) = 10, read from the memory
					  addressA			<= af_fifo_out_data(30 downto 0);
					  addressB			<= af_fifo_out_data(61 downto 31);	
					  if (af_fifo_out_data(63 downto 62)="01") then
							cmd				<= '1';
							we					<= '0';					
						   bit_mask_dataA <= wdf_fifo_out_data(63 downto 0);							
						   bit_mask_dataB	<= wdf_fifo_out_data(127 downto 64);
							wdf_fifo_in_re  <= '1';  
					      pr_state 		<= state_2;							
					  elsif (af_fifo_out_data(63 downto 62)="10") then   
  							cmd				<= '1';
							we					<= '0';
							pr_state 		<= state_4;
					  end if;					 
				end if;
			
			--Wait until valid data has been read from the memory at location A and B
			--Use the mask data to write the modified data to location A and B
			when state_2 => 
			   if (valid = '1') then
				  datainA	           <= ((DataoutA and bit_mask(63 downto 0)) or (bit_mask_dataA and (not bit_mask(63 downto 0))));  
				  datainB			     <= ((DataoutB and bit_mask(127 downto 64)) or (bit_mask_dataB and (not bit_mask(127 downto 64))));
				  cmd				         <= '0';
				  we					      <= '1';				  
				  pr_state 			      <= state_3;
            end if;
			
			--By this cycle the next 128-bit data from the data fifo is available.
			--Generate the mask data using mask bits stored in 144 downto 129 bits
			--Increment the address to read present data from the next 2 locations of the memory
			when state_3 => 		
					cmd				       <= '1';
					we					       <= '0';					
					bit_mask_dataA        <= wdf_fifo_out_data(63 downto 0);							
					bit_mask_dataB	       <= wdf_fifo_out_data(127 downto 64);
					
					addressA(1 downto 0)  <= std_logic_vector(unsigned(af_fifo_out_data(1 downto 0))+2);
					addressA(30 downto 2) <= af_fifo_out_data(30 downto 2);
					addressB(1 downto 0)  <= std_logic_vector(unsigned(af_fifo_out_data(1 downto 0))+3);
					addressB(30 downto 2) <= af_fifo_out_data(30 downto 2);				
					
					pr_state 		       <= state_4;				
					
			--Wait until valid data has been read from the memory at location A and B
			--Use the mask data to write the modified data to location A and B
			--For Write- Perform a read request to the data fifo, so that valid data is available next time
			--For Read- Perform a read request to the addr fifo, so that valid addr is available next time
			when state_4 =>
			   --Write
				if (af_fifo_out_data(63 downto 62)="01") and (valid = '1') then					     				
						cmd					  <= '0';
						we						  <= '1';
				      datainA	           <= ((DataoutA and bit_mask(63 downto 0)) or (bit_mask_dataA and (not bit_mask(63 downto 0))));  
 				      datainB			     <= ((DataoutB and bit_mask(127 downto 64)) or (bit_mask_dataB and (not bit_mask(127 downto 64))));
						wdf_fifo_in_re 	  <= '1';		 --Write request for next data from fifo will happen only if write command was issues								
						af_fifo_in_re       <= '1'; --2 128-bit packet have been read, request the next address from af_fifo										
					   pr_state 			  <= state_5;
				--Read		
				elsif (af_fifo_out_data(63 downto 62)="10") then		
						
						af_fifo_in_re         <= '1'; --2 128-bit packet have been read, request the next address from af_fifo				
						cmd				 		 <= '1';
						we							 <= '0';
						
						addressA(1 downto 0)  <= std_logic_vector(unsigned(af_fifo_out_data(1 downto 0))+2);
						addressA(30 downto 2) <= af_fifo_out_data(30 downto 2);
						addressB(1 downto 0)  <= std_logic_vector(unsigned(af_fifo_out_data(1 downto 0))+3);
						addressB(30 downto 2) <= af_fifo_out_data(30 downto 2);
						
						pr_state 				 <= state_5;
				end if;
				 				 
				  
			when state_5 => --one cycle delay in reading new data from the fifo
				  pr_state 				<= state_1;				  
				  
			end case;
			
		end if; --rst
	end if; --sys_clk_p		

end process;
end architecture behavioral;
