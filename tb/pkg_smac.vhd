library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context; --required for info

library work;
use work.pkg_aes.all;
use work.pkg_gnrl.all;

package pkg_smac is
    --constant declarations
    constant C_SMAC_REG_WIDTH : integer := 128;
    --permutations
    type t_permutation_array is array (0 to 15) of integer;
    --type t_permutation_arrays is array (natural range <>) of t_permutation_array; --this will be used when all of the permutations are written as constants
    constant C_PERMUTATION_ARRAY_1 : t_permutation_array := (
        0 => 0, 1 => 7, 2 => 14, 3 => 11, 4 => 4, 5 => 13, 6 => 10, 7 => 1, 8 => 8, 9 => 15, 10 => 6, 11 => 3, 12 => 12, 13 => 5, 14 => 2, 15 => 9
    );
    constant C_PERMUTATION_ARRAY_42 : t_permutation_array := (
        0 => 7, 1 => 14, 2 => 15, 3 => 10, 4 => 12, 5 => 13, 6 => 3, 7 => 0, 8 => 4, 9 => 6, 10 => 1, 11 => 5, 12 => 8, 13 => 11, 14 => 2, 15 => 9
    );
    constant C_PERMUTATION_ARRAY_61 : t_permutation_array := (
        0 => 0, 1 => 11, 2 => 7, 3 => 14, 4 => 6, 5 => 4, 6 => 1, 7 => 15, 8 => 9, 9 => 3, 10 => 8, 11 => 5, 12 => 13, 13 => 2, 14 => 10, 15 => 12
    );

    impure function f_smac_permutation (
        permutation_array : t_permutation_array;
        vec               : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) return std_logic_vector;

    function f_smac_input_vec_length_calculator(
        ad_i : in std_logic_vector;
        cp_i : in std_logic_vector
    ) return integer;

    procedure p_smac_compression(
        permutation_array_i : in t_permutation_array;
        a1_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i                 : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a1_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    );

    procedure p_init_phase(
        permutation_array_i : in t_permutation_array;
        d_i                 : in integer;
        a1_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a1_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    );

    procedure p_compression_phase(
        permutation_array_i : in t_permutation_array;
        m_round_limit_i     : in integer; -- this variable is used for appending 1*. if m_round_limit_i=3 then process a block with m=1* after 3 round of message is processed.
        a1_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i                 : in std_logic_vector;
        a1_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    );

    procedure p_smac_1(
        init_phase_rounds_i  : in integer;
        final_phase_rounds_i : in integer;
        a1_i                 : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i                 : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i                 : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i                  : in std_logic_vector; --message
        a1_o                 : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o                 : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o                 : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    );

    procedure p_smac_3_4(
        a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i  : in std_logic_vector;
        a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    );

    procedure p_smac_1_2(
        a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i  : in std_logic_vector;
        a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    );

    procedure p_generate_smac_input_vector(
        ad_i              : in std_logic_vector;
        cp_i              : in std_logic_vector;
        smac_input_vector : out std_logic_vector
    );

end package pkg_smac;

