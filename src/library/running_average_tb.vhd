library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity running_average_tb is
end running_average_tb;

architecture arch of running_average_tb is

    component running_average is
        generic (
            DATA_WIDTH : integer;
            POP_SIZE_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            load : in std_logic;
            data_in : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            average : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    procedure assert_equal(actual, expected : in std_logic_vector(31 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & integer'image(to_integer(signed(expected))) & " but was " & integer'image(to_integer(signed(actual))) severity error;
    end assert_equal;

    constant clock_period : time := 20 ns;

    signal clock : std_logic;
    signal reset : std_logic;

    signal data_in : std_logic_vector(31 downto 0);
    signal load : std_logic;
    signal average : std_logic_vector(31 downto 0);

begin

    dut : running_average
        generic map (
            DATA_WIDTH => 32,
            POP_SIZE_WIDTH => 3
        )
        port map (
            clock => clock,
            reset => reset,
            load => load,
            data_in => data_in,
            average => average
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

        load <= '1';
        
        data_in <= std_logic_vector(to_unsigned(16, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(2, 32)), error_count);

        data_in <= std_logic_vector(to_unsigned(16, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(4, 32)), error_count);

        data_in <= std_logic_vector(to_unsigned(16, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(6, 32)), error_count);

        data_in <= std_logic_vector(to_unsigned(16, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(8, 32)), error_count);

        data_in <= std_logic_vector(to_unsigned(16, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(10, 32)), error_count);

        data_in <= std_logic_vector(to_unsigned(16, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(12, 32)), error_count);

        data_in <= std_logic_vector(to_unsigned(16, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(14, 32)), error_count);

        data_in <= std_logic_vector(to_unsigned(16, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(16, 32)), error_count);

        data_in <= std_logic_vector(to_unsigned(2147483647, 32));
        wait for clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(268435469, 32)), error_count);

        wait for 7 * clock_period;
        assert_equal(average, std_logic_vector(to_unsigned(2147483647, 32)), error_count);

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture;
