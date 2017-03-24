library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity oscilloscope_tb is
end oscilloscope_tb;

architecture arch of oscilloscope_tb is

    component oscilloscope is
        generic (
            ADC_DATA_WIDTH : integer := 12;
            MAX_UPSAMPLE : integer := 5
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            horizontal_scale : in std_logic_vector(31 downto 0) := x"00000080";
            vertical_scale : in std_logic_vector(31 downto 0) := x"00000200";
            upsample : in integer range 0 to MAX_UPSAMPLE := 0;
            trigger_type : in std_logic := '1';
            trigger_ref : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0) := x"800";
            adc_data : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
            adc_en : in std_logic;
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

    constant clock_period : time := 20 ns;

    signal clock : std_logic;
    signal reset : std_logic;

    signal adc_data : std_logic_vector(11 downto 0);
    signal adc_en : std_logic;
    signal adc_sample_count : integer range 0 to 99;

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
            adc_data => adc_data,
            adc_en => adc_en,
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

    adc_processing : process (clock, reset)
    begin
        if (reset = '1') then
            adc_sample_count <= 0;
            adc_en <= '0';
        elsif (rising_edge(clock)) then
            adc_en <= '0';
            if (adc_sample_count = 99) then
                adc_sample_count <= 0;
                adc_en <= '1';
            else
                adc_sample_count <= adc_sample_count + 1;
            end if;
        end if;
    end process;

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
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
        frequency_control <= x"0083";
        wait for 40 ms;

        -- 10 kHz
        frequency_control <= x"051F";
        wait for 20 ms;

        -- 100 kHz
        frequency_control <= x"3333";
        wait for 10 ms;

        -- 200 kHz
        frequency_control <= x"6666";
        wait for 10 ms;

        wait;
    end process;

end architecture;
