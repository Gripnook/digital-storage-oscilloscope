library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_sampler_tb is
end adc_sampler_tb;

architecture arch of adc_sampler_tb is

    component adc_sampler is
        generic (
            ADC_DATA_WIDTH : integer := 12;
            ADC_SAMPLE_PERIOD : integer := 80 -- 2 us in clock cycles
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            adc_sclk : out std_logic;
            adc_din : out std_logic;
            adc_dout : in std_logic;
            adc_convst : out std_logic;
            adc_sample : out std_logic;
            adc_data : out std_logic_vector(ADC_DATA_WIDTH - 1 downto 0)
        );
    end component;

    procedure assert_equal(actual, expected : in std_logic_vector(11 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & integer'image(to_integer(unsigned(expected))) & " but was " & integer'image(to_integer(unsigned(actual))) severity error;
    end assert_equal;

    constant HI  : std_logic := '1';
    constant LOW : std_logic := '0';

    constant clock_period : time := 25 ns;

    signal clock : std_logic;
    signal reset : std_logic;

    signal adc_sclk : std_logic;
    signal adc_din : std_logic;
    signal adc_dout : std_logic;
    signal adc_convst : std_logic;
    signal adc_sample : std_logic;
    signal adc_data : std_logic_vector(11 downto 0);

begin

    dut : adc_sampler
        port map (
            clock => clock,
            reset => reset,
            adc_sclk => adc_sclk,
            adc_din => adc_din,
            adc_dout => adc_dout,
            adc_convst => adc_convst,
            adc_sample => adc_sample,
            adc_data => adc_data
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

        adc_dout <= '1';

        wait until adc_sample = '1';

        assert_equal(adc_data, x"FFF", error_count);

        wait until rising_edge(adc_sclk);
        adc_dout <= '1';
        wait for clock_period;
        adc_dout <= '0';
        wait for clock_period;
        adc_dout <= '0';
        wait for clock_period;
        adc_dout <= '0';
        wait for clock_period;
        adc_dout <= '1';
        wait for clock_period;
        adc_dout <= '1';
        wait for clock_period;
        adc_dout <= '0';
        wait for clock_period;
        adc_dout <= '0';
        wait for clock_period;
        adc_dout <= '0';
        wait for clock_period;
        adc_dout <= '1';
        wait for clock_period;
        adc_dout <= '0';
        wait for clock_period;
        adc_dout <= '1';

        wait until adc_sample = '1';

        assert_equal(adc_data, x"8C5", error_count);

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture;
