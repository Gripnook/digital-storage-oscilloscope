library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_grid_generator is
    generic (
        X0 : integer;
        Y0 : integer;
        PLOT_WIDTH : integer;
        PLOT_HEIGHT : integer
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        row : in integer range 0 to 599;
        column : in integer range 0 to 799;
        grid_on : out std_logic
    );
end vga_grid_generator;

architecture arch of vga_grid_generator is

    constant X0_VECTOR : unsigned(5 downto 0) := to_unsigned(X0, 6);
    constant Y0_VECTOR : unsigned(5 downto 0) := to_unsigned(Y0, 6);

    signal grid_row : unsigned(9 downto 0);
    signal grid_col : unsigned(9 downto 0);

    signal in_grid : std_logic;
    signal on_grid_row : std_logic;
    signal on_grid_column : std_logic;

begin

    grid_row <= to_unsigned(599 - row, 10);
    grid_col <= to_unsigned(column, 10);

    in_grid <= '1' when (row <= 599 - Y0 and row >= 599 - PLOT_HEIGHT - Y0 and column >= X0 and column <= PLOT_WIDTH + X0) else '0';

    on_grid_row <= '1' when (grid_row(5 downto 0) = Y0_VECTOR) else '0';
    on_grid_column <= '1' when (grid_col(5 downto 0) = X0_VECTOR) else '0';

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
