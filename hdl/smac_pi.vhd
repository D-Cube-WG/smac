----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_pi is
    generic (
        G_SMAC_VARIANT : integer := 1 --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
    );
    port (
        a1_i      : in std_logic_vector(127 downto 0);
        a2_i      : in std_logic_vector(127 downto 0);
        a3_i      : in std_logic_vector(127 downto 0);
        message_i : in std_logic_vector(127 downto 0);

        a1_o : out std_logic_vector(127 downto 0);
        a2_o : out std_logic_vector(127 downto 0);
        a3_o : out std_logic_vector(127 downto 0)
    );
end entity smac_pi;

architecture rtl of smac_pi is

    -- constant declarations
    constant C_REG_WIDTH : integer := 128;

    -- signal declarations
    signal l_a1 : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal l_a2 : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal l_a3 : std_logic_vector(C_REG_WIDTH - 1 downto 0);

    signal l_xor_o : std_logic_vector(C_REG_WIDTH - 1 downto 0);

begin

    l_xor_o <= a2_i xor a3_i xor message_i;
    
    U_SMAC_PERM : entity work.smac_perm
        generic map(
            G_SMAC_VARIANT => G_SMAC_VARIANT --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        )
        port map(
            smac_perm_i => l_xor_o,
            smac_perm_o => l_a1
        );

    U_AES_ROUND_0 : entity work.aes_round
        port map(
            round_data_i => a1_i,      --! 128-bit Round input data 
            round_key_i  => message_i, --! 128-bit Round key
            round_data_o => l_a2       --! 128-bit Round output data
        );

    U_AES_ROUND_1 : entity work.aes_round
        port map(
            round_data_i => a2_i,      --! 128-bit Round input data 
            round_key_i  => message_i, --! 128-bit Round key
            round_data_o => l_a3       --! 128-bit Round output data
        );

    --combinational assigments
    a1_o <= l_a1;
    a2_o <= l_a2;
    a3_o <= l_a3;

end architecture rtl;