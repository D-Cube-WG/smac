library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context; -- <-- REQUIRED for test_runner_setup, run, test_runner_cleanup
use vunit_lib.queue_pkg;

library osvvm;
use osvvm.RandomPkg.all;

library work;
use work.pkg_aes.all;
use work.pkg_smac.all;
use work.pkg_gnrl.all;

entity tb_smac_pi is
    generic (runner_cfg : string);
end tb_smac_pi;

architecture tb of tb_smac_pi is
    --constant declarations
    constant C_DATA_WIDTH : integer := 8;
    constant C_CLK_PERIOD : time    := 10 ns;

    constant C_SMAC_VARIANT : integer := 1;

    --signal declarations
    signal clk  : std_logic := '0';
    signal rstn : std_logic := '0';

    --signal declerations
    signal a1_i    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    signal a2_i    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    signal a3_i    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    signal a1_o    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    signal a2_o    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    signal a3_o    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
    signal message : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

begin

    -- clock and reset generation
    clk  <= not clk after C_CLK_PERIOD/2;
    rstn <= '1' after 10 * C_CLK_PERIOD;

    main : process
        variable v_a1      : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2      : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3      : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_ad      : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_cp      : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a1_o    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a2_o    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_a3_o    : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);
        variable v_message : std_logic_vector(C_SMAC_REG_WIDTH - 1 downto 0);

        variable rnd_seed : integer := 0;

        variable flag : integer;

    begin
        -- VUnit test runner setup
        test_runner_setup(runner, runner_cfg);

        wait until rstn = '1';
        wait until rising_edge(clk);

        if run("test_0") then
            flag := 1;
            TEST_NUMBER_LOOP : for i in 0 to 127 loop

                info("== TEST " & to_string(i) & " ==");

                v_a1      := f_rand_vector(C_SMAC_REG_WIDTH, rnd_seed);
                rnd_seed  := rnd_seed + 1;
                v_a2      := f_rand_vector(C_SMAC_REG_WIDTH, rnd_seed);
                rnd_seed  := rnd_seed + 1;
                v_a3      := f_rand_vector(C_SMAC_REG_WIDTH, rnd_seed);
                rnd_seed  := rnd_seed + 1;
                v_message := f_rand_vector(C_SMAC_REG_WIDTH, rnd_seed);
                rnd_seed  := rnd_seed + 1;

                a1_i    <= v_a1;
                a2_i    <= v_a2;
                a3_i    <= v_a3;
                message <= v_message;

                wait until rising_edge(clk);
                p_smac_compression(
                permutation_array_i => C_PERMUTATION_ARRAY_1,

                a1_i => v_a1,
                a2_i => v_a2,
                a3_i => v_a3,
                m_i  => v_message,

                a1_o => v_a1_o,
                a2_o => v_a2_o,
                a3_o => v_a3_o
                );

                wait for 0 ns;
                --wait until rising_edge(clk);
                if (v_a1_o /= a1_o) then
                    flag := 0;
                    info("ERROR | expected a1_o : " & to_hstring(v_a1_o) & " received a1_o : " & to_hstring(a1_o));
                end if;

                if (v_a2_o /= a2_o) then
                    flag := 0;
                    info("ERROR | expected a2_o : " & to_hstring(v_a2_o) & " received a2_o : " & to_hstring(a2_o));
                end if;

                if (v_a3_o /= a3_o) then
                    flag := 0;
                    info("ERROR | expected a3_o : " & to_hstring(v_a3_o) & " received a3_o : " & to_hstring(a3_o));
                end if;

                if (flag = 0) then
                    exit;
                end if;
            end loop TEST_NUMBER_LOOP;
        end if;

        -- VUnit test runner cleanup
        test_runner_cleanup(runner);
    end process;

    -- DUT instantiation
    U_SMAC_PI : entity work.smac_pi
        generic map(
            G_SMAC_VARIANT => C_SMAC_VARIANT --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        )
        port map(
            a1_i      => a1_i,
            a2_i      => a2_i,
            a3_i      => a3_i,
            message_i => message,

            a1_o => a1_o,
            a2_o => a2_o,
            a3_o => a3_o
        );
end architecture;