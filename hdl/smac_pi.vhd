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
        G_SMAC_VARIANT  : integer := 1  --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
    );
    port(
        state_i   :  in std_logic_vector(383 downto 0);
        key_i     :  in std_logic_vector(127 downto 0);
        state_o   : out std_logic_vector(383 downto 0);
    );
end entity smac_pi;

architecture rtl of smac_pi  is

    -- constant declarations

    -- signal declarations

begin

    --TODO: Combinational SMAC PI implementation
    --! Use smac_perm instance here.
    --! Use two aes_round instances here.
end architecture rtl;