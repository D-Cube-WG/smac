library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context; --required for info
use vunit_lib.queue_pkg;

library osvvm;
use osvvm.RandomPkg.all;

package pkg_gnrl is
    function f_ceil (
        a : natural;
        b : positive
    ) return natural;

    function f_swap_bytes(
        vec : std_logic_vector
    ) return std_logic_vector;

    function f_byte_to_axis (
        byte_i          : queue_t;
        word_width_i    : integer;
        is_big_endian_i : boolean := true
    ) return queue_t;

    impure function f_rand_vector(
        vec_width : natural;
        seed      : natural
    ) return std_logic_vector;

end package pkg_gnrl;

package body pkg_gnrl is

    function f_ceil (
        a : natural;
        b : positive
    ) return natural is
    begin
        return (a + b - 1) / b;
    end function f_ceil;

    function f_swap_bytes(
        vec : std_logic_vector
    ) return std_logic_vector is
        variable v_r_vec    : std_logic_vector(vec'length - 1 downto 0);
        variable v_swap_vec : std_logic_vector(vec'length - 1 downto 0);
    begin
        v_r_vec := vec;
        for i in 0 to v_r_vec'length/8 - 1 loop
            v_swap_vec(8 * (i + 1) - 1 downto 8 * i) := v_r_vec(v_r_vec'left - i * 8 downto v_r_vec'length - (i + 1) * 8);
        end loop;
        return v_swap_vec;
    end function f_swap_bytes;

    function f_byte_to_axis (
        byte_i          : queue_t;
        word_width_i    : integer;
        is_big_endian_i : boolean := true
    ) return queue_t is
        variable v_word_queue : queue_t := new_queue;
        variable v8           : std_logic_vector(7 downto 0);
        variable v_tdata      : std_logic_vector(8 * word_width_i - 1 downto 0) := (others => '0');
        variable v_tkeep      : std_logic_vector(word_width_i - 1 downto 0)     := (others => '0');
        variable v_tlast      : std_logic                                       := '0';
        variable v_valid_byte : std_logic;
    begin
        v_tlast := '0';
        while (v_tlast = '0') loop
            for i in 0 to word_width_i - 1 loop
                if (v_tlast = '1') then --if v_tlast='1' then there is nothing to pop
                    v8           := (others => '0');
                    v_valid_byte := '0';
                else
                    v8 := pop(byte_i);
                    if (is_empty(byte_i)) then
                        v_tlast := '1';
                    end if;
                    v_valid_byte := '1';
                end if;

                if (is_big_endian_i = true) then                    --we could use a byte-swap function but it could increase our cpu-work-load
                    v_tdata := v_tdata(v_tdata'left - 8 downto 0) & v8; --assuming simulation tool optimized shift operation
                    v_tkeep := v_tkeep(v_tkeep'left - 1 downto 0) & v_valid_byte;
                else
                    v_tdata := v8 & v_tdata(v_tdata'left downto 8);
                    v_tkeep := v_valid_byte & v_tkeep(v_tkeep'left downto 1);
                end if;
            end loop;
            --info("v_tdata : " & to_hstring(v_tdata) & " | v_tkeep : " & to_hstring(v_tkeep) & " | v_tlast : " & to_string(v_tlast));
            --push(v_word_queue, v_tdata & v_tkeep & v_tlast);
            push_std_ulogic_vector(v_word_queue, v_tdata & v_tkeep & v_tlast);
        end loop;
        return v_word_queue;
    end function f_byte_to_axis;

    impure function f_rand_vector(
        vec_width : natural;
        seed      : natural
    ) return std_logic_vector is
        variable rnd : RandomPType;
    begin
        rnd.InitSeed(seed);
        return rnd.RandSlv(vec_width);
    end function f_rand_vector;
end package body pkg_gnrl;