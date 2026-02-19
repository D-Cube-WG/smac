----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of smac_n
-- Date         : 18.02.2026
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_n is
    generic (
        G_SMAC_VARIANT   : integer := 1;
        G_NUM_OF_STREAMS : integer := 16
    );
    port (
        clk_i  : in std_logic;
        rstn_i : in std_logic;

        start_i : in std_logic;
        key_i   : in std_logic_vector(255 downto 0);
        iv_i    : in std_logic_vector(127 downto 0);

        s00_axis_tdata_i  : in  std_logic_vector(G_NUM_OF_STREAMS*128-1 downto 0);
        s00_axis_tvalid_i : in  std_logic;
        s00_axis_tlast_i  : in  std_logic;
        s00_axis_tready_o : out std_logic;

        m00_axis_tdata_o  : out std_logic_vector(3*128-1 downto 0);
        m00_axis_tvalid_o : out std_logic;
        m00_axis_tlast_o  : out std_logic;
        m00_axis_tready_i : in  std_logic
    );
end entity;

architecture rtl of smac_n is

    ------------------------------------------------------------------
    -- CONSTANTS
    ------------------------------------------------------------------
    constant C_ONE_STAR : std_logic_vector(127 downto 0) := x"01" & (119 downto 0 => '0');

    ------------------------------------------------------------------
    -- STATES
    ------------------------------------------------------------------
    type t_states is (
        ST_IDLE,
        ST_SMAC_INIT,
        ST_SMAC_COMPRESSION,
        ST_SMAC_FINALIZE_1,
        ST_SMAC_FINALIZE_2,
        ST_SEND_SMAC_RESULT
    );

    signal state   : t_states;
    signal counter : unsigned(15 downto 0);

    ------------------------------------------------------------------
    -- DATA PATH
    ------------------------------------------------------------------
    signal s_in   : std_logic_vector(G_NUM_OF_STREAMS*384-1 downto 0);
    signal s_out  : std_logic_vector(G_NUM_OF_STREAMS*384-1 downto 0);
    signal s_init : std_logic_vector(G_NUM_OF_STREAMS*384-1 downto 0);

    signal k_in       : std_logic_vector(G_NUM_OF_STREAMS*128-1 downto 0);
    signal one_star_n : std_logic_vector(G_NUM_OF_STREAMS*128-1 downto 0);

    signal xor_o     : std_logic_vector(383 downto 0);
    signal xor_o_reg : std_logic_vector(383 downto 0);

    signal key : std_logic_vector(255 downto 0);
    signal iv  : std_logic_vector(127 downto 0);

    ------------------------------------------------------------------
    -- AXI
    ------------------------------------------------------------------
    signal input_fire  : std_logic;
    signal output_fire : std_logic;

    signal tag_reg   : std_logic_vector(3*128-1 downto 0);
    signal tag_valid : std_logic;