package body pkg_smac is

    impure function f_smac_permutation (
        permutation_array : t_permutation_array;
        vec               : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) return std_logic_vector is
        variable new_vec      : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable offset_value : integer;
    begin
        for i in 0 to C_SMAC_REG_WIDTH/8 - 1 loop
            offset_value                                                      := permutation_array(i);
            new_vec(new_vec'left - 8 * i downto new_vec'length - 8 * (i + 1)) := vec(new_vec'left - 8 * offset_value downto new_vec'length - 8 * (offset_value + 1));
        end loop;
        return new_vec;
    end function f_smac_permutation;

    function f_smac_input_vec_length_calculator(
        ad_i : in std_logic_vector;
        cp_i : in std_logic_vector
    ) return integer is
        variable v_ad_leftover_bits : integer := C_SMAC_REG_WIDTH - (((ad_i'length - 1) mod C_SMAC_REG_WIDTH) + 1);
        variable v_cp_leftover_bits : integer := C_SMAC_REG_WIDTH - (((cp_i'length - 1) mod C_SMAC_REG_WIDTH) + 1);

        variable len : integer;
    begin
        len := ad_i'length + v_ad_leftover_bits + cp_i'length + v_cp_leftover_bits + C_SMAC_REG_WIDTH;
        return len;
    end function f_smac_input_vec_length_calculator;

    procedure p_generate_smac_input_vector(
        ad_i              : in std_logic_vector;
        cp_i              : in std_logic_vector;
        smac_input_vector : out std_logic_vector
    ) is
        variable v_ad_leftover_bits : integer := C_SMAC_REG_WIDTH - (((ad_i'length - 1) mod C_SMAC_REG_WIDTH) + 1);
        variable v_cp_leftover_bits : integer := C_SMAC_REG_WIDTH - (((cp_i'length - 1) mod C_SMAC_REG_WIDTH) + 1);

        variable v_ad_leftover_zeros : std_logic_vector(v_ad_leftover_bits - 1 downto 0) := (others => '0');
        variable v_cp_leftover_zeros : std_logic_vector(v_cp_leftover_bits - 1 downto 0) := (others => '0');

        variable v_ad_len_vector : std_logic_vector(C_SMAC_REG_WIDTH/2 - 1 downto 0);
        variable v_cp_len_vector : std_logic_vector(C_SMAC_REG_WIDTH/2 - 1 downto 0);
        variable v_len_vector    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

        variable v_vec : std_logic_vector(ad_i'length + v_ad_leftover_bits + cp_i'length + v_cp_leftover_bits + C_SMAC_REG_WIDTH - 1 downto 0);
    begin
        v_ad_len_vector := f_swap_bytes(std_logic_vector(to_unsigned(ad_i'length, C_SMAC_REG_WIDTH/2)));
        v_cp_len_vector := f_swap_bytes(std_logic_vector(to_unsigned(cp_i'length, C_SMAC_REG_WIDTH/2)));
        v_len_vector    := v_ad_len_vector & v_cp_len_vector;

        if (ad_i'length /= 0) then
            v_vec := v_vec(v_vec'length - ad_i'length - 1 downto 0) & ad_i;

            if (v_ad_leftover_bits /= 0) then
                v_vec := v_vec(v_vec'length - v_ad_leftover_zeros'length - 1 downto 0) & v_ad_leftover_zeros;
            end if;
        end if;

        if (cp_i'length /= 0) then
            v_vec := v_vec(v_vec'length - cp_i'length - 1 downto 0) & cp_i;

            if (v_cp_leftover_bits /= 0) then
                v_vec := v_vec(v_vec'length - v_cp_leftover_zeros'length - 1 downto 0) & v_cp_leftover_zeros;
            end if;
        end if;

        smac_input_vector := v_vec(v_vec'length - v_len_vector'length - 1 downto 0) & v_len_vector;

    end procedure p_generate_smac_input_vector;

    procedure p_smac_compression(
        permutation_array_i : in t_permutation_array;
        a1_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i                 : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a1_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) is begin
        --info("INPUT COMPRESSION FUNC | a1_i : " & to_hstring(a1_i) & " | a2_i : " & to_hstring(a2_i) & " | a3_i : " & to_hstring(a3_i) & " | m_i : " & to_hstring(m_i));
        a1_o := f_smac_permutation(permutation_array_i, a2_i xor a3_i xor m_i);
        a2_o := f_aes_round(a1_i, m_i);
        a3_o := f_aes_round(a2_i, m_i);
        --info("OUTPUT COMPRESSION FUNC | a1_o : " & to_hstring(a1_o) & " | a2_o : " & to_hstring(a2_o) & " | a3_o : " & to_hstring(a3_o));
    end procedure p_smac_compression;

    procedure p_init_phase(
        permutation_array_i : in t_permutation_array;
        d_i                 : in integer;
        a1_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a1_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) is
        variable v_a1_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a1_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_m    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    begin
        v_a1_i := a1_i;
        v_a2_i := a2_i;
        v_a3_i := a3_i;
        v_m    := (v_m'left downto v_m'length - 8 => x"01", others => '0');
        --info("d : " & to_string(d));
        --info("BEFORE INIT | a1 : " & to_hstring(v_a1_i) & " | a2 : " & to_hstring(v_a2_i) & " | a3 : " & to_hstring(v_a3_i));
        for i in 0 to d_i - 1 loop
            p_smac_compression(permutation_array_i, v_a1_i, v_a2_i, v_a3_i, v_m, v_a1_o, v_a2_o, v_a3_o);
            v_a1_i := v_a1_o;
            v_a2_i := v_a2_o;
            v_a3_i := v_a3_o;
        end loop;
        a1_o := a1_i xor v_a1_i;
        a2_o := a2_i xor v_a2_i;
        a3_o := a3_i xor v_a3_i;
        --info("AFTER INIT/FINAL        | a1 : " & to_hstring(a1_o) & " | a2 : " & to_hstring(a2_o) & " | a3 : " & to_hstring(a3_o));
    end procedure p_init_phase;

    procedure p_compression_phase(
        permutation_array_i : in t_permutation_array;
        m_round_limit_i     : in integer; -- this variable is used for appending 1*. if m_round_limit_i=3 then process a block with m=1* after 3 round of message is processed.
        a1_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i                : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i                 : in std_logic_vector;
        a1_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o                : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) is
        variable v_a1_i          : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2_i          : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3_i          : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a1_o          : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2_o          : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3_o          : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_m_block       : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_round_counter : integer := 0;

        variable v_num_of_blocks : integer := m_i'length/C_SMAC_REG_WIDTH;
    begin
        v_a1_i := a1_i;
        v_a2_i := a2_i;
        v_a3_i := a3_i;

        --info("BEFORE COMPRESSION PHASE | a1 : " & to_hstring(v_a1_i) & " | a2 : " & to_hstring(v_a2_i) & " | a3 : " & to_hstring(v_a3_i));
        --info("BEFORE COMPRESSION PHASE | ad : " & to_hstring(ad_i) & " | cp : " & to_hstring(cp_i));
        for i in 0 to v_num_of_blocks - 1 loop
            v_m_block := m_i(m_i'left - i * C_SMAC_REG_WIDTH downto m_i'length - (i + 1) * C_SMAC_REG_WIDTH);
            --info("v_m_block_ad  : " & to_hstring(v_m_block));

            p_smac_compression(permutation_array_i, v_a1_i, v_a2_i, v_a3_i, v_m_block, v_a1_o, v_a2_o, v_a3_o);

            v_a1_i := v_a1_o;
            v_a2_i := v_a2_o;
            v_a3_i := v_a3_o;
            --info("AD COMPRESSION PHASE | a1 : " & to_hstring(v_a1_i) & " | a2 : " & to_hstring(v_a2_i) & " | a3 : " & to_hstring(v_a3_i));

            v_round_counter := v_round_counter + 1;
            if (v_round_counter = m_round_limit_i) then
                v_round_counter := 0; --resetting counter
                v_m_block       := (v_m_block'left downto v_m_block'length - 8 => x"01", others => '0');
                p_smac_compression(permutation_array_i, v_a1_i, v_a2_i, v_a3_i, v_m_block, v_a1_o, v_a2_o, v_a3_o);
                v_a1_i := v_a1_o;
                v_a2_i := v_a2_o;
                v_a3_i := v_a3_o;
            end if;
        end loop;

        a1_o := v_a1_o;
        a2_o := v_a2_o;
        a3_o := v_a3_o;
        --info("AFTER COMPRESSION PHASE | a1 : " & to_hstring(a1_o) & " | a2 : " & to_hstring(a2_o) & " | a3 : " & to_hstring(a3_o));
    end procedure p_compression_phase;

    procedure p_smac_1(
        init_phase_rounds_i  : in integer;
        final_phase_rounds_i : in integer;
        a1_i                 : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i                 : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i                 : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i                  : in std_logic_vector; --message
        a1_o                 : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o                 : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o                 : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) is
        variable v_a1                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a1_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        constant C_LIMIT_FOR_APPENDING_DUMMY_ROUND : integer := 0; --this constant is used for appending 1* into the compression phase. 0:dont append any dummy rounds
    begin

        p_init_phase(C_PERMUTATION_ARRAY_1, init_phase_rounds_i, a1_i, a2_i, a3_i, v_a1_o, v_a2_o, v_a3_o);

        v_a1 := v_a1_o;
        v_a2 := v_a2_o;
        v_a3 := v_a3_o;

        p_compression_phase(C_PERMUTATION_ARRAY_1, C_LIMIT_FOR_APPENDING_DUMMY_ROUND, v_a1, v_a2, v_a3, m_i, v_a1_o, v_a2_o, v_a3_o);

        v_a1 := v_a1_o;
        v_a2 := v_a2_o;
        v_a3 := v_a3_o;

        p_init_phase(C_PERMUTATION_ARRAY_1, final_phase_rounds_i, v_a1, v_a2, v_a3, v_a1_o, v_a2_o, v_a3_o);
        a1_o := v_a1_o;
        a2_o := v_a2_o;
        a3_o := v_a3_o;
    end procedure p_smac_1;

    procedure p_smac_3_4(
        a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i  : in std_logic_vector;
        a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) is
        variable v_a1                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a1_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_d                               : integer := 9; --turn this into a global constant
        constant C_LIMIT_FOR_APPENDING_DUMMY_ROUND : integer := 3; --this constant is used for appending 1* into the compression phase.
    begin
        p_init_phase(C_PERMUTATION_ARRAY_42, v_d, a1_i, a2_i, a3_i, v_a1_o, v_a2_o, v_a3_o);
        v_a1 := v_a1_o;
        v_a2 := v_a2_o;
        v_a3 := v_a3_o;
        p_compression_phase(C_PERMUTATION_ARRAY_42, C_LIMIT_FOR_APPENDING_DUMMY_ROUND, v_a1, v_a2, v_a3, m_i, v_a1_o, v_a2_o, v_a3_o);
        v_a1 := v_a1_o;
        v_a2 := v_a2_o;
        v_a3 := v_a3_o;
        p_init_phase(C_PERMUTATION_ARRAY_42, v_d, v_a1, v_a2, v_a3, v_a1_o, v_a2_o, v_a3_o);
        a1_o := v_a1_o;
        a2_o := v_a2_o;
        a3_o := v_a3_o;
    end procedure p_smac_3_4;

    procedure p_smac_1_2(
        a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i  : in std_logic_vector;
        a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) is
        variable v_a1                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3                              : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a1_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3_o                            : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_d                               : integer := 9; --turn this into a global constant
        constant C_LIMIT_FOR_APPENDING_DUMMY_ROUND : integer := 1; --this constant is used for appending 1* into the compression phase.
    begin

        p_init_phase(C_PERMUTATION_ARRAY_61, v_d, a1_i, a2_i, a3_i, v_a1_o, v_a2_o, v_a3_o);
        v_a1 := v_a1_o;
        v_a2 := v_a2_o;
        v_a3 := v_a3_o;
        p_compression_phase(C_PERMUTATION_ARRAY_61, C_LIMIT_FOR_APPENDING_DUMMY_ROUND, v_a1, v_a2, v_a3, m_i, v_a1_o, v_a2_o, v_a3_o);
        v_a1 := v_a1_o;
        v_a2 := v_a2_o;
        v_a3 := v_a3_o;
        p_init_phase(C_PERMUTATION_ARRAY_61, v_d, v_a1, v_a2, v_a3, v_a1_o, v_a2_o, v_a3_o);
        a1_o := v_a1_o;
        a2_o := v_a2_o;
        a3_o := v_a3_o;
    end procedure p_smac_1_2;

    procedure p_smac_n(
        num_of_streams_i : in integer;
        a1_i             : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_i             : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_i             : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        m_i              : in std_logic_vector; --message
        a1_o             : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a2_o             : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        a3_o             : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
    ) is

    begin

        for i in 0 to num_of_streams_i - 1 loop
            p_smac_1(
            init_phase_rounds_i  => 9,
            final_phase_rounds_i => 6,
            a1_i                 => a1_i,
            a2_i                 => a2_i,
            a3_i                 => a3_i,
            m_i                  => m_i,
            a1_o                 => a1_o,
            a2_o                 => a2_o,
            a3_o                 => a3_o
            );
        end loop;
    end procedure p_smac_n;

    --if run("test_0") then
    --    v_a1 := x"00000000000000000000000000000000"; --key low
    --    v_a2 := x"00000000000000000000000000000000"; --key high
    --    v_a3 := x"00000000000000000000000000000000"; --iv
    --    info("== TEST 1 ==");
    --    info("KEY : " & to_hstring(v_a2 & v_a1));
    --    info("IV  : " & to_hstring(v_a3));
    --    info("AD  : null");
    --    info("CP  : null");
    --    info("For SMAC-1:");
    --    p_smac_1('0', '0', v_a1, v_a2, v_a3, x"00", x"11", v_a1_o, v_a2_o, v_a3_o);
    --    info("For SMAC-3/4:");
    --    p_smac_3_4('0', '0', v_a1, v_a2, v_a3, x"00", x"11", v_a1_o, v_a2_o, v_a3_o);
    --    info("For SMAC-1/2:");
    --    p_smac_1_2('0', '0', v_a1, v_a2, v_a3, x"00", x"11", v_a1_o, v_a2_o, v_a3_o);
    --    v_a1 := x"00000000000000000000000000000000"; --key low
    --    v_a2 := x"01000000000000000000000000000000"; --key high
    --    v_a3 := x"02000000000000000000000000000000"; --iv
    --    info("== TEST 2 ==");
    --    info("KEY : " & to_hstring(v_a2 & v_a1));
    --    info("IV  : " & to_hstring(v_a3));
    --    info("AD  : 03");
    --    info("CP  : null");
    --    info("For SMAC-1:");
    --    p_smac_1('1', '0', v_a1, v_a2, v_a3, x"03", x"11", v_a1_o, v_a2_o, v_a3_o);
    --    info("For SMAC-3/4:");
    --    p_smac_3_4('1', '0', v_a1, v_a2, v_a3, x"03", x"11", v_a1_o, v_a2_o, v_a3_o);
    --    info("For SMAC-1/2:");
    --    p_smac_1_2('1', '0', v_a1, v_a2, v_a3, x"03", x"11", v_a1_o, v_a2_o, v_a3_o);
    --    v_a1 := x"c0c1c2c3c4c5c6c7c8c9cacbcccdcecf"; --key low
    --    v_a2 := x"b0b1b2b3b4b5b6b7b8b9babbbcbdbebf"; --key high
    --    v_a3 := x"d0d1d2d3d4d5d6d7d8d9dadbdcdddedf"; --iv
    --    --v_ad := x"e0e1e2e3e4e5e6e7e8e9eaebecdddeef";
    --    --v_cp := x"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";
    --    info("== TEST 3 ==");
    --    info("KEY : " & to_hstring(v_a2 & v_a1));
    --    info("IV  : " & to_hstring(v_a3));
    --    info("AD  : e0e1e2e3e4e5e6e7e8e9eaebecdddeef");
    --    info("CP  : f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff");
    --    info("For SMAC-1:");
    --    p_smac_1('1', '1', v_a1, v_a2, v_a3, x"e0e1e2e3e4e5e6e7e8e9eaebecdddeef", x"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff", v_a1_o, v_a2_o, v_a3_o);
    --    info("For SMAC-3/4:");
    --    p_smac_3_4('1', '1', v_a1, v_a2, v_a3, x"e0e1e2e3e4e5e6e7e8e9eaebecdddeef", x"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff", v_a1_o, v_a2_o, v_a3_o);
    --    info("For SMAC-1/2:");
    --    p_smac_1_2('1', '1', v_a1, v_a2, v_a3, x"e0e1e2e3e4e5e6e7e8e9eaebecdddeef", x"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff", v_a1_o, v_a2_o, v_a3_o);
    --    v_a1 := x"101112131415161718191a1b1c1d1e1f"; --key low
    --    v_a2 := x"000102030405060708090a0b0c0d0e0f"; --key high
    --    v_a3 := x"fffefdfcfbfaf9f8f7f6f5f4f3f2f1f0"; --iv
    --    --v_ad := x"0102030405060708090a0b0c0d0e0f10111213";
    --    --v_cp := x"1415161718191a1b1c1d1e1f20";
    --    info("== TEST 4 ==");
    --    info("KEY : " & to_hstring(v_a2 & v_a1));
    --    info("IV  : " & to_hstring(v_a3));
    --    info("AD  : 0102030405060708090a0b0c0d0e0f10111213");
    --    info("CP  : 1415161718191a1b1c1d1e1f20");
    --    info("For SMAC-1:");
    --    p_smac_1('1', '1', v_a1, v_a2, v_a3, x"0102030405060708090a0b0c0d0e0f10111213", x"1415161718191a1b1c1d1e1f20", v_a1_o, v_a2_o, v_a3_o);
    --    info("For SMAC-3/4:");
    --    p_smac_3_4('1', '1', v_a1, v_a2, v_a3, x"0102030405060708090a0b0c0d0e0f10111213", x"1415161718191a1b1c1d1e1f20", v_a1_o, v_a2_o, v_a3_o);
    --    info("For SMAC-1/2:");
    --    p_smac_1_2('1', '1', v_a1, v_a2, v_a3, x"0102030405060708090a0b0c0d0e0f10111213", x"1415161718191a1b1c1d1e1f20", v_a1_o, v_a2_o, v_a3_o);
    --end if;
end package body pkg_smac;