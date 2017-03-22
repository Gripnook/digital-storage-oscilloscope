library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider_tb is
end divider_tb;

architecture arch of divider_tb is

    component divider is
        generic (
            DATA_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            dividend : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            divisor : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            start : in std_logic;
            quotient : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            remainder : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            done : out std_logic
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

    signal dividend : std_logic_vector(31 downto 0);
    signal divisor : std_logic_vector(31 downto 0);
    signal start : std_logic;
    signal quotient : std_logic_vector(31 downto 0);
    signal remainder : std_logic_vector(31 downto 0);
    signal done : std_logic;

begin

    dut : divider
        generic map (
            DATA_WIDTH => 32
        )
        port map (
            clock => clock,
            reset => reset,
            dividend => dividend,
            divisor => divisor,
            start => start,
            quotient => quotient,
            remainder => remainder,
            done => done
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
        wait until rising_edge(clock);
        reset <= '0';

        -- Division by zero should not loop infinitely, but we don't care about the result
        dividend <= std_logic_vector(to_unsigned(0, 32));
        divisor <= std_logic_vector(to_unsigned(0, 32));
        start <= '1';
        wait until done = '1';
        start <= '0';
        wait for clock_period;

        dividend <= std_logic_vector(to_unsigned(4095, 32));
        divisor <= std_logic_vector(to_unsigned(1, 32));
        start <= '1';
        wait until done = '1';
        assert_equal(quotient, std_logic_vector(to_unsigned(4095, 32)), error_count);
        assert_equal(remainder, std_logic_vector(to_unsigned(0, 32)), error_count);
        start <= '0';
        wait for clock_period;

        dividend <= std_logic_vector(to_unsigned(342, 32));
        divisor <= std_logic_vector(to_unsigned(7, 32));
        start <= '1';
        wait until done = '1';
        assert_equal(quotient, std_logic_vector(to_unsigned(48, 32)), error_count);
        assert_equal(remainder, std_logic_vector(to_unsigned(6, 32)), error_count);
        start <= '0';
        wait for clock_period;

        dividend <= std_logic_vector(to_unsigned(50000000, 32));
        divisor <= std_logic_vector(to_unsigned(147, 32));
        start <= '1';
        wait until done = '1';
        assert_equal(quotient, std_logic_vector(to_unsigned(340136, 32)), error_count);
        assert_equal(remainder, std_logic_vector(to_unsigned(8, 32)), error_count);
        start <= '0';
        wait for clock_period;

        dividend <= std_logic_vector(to_unsigned(40000000, 32));
        divisor <= std_logic_vector(to_unsigned(4095, 32));
        start <= '1';
        wait until done = '1';
        assert_equal(quotient, std_logic_vector(to_unsigned(9768, 32)), error_count);
        assert_equal(remainder, std_logic_vector(to_unsigned(40, 32)), error_count);
        start <= '0';
        wait for clock_period;

        dividend <= std_logic_vector(to_unsigned(500000, 32));
        divisor <= std_logic_vector(to_unsigned(40000, 32));
        start <= '1';
        wait until done = '1';
        assert_equal(quotient, std_logic_vector(to_unsigned(12, 32)), error_count);
        assert_equal(remainder, std_logic_vector(to_unsigned(20000, 32)), error_count);
        start <= '0';
        wait for clock_period;

        dividend <= std_logic_vector(to_unsigned(256, 32));
        divisor <= std_logic_vector(to_unsigned(500, 32));
        start <= '1';
        wait until done = '1';
        assert_equal(quotient, std_logic_vector(to_unsigned(0, 32)), error_count);
        assert_equal(remainder, std_logic_vector(to_unsigned(256, 32)), error_count);
        start <= '0';
        wait for clock_period;

        dividend <= std_logic_vector(to_unsigned(4000000, 32));
        divisor <= std_logic_vector(to_unsigned(3000000, 32));
        start <= '1';
        wait until done = '1';
        assert_equal(quotient, std_logic_vector(to_unsigned(1, 32)), error_count);
        assert_equal(remainder, std_logic_vector(to_unsigned(1000000, 32)), error_count);
        start <= '0';
        wait for clock_period;

        dividend <= std_logic_vector(to_unsigned(2147483647, 32));
        divisor <= std_logic_vector(to_unsigned(512, 32));
        start <= '1';
        wait until done = '1';
        assert_equal(quotient, std_logic_vector(to_unsigned(4194303, 32)), error_count);
        assert_equal(remainder, std_logic_vector(to_unsigned(511, 32)), error_count);
        start <= '0';
        wait for clock_period;

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture;
