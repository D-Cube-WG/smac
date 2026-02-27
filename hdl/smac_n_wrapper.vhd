library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_n_wrapper is
    generic (
        G_SMAC_VARIANT   : integer := 1;
        G_NUM_OF_STREAMS : integer := 16;
        G_IS_SMAC_N      : integer := 1
    );
    port (
        clk_i  : in std_logic;
        rstn_i : in std_logic;

        ------------------------------------------------------------------
        -- CONTROL
        ------------------------------------------------------------------
        start_i : in std_logic;

        ------------------------------------------------------------------
        -- 32-bit KEY INPUT (8 words = 256 bits)
        ------------------------------------------------------------------
        key_tdata_i  : in  std_logic_vector(31 downto 0);
        key_tvalid_i : in  std_logic;
        key_tready_o : out std_logic;

        ------------------------------------------------------------------
        -- 32-bit IV INPUT (4 words = 128 bits)
        ------------------------------------------------------------------
        iv_tdata_i  : in  std_logic_vector(31 downto 0);
        iv_tvalid_i : in  std_logic;
        iv_tready_o : out std_logic;

        ------------------------------------------------------------------
        -- 32-bit MESSAGE INPUT
        ------------------------------------------------------------------
        s_axis_tdata_i  : in  std_logic_vector(31 downto 0);
        s_axis_tvalid_i : in  std_logic;
        s_axis_tlast_i  : in  std_logic;
        s_axis_tready_o : out std_logic;

        ------------------------------------------------------------------
        -- 32-bit TAG OUTPUT
        ------------------------------------------------------------------
        m_axis_tdata_o  : out std_logic_vector(31 downto 0);
        m_axis_tvalid_o : out std_logic;
        m_axis_tlast_o  : out std_logic;
        m_axis_tready_i : in  std_logic
    );
end entity;

architecture rtl of smac_n_wrapper is

    ------------------------------------------------------------------
    -- INTERNAL REGISTERS
    ------------------------------------------------------------------
    signal key_reg  : std_logic_vector(255 downto 0);
    signal iv_reg   : std_logic_vector(127 downto 0);

    signal key_cnt  : unsigned(3 downto 0);
    signal iv_cnt   : unsigned(2 downto 0);

    signal msg_word128 : std_logic_vector(127 downto 0);
    signal msg_cnt32   : unsigned(1 downto 0);

    signal stream_reg  : std_logic_vector(G_NUM_OF_STREAMS*128-1 downto 0);
    signal stream_cnt  : unsigned(7 downto 0);

    signal smac_data   : std_logic_vector(G_NUM_OF_STREAMS*128-1 downto 0);
    signal smac_valid  : std_logic;
    signal smac_last   : std_logic;
    signal smac_ready  : std_logic;

    signal tag_full    : std_logic_vector(383 downto 0);
    signal tag_shift   : std_logic_vector(383 downto 0);
    signal tag_cnt     : unsigned(4 downto 0);
    signal tag_valid   : std_logic;
    
    
    signal m_axis_tvalid   : std_logic;

begin

    ------------------------------------------------------------------
    -- SMAC CORE
    ------------------------------------------------------------------
    inst_smac : entity work.smac_n
        generic map (
            G_SMAC_VARIANT   => G_SMAC_VARIANT,
            G_NUM_OF_STREAMS => G_NUM_OF_STREAMS,
            G_IS_SMAC_N      => G_IS_SMAC_N
        )
        port map (
            clk_i  => clk_i,
            rstn_i => rstn_i,
            start_i => start_i,
            key_i   => key_reg,
            iv_i    => iv_reg,

            s00_axis_tdata_i  => smac_data,
            s00_axis_tvalid_i => smac_valid,
            s00_axis_tlast_i  => smac_last,
            s00_axis_tready_o => smac_ready,

            m00_axis_tdata_o  => tag_full,
            m00_axis_tvalid_o => tag_valid,
            m00_axis_tlast_o  => open,
            m00_axis_tready_i => '1'
        );

    ------------------------------------------------------------------
    -- KEY PACKER (8 × 32-bit)
    ------------------------------------------------------------------
    key_tready_o <= '1';

    process(clk_i, rstn_i)
    begin
        if rstn_i='0' then
            key_cnt <= (others=>'0');
        elsif rising_edge(clk_i) then
            if key_tvalid_i='1' then
                key_reg <= key_reg(223 downto 0) & key_tdata_i;
                key_cnt <= key_cnt + 1;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- IV PACKER (4 × 32-bit)
    ------------------------------------------------------------------
    iv_tready_o <= '1';

    process(clk_i, rstn_i)
    begin
        if rstn_i='0' then
            iv_cnt <= (others=>'0');
        elsif rising_edge(clk_i) then
            if iv_tvalid_i='1' then
                iv_reg <= iv_reg(95 downto 0) & iv_tdata_i;
                iv_cnt <= iv_cnt + 1;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- MESSAGE PACKER 32 → 128
    ------------------------------------------------------------------
    s_axis_tready_o <= '1';

    process(clk_i, rstn_i)
    begin
        if rstn_i='0' then
            msg_cnt32  <= (others=>'0');
            stream_cnt <= (others=>'0');
            smac_valid <= '0';
        elsif rising_edge(clk_i) then

            smac_valid <= '0';

            if s_axis_tvalid_i='1' then

                msg_word128 <= msg_word128(95 downto 0) & s_axis_tdata_i;
                msg_cnt32   <= msg_cnt32 + 1;

                if msg_cnt32=3 then

                    stream_reg <= stream_reg(stream_reg'high-128 downto 0) &
                                  (msg_word128(95 downto 0) & s_axis_tdata_i);

                    stream_cnt <= stream_cnt + 1;
                    msg_cnt32  <= (others=>'0');

                    if stream_cnt=G_NUM_OF_STREAMS-1 then
                        smac_data  <= stream_reg(stream_reg'high-128 downto 0) &
                                      (msg_word128(95 downto 0) & s_axis_tdata_i);
                        smac_valid <= '1';
                        smac_last  <= s_axis_tlast_i;
                        stream_cnt <= (others=>'0');
                    end if;

                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- TAG UNPACKER 384 → 32-bit AXI
    ------------------------------------------------------------------
    process(clk_i, rstn_i)
    begin
        if rstn_i='0' then
            tag_cnt   <= (others=>'0');
            tag_shift <= (others=>'0');
        elsif rising_edge(clk_i) then

            if tag_valid='1' then
                tag_shift <= tag_full;
                tag_cnt   <= (others=>'0');
            elsif m_axis_tready_i='1' and m_axis_tvalid = '1' then
                tag_shift <= tag_shift(351 downto 0) & x"00000000";
                tag_cnt   <= tag_cnt + 1;
            end if;

        end if;
    end process;

    m_axis_tdata_o  <= tag_shift(383 downto 352);
    m_axis_tvalid   <= '1' when (tag_cnt < 12) else '0';
    m_axis_tlast_o  <= '1' when (tag_cnt = 11) else '0';
    
    m_axis_tvalid_o <= m_axis_tvalid;

end architecture;
