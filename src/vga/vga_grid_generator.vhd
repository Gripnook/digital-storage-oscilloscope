-- A module that asserts a control signal when the display should show a grid
-- in the waveform plot area.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_parameters.all;

entity vga_grid_generator is
    port (
        clock : in std_logic;
        reset : in std_logic;
        row : in integer range 0 to V_PIXELS - 1;
        column : in integer range 0 to H_PIXELS - 1;
        grid_on : out std_logic
    );
end vga_grid_generator;

architecture arch of vga_grid_generator is

    signal grid_row : unsigned(V_PIXELS_BIT_LENGTH - 1 downto 0);
    signal grid_col : unsigned(H_PIXELS_BIT_LENGTH - 1 downto 0);

    signal in_grid : std_logic;
    signal on_grid_row : std_logic;
    signal on_grid_column : std_logic;

begin

    grid_row <= to_unsigned(V_PIXELS - 1 - row, V_PIXELS_BIT_LENGTH);
    grid_col <= to_unsigned(column, H_PIXELS_BIT_LENGTH);

    in_grid <= '1' when (row <= V_PIXELS - 1 - Y0 and row >= V_PIXELS - 1 - PLOT_HEIGHT - Y0 and
        column >= X0 and column <= PLOT_WIDTH + X0) else '0';

    on_grid_row <= '1' when (grid_row(GRID_HEIGHT_BIT_LENGTH - 1 downto 0) = Y0_GRID_VECTOR) else '0';
    on_grid_column <= '1' when (grid_col(GRID_WIDTH_BIT_LENGTH - 1 downto 0) = X0_GRID_VECTOR) else '0';

    process (clock, reset)
    begin
        if (reset = '1') then
            grid_on <= '0';
        elsif (rising_edge(clock)) then
            grid_on <= '0'; -- default value
            if (in_grid = '1' and (on_grid_row = '1' or on_grid_column = '1')) then
                grid_on <= '1';
            end if;
        end if;
    end process;

end architecture;
