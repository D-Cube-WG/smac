----------------------------------------------------------------------------------
-- Author       : Hakan GULER
-- Project Name : SMAC
-- Date         : 11.01.2026
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_perm is
    generic (
        G_SMAC_VARIANT : integer := 1 --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
    );
    port (
        smac_perm_i : in std_logic_vector(127 downto 0);
        smac_perm_o : out std_logic_vector(127 downto 0)
    );
end entity smac_perm;

architecture rtl of smac_perm is

    --type declarations
    type t_permutation_array is array (0 to 15) of integer;

    -- constant declarations
    constant C_PERM_ARRAY_ZEROS    : t_permutation_array := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    constant C_PERM_ARRAY_SMAC_1   : t_permutation_array := (0, 7, 14, 11, 4, 13, 10, 1, 8, 15, 6, 3, 12, 5, 2, 9);
    constant C_PERM_ARRAY_SMAC_3_4 : t_permutation_array := (7, 14, 15, 10, 12, 13, 3, 0, 4, 6, 1, 5, 8, 11, 2, 9);
    constant C_PERM_ARRAY_SMAC_1_2 : t_permutation_array := (0, 11, 7, 14, 6, 4, 1, 15, 9, 3, 8, 5, 13, 2, 10, 12);

    --functions declerationss
    function f_select_perm_array(smac_type : integer) return t_permutation_array is
        variable v_perm_array                  : t_permutation_array;
    begin
        case smac_type is
            when 1 =>
                v_perm_array := C_PERM_ARRAY_SMAC_1;
            when 2 =>
                v_perm_array := C_PERM_ARRAY_SMAC_3_4;
            when 3 =>
                v_perm_array := C_PERM_ARRAY_SMAC_1_2;
            when others =>
                v_perm_array := C_PERM_ARRAY_ZEROS;
        end case;
        return v_perm_array;
    end function f_select_perm_array;

    constant C_PERM_TYPE : t_permutation_array := f_select_perm_array(G_SMAC_VARIANT);

    -- signal declarations
    signal l_smac_perm_o : std_logic_vector(127 downto 0);
begin

    --Combinational SMAC PERM implementation

    G0 : for i in 0 to 15 generate
        l_smac_perm_o(l_smac_perm_o'left - i * 8 downto l_smac_perm_o'length - (i + 1) * 8) <=
        smac_perm_i(smac_perm_i'left - 8 * C_PERM_TYPE(i) downto smac_perm_i'length - 8 * (C_PERM_TYPE(i) + 1));
    end generate G0;

    smac_perm_o <= l_smac_perm_o;
end architecture rtl;