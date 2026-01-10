----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_N_pi is
    generic(
        G_SMAC_VARIANT      : integer := 1; --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        G_NUM_OF_STREAMS    : integer := 4  --! Number of parallel SMAC streams
    );
    port(
        state_i   :  in std_logic_vector(384*G_NUM_OF_STREAMS-1 downto 0);
        key_i     :  in std_logic_vector(127 downto 0);
        state_o   : out std_logic_vector(384*G_NUM_OF_STREAMS-1 downto 0);
    );
end entity smac_N_pi;

architecture rtl of smac_N_pi is

    -- constant declarations

     -- signal declarations

begin

    --TODO: Combinational SMACxN PI implementation
    --! Use G_NUM_OF_STREAMS number of smac_pi instances here.


end architecture rtl;