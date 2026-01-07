library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context; -- <-- REQUIRED for test_runner_setup, run, test_runner_cleanup
use vunit_lib.queue_pkg;

library work;
use work.pkg_aes.all;

entity tb_smac is
  generic
    (runner_cfg : string);
end tb_smac;

architecture tb of tb_smac is
  --constant declarations
  constant C_DATA_WIDTH : integer := 8;
  constant C_WORD_WIDTH : integer := 4;
  constant C_CLK_PERIOD : time    := 10 ns;

  constant C_SMAC_REG_WIDTH : integer := 128;

  --permutations
  type t_permutation_array is array (0 to 15) of integer;
  --type t_permutation_arrays is array (natural range <>) of t_permutation_array; --this will be used when all of the permutations are written as constants
  constant C_PERMUTATION_ARRAY_1 : t_permutation_array := (
    0  => 0,
    1  => 7,
    2  => 14,
    3  => 11,
    4  => 4,
    5  => 13,
    6  => 10,
    7  => 1,
    8  => 8,
    9  => 15,
    10 => 6,
    11 => 3,
    12 => 12,
    13 => 5,
    14 => 2,
    15 => 9
  );

  constant C_PERMUTATION_ARRAY_42 : t_permutation_array := (
    0 => 7, 1 => 14, 2 => 15, 3 => 10, 4 => 12, 5 => 13, 6 => 3, 7 => 0, 8 => 4, 9 => 6, 10 => 1, 11 => 5, 12 => 8, 13 => 11, 14 => 2, 15 => 9
  );

  constant C_PERMUTATION_ARRAY_61 : t_permutation_array := (
    0 => 0, 1 => 11, 2 => 7, 3 => 14, 4 => 6, 5 => 4, 6 => 1, 7 => 15, 8 => 9, 9 => 3, 10 => 8, 11 => 5, 12 => 13, 13 => 2, 14 => 10, 15 => 12
  );

  --signal declarations
  signal clk  : std_logic := '0';
  signal rstn : std_logic := '0';

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

  impure function f_byte_to_axis (
    byte_i          : queue_t;
    word_width_i    : integer := C_WORD_WIDTH;
    is_big_endian_i : boolean := true
  ) return queue_t is
    variable v_word_queue : queue_t := new_queue;

    variable v8 : std_logic_vector(7 downto 0);

    variable v_tdata : std_logic_vector(8 * word_width_i - 1 downto 0);
    variable v_tkeep : std_logic_vector(word_width_i - 1 downto 0);
    variable v_tlast : std_logic;

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
      push(v_word_queue, v_tdata & v_tkeep & v_tlast);
    end loop;

    return v_word_queue;
  end function f_byte_to_axis;

  procedure p_prep_packet (
    length_i           : in integer;
    generated_packet_o : out queue_t;
    expected_packet_o  : out queue_t
  ) is
    variable v_byte_queue : queue_t := new_queue;

    variable v8 : std_logic_vector(7 downto 0);
  begin
    --generating dst_mac
    for i in 0 to 5 loop
      v8 := std_logic_vector(to_unsigned(i, 8));
      push(v_byte_queue, v8);

      --info("v8 : " & to_hstring(v8));
    end loop;

    --generating src_mac
    for i in 0 to 5 loop
      v8 := std_logic_vector(to_unsigned(i, 8));
      push(v_byte_queue, v8);

      --info("v8 : " & to_hstring(v8));
    end loop;

    --generating eth_type
    for i in 0 to 1 loop
      v8 := std_logic_vector(to_unsigned(i, 8));
      push(v_byte_queue, v8);

      --info("v8 : " & to_hstring(v8));
    end loop;

    generated_packet_o := v_byte_queue;
    expected_packet_o  := f_byte_to_axis(v_byte_queue);

  end procedure p_prep_packet;

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

  procedure f_smac_compression(
    permutation_array_i : in t_permutation_array;

    a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    m_i  : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
  ) is begin
    --info("INPUT COMPRESSION FUNC | a1_i : " & to_hstring(a1_i) & " | a2_i : " & to_hstring(a2_i) & " | a3_i : " & to_hstring(a3_i) & " | m_i : " & to_hstring(m_i));

    a1_o := f_smac_permutation(permutation_array_i, a2_i xor a3_i xor m_i);
    a2_o := f_aes_round(a1_i, m_i);
    a3_o := f_aes_round(a2_i, m_i);

    --info("OUTPUT COMPRESSION FUNC | a1_o : " & to_hstring(a1_o) & " | a2_o : " & to_hstring(a2_o) & " | a3_o : " & to_hstring(a3_o));
  end procedure f_smac_compression;

  procedure p_init_phase(
    permutation_array_i : in t_permutation_array;
    d_i                 : in integer;

    a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
  ) is
    variable v_a1_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    variable v_a1_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    variable v_m : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  begin
    v_a1_i := a1_i;
    v_a2_i := a2_i;
    v_a3_i := a3_i;

    v_m := (v_m'left downto v_m'length - 8 => x"01", others => '0');
    --info("d : " & to_string(d));
    --info("BEFORE INIT | a1 : " & to_hstring(v_a1_i) & " | a2 : " & to_hstring(v_a2_i) & " | a3 : " & to_hstring(v_a3_i));
    for i in 0 to d_i - 1 loop
      f_smac_compression(permutation_array_i, v_a1_i, v_a2_i, v_a3_i, v_m, v_a1_o, v_a2_o, v_a3_o);

      v_a1_i := v_a1_o;
      v_a2_i := v_a2_o;
      v_a3_i := v_a3_o;
    end loop;

    a1_o := a1_i xor v_a1_i;
    a2_o := a2_i xor v_a2_i;
    a3_o := a3_i xor v_a3_i;

    info("AFTER INIT/FINAL        | a1 : " & to_hstring(a1_o) & " | a2 : " & to_hstring(a2_o) & " | a3 : " & to_hstring(a3_o));
  end procedure p_init_phase;

  procedure f_compression_phase(
    permutation_array_i : in t_permutation_array;

    num_of_ad_bytes_i : in integer := 0;
    num_of_cp_bytes_i : in integer := 0;

    a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    ad_i : in std_logic_vector;
    cp_i : in std_logic_vector;

    a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
  ) is
    variable v_a1_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    variable v_a1_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    variable v_m_block : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    variable v_num_of_ad_blocks : integer := f_ceil(num_of_ad_bytes_i, 16);
    variable v_num_of_cp_blocks : integer := f_ceil(num_of_cp_bytes_i, 16);

    variable v_ad_i : std_logic_vector(C_SMAC_REG_WIDTH * v_num_of_ad_blocks - 1 downto 0);
    variable v_cp_i : std_logic_vector(C_SMAC_REG_WIDTH * v_num_of_cp_blocks - 1 downto 0);

  begin
    v_a1_i := a1_i;
    v_a2_i := a2_i;
    v_a3_i := a3_i;

    --info("num_of_ad_bytes_i   : " & to_string(num_of_ad_bytes_i));
    --info("num_of_cp_bytes_i   : " & to_string(num_of_cp_bytes_i));
    --info("v_num_of_ad_blocks : " & to_string(v_num_of_ad_blocks));
    --info("v_num_of_cp_blocks : " & to_string(v_num_of_cp_blocks));
    --info("BEFORE COMPRESSION PHASE | a1 : " & to_hstring(v_a1_i) & " | a2 : " & to_hstring(v_a2_i) & " | a3 : " & to_hstring(v_a3_i));
    --info("BEFORE COMPRESSION PHASE | ad : " & to_hstring(ad_i) & " | cp : " & to_hstring(cp_i));

    AD_BLOCKS : if (num_of_ad_bytes_i /= 0) then
      v_ad_i := (v_ad_i'left downto v_ad_i'length - ad_i'length => ad_i, others => '0'); --generating a vector that is multiple of the block size and padding the lsb with zeros

      for i in 0 to v_num_of_ad_blocks - 1 loop
        v_m_block := v_ad_i(v_ad_i'left - i * C_SMAC_REG_WIDTH downto v_ad_i'length - (i + 1) * C_SMAC_REG_WIDTH);
        --info("v_m_block_ad  : " & to_hstring(v_m_block));

        f_smac_compression(permutation_array_i, v_a1_i, v_a2_i, v_a3_i, v_m_block, v_a1_o, v_a2_o, v_a3_o);

        v_a1_i := v_a1_o;
        v_a2_i := v_a2_o;
        v_a3_i := v_a3_o;
        --info("AD COMPRESSION PHASE | a1 : " & to_hstring(v_a1_i) & " | a2 : " & to_hstring(v_a2_i) & " | a3 : " & to_hstring(v_a3_i));
      end loop;
    end if;

    CP_BLOCKS : if (num_of_cp_bytes_i /= 0) then
      v_cp_i := (v_cp_i'left downto v_cp_i'length - cp_i'length => cp_i, others => '0'); --generating a vector that is multiple of the block size and padding the lsb with zeros

      for i in 0 to v_num_of_cp_blocks - 1 loop
        v_m_block := v_cp_i(v_cp_i'left - i * C_SMAC_REG_WIDTH downto v_cp_i'length - (i + 1) * C_SMAC_REG_WIDTH);

        --info("v_m_block_cp  : " & to_hstring(v_m_block));
        f_smac_compression(permutation_array_i, v_a1_i, v_a2_i, v_a3_i, v_m_block, v_a1_o, v_a2_o, v_a3_o);

        v_a1_i := v_a1_o;
        v_a2_i := v_a2_o;
        v_a3_i := v_a3_o;
        --info("CP COMPRESSION PHASE | a1 : " & to_hstring(v_a1_i) & " | a2 : " & to_hstring(v_a2_i) & " | a3 : " & to_hstring(v_a3_i));
      end loop;
    end if;

    v_m_block(C_SMAC_REG_WIDTH - 1 downto C_SMAC_REG_WIDTH/2) := std_logic_vector(to_unsigned(num_of_ad_bytes_i * 8, C_SMAC_REG_WIDTH/2)); --size-in-bits
    v_m_block(C_SMAC_REG_WIDTH/2 - 1 downto 0)                := std_logic_vector(to_unsigned(num_of_cp_bytes_i * 8, C_SMAC_REG_WIDTH/2)); --size-in-bits

    v_m_block(C_SMAC_REG_WIDTH - 1 downto C_SMAC_REG_WIDTH/2) := f_swap_bytes(v_m_block(C_SMAC_REG_WIDTH - 1 downto C_SMAC_REG_WIDTH/2));
    v_m_block(C_SMAC_REG_WIDTH/2 - 1 downto 0)                := f_swap_bytes(v_m_block(C_SMAC_REG_WIDTH/2 - 1 downto 0));
    --info("v_m_block_len : " & to_hstring(v_m_block));

    f_smac_compression(permutation_array_i, v_a1_i, v_a2_i, v_a3_i, v_m_block, v_a1_o, v_a2_o, v_a3_o);

    a1_o := v_a1_o;
    a2_o := v_a2_o;
    a3_o := v_a3_o;

    info("AFTER COMPRESSION PHASE | a1 : " & to_hstring(a1_o) & " | a2 : " & to_hstring(a2_o) & " | a3 : " & to_hstring(a3_o));
  end procedure f_compression_phase;

  procedure p_smac_1(
    is_ad_valid_i : std_logic;
    is_cp_valid_i : std_logic;

    a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    ad_i : in std_logic_vector; --associated data
    cp_i : in std_logic_vector; --ciphertext data

    a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
  ) is
    variable v_a1 : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2 : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3 : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    variable v_a1_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    constant d      : integer := 9; --turn this into a global constant
    variable ad_len : integer;
    variable cp_len : integer;
  begin

    if (is_ad_valid_i = '1') then
      ad_len := ad_i'length/8;
    else
      ad_len := 0;
    end if;
    if (is_cp_valid_i = '1') then
      cp_len := cp_i'length/8;
    else
      cp_len := 0;
    end if;

    p_init_phase(C_PERMUTATION_ARRAY_1, d, a1_i, a2_i, a3_i, v_a1_o, v_a2_o, v_a3_o);

    v_a1 := v_a1_o;
    v_a2 := v_a2_o;
    v_a3 := v_a3_o;

    f_compression_phase(C_PERMUTATION_ARRAY_1, ad_len, cp_len, v_a1, v_a2, v_a3, ad_i, cp_i, v_a1_o, v_a2_o, v_a3_o);

    v_a1 := v_a1_o;
    v_a2 := v_a2_o;
    v_a3 := v_a3_o;

    p_init_phase(C_PERMUTATION_ARRAY_1, d, v_a1, v_a2, v_a3, v_a1_o, v_a2_o, v_a3_o);
  end procedure p_smac_1;

  procedure p_smac_3_4(--this function is not done
  is_ad_valid_i : std_logic;
  is_cp_valid_i : std_logic;

  a1_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  a2_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  a3_i : in std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  ad_i : in std_logic_vector; --associated data
  cp_i : in std_logic_vector; --ciphertext data

  a1_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  a2_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  a3_o : out std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0)
  ) is
  variable v_a1 : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a2 : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a3 : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

  variable v_a1_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a2_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a3_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

  variable v_d    : integer := 9; --turn this into a global constant
  variable ad_len : integer;
  variable cp_len : integer;
begin

  if (is_ad_valid_i = '1') then
    ad_len := ad_i'length/8;
  else
    ad_len := 0;
  end if;
  if (is_cp_valid_i = '1') then
    cp_len := cp_i'length/8;
  else
    cp_len := 0;
  end if;

  p_init_phase(C_PERMUTATION_ARRAY_42, v_d, a1_i, a2_i, a3_i, v_a1_o, v_a2_o, v_a3_o);

  v_a1 := v_a1_o;
  v_a2 := v_a2_o;
  v_a3 := v_a3_o;

  f_compression_phase(C_PERMUTATION_ARRAY_42, ad_len, cp_len, v_a1, v_a2, v_a3, ad_i, cp_i, v_a1_o, v_a2_o, v_a3_o);

  v_a1 := v_a1_o;
  v_a2 := v_a2_o;
  v_a3 := v_a3_o;

  p_init_phase(C_PERMUTATION_ARRAY_42, v_d, v_a1, v_a2, v_a3, v_a1_o, v_a2_o, v_a3_o);
end procedure p_smac_3_4;

begin

-- clock and reset generation
clk  <= not clk after C_CLK_PERIOD/2;
rstn <= '1' after 10 * C_CLK_PERIOD;

main : process
  variable v_a1   : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a2   : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a3   : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_ad   : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_cp   : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a1_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a2_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  variable v_a3_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

begin
  -- VUnit test runner setup
  test_runner_setup(runner, runner_cfg);

  wait until rstn = '1';
  wait until rising_edge(clk);

  if run("test_0") then
    v_a1 := x"00000000000000000000000000000000"; --key low
    v_a2 := x"00000000000000000000000000000000"; --key high
    v_a3 := x"00000000000000000000000000000000"; --iv

    info("== TEST 1 ==");
    info("KEY : " & to_hstring(v_a2 & v_a1));
    info("IV  : " & to_hstring(v_a3));
    info("AD  : null");
    info("CP  : null");
    info("For SMAC-1:");
    p_smac_1('0', '0', v_a1, v_a2, v_a3, x"00", x"11", v_a1_o, v_a2_o, v_a3_o);

    v_a1 := x"00000000000000000000000000000000"; --key low
    v_a2 := x"01000000000000000000000000000000"; --key high
    v_a3 := x"02000000000000000000000000000000"; --iv

    info("== TEST 2 ==");
    info("KEY : " & to_hstring(v_a2 & v_a1));
    info("IV  : " & to_hstring(v_a3));
    info("AD  : 03");
    info("CP  : null");
    info("For SMAC-1:");
    p_smac_1('1', '0', v_a1, v_a2, v_a3, x"03", x"11", v_a1_o, v_a2_o, v_a3_o);

    v_a1 := x"c0c1c2c3c4c5c6c7c8c9cacbcccdcecf"; --key low
    v_a2 := x"b0b1b2b3b4b5b6b7b8b9babbbcbdbebf"; --key high
    v_a3 := x"d0d1d2d3d4d5d6d7d8d9dadbdcdddedf"; --iv
    --v_ad := x"e0e1e2e3e4e5e6e7e8e9eaebecdddeef";
    --v_cp := x"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";

    info("== TEST 3 ==");
    info("KEY : " & to_hstring(v_a2 & v_a1));
    info("IV  : " & to_hstring(v_a3));
    info("AD  : e0e1e2e3e4e5e6e7e8e9eaebecdddeef");
    info("CP  : f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff");
    info("For SMAC-1:");
    p_smac_1('1', '1', v_a1, v_a2, v_a3, x"e0e1e2e3e4e5e6e7e8e9eaebecdddeef", x"f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff", v_a1_o, v_a2_o, v_a3_o);

    v_a1 := x"101112131415161718191a1b1c1d1e1f"; --key low
    v_a2 := x"000102030405060708090a0b0c0d0e0f"; --key high
    v_a3 := x"fffefdfcfbfaf9f8f7f6f5f4f3f2f1f0"; --iv
    --v_ad := x"0102030405060708090a0b0c0d0e0f10111213";
    --v_cp := x"1415161718191a1b1c1d1e1f20";

    info("== TEST 4 ==");
    info("KEY : " & to_hstring(v_a2 & v_a1));
    info("IV  : " & to_hstring(v_a3));
    info("AD  : 0102030405060708090a0b0c0d0e0f10111213");
    info("CP  : 1415161718191a1b1c1d1e1f20");
    info("For SMAC-1:");
    p_smac_1('1', '1', v_a1, v_a2, v_a3, x"0102030405060708090a0b0c0d0e0f10111213", x"1415161718191a1b1c1d1e1f20", v_a1_o, v_a2_o, v_a3_o);
  end if;

  -- VUnit test runner cleanup
  test_runner_cleanup(runner);
end process;

-- DUT instantiation

end architecture;