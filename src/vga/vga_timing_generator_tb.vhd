library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity vga_timing_generator_tb is
end vga_timing_generator_tb;

architecture arch of vga_timing_generator_tb is

    component vga_timing_generator is
        generic (
            H_PIXELS : integer   := 800; -- horizontal display width in pixels
            H_PULSE  : integer   := 120; -- horizontal sync pulse width in pixels
            H_BP     : integer   := 56;  -- horizontal back porch width in pixels
            H_FP     : integer   := 64;  -- horizontal front porch width in pixels
            H_POL    : std_logic := '1'; -- horizontal sync pulse polarity (1 = positive, 0 = negative)
            V_PIXELS : integer   := 600; -- vertical display width in rows
            V_PULSE  : integer   := 6;   -- vertical sync pulse width in rows
            V_BP     : integer   := 37;  -- vertical back porch width in rows
            V_FP     : integer   := 23;  -- vertical front porch width in rows
            V_POL    : std_logic := '1'  -- vertical sync pulse polarity (1 = positive, 0 = negative)
        );
        port (
            clock   : in  std_logic; -- pixel clock at frequency of VGA mode being used
            reset   : in  std_logic; -- asynchronous reset
            row     : out integer range 0 to V_PIXELS - 1; -- vertical pixel coordinate
            column  : out integer range 0 to H_PIXELS - 1; -- horizontal pixel coordinate
            hsync   : out std_logic; -- horizontal sync pulse
            vsync   : out std_logic; -- vertical sync pulse
            blank_n : out std_logic -- active low blanking output
        );
    end component;

    constant space : string := " ";
    constant colon : string := ":";

    constant clock_period : time := 20 ns;

    signal clock : std_logic;
    signal reset : std_logic;
    signal row : integer;
    signal column : integer;
    signal hsync : std_logic;
    signal vsync : std_logic;
    signal blank_n : std_logic;

    signal rgb : std_logic_vector(23 downto 0);
    signal r : std_logic_vector(7 downto 0);
    signal g : std_logic_vector(7 downto 0);
    signal b : std_logic_vector(7 downto 0);

begin

    dut : vga_timing_generator
        port map (
            clock => clock,
            reset => reset,
            row => row,
            column => column,
            hsync => hsync,
            vsync => vsync,
            blank_n => blank_n
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    rgb_process : process (row, column, blank_n)
    begin
        if (blank_n = '0') then
            rgb <= x"000000";
        else
            if (row = 0 or row = 599 or column = 0 or column = 799) then
                rgb <= x"FF0000"; -- red border
            elsif (column < 100) then
                rgb <= x"FFFFFF";
            elsif (column < 200) then
                rgb <= x"FFFF00";
            elsif (column < 300) then
                rgb <= x"00FFFF";
            elsif (column < 400) then
                rgb <= x"00FF00";
            elsif (column < 500) then
                rgb <= x"FF00FF";
            elsif (column < 600) then
                rgb <= x"FF0000";
            elsif (column < 700) then
                rgb <= x"0000FF";
            else
                rgb <= x"000000";
            end if;
        end if;
    end process;

    r <= rgb(23 downto 16);
    g <= rgb(15 downto 8);
    b <= rgb(7 downto 0);

    output_process : process (clock)
        file vga_log : text is out "vga/test-results/vga_timing_generator_log.txt";
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
        wait;
    end process;

end architecture;
