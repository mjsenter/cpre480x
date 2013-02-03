-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-- memInit.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file implements the initialization of the 
-- entire framebuffer memory to a predefined constant.
-- NOTES:
-- 07/25/10 by JAZ::Design created.
-------------------------------------------------------------------------

LIBRARY IEEE;
use IEEE.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
use IEEE.numeric_std.ALL;
use WORK.SGP_config.all;
 
entity memInit is
  generic (INIT_COLOR			 : std_logic_vector(31 downto 0) := (others=>'0');
	  	     NUM_ROWS	          : integer := 2048;	-- 1280 goes to higher power 2 = 2048
		     NUM_COLS            : integer := 4096);
  port(clk200	                : in std_logic;
	    rst		                : in std_logic;
       init_ddr2app_af_afull   : in std_logic;
	    init_ddr2app_wdf_afull  : in std_logic;
       init_ddr2app_cmd        : out ddr2app_cmd;
	    init_done			       : out std_logic);
end memInit;

architecture behavior of memInit is

-- Note: for 1280x1024 resolution, we are storing 2 pixels per memory 
-- addr, and consequently there are 640 writes per row (640*4 = 1280). 
-- To make this a power of 2 for simple address math we simply  
-- extend the framebuffer to include 1024 values per row. For this 
-- module this becomes a non-issue because we initialize all of the 
-- buffer, not just the entries that correspond to the pixels on the 
-- screen. 

signal fb_addr	               : std_logic_vector(31 downto 0);

signal write_cnt					: integer range 0 to NUM_ROWS*NUM_COLS/4;
signal afull, state           : std_logic;

begin

   afull <= init_ddr2app_af_afull or init_ddr2app_wdf_afull;
	
	--Const outputs
	init_ddr2app_cmd.wdf_data <= INIT_COLOR & INIT_COLOR & INIT_COLOR & INIT_COLOR;
	
	
	process(clk200) 
	begin
	if (rising_edge(clk200)) then
		if (rst = '1') then
         init_ddr2app_cmd.af_wren <= '0';
         init_ddr2app_cmd.wdf_wren <= '0';
			--init_ddr2app_cmd.wdf_data <= (others => '0');
			init_ddr2app_cmd.wdf_mask_data <= (others => '0');
			init_ddr2app_cmd.af_cmd <= (others => '0');
			init_done <= '0';
			fb_addr <= (others => '0');
			write_cnt <= 0;
			state <= '0';
			
      else
		   init_ddr2app_cmd.af_addr <= fb_addr(30 downto 0);
			--init_ddr2app_cmd.wdf_data <= fb_addr & fb_addr &  fb_addr & fb_addr;
			init_ddr2app_cmd.wdf_mask_data <= (others => '0');
			init_ddr2app_cmd.af_cmd <= "000";

         
         init_done <= '0';
		 	
         -- If we haven't initialized a full frame, keep the bus
         if ((write_cnt < NUM_ROWS*NUM_COLS/4) and (afull = '0')) then
             
             init_ddr2app_cmd.wdf_wren <= '1';
				 
               -- Here we set up a trivial 2-state FSM, since the af_wren
				   -- should only be set (and the address incremented) every
				   -- other cycle. 
				 
					if (state = '0') then
				      init_ddr2app_cmd.af_wren <= '1';
					else
				      init_ddr2app_cmd.af_wren <= '0';
					end if;
					fb_addr <= fb_addr + 2;
					state <= not state;

					write_cnt <= write_cnt + 1;
         
         elsif (write_cnt = NUM_ROWS*NUM_COLS/4) then			 
			    init_done  <= '1';
				 init_ddr2app_cmd.wdf_wren <= '0';
				 init_ddr2app_cmd.af_wren <= '0';
         end if;
			 
		end if;
	end if;		
	end process;	
		
end behavior;