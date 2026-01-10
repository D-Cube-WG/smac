----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac is
    generic (
        G_SMAC_VARIANT      : integer := 1;     --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        G_NUM_OF_STREAMS    : integer := 4;     --! Number of parallel SMAC streams
        G_TAG_WIDTH         : integer := 384    --! Tag width in bits
    );
    port(
        clk_i   :  in std_logic;
        rstn_i  :  in std_logic;

        s00_axis_tdata_i  :  in std_logic_vector(G_NUM_OF_STREAMS*384-1 downto 0);
        s00_axis_tvalid_i :  in std_logic;
        s00_axis_tlast_i  :  in std_logic;
        s00_axis_tready_o : out std_logic;

        m00_axis_tdata_o  : out std_logic_vector(G_TAG_WIDTH-1 downto 0);
        m00_axis_tvalid_o : out std_logic;
        m00_axis_tlast_o  : out std_logic; --! Always '1' when tvalid is '1', since tag is single word.
        m00_axis_tready_i :  in std_logic
    );
end entity smac;

architecture rtl of smac is
    
    -- constant declarations
    constant C_KEY_WIDTH : integer := 256;
    constant C_IV_WIDTH  : integer := 128;
    constant C_ONE_STAR  : std_logic_vector(383 downto 0) := x"010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
    -- signal declarations
begin

    --TODO: Sequential SMAC Top implementation
    -- The first s00_axis_tdata_i will contain the KEY and IV information.
    -- The rest will be the actual data to be processed. 
    -- After all data is processed, the tag will be output on m00_axis_tdata_o.

    -- Use only ONE smac_N_pi and ONE smac_xor instance here.

    --! Use appropriate FSM to control the data flow.
    --! --> ST_SMAC_INIT, 
    --! --> ST_SMAC_COMPRESSION,
    --! --> ST_SMAC_FINALIZE_1, 
    --! --> ST_SMAC_FINALIZE_2 
    --! states are suggested.

end architecture rtl;