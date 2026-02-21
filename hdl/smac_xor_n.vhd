----------------------------------------------------------------------------------
-- Author       : 
-- Project Name :  
-- Date         :  
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smac_xor_n is
    generic (
        G_DATA_WIDTH    : integer := 128;
        G_NUM_OF_INPUTS : integer := 16
    );
    port (
        clk_i   :  in std_logic;
        rstn_i  :  in std_logic;
        in0_i   :  in std_logic_vector(G_DATA_WIDTH * G_NUM_OF_INPUTS - 1 downto 0);
        xor_o   : out std_logic_vector(G_DATA_WIDTH - 1 downto 0) --! two cycle delayed
    );
end entity smac_xor_n;

architecture rtl of smac_xor_n is
    -- Input registers
    signal in_data_reg : std_logic_vector(G_DATA_WIDTH * G_NUM_OF_INPUTS - 1 downto 0);

    -- Combinatorial XOR result
    signal xor_result : std_logic_vector(G_DATA_WIDTH - 1 downto 0);

begin

    -- Input register stage
    process (clk_i, rstn_i)
    begin
        if rstn_i = '0' then
            in_data_reg <= (others => '0');
        elsif rising_edge(clk_i) then
            in_data_reg <= in0_i;
        end if;
    end process;

    -- Combinatorial XOR of all registered inputs
    process (in_data_reg)
        variable v_xor_result : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    begin
        v_xor_result := in_data_reg(G_DATA_WIDTH - 1 downto 0);
        for i in 1 to G_NUM_OF_INPUTS - 1 loop
            v_xor_result := v_xor_result xor in_data_reg((i + 1) * G_DATA_WIDTH - 1 downto i * G_DATA_WIDTH);
        end loop;
        xor_result <= v_xor_result;
    end process;

    -- Output register stage
    process (clk_i, rstn_i)
    begin
        if rstn_i = '0' then
            xor_o <= (others => '0');
        elsif rising_edge(clk_i) then
            xor_o <= xor_result;
        end if;
    end process;

end architecture rtl;