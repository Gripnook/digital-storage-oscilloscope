library ieee;
use ieee.std_logic_1164.all;

entity vga_rom is
    generic (
        X0 : integer;
        Y0 : integer;
        PLOT_WIDTH : integer;
        PLOT_HEIGHT : integer
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        row : in integer range 0 to 599;
        column : in integer range 0 to 799;
        horizontal_scale : in std_logic_vector(15 downto 0); -- BCD in mV/div
        vertical_scale : in std_logic_vector(15 downto 0); -- BCD in us/div
        trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
        trigger_frequency : in std_logic_vector(15 downto 0); -- BCD in 100Hz increments
        voltage_pp : in std_logic_vector(15 downto 0); -- BCD in mV
        voltage_avg : in std_logic_vector(15 downto 0); -- BCD in mV
        voltage_max : in std_logic_vector(15 downto 0); -- BCD in mV
        voltage_min : in std_logic_vector(15 downto 0); -- BCD in mV
        rgb : out std_logic_vector(23 downto 0)
    );
end vga_rom;

architecture arch of vga_rom is

    component vga_text_address_generator is
        port (
            row : in integer range 0 to 599;
            column : in integer range 0 to 799;
            text_row : out std_logic_vector(5 downto 0);
            text_col : out std_logic_vector(6 downto 0);
            font_row : out std_logic_vector(3 downto 0);
            font_col : out std_logic_vector(2 downto 0)
        );
    end component;

    component vga_grid_generator is
        generic (
            X0 : integer;
            Y0 : integer;
            PLOT_HEIGHT : integer;
            PLOT_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            row : in integer range 0 to 599;
            column : in integer range 0 to 799;
            grid_on : out std_logic
        );
    end component;

    component vga_text_generator is
        port (
            clock : in std_logic;
            reset : in std_logic;
            text_row : in std_logic_vector(5 downto 0);
            text_col : in std_logic_vector(6 downto 0);
            horizontal_scale : in std_logic_vector(15 downto 0); -- BCD in mV/div
            vertical_scale : in std_logic_vector(15 downto 0); -- BCD in us/div
            trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
            trigger_frequency : in std_logic_vector(15 downto 0); -- BCD in 100Hz increments
            voltage_pp : in std_logic_vector(15 downto 0); -- BCD in mV
            voltage_avg : in std_logic_vector(15 downto 0); -- BCD in mV
            voltage_max : in std_logic_vector(15 downto 0); -- BCD in mV
            voltage_min : in std_logic_vector(15 downto 0); -- BCD in mV
            ascii : out std_logic_vector(6 downto 0);
            rgb : out std_logic_vector(23 downto 0)
        );
    end component;

    component font_rom is
        port (
            clock : in std_logic;
            reset : in std_logic;
            char_code : in std_logic_vector(6 downto 0); -- 7-bit ASCII character code
            font_row : in std_logic_vector(3 downto 0); -- 0-15 row address in single character
            font_col : in std_logic_vector(2 downto 0); -- 0-7 column address in single character
            pixel_on : out std_logic -- pixel value at the given row and column for the selected character code
        );
    end component;

    constant BACKGROUND_COLOR : std_logic_vector(23 downto 0) := x"080808";
    constant GRID_COLOR : std_logic_vector(23 downto 0) := x"202020";

    signal text_row : std_logic_vector(5 downto 0);
    signal text_col : std_logic_vector(6 downto 0);

    signal font_row : std_logic_vector(3 downto 0);
    signal font_row_delayed : std_logic_vector(3 downto 0);
    signal font_col : std_logic_vector(2 downto 0);
    signal font_col_delayed : std_logic_vector(2 downto 0);

    signal grid_on : std_logic;
    signal grid_on_delayed : std_logic;

    signal pixel_on : std_logic;

    signal ascii : std_logic_vector(6 downto 0);
    signal rgb_text : std_logic_vector(23 downto 0);
    signal rgb_text_delayed : std_logic_vector(23 downto 0);

begin

    text_address_generator : vga_text_address_generator
        port map (
            row => row,
            column => column,
            text_row => text_row,
            text_col => text_col,
            font_row => font_row,
            font_col => font_col
        );

    grid_generator : vga_grid_generator
        generic map (
            X0 => X0,
            Y0 => Y0,
            PLOT_WIDTH => PLOT_WIDTH,
            PLOT_HEIGHT => PLOT_HEIGHT
        )
        port map (
            clock => clock,
            reset => reset,
            row => row,
            column => column,
            grid_on => grid_on
        );

    text_generator : vga_text_generator
        port map (
            clock => clock,
            reset => reset,
            text_row => text_row,
            text_col => text_col,
            horizontal_scale => horizontal_scale,
            vertical_scale => vertical_scale,
            trigger_type => trigger_type,
            trigger_frequency => trigger_frequency,
            voltage_pp => voltage_pp,
            voltage_avg => voltage_avg,
            voltage_max => voltage_max,
            voltage_min => voltage_min,
            ascii => ascii,
            rgb => rgb_text
        );

    rom : font_rom
        port map (
            clock => clock,
            reset => reset,
            char_code => ascii,
            font_row => font_row_delayed,
            font_col => font_col_delayed,
            pixel_on => pixel_on
        );

    delay_registers : process (clock, reset)
    begin
        if (reset = '1') then
            font_row_delayed <= (others => '0');
            font_col_delayed <= (others => '0');
            rgb_text_delayed <= (others => '0');
            grid_on_delayed <= '0';
        elsif (rising_edge(clock)) then
            font_row_delayed <= font_row;
            font_col_delayed <= font_col;
            rgb_text_delayed <= rgb_text;
            grid_on_delayed <= grid_on;
        end if;
    end process;

    mux : process (pixel_on, grid_on_delayed, rgb_text_delayed)
    begin
        if (pixel_on = '1') then
            rgb <= rgb_text_delayed;
        elsif (grid_on_delayed = '1') then
            rgb <= GRID_COLOR;
        else
            rgb <= BACKGROUND_COLOR;
        end if;
    end process;

end architecture;
