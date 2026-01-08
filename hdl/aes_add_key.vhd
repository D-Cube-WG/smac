----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of AES  
-- Date         : 10.11.2025
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes_add_key is
    port(
        add_rnd1_i  :  in std_logic_vector (127 downto 0);  --! first input of add round key module 
        add_rnd2_i  :  in std_logic_vector (127 downto 0); --! second input of add round key module
        add_rnd_o   : out std_logic_vector (127 downto 0)  --! XOR of first and second inputs
    ); 
end aes_add_key;

architecture behavioral of aes_add_key is

begin   
    --! This module returns XOR of first and second inputs
    add_rnd_o <= add_rnd1_i xor add_rnd2_i;

end behavioral;
