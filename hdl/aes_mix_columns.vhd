----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of AES  
-- Date         : 10.11.2025
----------------------------------------------------------------------------------
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes_mix_columns is
    port ( 
        mix_i :  in std_logic_vector (127 downto 0); --! 128-Bit state, whose columns will be mixed
        mix_o : out std_logic_vector (127 downto 0)  --! 128-Bit mixed state 
    );
end aes_mix_columns;
 
 
architecture behavioral of  aes_mix_columns is
 
    -- constants --
    constant C_IS_LOOKUP        : boolean := True;
    constant C_BYTES_IN_STATE   : integer := 16; --! Number of bytes in a state, where AES state is 128-bit.

    -- types --
    type t_byte_array is array(natural range <>) of std_logic_vector(7 downto 0); --! Generic size byte array

    -- signals --
    signal inp_mult_by2 : t_byte_array(0 to C_BYTES_IN_STATE-1); --! Input multiplied by 2
    signal inp_mult_by3 : t_byte_array(0 to C_BYTES_IN_STATE-1); --! Input multiplied by 3
 
begin
 
    -- multiply each byte by 2
    g_mult_by2: for i in 0 to C_BYTES_IN_STATE-1 generate
        i_mult2 : entity work.aes_mult_mod_gf 
            port map ( mult_mod_i => mix_i(127-8*i downto 120-8*i), mult_by_3_i => '0', mult_mod_o => inp_mult_by2(i));
    end generate;
 
    -- multiply each byte by 3, indexes are reordered according to mds matrix of aes 
    i_m3_0  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i(119 downto 112),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 0));
    i_m3_1  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i(111 downto 104),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 1));
    i_m3_2  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i(103 downto  96),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 2));
    i_m3_3  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i(127 downto 120),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 3));
    i_m3_4  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 87 downto  80),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 4));
    i_m3_5  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 79 downto  72),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 5));
    i_m3_6  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 71 downto  64),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 6));
    i_m3_7  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 95 downto  88),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 7));
    i_m3_8  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 55 downto  48),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 8));
    i_m3_9  : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 47 downto  40),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3( 9));
    i_m3_10 : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 39 downto  32),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3(10));
    i_m3_11 : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 63 downto  56),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3(11));
    i_m3_12 : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 23 downto  16),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3(12));
    i_m3_13 : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 15 downto   8),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3(13));
    i_m3_14 : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i(  7 downto   0),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3(14));
    i_m3_15 : entity work.aes_mult_mod_gf port map (mult_mod_i => mix_i( 31 downto  24),mult_by_3_i =>'1',mult_mod_o => inp_mult_by3(15));
    
    mix_o(127 downto 120) <= inp_mult_by2(0 ) xor inp_mult_by3( 0) xor mix_i(111 downto 104) xor mix_i(103 downto  96) ;
    mix_o(119 downto 112) <= inp_mult_by2(1 ) xor inp_mult_by3( 1) xor mix_i(127 downto 120) xor mix_i(103 downto  96) ;
    mix_o(111 downto 104) <= inp_mult_by2(2 ) xor inp_mult_by3( 2) xor mix_i(127 downto 120) xor mix_i(119 downto 112) ; 
    mix_o(103 downto  96) <= inp_mult_by2(3 ) xor inp_mult_by3( 3) xor mix_i(119 downto 112) xor mix_i(111 downto 104) ; 
    mix_o( 95 downto  88) <= inp_mult_by2(4 ) xor inp_mult_by3( 4) xor mix_i( 79 downto  72) xor mix_i( 71 downto  64) ; 
    mix_o( 87 downto  80) <= inp_mult_by2(5 ) xor inp_mult_by3( 5) xor mix_i( 95 downto  88) xor mix_i( 71 downto  64) ; 
    mix_o( 79 downto  72) <= inp_mult_by2(6 ) xor inp_mult_by3( 6) xor mix_i( 95 downto  88) xor mix_i( 87 downto  80) ; 
    mix_o( 71 downto  64) <= inp_mult_by2(7 ) xor inp_mult_by3( 7) xor mix_i( 87 downto  80) xor mix_i( 79 downto  72) ; 
    mix_o( 63 downto  56) <= inp_mult_by2(8 ) xor inp_mult_by3( 8) xor mix_i( 47 downto  40) xor mix_i( 39 downto  32) ; 
    mix_o( 55 downto  48) <= inp_mult_by2(9 ) xor inp_mult_by3( 9) xor mix_i( 63 downto  56) xor mix_i( 39 downto  32) ; 
    mix_o( 47 downto  40) <= inp_mult_by2(10) xor inp_mult_by3(10) xor mix_i( 63 downto  56) xor mix_i( 55 downto  48) ; 
    mix_o( 39 downto  32) <= inp_mult_by2(11) xor inp_mult_by3(11) xor mix_i( 55 downto  48) xor mix_i( 47 downto  40) ; 
    mix_o( 31 downto  24) <= inp_mult_by2(12) xor inp_mult_by3(12) xor mix_i( 15 downto   8) xor mix_i(  7 downto   0) ; 
    mix_o( 23 downto  16) <= inp_mult_by2(13) xor inp_mult_by3(13) xor mix_i( 31 downto  24) xor mix_i(  7 downto   0) ;
    mix_o( 15 downto   8) <= inp_mult_by2(14) xor inp_mult_by3(14) xor mix_i( 31 downto  24) xor mix_i( 23 downto  16) ; 
    mix_o(  7 downto   0) <= inp_mult_by2(15) xor inp_mult_by3(15) xor mix_i( 23 downto  16) xor mix_i( 15 downto   8) ; 
 
end behavioral;