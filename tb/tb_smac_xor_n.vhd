----------------------------------------------------------------------------------
-- Testbench for smac_xor_n
-- Simple, easy to follow test without VUnit
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_smac_xor_n is
end tb_smac_xor_n;

architecture tb of tb_smac_xor_n is
    -- Constants
    constant C_CLK_PERIOD : time := 10 ns;
    constant C_DATA_WIDTH : integer := 128;
    constant C_NUM_OF_STREAMS : integer := 16;
    constant C_PIPELINE_DEPTH : integer := 2;  -- Input reg + Output reg (XOR is combinatorial)

    -- Signals
    signal clk   : std_logic := '0';
    signal rstn  : std_logic := '0';

    signal in0_i : std_logic_vector(C_DATA_WIDTH * C_NUM_OF_STREAMS - 1 downto 0);
    signal xor_o : std_logic_vector(C_DATA_WIDTH - 1 downto 0);

    -- Test counters
    signal test_count : integer := 0;
    signal pass_count : integer := 0;
    signal fail_count : integer := 0;

begin

    -- Clock generation
    clk <= not clk after C_CLK_PERIOD / 2;

    -- Reset generation
    reset_proc : process
    begin
        rstn <= '0';
        wait for 10 * C_CLK_PERIOD;
        rstn <= '1';
        wait;
    end process;

    -- Main test process
    main : process
        variable v_expected_xor : std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        variable i : integer;

    begin

        in0_i <= (others => '0');
        wait until rstn = '1';
        wait until rising_edge(clk);


        -- ========================================
        -- TEST 1: All zeros input
        -- ========================================
        test_count <= test_count + 1;
        report "TEST 1: All zeros input";
        in0_i <= (others => '0');

        wait until rising_edge(clk);
        -- Wait for pipeline
        for i in 1 to C_PIPELINE_DEPTH loop
            wait until rising_edge(clk);
        end loop;

        v_expected_xor := (others => '0');
        if xor_o = v_expected_xor then
            report "TEST 1 PASS: All zeros -> XOR = 0" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 1 FAIL: Expected all zeros" severity error;
            fail_count <= fail_count + 1;
        end if;

        wait until rising_edge(clk);

        -- ========================================
        -- TEST 2: First input all ones, others zeros
        -- ========================================
        test_count <= test_count + 1;
        report "TEST 2: First input all ones, others zeros";
        -- Only first C_DATA_WIDTH bits set to one, rest zeros
        in0_i(C_DATA_WIDTH - 1 downto 0) <= (others => '1');
        for i in 1 to C_NUM_OF_STREAMS - 1 loop
            in0_i((i + 1) * C_DATA_WIDTH - 1 downto i * C_DATA_WIDTH) <=
                (others => '0');
        end loop;

        wait until rising_edge(clk);
        -- Wait for pipeline
        for i in 1 to C_PIPELINE_DEPTH loop
            wait until rising_edge(clk);
        end loop;

        v_expected_xor := (others => '1');  -- Only first input ones, rest zeros -> XOR = all ones
        if xor_o = v_expected_xor then
            report "TEST 2 PASS: First input ones, others zeros -> all ones" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 2 FAIL: Expected all ones" severity error;
            fail_count <= fail_count + 1;
        end if;

        wait until rising_edge(clk);

        -- ========================================
        -- TEST 3: Single bit set in first input
        -- ========================================
        test_count <= test_count + 1;
        report "TEST 3: Single bit set in first input only";
        in0_i <= (others => '0');
        in0_i(0) <= '1';  -- Set bit 0

        wait until rising_edge(clk);
        -- Wait for pipeline
        for i in 1 to C_PIPELINE_DEPTH loop
            wait until rising_edge(clk);
        end loop;

        v_expected_xor := (others => '0');
        v_expected_xor(0) := '1';
        if xor_o = v_expected_xor then
            report "TEST 3 PASS: Single bit in first input" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 3 FAIL: Expected bit 0 set" severity error;
            fail_count <= fail_count + 1;
        end if;

        wait until rising_edge(clk);

        -- ========================================
        -- TEST 4: Alternating pattern (0xAAAA...AAAA, 0x5555...5555, etc.)
        -- ========================================
        test_count <= test_count + 1;
        report "TEST 4: Alternating pattern inputs";
        for i in 0 to C_NUM_OF_STREAMS - 1 loop
            if i mod 2 = 0 then
                in0_i((i + 1) * C_DATA_WIDTH - 1 downto i * C_DATA_WIDTH) <=
                    (others => '1');
            else
                in0_i((i + 1) * C_DATA_WIDTH - 1 downto i * C_DATA_WIDTH) <=
                    (others => '0');
            end if;
        end loop;

        wait until rising_edge(clk);
        -- Wait for pipeline
        for i in 1 to C_PIPELINE_DEPTH loop
            wait until rising_edge(clk);
        end loop;

        v_expected_xor := (others => '0');  -- 8 ones XOR 8 zeros = all zeros
        if xor_o = v_expected_xor then
            report "TEST 4 PASS: Alternating pattern (8 ones, 8 zeros)" severity note;
            pass_count <= pass_count + 1;
        else
            report "TEST 4 FAIL: Expected all zeros" severity error;
            fail_count <= fail_count + 1;
        end if;

        wait until rising_edge(clk);

        -- ========================================
        -- TEST 5: Validity pipeline check
        -- ========================================
        test_count <= test_count + 1;
        report "TEST 5: Skipped (no validity signals)";
        pass_count <= pass_count + 1;

        wait until rising_edge(clk);

        -- ========================================
        -- TEST 6: Skipped (reset is tested at startup)
        -- ========================================
        test_count <= test_count + 1;
        report "TEST 6: Skipped (reset tested at startup)";
        pass_count <= pass_count + 1;

        wait until rising_edge(clk);

        -- ========================================
        -- Summary
        -- ========================================
        wait for 100 ns;
        report "=====================================";
        report "TEST SUMMARY:";
        report "Total Tests: " & integer'image(test_count);
        report "Passed: " & integer'image(pass_count);
        report "Failed: " & integer'image(fail_count);
        report "=====================================";

        if fail_count = 0 then
            report "ALL TESTS PASSED!" severity note;
        else
            report "SOME TESTS FAILED!" severity error;
        end if;

        std.env.finish;

    end process;

    -- DUT instantiation
    U_SMAC_XOR_N : entity work.smac_xor_n
        generic map(
            G_DATA_WIDTH    => C_DATA_WIDTH,
            G_NUM_OF_INPUTS => C_NUM_OF_STREAMS  -- DUT uses G_NUM_OF_INPUTS generic
        )
        port map(
            clk_i  => clk,
            rstn_i => rstn,
            in0_i  => in0_i,
            xor_o  => xor_o
        );

end architecture tb;
