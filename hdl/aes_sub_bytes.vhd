----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of AES  
-- Date         : 10.11.2025
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes_sub_bytes is
    generic (
        G_IS_LOOKUP : boolean := False  --! If True, S-Box is implemented using lookup table
    );
    port (
        sb_i :  in std_logic_vector (127 downto 0);  --! 128-Bit input word, which will be substituted.
        sb_o : out std_logic_vector (127 downto 0)   --! 128-Bit output word, after substitution operation.
    );  
end aes_sub_bytes;

architecture behavioral of aes_sub_bytes is

begin

    -- Apply S-Box operation on each byte simultaneously
    g_sub_word: for i in 0 to 15 generate
        i_sb : entity work.aes_sbox 
            generic map (
                G_IS_LOOK_UP => G_IS_LOOKUP
            )
            port map ( sbox_i => sb_i(127-8*i downto 120-8*i), sbox_o => sb_o(127-8*i downto 120-8*i) );
    end generate;

end behavioral;