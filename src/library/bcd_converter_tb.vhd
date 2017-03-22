library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd_converter_tb is
end bcd_converter_tb;

architecture arch of bcd_converter_tb is

    component bcd_converter is
        generic (
            INPUT_WIDTH : integer;
            BCD_DIGITS : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            binary : in std_logic_vector(INPUT_WIDTH - 1 downto 0);
            start : in std_logic;
            bcd : out std_logic_vector(4 * BCD_DIGITS - 1 downto 0);
            done : out std_logic
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

    signal binary : std_logic_vector(7 downto 0);
    signal start : std_logic;
    signal bcd : std_logic_vector(15 downto 0);
    signal done : std_logic;

begin

    dut : bcd_converter
        generic map (
            INPUT_WIDTH => 8,
            BCD_DIGITS => 4
        )
        port map (
            clock => clock,
            reset => reset,
            binary => binary,
            start => start,
            bcd => bcd,
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

        binary <= std_logic_vector(to_unsigned(0, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0000", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(1, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0001", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(2, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0002", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(4, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0004", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(13, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0013", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(16, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0016", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(31, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0031", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(32, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0032", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(64, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0064", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(99, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0099", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(100, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0100", error_count);
        start <= '0';
        wait for clock_period;

        binary <= std_logic_vector(to_unsigned(255, 8));
        start <= '1';
        wait until done = '1';
        assert_equal(bcd, x"0255", error_count);
        start <= '0';
        wait for clock_period;

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture;
