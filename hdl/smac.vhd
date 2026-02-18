----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac is
    generic (
        G_SMAC_VARIANT        : integer := 1; --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        G_NUM_OF_INIT_ROUNDS  : integer := 9;
        G_NUM_OF_FINAL_ROUNDS : integer := 9;
        G_SMAC_ID             : integer := 0 --used for aggregated mode
    );
    port (
        clk_i  : in std_logic;
        rstn_i : in std_logic;

        is_finalization_phase_2 : in std_logic;

        a1_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.
        a2_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.
        a3_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.

        s00_axis_tdata_i  : in std_logic_vector(127 downto 0);
        s00_axis_tvalid_i : in std_logic;
        s00_axis_tlast_i  : in std_logic;
        s00_axis_tready_o : out std_logic;

        m00_axis_tdata_o  : out std_logic_vector(3 * 128 - 1 downto 0);
        m00_axis_tvalid_o : out std_logic;
        m00_axis_tlast_o  : out std_logic; --! Always '1' when tvalid is '1', since tag is single word.
        m00_axis_tready_i : in std_logic
    );
end entity smac;

architecture rtl of smac is

    -- constant declarations
    constant C_REG_WIDTH : integer := 128;

    constant C_ONE_STAR : std_logic_vector(C_REG_WIDTH - 1 downto 0) := (C_REG_WIDTH - 1 downto C_REG_WIDTH - 8 => x"01", others => '0');

    -- type declarations
    type t_states is (ST_IDLE, ST_SMAC_INIT, ST_SMAC_COMPRESSION, ST_SMAC_FINALIZE, ST_SEND_SMAC_RESULT);
    signal state : t_states;

    -- signal declarations
    signal r_s00_axis_tready_o : std_logic;

    signal r_a1_i : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal r_a2_i : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal r_a3_i : std_logic_vector(C_REG_WIDTH - 1 downto 0);

    signal l_xor2_a1_o : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal l_xor2_a2_o : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal l_xor2_a3_o : std_logic_vector(C_REG_WIDTH - 1 downto 0);

    signal r_message_i : std_logic_vector(C_REG_WIDTH - 1 downto 0);

    signal r_xor2_0_inp_0_i : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal r_xor2_1_inp_0_i : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal r_xor2_2_inp_0_i : std_logic_vector(C_REG_WIDTH - 1 downto 0);

    signal l_pi_a1_o : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal l_pi_a2_o : std_logic_vector(C_REG_WIDTH - 1 downto 0);
    signal l_pi_a3_o : std_logic_vector(C_REG_WIDTH - 1 downto 0);

    signal r_m00_axis_tdata_o  : std_logic_vector(3 * C_REG_WIDTH - 1 downto 0);
    signal r_m00_axis_tvalid_o : std_logic;
    signal r_m00_axis_tlast_o  : std_logic;

    signal r_counter : unsigned(15 downto 0);

