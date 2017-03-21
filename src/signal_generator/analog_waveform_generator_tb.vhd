library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity analog_waveform_generator_tb is
end analog_waveform_generator_tb;

architecture arch of analog_waveform_generator_tb is

    component analog_waveform_generator is
        generic (N : integer := 5);
        port (clock : in std_logic;
              reset : in std_logic;
              update : in std_logic;
              frequency_control : in std_logic_vector(N-1 downto 0);
              analog_waveform : out std_logic_vector(7 downto 0));
    end component;

    constant clock_period : time := 15.625 ns; -- 64 MHz

    signal clock : std_logic;
    signal reset : std_logic;
    signal update : std_logic;
    signal frequency_control : std_logic_vector(4 downto 0);
    signal analog_waveform : std_logic_vector(7 downto 0);

begin

    generator : analog_waveform_generator
    port map (clock => clock,
              reset => reset,
              update => update,
              frequency_control => frequency_control,
              analog_waveform => analog_waveform);

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period/2;
        clock <= '1';
        wait for clock_period/2;
    end process;

    test_process : process
    begin

        reset <= '1';
        wait for clock_period;
        reset <= '0';

        -- 200 kHz sine wave
        frequency_control <= std_logic_vector(to_unsigned(1, 5));
        update <= '1';
        wait for 5 * clock_period;
        update <= '0';
        wait for 1024 * clock_period;

        -- 400 kHz sine wave
        frequency_control <= std_logic_vector(to_unsigned(2, 5));
        update <= '1';
        wait for 5 * clock_period;
        update <= '0';
        wait for 512 * clock_period;

        -- 3.2 MHz sine wave
        frequency_control <= std_logic_vector(to_unsigned(16, 5));
        update <= '1';
        wait for 5 * clock_period;
        update <= '0';
        wait for 128 * clock_period;

        wait;
    end process;

end architecture;
