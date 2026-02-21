----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_1_n is
    generic (
        G_DATA_WIDTH          : integer := 8; --! Data width in bits
        G_SMAC_VARIANT        : integer := 1; --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        G_NUM_OF_STREAMS      : integer := 4; --! Number of parallel SMAC streams
        G_NUM_OF_INIT_ROUNDS  : integer := 9;
        G_NUM_OF_FINAL_ROUNDS : integer := 9
    );
    port (
        clk_i  : in std_logic;
        rstn_i : in std_logic;

        a1_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.
        a2_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.
        a3_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.

        s_axis_tdata_i  : in std_logic_vector(128 * G_NUM_OF_STREAMS - 1 downto 0);
        s_axis_tvalid_i : in std_logic;
        s_axis_tready_o : out std_logic;
        s_axis_tlast_i  : in std_logic;

        m_axis_tdata_o  : out std_logic_vector(383 downto 0);
        m_axis_tvalid_o : out std_logic;
        m_axis_tready_i : in std_logic;
        m_axis_tlast_o  : out std_logic
    );
end entity smac_1_n;

architecture rtl of smac_1_n is

    --constant declarations

    --type declarations
    type states is (ST_IDLE, ST_REG_FINALIZATION_1_RESULT, ST_WAIT_FOR_FINALIZATION_PHASE_1, ST_SMAC_FINALIZE_1, ST_SMAC_FINALIZE_2);
    signal state : states;

    --signal declarations

    --s_axis signals
    signal l_s_axis_tready_o : std_logic;
    signal r_s_axis_tready_o : std_logic_vector(G_NUM_OF_STREAMS - 1 downto 0);

    --m_axis signals
    signal r_m_axis_tdata_o   : std_logic_vector(384 * G_NUM_OF_STREAMS - 1 downto 0);
    signal r_m_axis_tvalid_o  : std_logic_vector(G_NUM_OF_STREAMS - 1 downto 0);
    signal r_m_axis_tready_en : std_logic;
    signal r_m_axis_tlast_o   : std_logic_vector(G_NUM_OF_STREAMS - 1 downto 0);
    signal r_m_axis_tready_i  : std_logic;

    --other signals
    signal r_is_finalization_phase_2 : std_logic;

    signal r_stream_enable : std_logic;

    signal r_finalization_1_a1 : std_logic_vector(127 downto 0);
    signal r_finalization_1_a2 : std_logic_vector(127 downto 0);
    signal r_finalization_1_a3 : std_logic_vector(127 downto 0);

    signal l_a1 : std_logic_vector(127 downto 0);
    signal l_a2 : std_logic_vector(127 downto 0);
    signal l_a3 : std_logic_vector(127 downto 0);

    signal r_finalization_1_result : std_logic_vector(383 downto 0);
begin

    --------------------------------
    -- main_process: This module ..
    --------------------------------
    main_process : process (clk_i, rstn_i)
    begin
        if (rstn_i = '0') then
            state                     <= ST_IDLE;
            r_stream_enable           <= '0';
            r_m_axis_tready_en        <= '0';
            r_is_finalization_phase_2 <= '0';

        elsif rising_edge(clk_i) then
            case state is
                when ST_IDLE =>
                    r_stream_enable <= '1';
                    if (s_axis_tvalid_i = '1' and l_s_axis_tready_o = '1') then
                        r_m_axis_tready_en <= '1';
                        state              <= ST_WAIT_FOR_FINALIZATION_PHASE_1;
                    end if;

                when ST_WAIT_FOR_FINALIZATION_PHASE_1 =>
                    if (r_m_axis_tvalid_o(0) = '1') then --compression phase of the smac modules are all done
                        r_m_axis_tready_en <= '0';

                        state <= ST_REG_FINALIZATION_1_RESULT;
                    end if;

                when ST_REG_FINALIZATION_1_RESULT =>
                    r_finalization_1_a1 <= r_finalization_1_result(383 downto 256);
                    r_finalization_1_a2 <= r_finalization_1_result(255 downto 128);
                    r_finalization_1_a3 <= r_finalization_1_result(127 downto 0);

                    r_is_finalization_phase_2 <= '1';

                    state <= ST_SMAC_FINALIZE_1;

                when ST_SMAC_FINALIZE_1 =>
                    if (r_m_axis_tvalid_o(0) = '1') then --compression phase of the smac modules are all done
                        r_m_axis_tready_en <= '0';
                        state              <= ST_SMAC_FINALIZE_2;
                    end if;

                when ST_SMAC_FINALIZE_2 => null;
                when others             => null;
            end case;
        end if;
    end process;

    --! this a wrapper module for smac.vhd
    --! the the first data word will contain the KEY and IV information.
    --! the rest will be the actual data to be processed. 
    --! After all data is processed, the tag will be output.    

    GEN_SMACS : for i in 0 to G_NUM_OF_STREAMS - 1 generate
        inst_smac : entity work.smac
            generic map(
                G_SMAC_VARIANT        => G_SMAC_VARIANT,
                G_NUM_OF_INIT_ROUNDS  => G_NUM_OF_INIT_ROUNDS,
                G_NUM_OF_FINAL_ROUNDS => G_NUM_OF_FINAL_ROUNDS,
                G_SMAC_ID             => i
            )
            port map(
                clk_i  => clk_i,
                rstn_i => rstn_i,

                is_finalization_phase_2 => r_is_finalization_phase_2,

                a1_i => l_a1,
                a2_i => l_a2,
                a3_i => l_a3,

                s00_axis_tdata_i  => s_axis_tdata_i(128 * (i + 1) - 1 downto 128 * i),
                s00_axis_tvalid_i => s_axis_tvalid_i,
                s00_axis_tlast_i  => s_axis_tlast_i,
                s00_axis_tready_o => r_s_axis_tready_o(i),

                m00_axis_tdata_o  => r_m_axis_tdata_o(384 * (i + 1) - 1 downto 384 * i),
                m00_axis_tvalid_o => r_m_axis_tvalid_o(i),
                m00_axis_tlast_o  => r_m_axis_tlast_o(i),
                m00_axis_tready_i => r_m_axis_tready_i
            );
    end generate GEN_SMACS;

    GEN_XOR_N : entity work.smac_xor_n
        generic map(
            G_DATA_WIDTH    => 384,
            G_NUM_OF_INPUTS => G_NUM_OF_STREAMS
        )
        port map(
            clk_i  => clk_i,  --! Future Work: If there is critical path problem!  
            rstn_i => rstn_i, --! Future Work: If there is critical path problem!  
            --vld_i   :  in std_logic; --! Future Work: If there is critical path problem!  
            --vld_o   : out std_logic; --! Future Work: If there is critical path problem!  
            in0_i => r_m_axis_tdata_o,

            xor_o => r_finalization_1_result
        );

    l_a1 <= r_finalization_1_a1 when r_is_finalization_phase_2 = '1' else a1_i;
    l_a2 <= r_finalization_1_a2 when r_is_finalization_phase_2 = '1' else a2_i;
    l_a3 <= r_finalization_1_a3 when r_is_finalization_phase_2 = '1' else a3_i;

    l_s_axis_tready_o <= r_stream_enable and r_s_axis_tready_o(0);
    s_axis_tready_o   <= l_s_axis_tready_o;

    m_axis_tdata_o    <= r_m_axis_tdata_o(383 downto 0);
    m_axis_tvalid_o   <= r_m_axis_tvalid_o(0);
    m_axis_tlast_o    <= r_m_axis_tlast_o(0);
    r_m_axis_tready_i <= m_axis_tready_i and r_m_axis_tready_en;

end architecture rtl;