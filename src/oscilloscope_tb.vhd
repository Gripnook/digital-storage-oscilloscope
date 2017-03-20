library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity oscilloscope_tb is
end oscilloscope_tb;

architecture arch of oscilloscope_tb is

    component oscilloscope is
        generic (ADC_DATA_WIDTH : integer := 12);
        port (
            clock : in std_logic;
            reset_n : in std_logic;
            timebase : in std_logic_vector(1 downto 0);
            trigger_up_n : in std_logic;
            trigger_down_n : in std_logic;
            trigger_type : in std_logic;
            pixel_clock : out std_logic;
            hsync, vsync : out std_logic;
            r, g, b : out std_logic_vector(7 downto 0)
        );
    end component;

    constant HI  : std_logic := '1';
    constant LOW : std_logic := '0';

    constant space : string := " ";
    constant colon : string := ":";

    constant clock_period : time := 20 ns;

    signal clock : std_logic;
    signal reset_n : std_logic;

    signal timebase : std_logic_vector(1 downto 0) := "00";

    signal trigger_up_n, trigger_down_n : std_logic := '0';
    signal trigger_type : std_logic := '1';

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
            reset_n => reset_n,
            timebase => timebase,
            trigger_up_n => trigger_up_n,
            trigger_down_n => trigger_down_n,
            trigger_type => trigger_type,
            pixel_clock => pixel_clock,
            hsync => hsync,
            vsync => vsync,
            r => r,
            g => g,
            b => b
        );

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
        reset_n <= '0';
        wait until rising_edge(clock);
        reset_n <= '1';
        wait;
    end process;

end architecture;
