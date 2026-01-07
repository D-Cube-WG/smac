library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac is
  generic
  (
    G_DATA_WIDTH : integer := 8;
    G_ADDR_DEPTH : integer := 8 --addr depth in bits
  );
  port
  (
    clk_i  : in std_logic;
    rstn_i : in std_logic;

    s_axis_tdata_i  : in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    s_axis_tvalid_i : in std_logic;
    s_axis_tready_o : out std_logic;
    s_axis_tlast_i  : in std_logic;

    m_axis_tdata_o  : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    m_axis_tvalid_o : out std_logic;
    m_axis_tready_i : in std_logic;
    m_axis_tlast_o  : out std_logic
  );
end entity smac;

architecture rtl of smac is
  --constant declarations

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