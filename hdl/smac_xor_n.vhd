----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_xor_n is
    generic (
        G_DATA_WIDTH    : integer := 128;
        G_NUM_OF_INPUTS : integer := 16
    );
    port (
        --clk_i   :  in std_logic; --! Future Work: If there is critical path problem!  
        --rstn_i  :  in std_logic; --! Future Work: If there is critical path problem!  
        --vld_i   :  in std_logic; --! Future Work: If there is critical path problem!  
        --vld_o   : out std_logic; --! Future Work: If there is critical path problem!  
        in0_i : in std_logic_vector(G_DATA_WIDTH * G_NUM_OF_INPUTS - 1 downto 0);

        xor_o : out std_logic_vector(G_DATA_WIDTH - 1 downto 0)
    );
end entity smac_xor_n;

architecture rtl of smac_xor_n is
begin

    -- Combinatorial process to XOR the sub-vectors
    process (in0_i)
        variable v_xor_result : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    begin
        -- Initialize the variable with the first segment of the input
        v_xor_result := in0_i(G_DATA_WIDTH - 1 downto 0);

        -- Loop through the remaining segments (from 1 to G_NUM_OF_INPUTS - 1)
        for i in 1 to G_NUM_OF_INPUTS - 1 loop
            v_xor_result := v_xor_result xor in0_i((i + 1) * G_DATA_WIDTH - 1 downto i * G_DATA_WIDTH);
        end loop;

        -- Assign the final accumulated result to the output
        xor_o <= v_xor_result;
    end process;

end architecture rtl;