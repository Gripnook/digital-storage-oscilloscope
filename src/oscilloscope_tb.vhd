library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;

entity oscilloscope_tb is
end oscilloscope_tb;

architecture arch of oscilloscope_tb is

    component oscilloscope is
        generic (
            ADC_DATA_WIDTH : integer := 12;
            MAX_UPSAMPLE : integer := 4;
            MAX_DOWNSAMPLE : integer := 3
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            horizontal_scale : in std_logic_vector(31 downto 0); -- us/div
            vertical_scale : in std_logic_vector(31 downto 0) := x"00000200"; -- mV/div
            upsample : in integer range 0 to MAX_UPSAMPLE; -- upsampling rate is 2 ** upsample
            downsample : in integer range 0 to MAX_DOWNSAMPLE; -- downsampling rate is 2 ** downsample
            interpolation_enable : in std_logic := '1';
            trigger_type : in std_logic := '1'; -- '1' for rising edge, '0' for falling edge
            trigger_ref : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0) := x"800";
            trigger_correction_enable : in std_logic := '1';
            adc_data : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
            adc_sample : in std_logic;
            pixel_clock : out std_logic;
            hsync, vsync : out std_logic;
            r, g, b : out std_logic_vector(7 downto 0)
        );
    end component;

    component analog_waveform_generator is
        generic (N : integer);
        port (
            clock : in std_logic;
            reset : in std_logic;
            update : in std_logic := '1';
            frequency_control : in std_logic_vector(N-1 downto 0);
            analog_waveform : out std_logic_vector(7 downto 0)
        );
    end component;

    constant HI  : std_logic := '1';
    constant LOW : std_logic := '0';

    constant space : string := " ";
    constant colon : string := ":";

    constant clock_period  : time := 20 ns;
    constant sample_period : time := 2 us;

    signal clock : std_logic;
    signal reset : std_logic;

    signal horizontal_scale : std_logic_vector(31 downto 0);
    signal upsample : integer range 0 to 4;
    signal downsample : integer range 0 to 3;

    signal adc_data : std_logic_vector(11 downto 0);
    signal adc_sample : std_logic;

    signal frequency_control : std_logic_vector(15 downto 0);
    signal analog_waveform : std_logic_vector(7 downto 0);

    signal pixel_clock : std_logic;
    signal hsync : std_logic;
    signal vsync : std_logic;

    signal r : std_logic_vector(7 downto 0);
    signal g : std_logic_vector(7 downto 0);
    signal b : std_logic_vector(7 downto 0);

begin

    dut : oscilloscope
        port map (
            clock => clock,
            reset => reset,
            horizontal_scale => horizontal_scale,
            upsample => upsample,
            downsample => downsample,
            adc_data => adc_data,
            adc_sample => adc_sample,
            pixel_clock => pixel_clock,
            hsync => hsync,
            vsync => vsync,
            r => r,
            g => g,
            b => b
        );

    sig_gen : analog_waveform_generator
        generic map (N => 16)
        port map (
            clock => clock,
            reset => reset,
            frequency_control => frequency_control,
            analog_waveform => analog_waveform
        );

    adc_data <= analog_waveform & "0000";

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    sampling_process : process
    begin
        adc_sample <= '0';
        wait for sample_period - clock_period;
        adc_sample <= '1';
        wait for clock_period;
    end process;

    output_process : process (clock)
        file vga_log : text is out "test-results/oscilloscope_log.txt";
        variable vga_line : line;
    begin
        if (rising_edge(clock)) then
            write(vga_line, now);
            write(vga_line, colon & space);
            write(vga_line, hsync);
            write(vga_line, space);
            write(vga_line, vsync);
            write(vga_line, space);
            write(vga_line, r);
            write(vga_line, space);
            write(vga_line, g);
            write(vga_line, space);
            write(vga_line, b);
            writeline(vga_log, vga_line);
        end if;
    end process;

    test_process : process
    begin
        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';

        -- 1 kHz
        upsample <= 0;
        downsample <= 1;
        horizontal_scale <= std_logic_vector(to_unsigned(256, 32));
        frequency_control <= x"0083";
        wait for 14 ms;
        wait for 14 ms;

        -- 10 kHz
        upsample <= 2;
        downsample <= 0;
        horizontal_scale <= std_logic_vector(to_unsigned(32, 32));
        frequency_control <= x"051F";
        wait for 14 ms;
        wait for 14 ms;

        -- 100 kHz
        upsample <= 4;
        horizontal_scale <= std_logic_vector(to_unsigned(8, 32));
        frequency_control <= x"3333";
        wait for 14 ms;

        -- 200 kHz
        frequency_control <= x"6666";
        wait for 14 ms;

        wait;
    end process;

end architecture;
