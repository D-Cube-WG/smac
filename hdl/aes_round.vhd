----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of AES  
-- Date         : 10.11.2025
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes_round is
    port ( 
        round_data_i :  in std_logic_vector (127 downto 0);  --! 128-bit Round input data 
        round_key_i  :  in std_logic_vector (127 downto 0);  --! 128-bit Round key
        round_data_o : out std_logic_vector (127 downto 0)   --! 128-bit Round output data
	 );
end aes_round;

architecture behavioral of aes_round is

    -- signals -- 
    signal s_out    :  std_logic_vector (127 downto 0); --! Output of sub_bytes layer
    signal m_in     :  std_logic_vector (127 downto 0); --! Input of mix_columns layer
    signal m_out    :  std_logic_vector (127 downto 0); --! Output of mix_columns layer
	
    -- constants --
    constant C_IS_LOOKUP : boolean := False;  --! Use lookup table implementation
    
begin

    --! Sub bytes operation
    i_sub_bytes: entity work.aes_sub_bytes 
        generic map(
            G_IS_LOOKUP => C_IS_LOOKUP  --! Use lookup table implementation
        )
        port map(
            sb_i => round_data_i, 
            sb_o => s_out
        );
    --! Shift rows operation
    i_shift_rows: entity work.aes_shift_rows 
        port map(
            shift_rows_i => s_out, 
            shift_rows_o => m_in
        );
    --! Mix columns operation
    i_mix_columns: entity work.aes_mix_columns 
        port map(
            mix_i => m_in,
            mix_o => m_out
        );
    --! Add round key operation
	i_add_round_key: entity work.aes_add_key 
        port map(
            add_rnd1_i  => m_out ,
            add_rnd2_i  => round_key_i, 
            add_rnd_o   => round_data_o
        ); 
    
	



end behavioral;
