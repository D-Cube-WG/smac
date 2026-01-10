----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_xor is
    generic (
        G_NUM_OF_STREAMS    : integer := 4  --! Number of parallel SMAC streams
    );
    port(
        --clk_i   :  in std_logic; --! Future Work: If there is critical path problem!  
        --rstn_i  :  in std_logic; --! Future Work: If there is critical path problem!  
        --vld_i   :  in std_logic; --! Future Work: If there is critical path problem!  
        --vld_o   : out std_logic; --! Future Work: If there is critical path problem!  
        xor_i   :  in std_logic_vector(G_NUM_OF_STREAMS*384-1 downto 0);
        xor_o   : out std_logic_vector(383 downto 0);
    );
end entity smac_xor;    

architecture rtl of smac_xor is

    -- constant declarations

    -- signal declarations

begin

    --TODO: Combinational SMAC XOR implementation
    --! Future Work: If there critical path problem!
    --! Use log(G_NUM_OF_STREAMS) levels of XOR tree structure

end architecture rtl;