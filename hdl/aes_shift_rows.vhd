----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of AES  
-- Date         : 10.11.2025
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity aes_shift_rows is
    port (
        shift_rows_i :  in std_logic_vector (127 downto 0); --! 128-Bit state, whose rows will be shifted
        shift_rows_o : out std_logic_vector (127 downto 0)  --! 128-Bit shifted state
    ); 
end aes_shift_rows;

architecture behavioral of aes_shift_rows is

begin
        
    --! The first row is stayed the same
    shift_rows_o(127 downto 120) <= shift_rows_i(127 downto 120);
    shift_rows_o(119 downto 112) <= shift_rows_i(87 downto 80);
    shift_rows_o(111 downto 104) <= shift_rows_i(47 downto 40);
    shift_rows_o(103 downto  96) <= shift_rows_i(7 downto 0); 

    --! The second row is shifted by one byte
    shift_rows_o( 95 downto  88) <= shift_rows_i(95 downto 88);
    shift_rows_o( 87 downto  80) <= shift_rows_i(55 downto 48);
    shift_rows_o( 79 downto  72) <= shift_rows_i(15 downto 8);
    shift_rows_o( 71 downto  64) <= shift_rows_i(103 downto 96);

    --! The third row is shifted by two bytes
    shift_rows_o( 63 downto  56) <= shift_rows_i(63 downto 56);
    shift_rows_o( 55 downto  48) <= shift_rows_i(23 downto 16);
    shift_rows_o( 47 downto  40) <= shift_rows_i(111 downto 104);
    shift_rows_o( 39 downto  32) <= shift_rows_i(71 downto 64);

    --! The fourth row is shifted by three bytes
    shift_rows_o( 31 downto  24) <= shift_rows_i(31 downto 24);
    shift_rows_o( 23 downto  16) <= shift_rows_i(119 downto 112);
    shift_rows_o( 15 downto   8) <= shift_rows_i(79 downto 72);
    shift_rows_o(  7 downto   0) <= shift_rows_i(39 downto 32);

end behavioral;

 