begin

    ------------------------------------------------------------------
    -- XOR REDUCTION (Collapse S0..S3 --> S_sum)
    ------------------------------------------------------------------
    inst_smac_xor_n : entity work.smac_xor_n
        generic map (
            G_DATA_WIDTH    => 384,
            G_NUM_OF_INPUTS => G_NUM_OF_STREAMS
        )
        port map (
            in0_i => s_out,
            xor_o => xor_o
        );

    ------------------------------------------------------------------
    -- PI LAYER
    ------------------------------------------------------------------
    inst_smac_n_pi : entity work.smac_n_pi
        generic map (
            G_SMAC_VARIANT   => G_SMAC_VARIANT,
            G_NUM_OF_STREAMS => G_NUM_OF_STREAMS
        )
        port map (
            state_i => s_in,
            key_i   => k_in,
            state_o => s_out
        );

    ------------------------------------------------------------------
    -- Generate ONE*
    ------------------------------------------------------------------
    gen_one_star_n : for i in 0 to G_NUM_OF_STREAMS-1 generate
        one_star_n(one_star_n'high-(i*128) downto one_star_n'length-(i*128)-128) <= C_ONE_STAR;
    end generate;

    ------------------------------------------------------------------
    -- Generate Initial State
    ------------------------------------------------------------------
    gen_key_in : for i in 0 to G_NUM_OF_STREAMS - 1 generate
        s_init(s_init'high-(i*384)     downto s_init'length-(i*384)-128) <= key(255 downto 128);
        s_init(s_init'high-(i*384)-128 downto s_init'length-(i*384)-256) <= key(127 downto 0);
        s_init(s_init'high-(i*384)-256 downto s_init'length-(i*384)-260) <= std_logic_vector(to_unsigned(G_NUM_OF_STREAMS-1, 4));
        s_init(s_init'high-(i*384)-260 downto s_init'length-(i*384)-264) <= std_logic_vector(to_unsigned(i, 4));
        s_init(s_init'high-(i*384)-264 downto s_init'length-(i*384)-384) <= iv(119 downto 0);
    end generate;

    ------------------------------------------------------------------
    -- AXI COMBINATIONAL
    ------------------------------------------------------------------
    input_fire  <= s00_axis_tvalid_i and s00_axis_tready_o;
    output_fire <= tag_valid and m00_axis_tready_i;

    m00_axis_tdata_o  <= tag_reg;
    m00_axis_tvalid_o <= tag_valid;
    m00_axis_tlast_o  <= tag_valid;

    ------------------------------------------------------------------
    -- MAIN FSM
    ------------------------------------------------------------------
    process(clk_i, rstn_i)
    begin
        if rstn_i = '0' then
            state             <= ST_IDLE;
            counter           <= (others=>'0');
            s_in              <= (others=>'0');
            k_in              <= (others=>'0');
            key               <= (others=>'0');
            iv                <= (others=>'0');
            tag_reg           <= (others=>'0');
            tag_valid         <= '0';
            s00_axis_tready_o <= '0';

        elsif rising_edge(clk_i) then

            -- defaults
            s00_axis_tready_o <= '0';

            case state is

            ------------------------------------------------------------------
            when ST_IDLE =>
                tag_valid <= '0';

                if start_i = '1' then
                    key     <= key_i;
                    iv      <= iv_i;
                    counter <= (others=>'0');
                    state   <= ST_SMAC_INIT;
                end if;

            ------------------------------------------------------------------
            when ST_SMAC_INIT =>
                k_in <= one_star_n;

                if counter = 0 then
                    s_in <= s_init;   -- first cycle after key/iv latched
                else
                    s_in <= s_out;
                end if;

                counter <= counter + 1;

                if counter = 8 then   -- 9 clocks
                    counter <= (others=>'0');
                    state   <= ST_SMAC_COMPRESSION;
                    s_in    <= s_out xor s_init;
                end if;

            ------------------------------------------------------------------
            when ST_SMAC_COMPRESSION =>
                s00_axis_tready_o <= '1';
                s_in <= s_out;
                k_in <= s00_axis_tdata_i;

                if input_fire = '1' then
                    if s00_axis_tlast_i = '1' then
                        counter <= (others=>'0');
                        state   <= ST_SMAC_FINALIZE_1;
                    end if;
                end if;

            ------------------------------------------------------------------
            when ST_SMAC_FINALIZE_1 =>
                k_in <= one_star_n;
                s_in <= s_out;
                counter <= counter + 1;

                if counter = 5 then  -- 6 clocks
                    counter <= (others=>'0');
                    xor_o_reg <= xor_o;
                    s_in <= (others=>'0');
                    s_in(383 downto 0) <= xor_o;
                    state <= ST_SMAC_FINALIZE_2;
                end if;

            ------------------------------------------------------------------
            when ST_SMAC_FINALIZE_2 =>
                k_in <= one_star_n;
                s_in <= s_out;
                counter <= counter + 1;

                if counter = 8 then  -- 9 clocks
                    counter <= (others=>'0');
                    state   <= ST_SEND_SMAC_RESULT;
                end if;

            ------------------------------------------------------------------
            when ST_SEND_SMAC_RESULT =>
                if tag_valid = '0' then
                    tag_reg   <= xor_o_reg xor s_out(383 downto 0);
                    tag_valid <= '1';
                end if;

                if output_fire = '1' then
                    tag_valid <= '0';
                    state     <= ST_IDLE;
                end if;

            ------------------------------------------------------------------
            when others =>
                state <= ST_IDLE;

            end case;
        end if;
    end process;

end architecture;
