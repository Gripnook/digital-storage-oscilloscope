-- Generates statistics for a population of 2 ** POP_SIZE_WIDTH. A new data point
-- can be clocked in every cycle using the enable input, and the data can be cleared
-- using the clear input. The statistics are computed using the data that has been
-- clocked in since the last clear input. It is up to the user to ensure that there
-- are exactly 2 ** POP_SIZE_WIDTH data points if a correct average is required. The
-- other statistical parameters do not depend on the number of data points.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity statistics is
    generic (
        DATA_WIDTH : integer;
        POP_SIZE_WIDTH : integer
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        enable : in std_logic;
        clear : in std_logic;
        data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        spread : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        average : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        maximum : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        minimum : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end statistics;

architecture arch of statistics is

    signal accumulator : std_logic_vector(DATA_WIDTH + POP_SIZE_WIDTH - 1 downto 0);
    signal accumulator_next : std_logic_vector(DATA_WIDTH + POP_SIZE_WIDTH - 1 downto 0);
    signal maximum_internal : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal minimum_internal : std_logic_vector(DATA_WIDTH - 1 downto 0);

    signal greater_than_maximum : std_logic;
    signal maximum_enable : std_logic;
    signal less_than_minimum : std_logic;
    signal minimum_enable : std_logic;

begin

    spread <= std_logic_vector(unsigned(maximum_internal) - unsigned(minimum_internal));
    average <= accumulator(DATA_WIDTH + POP_SIZE_WIDTH - 1 downto POP_SIZE_WIDTH);
    maximum <= maximum_internal;
    minimum <= minimum_internal;

    accumulator_next <= std_logic_vector(unsigned(accumulator) + unsigned(data));

    accumulator_reg : process (clock, reset)
    begin
        if (reset = '1') then
            accumulator <= (others => '0');
        elsif (rising_edge(clock)) then
            if (clear = '1') then
                accumulator <= (others => '0');
            elsif (enable = '1') then
                accumulator <= accumulator_next;
            end if;
        end if;
    end process;

    greater_than_maximum <= '1' when unsigned(data) > unsigned(maximum_internal) else '0';
    maximum_enable <= enable and greater_than_maximum;

    maximum_reg : process (clock, reset)
    begin
        if (reset = '1') then
            maximum_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (clear = '1') then
                maximum_internal <= (others => '0');
            elsif (maximum_enable = '1') then
                maximum_internal <= data;
            end if;
        end if;
    end process;

    less_than_minimum <= '1' when unsigned(data) < unsigned(minimum_internal) else '0';
    minimum_enable <= enable and less_than_minimum;

    minimum_reg : process (clock, reset)
    begin
        if (reset = '1') then
            minimum_internal <= (others => '1');
        elsif (rising_edge(clock)) then
            if (clear = '1') then
                minimum_internal <= (others => '1');
            elsif (minimum_enable = '1') then
                minimum_internal <= data;
            end if;
        end if;
    end process;

end architecture;
