----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_perm is
    generic (
        G_SMAC_VARIANT  : integer := 1  --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
    );
    port(
        smac_perm_i :  in std_logic_vector(127 downto 0);
        smac_perm_o : out std_logic_vector(127 downto 0);
    );
end entity smac_perm;

architecture rtl of smac_perm  is
    
    -- constant declarations
    --! perm_table = {0,7,14,11,4,13,10,1,8,15,6,3,12,5,2,9} for SMAC-1
    --! perm_table = {7,14,15,10,12,13,3,0,4,6,1,5,8,11,2,9} for SMAC-3/4
    --! perm_table = {0,11,7,14,6,4,1,x15,9,3,8,5,13,2,10,12} for SMAC-1/2
    
    -- signal declarations

begin

    --TODO: Combinational SMAC PERM implementation 

end architecture rtl;