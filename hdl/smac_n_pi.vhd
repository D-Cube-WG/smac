----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of smac_n_pi  
-- Date         : 18.02.2026
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_n_pi is
    generic (
        G_SMAC_VARIANT   : integer := 1; --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        G_NUM_OF_STREAMS : integer := 16  --! Number of parallel SMAC streams
    );
    port (
        state_i :  in std_logic_vector(384 * G_NUM_OF_STREAMS - 1 downto 0);
        key_i   :  in std_logic_vector(128 * G_NUM_OF_STREAMS - 1 downto 0);
        state_o : out std_logic_vector(384 * G_NUM_OF_STREAMS - 1 downto 0)
    );
end entity smac_n_pi ;

architecture rtl of smac_n_pi is

    -- constant declarations

    -- signal declarations

begin

    ------------------------------------------------------------------------------
    -- Combinational SMACxN PI implementation
    -- Instantiates G_NUM_OF_STREAMS parallel smac_pi blocks
    ------------------------------------------------------------------------------

    gen_smac_pi : for i in 0 to G_NUM_OF_STREAMS-1 generate

        -- Input slice indices
        constant C_LOW  : integer := i * 384;
        constant C_HIGH : integer := (i+1) * 384 - 1;

    begin

        u_smac_pi : entity work.smac_pi
            generic map (
                G_SMAC_VARIANT => G_SMAC_VARIANT
            )
            port map (
                a1_i      => state_i(C_LOW + 383 downto C_LOW + 256),
                a2_i      => state_i(C_LOW + 255 downto C_LOW + 128),
                a3_i      => state_i(C_LOW + 127 downto C_LOW),
                message_i => key_i(i*128 + 127 downto i*128),

                a1_o => state_o(C_LOW + 383 downto C_LOW + 256),
                a2_o => state_o(C_LOW + 255 downto C_LOW + 128),
                a3_o => state_o(C_LOW + 127 downto C_LOW)
            );

    end generate gen_smac_pi;


end architecture rtl;