begin

    --TODO: Sequential SMAC Top implementation
    -- The first s00_axis_tdata_i will contain the KEY and IV information.
    -- The rest will be the actual data to be processed. 
    -- After all data is processed, the tag will be output on m00_axis_tdata_o.

    -- Use only ONE smac_N_pi and ONE smac_xor_3 instance here.

    --! Use appropriate FSM to control the data flow.
    --! --> ST_SMAC_INIT, 
    --! --> ST_SMAC_COMPRESSION,
    --! --> ST_SMAC_FINALIZE_1, 
    --! --> ST_SMAC_FINALIZE_2 
    --! states are suggested.

    main_process : process (clk_i, rstn_i) begin
        if (rstn_i = '0') then
            state <= ST_IDLE;

            r_s00_axis_tready_o <= '0';
            r_counter           <= (others => '0');

            r_m00_axis_tvalid_o <= '0';
            r_m00_axis_tlast_o  <= '0';

        elsif (rising_edge(clk_i)) then
            case state is
                when ST_IDLE =>
                    --we are waiting for a valid word
                    if (s00_axis_tvalid_i = '1') or (is_finalization_phase_2 = '1' and G_SMAC_ID = 0) then
                        r_a1_i <= a1_i;
                        r_a2_i <= a2_i;
                        r_a3_i <= a3_i;

                        r_xor2_0_inp_0_i <= a1_i;
                        r_xor2_1_inp_0_i <= a2_i;
                        r_xor2_2_inp_0_i <= a3_i;

                        r_message_i <= C_ONE_STAR;

                        r_s00_axis_tready_o <= '0';
                        r_counter           <= (others => '0');
                        state               <= ST_SMAC_INIT;
                    end if;

                when ST_SMAC_INIT =>
                    r_counter <= r_counter + 1;

                    if (r_counter = G_NUM_OF_INIT_ROUNDS - 1) then
                        r_a1_i <= l_xor2_a1_o;
                        r_a2_i <= l_xor2_a2_o;
                        r_a3_i <= l_xor2_a3_o;

                        r_message_i <= s00_axis_tdata_i; --tvalid='1' when we are here
                        r_counter   <= (others => '0');

                        if (is_finalization_phase_2 = '1') then
                            state <= ST_SMAC_FINALIZE;
                        else
                            state <= ST_SMAC_COMPRESSION;
                        end if;
                    else
                        r_a1_i <= l_pi_a1_o;
                        r_a2_i <= l_pi_a2_o;
                        r_a3_i <= l_pi_a3_o;

                        if (r_counter = G_NUM_OF_INIT_ROUNDS - 2) then
                            r_s00_axis_tready_o <= '1';
                        end if;
                    end if;

                when ST_SMAC_COMPRESSION =>
                    if (s00_axis_tvalid_i = '1') then
                        r_message_i <= s00_axis_tdata_i;

                        r_a1_i <= l_pi_a1_o;
                        r_a2_i <= l_pi_a2_o;
                        r_a3_i <= l_pi_a3_o;

                        if (s00_axis_tlast_i = '1') then
                            r_s00_axis_tready_o <= '0';

                            state <= ST_SMAC_FINALIZE;
                        end if;
                    end if;

                when ST_SMAC_FINALIZE =>
                    r_message_i <= C_ONE_STAR;

                    r_counter <= r_counter + 1;
                    if (r_counter = G_NUM_OF_FINAL_ROUNDS) then

                        r_a1_i <= l_xor2_a1_o;
                        r_a2_i <= l_xor2_a2_o;
                        r_a3_i <= l_xor2_a3_o;

                        state <= ST_SEND_SMAC_RESULT;
                    else
                        if (r_counter = 0) then
                            r_xor2_0_inp_0_i <= l_pi_a1_o;
                            r_xor2_1_inp_0_i <= l_pi_a2_o;
                            r_xor2_2_inp_0_i <= l_pi_a3_o;
                        end if;

                        r_a1_i <= l_pi_a1_o;
                        r_a2_i <= l_pi_a2_o;
                        r_a3_i <= l_pi_a3_o;
                    end if;

                when ST_SEND_SMAC_RESULT =>
                    r_m00_axis_tdata_o  <= r_a1_i & r_a2_i & r_a3_i;
                    r_m00_axis_tvalid_o <= '1';
                    r_m00_axis_tlast_o  <= '1';

                    if (m00_axis_tready_i = '1' and r_m00_axis_tvalid_o = '1') then
                        r_m00_axis_tvalid_o <= '0';
                        r_m00_axis_tlast_o  <= '0';

                        state <= ST_IDLE;
                    end if;

                when others => null;
            end case;
        end if;
    end process main_process;

    U_PI : entity work.smac_pi
        generic map(
            G_SMAC_VARIANT => G_SMAC_VARIANT --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        )
        port map(
            a1_i      => r_a1_i,
            a2_i      => r_a2_i,
            a3_i      => r_a3_i,
            message_i => r_message_i,

            a1_o => l_pi_a1_o,
            a2_o => l_pi_a2_o,
            a3_o => l_pi_a3_o
        );

    U_XOR2_0 : entity work.smac_xor_2
        port map(
            --clk_i   :  in std_logic; --! Future Work: If there is critical path problem!  
            --rstn_i  :  in std_logic; --! Future Work: If there is critical path problem!  
            --vld_i   :  in std_logic; --! Future Work: If there is critical path problem!  
            --vld_o   : out std_logic; --! Future Work: If there is critical path problem!  
            in0_i => r_xor2_0_inp_0_i,
            in1_i => l_pi_a1_o,
            xor_o => l_xor2_a1_o
        );

    U_XOR2_1 : entity work.smac_xor_2
        port map(
            --clk_i   :  in std_logic; --! Future Work: If there is critical path problem!  
            --rstn_i  :  in std_logic; --! Future Work: If there is critical path problem!  
            --vld_i   :  in std_logic; --! Future Work: If there is critical path problem!  
            --vld_o   : out std_logic; --! Future Work: If there is critical path problem!  
            in0_i => r_xor2_1_inp_0_i,
            in1_i => l_pi_a2_o,
            xor_o => l_xor2_a2_o
        );

    U_XOR2_2 : entity work.smac_xor_2
        port map(
            --clk_i   :  in std_logic; --! Future Work: If there is critical path problem!  
            --rstn_i  :  in std_logic; --! Future Work: If there is critical path problem!  
            --vld_i   :  in std_logic; --! Future Work: If there is critical path problem!  
            --vld_o   : out std_logic; --! Future Work: If there is critical path problem!  
            in0_i => r_xor2_2_inp_0_i,
            in1_i => l_pi_a3_o,
            xor_o => l_xor2_a3_o
        );
    -- combinational assigments
    s00_axis_tready_o <= r_s00_axis_tready_o;

    m00_axis_tdata_o  <= r_m00_axis_tdata_o;
    m00_axis_tvalid_o <= r_m00_axis_tvalid_o;
    m00_axis_tlast_o  <= r_m00_axis_tlast_o;
end architecture rtl;