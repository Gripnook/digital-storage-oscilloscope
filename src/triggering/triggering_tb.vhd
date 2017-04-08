library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity triggering_tb is
end triggering_tb;

architecture arch of triggering_tb is

    component triggering is
        generic (
            DATA_WIDTH : integer := 8
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            adc_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            adc_sample : in std_logic;
            trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
            trigger_ref : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            trigger : out std_logic;
            trigger_frequency : out std_logic_vector(31 downto 0) -- Hz
        );
    end component;

    component analog_waveform_generator is
        generic (N : integer := 16);
        port (
            clock : in std_logic;
            reset : in std_logic;
            update : in std_logic := '1';
            frequency_control : in std_logic_vector(N-1 downto 0);
            analog_waveform : out std_logic_vector(7 downto 0)
        );
    end component;

    constant clock_period : time := 20 ns;

    signal clock : std_logic;
    signal reset : std_logic;

    signal adc_data : std_logic_vector(7 downto 0);
    signal adc_sample : std_logic;
    signal trigger_type : std_logic;
    signal trigger_ref : std_logic_vector(7 downto 0);
    signal trigger : std_logic;
    signal trigger_frequency : std_logic_vector(31 downto 0);

    signal frequency_control : std_logic_vector(15 downto 0);

begin

    dut : triggering
        port map (
            clock => clock,
            reset => reset,
            adc_data => adc_data,
            adc_sample => adc_sample,
            trigger_type => trigger_type,
            trigger_ref => trigger_ref,
            trigger => trigger,
            trigger_frequency => trigger_frequency
        );

    sig_gen : analog_waveform_generator
        port map (
            clock => clock,
            reset => reset,
            frequency_control => frequency_control,
            analog_waveform => adc_data
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    test_process : process
    begin
        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';

        trigger_ref <= x"80";

        trigger_type <= '1';

        adc_sample <= '1';

        -- 10 kHz
        frequency_control <= x"051F";
        wait for 2000 us;

        -- 100 kHz
        frequency_control <= x"3333";
        wait for 200 us;

        -- 200 kHz
        frequency_control <= x"6666";
        wait for 200 us;

        trigger_type <= '0';

        -- 10 kHz
        frequency_control <= x"051F";
        wait for 2000 us;

        -- 100 kHz
        frequency_control <= x"3333";
        wait for 200 us;

        -- 200 kHz
        frequency_control <= x"6666";
        wait for 200 us;

        wait;
    end process;

end architecture;
