----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_xor_2 is
    port (
        --clk_i   :  in std_logic; --! Future Work: If there is critical path problem!  
        --rstn_i  :  in std_logic; --! Future Work: If there is critical path problem!  
        --vld_i   :  in std_logic; --! Future Work: If there is critical path problem!  
        --vld_o   : out std_logic; --! Future Work: If there is critical path problem!  
        in0_i : in std_logic_vector(127 downto 0);
        in1_i : in std_logic_vector(127 downto 0);

        xor_o : out std_logic_vector(127 downto 0)
    );
end entity smac_xor_2;

architecture rtl of smac_xor_2 is

    -- constant declarations
    constant C_REG_SIZE : integer := 128;

    -- signal declarations

begin

    --TODO: Combinational SMAC XOR implementation
    --! Future Work: If there critical path problem!
    --! Use log(G_NUM_OF_STREAMS) levels of XOR tree structure

    xor_o <= in0_i xor in1_i;

end architecture rtl;