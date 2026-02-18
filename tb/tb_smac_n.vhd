library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_smac_n is
end entity;

architecture sim of tb_smac_n is

    ------------------------------------------------------------------
    -- GENERICS
    ------------------------------------------------------------------
    constant G_NUM_OF_STREAMS : integer := 4;
    constant CLK_PERIOD       : time := 10 ns;

    ------------------------------------------------------------------
    -- DUT SIGNALS
    ------------------------------------------------------------------
    signal clk_i  : std_logic := '0';
    signal rstn_i : std_logic := '0';

    signal start_i : std_logic := '0';
    signal key_i   : std_logic_vector(255 downto 0);
    signal iv_i    : std_logic_vector(127 downto 0);

    signal s00_axis_tdata_i  : std_logic_vector(G_NUM_OF_STREAMS*128-1 downto 0);
    signal s00_axis_tvalid_i : std_logic := '0';
    signal s00_axis_tlast_i  : std_logic := '0';
    signal s00_axis_tready_o : std_logic;

    signal m00_axis_tdata_o  : std_logic_vector(3*128-1 downto 0);
    signal m00_axis_tvalid_o : std_logic;
    signal m00_axis_tlast_o  : std_logic;
    signal m00_axis_tready_i : std_logic := '0';

begin

    ------------------------------------------------------------------
    -- CLOCK
    ------------------------------------------------------------------
    clk_i <= not clk_i after CLK_PERIOD/2;

    ------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------
    uut : entity work.smac_n
        generic map (
            G_NUM_OF_STREAMS => G_NUM_OF_STREAMS
        )
        port map (
            clk_i  => clk_i,
            rstn_i => rstn_i,
            start_i => start_i,
            key_i   => key_i,
            iv_i    => iv_i,
            s00_axis_tdata_i  => s00_axis_tdata_i,
            s00_axis_tvalid_i => s00_axis_tvalid_i,
            s00_axis_tlast_i  => s00_axis_tlast_i,
            s00_axis_tready_o => s00_axis_tready_o,
            m00_axis_tdata_o  => m00_axis_tdata_o,
            m00_axis_tvalid_o => m00_axis_tvalid_o,
            m00_axis_tlast_o  => m00_axis_tlast_o,
            m00_axis_tready_i => m00_axis_tready_i
        );

    ------------------------------------------------------------------
    -- RESET
    ------------------------------------------------------------------
    process
    begin
        rstn_i <= '0';
        wait for 50 ns;
        rstn_i <= '1';
        wait;
    end process;

    ------------------------------------------------------------------
    -- STIMULUS PROCESS
    ------------------------------------------------------------------
    process
        variable data_word : std_logic_vector(G_NUM_OF_STREAMS*128-1 downto 0);
    begin

        wait until rstn_i = '1';
        wait for 20 ns;

        --------------------------------------------------------------
        -- SET KEY / IV
        --------------------------------------------------------------
        key_i <= x"000102030405060708090A0B0C0D0E0F" &
                 x"101112131415161718191A1B1C1D1E1F";

        iv_i  <= x"00112233445566778899AABBCCDDEEFF";

        --------------------------------------------------------------
        -- START
        --------------------------------------------------------------
        start_i <= '1';
        wait for CLK_PERIOD;
        start_i <= '0';

        --------------------------------------------------------------
        -- WAIT FOR COMPRESSION PHASE (tready asserted)
        --------------------------------------------------------------
        wait until s00_axis_tready_o = '1';

        --------------------------------------------------------------
        -- SEND 3 MESSAGE BLOCKS
        --------------------------------------------------------------
        for blk in 0 to 2 loop

            data_word :=
                std_logic_vector(to_unsigned(blk+1,128)) &
                std_logic_vector(to_unsigned(blk+2,128)) &
                std_logic_vector(to_unsigned(blk+3,128)) &
                std_logic_vector(to_unsigned(blk+4,128));

            s00_axis_tdata_i  <= data_word;
            s00_axis_tvalid_i <= '1';

            if blk = 2 then
                s00_axis_tlast_i <= '1';
            else
                s00_axis_tlast_i <= '0';
            end if;

            -- Wait until accepted
            wait until rising_edge(clk_i);
            wait until s00_axis_tready_o = '1';

        end loop;

        s00_axis_tvalid_i <= '0';
        s00_axis_tlast_i  <= '0';

        --------------------------------------------------------------
        -- WAIT FOR TAG VALID
        --------------------------------------------------------------
        wait until m00_axis_tvalid_o = '1';

        --------------------------------------------------------------
        -- APPLY BACKPRESSURE (AXI compliance test)
        --------------------------------------------------------------
        wait for 40 ns;  -- downstream stall

        m00_axis_tready_i <= '1';
        wait until rising_edge(clk_i);
        m00_axis_tready_i <= '0';

        --------------------------------------------------------------
        -- PRINT TAG
        --------------------------------------------------------------
        report "SMAC TAG = " & to_hstring(m00_axis_tdata_o);

        --------------------------------------------------------------
        -- WAIT & FINISH
        --------------------------------------------------------------
        wait for 200 ns;
        report "SIMULATION FINISHED SUCCESSFULLY";
        wait;

    end process;

end architecture;
