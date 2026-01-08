----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of AES  
-- Date         : 10.11.2025
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity aes_mult_mod_gf is
    port (
        mult_mod_i  :  in std_logic_vector(7 downto 0);   --! 8-Bit input value, which will be multiplied
        mult_by_3_i :  in std_logic;                      --! If '1' then multiply by 3, else by 2
        mult_mod_o  : out std_logic_vector(7 downto 0)    --! Modulo value of input value
    ); 
end aes_mult_mod_gf;

architecture behavioral of aes_mult_mod_gf is

    -- constants --
    constant C_IRRPOLY : std_logic_vector(7 downto 0) := x"1B"; --! Hex notation of AES irr. poly, g(x) = x^8+x^4+x^3+x^1+1

    -- signals --
    signal multiplied_val : std_logic_vector(8 downto 0); 

begin

    --------------------------------------------------------
    -- pr_mult: Multiplication operation, 
    -- Input is multiplied by 2 or 3 according to mult_by_3_i 
    --------------------------------------------------------
    pr_mult: process (mult_by_3_i,mult_mod_i) is
    begin
        mult_if: if (mult_by_3_i = '1') then  --! Multiply by 3
            multiplied_val <= (mult_mod_i & '0') xor ('0' & mult_mod_i);
        else --! Multiply by 2, simply shift operation
            multiplied_val <= (mult_mod_i & '0'); 
        end if;
    end process;

    --------------------------------------------------------
    -- pr_modulo: Modulo operation on Galois Field of AES
    --------------------------------------------------------
    pr_modulo: process (multiplied_val) is
    begin
        mod_if: if (multiplied_val(8) = '1') then  --! Check msb of input, then apply XOR
            mult_mod_o <= (multiplied_val(7 downto 0) xor C_IRRPOLY);
        else --! return last 8-bit of multiplied result  
            mult_mod_o <= multiplied_val(7 downto 0); 
        end if;
    end process;

end behavioral;