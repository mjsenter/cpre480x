-------------------------------------------------------------------------
-- Michael Steffen
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- graphicsPipe.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains top-level module for the 3D graphics
-- pipeline. 
--
-- NOTES:
-- 1/20/11 by JAZ::Redesign for SGP_V2_0. 
-- 10/12/10 by MAS::Design created.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.SGP_config.all;

entity graphicsPipe is

     port (clk100  : in std_logic;
		 	  rst		 : in std_logic;
			  
			  -- Connections to hostBus
			  hostBusMaster      : in hostBusMaster_t;
			  hostBusSlaves	   : out hostBusSlave_a(SGP_HOSTBUS_PES-2 downto 0);
			  			  
			  -- Connections to cacheArbiter
			  cacheArbiterReqs    : out cacheArbiterReq_a(0 to SGP_CACHEARB_PES-2);
			  cacheArbiterGrants  : in cacheArbiterGrant_a(0 to SGP_CACHEARB_PES-2);
			  
			  -- Texture unit memory interface to cache
			  memOps_data			: in std_logic_vector(31 downto 0);
			  memOps_valid			: in std_logic;
			  memOps_count			: in std_logic_vector(31 downto 0);
			  memOps_full			: out std_logic;
			  
			  -- Display buffer address
			  disp_fb_address		 : out std_logic_vector(FB_BASE_ADDRESS_BITS-1 downto 0);
			  
			  packetError    : out std_logic);
end graphicsPipe;


architecture structure of graphicsPipe is

  -- Front of the pipeline
  component pipeFront
	  generic(BUS_ADDRESS : integer);
     port (clk100  : in std_logic;
		 	  rst		 : in std_logic;
			  
			  -- Connections to the hostBus
			  hostBusMaster  : in hostBusMaster_t;
			  hostBusSlave   : out hostBusSlave_t;
			  
			  -- Downpipe connection for the primitive queue data
		     pipeFrontData  : out pipeFrontData_t;
			  pipeStall      : in std_logic);			  
  end component;

  -- Pixel processing stage
  component pixelOps 
	  generic(BUS_ADDRESS : integer);
     port (clk100  : in std_logic;
		 	  rst		 : in std_logic;
			  
			  -- Connections to the hostBus
			  hostBusMaster   : in hostBusMaster_t;
			  hostBusSlave    : out hostBusSlave_t;
			  
			  -- Uppipe connection for the vertex data
		     pipeFrontData   : in  pipeFrontData_t;
			  pipeStall       : out std_logic;
			  
			  -- Downpipe connection to the cacheArbiter
			  cacheArbiterReq    : out cacheArbiterReq_t;
			  cacheArbiterGrant  : in cacheArbiterGrant_t);
			  
  end component;
 
  -- Signals to connect pipeFront to pixelOps
  signal pipeFront2PixelOpsData	: pipeFrontData_t;
  signal stallPixelOps2PipeFront	: std_logic;

begin

	-- signals that will be used in other MPs
	memOps_full 		<= '0';
   disp_fb_address	<= (others => '0');
	packetError			<= '0';


  -- Connect the front of the pipeline to the hostBus and downpipe
  u_pipeFront: pipeFront
	  generic map(BUS_ADDRESS	    => PIPEFRONT_BUS_ADDRESS)
     port map(clk100  				 => clk100,
		 	     rst		 				 => rst,  
			     
				  -- Connections to the hostBus. The slave return values are logically ORed together
			     hostBusMaster       => hostBusMaster,
			     hostBusSlave        => hostBusSlaves(0),
			  
			     -- Downpipe connection for the primitive queue data
		        pipeFrontData   	=> pipeFront2PixelOpsData,
				  pipeStall			   => stallPixelOps2PipeFront);


  -- Connect the pixelOps to the hostBus and downpipe
  u_pixelOps: pixelOps
	  generic map(BUS_ADDRESS	    => PIXELOPS_BUS_ADDRESS)
     port map(clk100  				 => clk100,
		 	     rst		 				 => rst,  
			     
				  -- Connections to the hostBus. The slave return values are logically ORed together
			     hostBusMaster       => hostBusMaster,
			     hostBusSlave        => hostBusSlaves(1),
			  
			     -- Uppipe connection for the primitive queue data
		        pipeFrontData       => pipeFront2PixelOpsData,
				  pipeStall           => stallPixelOps2PipeFront,
				  
				  -- Connection to the cacheArbiter. Provide it a unique port. 
				  cacheArbiterReq     => cacheArbiterReqs(0),
				  cacheArbiterGrant   => cacheArbiterGrants(0));					  


end structure;