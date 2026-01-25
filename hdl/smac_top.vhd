----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_top is
    generic (
        G_DATA_WIDTH     : integer := 8;  --! Data width in bits
        G_SMAC_VARIANT   : integer := 1;  --! 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
        G_NUM_OF_STREAMS : integer := 4;  --! Number of parallel SMAC streams
        G_TAG_WIDTH      : integer := 384 --! Tag width in bits
    );
    port (
        clk_i  : in std_logic;
        rstn_i : in std_logic;

        a1_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.
        a2_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.
        a3_i : in std_logic_vector(127 downto 0); --assuming this will be valid with at the first tvalid and will be stable to until tlast.

        s_axis_tdata_i  : in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        s_axis_tvalid_i : in std_logic;
        s_axis_tready_o : out std_logic;
        s_axis_tlast_i  : in std_logic;

        m_axis_tdata_o  : out std_logic_vector(3 * G_DATA_WIDTH - 1 downto 0);
        m_axis_tvalid_o : out std_logic;
        m_axis_tready_i : in std_logic;
        m_axis_tlast_o  : out std_logic
    );
end entity smac_top;

architecture rtl of smac_top is

    --constant declarations
    constant C_SMAC_VARIANT   : integer := 1; -- 1: SMAC-1 , 2: SMAC-1/2 , 3: SMAC-3/4
    constant C_NUM_OF_STREAMS : integer := 1;
    constant C_TAG_WIDTH      : integer := 384;

    --signal declarations

    --s_axis signals
    signal r_s_axis_tdata_i  : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal r_s_axis_tvalid_i : std_logic;
    signal r_s_axis_tready_o : std_logic;
    signal r_s_axis_tlast_i  : std_logic;

    --m_axis signals
    signal r_m_axis_tdata_i  : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal r_m_axis_tvalid_i : std_logic;
    signal r_m_axis_tready_o : std_logic;
    signal r_m_axis_tlast_i  : std_logic;

begin

    --! TODO: Use smac_top instance here.
    --! this a wrapper module for smac.vhd
    --! the the first data word will contain the KEY and IV information.
    --! the rest will be the actual data to be processed. 
    --! After all data is processed, the tag will be output.    

    inst_smac : entity work.smac
        generic map(
            G_SMAC_VARIANT   => C_SMAC_VARIANT,
            G_NUM_OF_STREAMS => C_NUM_OF_STREAMS,
            G_TAG_WIDTH      => C_TAG_WIDTH
        )
        port map(
            clk_i  => clk_i,
            rstn_i => rstn_i,

            a1_i => a1_i,
            a2_i => a2_i,
            a3_i => a3_i,

            s00_axis_tdata_i => (others => '0'), -- TODO: Connect appropriately
            s00_axis_tvalid_i => '0',            -- TODO: Connect appropriately
            s00_axis_tlast_i  => '0',            -- TODO: Connect appropriately
            s00_axis_tready_o => open,           -- TODO: Connect appropriately

            m00_axis_tdata_o  => open, -- TODO: Connect appropriately
            m00_axis_tvalid_o => open, -- TODO: Connect appropriately
            m00_axis_tlast_o  => open, -- TODO: Connect appropriately
            m00_axis_tready_i => '0'   -- TODO: Connect appropriately
        );

    --------------------------------
    -- main_process: This module ..
    --------------------------------
    main_process : process (clk_i, rstn_i)
    begin
        if (rstn_i = '0') then

        elsif rising_edge(clk_i) then

        end if;
    end process;

end architecture rtl;