library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context; -- <-- REQUIRED for test_runner_setup, run, test_runner_cleanup
use vunit_lib.com_pkg.all;
use vunit_lib.axi_stream_pkg.all;
use vunit_lib.queue_pkg.all;

library work;
use work.pkg_aes.all;
use work.pkg_smac.all;
use work.pkg_gnrl.all;

entity tb_smac_1_n is
  generic (runner_cfg : string);
end tb_smac_1_n;

architecture tb of tb_smac_1_n is
  --constant declarations
  constant C_DATA_WIDTH        : integer := 4 * C_SMAC_REG_WIDTH;
  constant C_WORD_WIDTH        : integer := C_DATA_WIDTH/8;
  constant C_M_AXIS_DATA_WIDTH : integer := 3 * C_SMAC_REG_WIDTH;
  constant C_M_AXIS_WORD_WIDTH : integer := 3 * C_DATA_WIDTH/8;
  constant C_CLK_PERIOD        : time    := 10 ns;

  constant C_NUM_OF_STREAMS : integer := 4;

  constant C_M_AXIS_STALL_CONFIG : stall_config_t := (
    stall_probability => 0.5,
    min_stall_cycles  => 1,
    max_stall_cycles  => 4
  );

  constant C_S_AXIS_STALL_CONFIG : stall_config_t := (
    stall_probability => 1.0,
    min_stall_cycles  => 1,
    max_stall_cycles  => 4
  );

  constant master_axi_stream : axi_stream_master_t := new_axi_stream_master(
  data_length  => C_DATA_WIDTH,
  id_length    => 0,
  user_length  => 0,
  stall_config => C_M_AXIS_STALL_CONFIG
  );

  constant slave_axi_stream : axi_stream_slave_t := new_axi_stream_slave(
  data_length  => C_M_AXIS_DATA_WIDTH,
  id_length    => 0,
  dest_length  => 0,
  user_length  => 0,
  stall_config => C_S_AXIS_STALL_CONFIG
  );

  --signal declarations
  signal clk  : std_logic := '0';
  signal rstn : std_logic := '0';

  signal a1_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  signal a2_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
  signal a3_i : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

  signal s00_axis_tdata  : std_logic_vector(C_DATA_WIDTH - 1 downto 0);
  signal s00_axis_tvalid : std_logic;
  signal s00_axis_tready : std_logic;
  signal s00_axis_tlast  : std_logic;

  signal m00_axis_tdata  : std_logic_vector(3 * C_SMAC_REG_WIDTH - 1 downto 0);
  signal m00_axis_tvalid : std_logic;
  signal m00_axis_tready : std_logic;
  signal m00_axis_tlast  : std_logic;

  procedure p_prep_packet (
    num_of_streams_i : in integer;
    ad_length_i      : in integer;
    cp_length_i      : in integer;

    a1_o : out std_logic_vector(127 downto 0);
    a2_o : out std_logic_vector(127 downto 0);
    a3_o : out std_logic_vector(127 downto 0);

    generated_packet_o : out queue_t;
    expected_packet_o  : out queue_t
  ) is
    variable v_byte_queue     : queue_t := new_queue;
    variable v_byte_queue_exp : queue_t := new_queue;

    variable v_a1     : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2     : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3     : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a1_o   : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2_o   : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3_o   : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_result : std_logic_vector(3 * C_SMAC_REG_WIDTH - 1 downto 0);
    variable v8       : std_logic_vector(7 downto 0);

    variable v_payload_ad : std_logic_vector(8 * ad_length_i - 1 downto 0);
    variable v_payload_cp : std_logic_vector(8 * cp_length_i - 1 downto 0);

    variable v_smac_inp : std_logic_vector(f_smac_input_vec_length_calculator(num_of_streams_i, v_payload_ad, v_payload_cp) - 1 downto 0);

    variable rnd_seed : integer := 0;
    variable len      : integer := 0;

  begin

    --generating a1
    v_a1     := f_rand_vector(C_SMAC_REG_WIDTH, rnd_seed);
    v_a1     := (others => '1');
    rnd_seed := rnd_seed + 1;

    --generating a2
    v_a2     := f_rand_vector(C_SMAC_REG_WIDTH, rnd_seed);
    v_a2     := (others => '1');
    rnd_seed := rnd_seed + 1;

    --generating a3
    v_a3     := f_rand_vector(C_SMAC_REG_WIDTH, rnd_seed);
    v_a3     := (others => '1');
    rnd_seed := rnd_seed + 1;

    if (ad_length_i /= 0) then
      --generating payload_ad
      --v_payload_ad := f_rand_vector(v_payload_ad'length, rnd_seed);
      v_payload_ad := (others => '1');
      rnd_seed     := rnd_seed + 1;
    end if;

    if (cp_length_i /= 0) then
      --generating payload_cp
      v_payload_cp := f_rand_vector(v_payload_cp'length, rnd_seed);
      rnd_seed     := rnd_seed + 1;
    end if;

    p_generate_smac_input_vector(num_of_streams_i, v_payload_ad, v_payload_cp, v_smac_inp);

    --info("v_payload_ad : " & to_hstring(v_payload_ad));
    --info("v_payload_cp : " & to_hstring(v_payload_cp));
    --info("v_smac_inp   : " & to_hstring(v_smac_inp));

    for i in 0 to v_smac_inp'length/8 - 1 loop
      v8 := v_smac_inp(v_smac_inp'left - 8 * i downto v_smac_inp'length - 8 * (i + 1));
      push_std_ulogic_vector(v_byte_queue, v8);
      len := len + 1;
      --info("m v8 : " & to_hstring(v8));
    end loop;

    a1_o := v_a1;
    a2_o := v_a2;
    a3_o := v_a3;

    p_smac_n(
    num_of_streams_i => num_of_streams_i,
    a1_i             => v_a1,
    a2_i             => v_a2,
    a3_i             => v_a3,
    m_i              => v_smac_inp,
    a1_o             => v_a1_o,
    a2_o             => v_a2_o,
    a3_o             => v_a3_o
    );

    --generating
    generated_packet_o := f_byte_to_axis(v_byte_queue, C_WORD_WIDTH);

    --generating
    v_result := v_a1_o & v_a2_o & v_a3_o;
    for i in 0 to v_result'length/8 - 1 loop
      v8 := v_result(v_result'left - 8 * i downto v_result'length - 8 * (i + 1));
      push_std_ulogic_vector(v_byte_queue_exp, v8);
      --info("v8 : " & to_hstring(v8));
    end loop;

    expected_packet_o := f_byte_to_axis(v_byte_queue_exp, C_M_AXIS_DATA_WIDTH/8);

  end procedure p_prep_packet;

  signal r_received_queue : queue_t := new_queue;

  impure function f_compare_axis(expected_queue : queue_t) return boolean is
    variable v_received_tdata                     : std_logic_vector(C_M_AXIS_DATA_WIDTH - 1 downto 0);
    variable v_received_tkeep                     : std_logic_vector(C_M_AXIS_DATA_WIDTH/8 - 1 downto 0);
    variable v_received_tlast                     : std_logic;
    variable v_received                           : std_logic_vector(v_received_tdata'length + v_received_tkeep'length + 1 - 1 downto 0);

    variable v_expected_tdata : std_logic_vector(C_M_AXIS_DATA_WIDTH - 1 downto 0);
    variable v_expected_tkeep : std_logic_vector(C_M_AXIS_DATA_WIDTH/8 - 1 downto 0);
    variable v_expected_tlast : std_logic;
    variable v_expected       : std_logic_vector(v_received_tdata'length + v_received_tkeep'length + 1 - 1 downto 0);

    variable v_flag : boolean := true;
  begin

    POP_LOOP : loop
      v_received       := pop_std_ulogic_vector(r_received_queue);
      v_received_tdata := v_received(v_received'left downto v_received'length - v_received_tdata'length);
      v_received_tkeep := v_received(v_received_tkeep'length downto 1);
      v_received_tlast := v_received(0);

      v_expected       := pop_std_ulogic_vector(expected_queue);
      v_expected_tdata := v_expected(v_expected'left downto v_expected'length - v_expected_tdata'length);
      v_expected_tkeep := v_expected(v_expected_tkeep'length downto 1);
      v_expected_tlast := v_expected(0);

      info("TDATA | expected : " & to_hstring(v_expected_tdata) & " | received : " & to_hstring(v_received_tdata));

      if (v_received_tdata /= v_expected_tdata) then
        v_flag := false;
        info("TDATA ERROR | expected : " & to_hstring(v_expected_tdata) & " | received : " & to_hstring(v_received_tdata));
      end if;

      if (v_received_tkeep /= v_expected_tkeep) then
        v_flag := false;
        info("TKEEP ERROR | expected : " & to_hstring(v_expected_tkeep) & " | received : " & to_hstring(v_received_tkeep));
      end if;

      if (v_received_tlast /= v_expected_tlast) then
        v_flag := false;
        info("TLAST ERROR | expected : " & to_string(v_expected_tlast) & " | received : " & to_string(v_received_tlast));
      end if;

      if (v_received_tlast = '1') then
        return v_flag;
        exit POP_LOOP;
      end if;
    end loop POP_LOOP;

  end function f_compare_axis;
begin

  -- clock and reset generation
  clk  <= not clk after C_CLK_PERIOD/2;
  rstn <= '1' after 10 * C_CLK_PERIOD;

  main : process
    variable v_inp_word_que : queue_t := new_queue;
    variable v_exp_word_que : queue_t := new_queue;

    variable v_a1_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a2_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    variable v_a3_o : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

    variable v_tdata      : std_logic_vector(C_DATA_WIDTH - 1 downto 0);
    variable v_tkeep      : std_logic_vector(C_DATA_WIDTH/8 - 1 downto 0);
    variable v_tlast      : std_logic;
    variable v_queue_data : std_logic_vector(C_DATA_WIDTH + C_DATA_WIDTH/8 + 1 - 1 downto 0);

    variable v_num_of_ad_bytes : integer;
    variable v_num_of_cp_bytes : integer;

    variable v_comp_flag : boolean;
    variable v_ad_vec    : std_logic_vector(15 downto 0) := x"AABB";
    variable v_cp_vec    : std_logic_vector(31 downto 0) := x"CCDDEEFF";
    variable v_smac_inp  : std_logic_vector(f_smac_input_vec_length_calculator(C_NUM_OF_STREAMS, v_ad_vec, v_cp_vec) - 1 downto 0);

  begin
    -- VUnit test runner setup
    test_runner_setup(runner, runner_cfg);

    wait until rstn = '1';
    wait until rising_edge(clk);

    if run("test_0") then

      CP_LOOP : for i in 0 to 255 loop
        AD_LOOP : for j in 1 to 255 loop --j=0 case should be corrected
          v_num_of_cp_bytes := 0;
          v_num_of_ad_bytes := 16 * 8;

          p_prep_packet(C_NUM_OF_STREAMS, v_num_of_ad_bytes, v_num_of_cp_bytes, v_a1_o, v_a2_o, v_a3_o, v_inp_word_que, v_exp_word_que);

          a1_i <= v_a1_o;
          a2_i <= v_a2_o;
          a3_i <= v_a3_o;
          wait until rising_edge(clk);

          v_tlast := '0';
          while(v_tlast = '0') loop
            v_queue_data := pop_std_ulogic_vector(v_inp_word_que);
            v_tdata      := v_queue_data(v_queue_data'left downto v_queue_data'length - C_DATA_WIDTH);
            v_tkeep      := v_queue_data(v_queue_data'length - C_DATA_WIDTH - 1 downto 1);
            v_tlast      := v_queue_data(0);

            push_axi_stream(net => net, axi_stream => master_axi_stream, tdata => v_tdata, tkeep => v_tkeep, tlast => v_tlast);
          end loop;

          wait until rising_edge(clk);

          wait until m00_axis_tvalid = '1' and m00_axis_tready = '1' and m00_axis_tlast = '1' and rising_edge(clk);
          wait until rising_edge(clk);
          wait until rising_edge(clk);

          v_comp_flag := f_compare_axis(v_exp_word_que);

          if (v_comp_flag = FALSE) then
            report "COMPARISON FALSE" severity ERROR;
          end if;
        end loop AD_LOOP;
      end loop CP_LOOP;
      wait for 100 * C_CLK_PERIOD;

    end if;

    -- VUnit test runner cleanup
    test_runner_cleanup(runner);
  end process;

  POP_M_AXIS_DATA : process
    variable v_tdata : std_logic_vector(C_M_AXIS_DATA_WIDTH - 1 downto 0);
    variable v_tlast : std_logic;

  begin
    wait until rstn = '1';
    loop
      pop_axi_stream(
      net        => net,
      axi_stream => slave_axi_stream,
      tdata      => v_tdata,
      tlast      => v_tlast
      );
    end loop;
  end process;

  PUSH_M_AXIS_DATA : process
    variable v_tkeep      : std_logic_vector(C_M_AXIS_DATA_WIDTH/8 - 1 downto 0) := (others => '1');
    variable v_queue_data : std_logic_vector(C_M_AXIS_DATA_WIDTH + C_M_AXIS_DATA_WIDTH/8 + 1 - 1 downto 0);
  begin
    wait until m00_axis_tvalid = '1' and m00_axis_tready = '1' and rising_edge(clk);
    v_queue_data := m00_axis_tdata & v_tkeep & m00_axis_tlast;
    push_std_ulogic_vector(r_received_queue, v_queue_data);
  end process;

  -- DUT instantiation
  DUT_SMAC : entity work.smac_1_n
    generic map(
      G_DATA_WIDTH          => C_DATA_WIDTH,                  --! Data width in bits
      G_SMAC_VARIANT        => 1,                             --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
      G_NUM_OF_STREAMS      => C_DATA_WIDTH/C_SMAC_REG_WIDTH, --! Number of parallel SMAC streams
      G_NUM_OF_INIT_ROUNDS  => 9,
      G_NUM_OF_FINAL_ROUNDS => 6
    )
    port map(
      clk_i  => clk,
      rstn_i => rstn,

      a1_i => a1_i,
      a2_i => a2_i,
      a3_i => a3_i,

      s_axis_tdata_i  => s00_axis_tdata,
      s_axis_tvalid_i => s00_axis_tvalid,
      s_axis_tready_o => s00_axis_tready,
      s_axis_tlast_i  => s00_axis_tlast,

      m_axis_tdata_o  => m00_axis_tdata,
      m_axis_tvalid_o => m00_axis_tvalid,
      m_axis_tready_i => m00_axis_tready,
      m_axis_tlast_o  => m00_axis_tlast --! Always '1' when tvalid is '1', since tag is single word.
    );

  axi_stream_master_inst : entity vunit_lib.axi_stream_master
    generic map(
      master => master_axi_stream
    )
    port map(
      aclk     => clk,
      areset_n => rstn,
      tdata    => s00_axis_tdata,
      tvalid   => s00_axis_tvalid,
      tready   => s00_axis_tready,
      tlast    => s00_axis_tlast
    );

  axi_stream_slave_inst : entity vunit_lib.axi_stream_slave
    generic map(
      slave => slave_axi_stream
    )
    port map(
      aclk     => clk,
      areset_n => rstn,
      tdata    => m00_axis_tdata,
      tvalid   => m00_axis_tvalid,
      tready   => m00_axis_tready,
      tlast    => m00_axis_tlast
    );

end architecture;