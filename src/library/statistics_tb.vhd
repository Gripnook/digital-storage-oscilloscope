library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity statistics_tb is
end statistics_tb;

architecture arch of statistics_tb is

    component statistics is
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
    end component;

    procedure assert_equal(actual, expected : in std_logic_vector(15 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & integer'image(to_integer(signed(expected))) & " but was " & integer'image(to_integer(signed(actual))) severity error;
    end assert_equal;

    constant clock_period : time := 20 ns;

    signal clock : std_logic;
    signal reset : std_logic;

    signal enable : std_logic;
    signal clear : std_logic;
    signal data : std_logic_vector(15 downto 0);
    signal spread : std_logic_vector(15 downto 0);
    signal average : std_logic_vector(15 downto 0);
    signal maximum : std_logic_vector(15 downto 0);
    signal minimum : std_logic_vector(15 downto 0);

begin

    dut : statistics
        generic map (
            DATA_WIDTH => 16,
            POP_SIZE_WIDTH => 2
        )
        port map (
            clock => clock,
            reset => reset,
            enable => enable,
            clear => clear,
            data => data,
            spread => spread,
            average => average,
            maximum => maximum,
            minimum => minimum
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    test_process : process
        variable error_count : integer := 0;
    begin
        reset <= '1';
        wait until falling_edge(clock);
        reset <= '0';

        enable <= '1';
        clear <= '0';
        
        data <= std_logic_vector(to_unsigned(24, 16));
        wait for clock_period;
        data <= std_logic_vector(to_unsigned(7, 16));
        wait for clock_period;
        data <= std_logic_vector(to_unsigned(3, 16));
        wait for clock_period;
        data <= std_logic_vector(to_unsigned(18, 16));
        wait for clock_period;

        assert_equal(spread, std_logic_vector(to_unsigned(21, 16)), error_count);
        assert_equal(average, std_logic_vector(to_unsigned(13, 16)), error_count);
        assert_equal(maximum, std_logic_vector(to_unsigned(24, 16)), error_count);
        assert_equal(minimum, std_logic_vector(to_unsigned(3, 16)), error_count);

        clear <= '1';
        wait for clock_period;
        clear <= '0';

        enable <= '1';
        
        data <= std_logic_vector(to_unsigned(65535, 16));
        wait for clock_period;
        data <= std_logic_vector(to_unsigned(0, 16));
        wait for clock_period;
        data <= std_logic_vector(to_unsigned(65535, 16));
        wait for clock_period;
        data <= std_logic_vector(to_unsigned(2, 16));
        wait for clock_period;

        assert_equal(spread, std_logic_vector(to_unsigned(65535, 16)), error_count);
        assert_equal(average, std_logic_vector(to_unsigned(32768, 16)), error_count);
        assert_equal(maximum, std_logic_vector(to_unsigned(65535, 16)), error_count);
        assert_equal(minimum, std_logic_vector(to_unsigned(0, 16)), error_count);

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture;
