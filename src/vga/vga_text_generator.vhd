-- A module that generates the ASCII text character that should currently be displayed,
-- along with the color it should be displayed in.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_parameters.all;

entity vga_text_generator is
    port (
        clock : in std_logic;
        reset : in std_logic;
        text_row : in std_logic_vector(TEXT_ROW_BIT_LENGTH - 1 downto 0);
        text_col : in std_logic_vector(TEXT_COL_BIT_LENGTH - 1 downto 0);
        horizontal_scale : in std_logic_vector(15 downto 0); -- BCD in us/div
        vertical_scale : in std_logic_vector(15 downto 0); -- BCD in mV/div
        trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
        trigger_frequency : in std_logic_vector(23 downto 0); -- BCD in Hz
        trigger_level : in std_logic_vector(15 downto 0); -- BCD in mV
        voltage_pp : in std_logic_vector(15 downto 0); -- BCD in mV
        voltage_avg : in std_logic_vector(15 downto 0); -- BCD in mV
        voltage_max : in std_logic_vector(15 downto 0); -- BCD in mV
        voltage_min : in std_logic_vector(15 downto 0); -- BCD in mV
        ascii : out std_logic_vector(6 downto 0);
        rgb : out std_logic_vector(23 downto 0)
    );
end vga_text_generator;

architecture arch of vga_text_generator is

    constant ASCII_V : std_logic_vector(6 downto 0) := "1010110";
    constant ASCII_k : std_logic_vector(6 downto 0) := "1101011";
    constant ASCII_H : std_logic_vector(6 downto 0) := "1001000";
    constant ASCII_z : std_logic_vector(6 downto 0) := "1111010";
    constant ASCII_DOT : std_logic_vector(6 downto 0) := "0101110";
    constant ASCII_0 : std_logic_vector(6 downto 0) := "0110000";

    function to_slv (str : string) return std_logic_vector is
        variable res_v : std_logic_vector(8 * str'length - 1 downto 0);
    begin
        for idx in str'range loop
            res_v(8 * idx - 1 downto 8 * idx - 8) := std_logic_vector(to_unsigned(character'pos(str(idx)), 8));
        end loop;
        return res_v;
    end function;

    function to_ascii (bcd : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable ascii : std_logic_vector(6 downto 0) := (others => '0');
    begin
        ascii := std_logic_vector(("000" & unsigned(bcd)) + unsigned(ASCII_0)); -- add the character 0 in ASCII
        return ascii;
    end to_ascii;

    constant TITLE_STRING : string := "DIGITAL STORAGE OSCILLOSCOPE";
    constant TITLE : std_logic_vector(8 * TITLE_STRING'length - 1 downto 0) := to_slv(TITLE_STRING);
    constant TITLE_START : integer := (TEXT_COL_RANGE - TITLE_STRING'length) / 2;

    constant AUTHORS_STRING : string := "By Andrei Purcarus and Ze Yu Yang";
    constant AUTHORS : std_logic_vector(8 * AUTHORS_STRING'length - 1 downto 0) := to_slv(AUTHORS_STRING);
    constant AUTHORS_START : integer := (TEXT_COL_RANGE - AUTHORS_STRING'length) / 2;

    constant DIVIDER_STRING : string := "------------------------";
    constant DIVIDER : std_logic_vector(8 * DIVIDER_STRING'length - 1 downto 0) := to_slv(DIVIDER_STRING);
    constant DIVIDER_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - DIVIDER_STRING'length) / 2;

    constant HORIZONTAL_SCALE_TITLE_STRING : string := "Horizontal Scale";
    constant HORIZONTAL_SCALE_TITLE : std_logic_vector(8 * HORIZONTAL_SCALE_TITLE_STRING'length - 1 downto 0) := to_slv(HORIZONTAL_SCALE_TITLE_STRING);
    constant HORIZONTAL_SCALE_TITLE_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - HORIZONTAL_SCALE_TITLE_STRING'length) / 2;
    constant HORIZONTAL_SCALE_STRING : string := "us/div";
    constant HORIZONTAL_SCALE_DISPLAY : std_logic_vector(8 * HORIZONTAL_SCALE_STRING'length - 1 downto 0) := to_slv(HORIZONTAL_SCALE_STRING);
    -- We add 4 to account for the measurement display
    constant HORIZONTAL_SCALE_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - (HORIZONTAL_SCALE_STRING'length + 4)) / 2;

    constant VERTICAL_SCALE_TITLE_STRING : string := "Vertical Scale";
    constant VERTICAL_SCALE_TITLE : std_logic_vector(8 * VERTICAL_SCALE_TITLE_STRING'length - 1 downto 0) := to_slv(VERTICAL_SCALE_TITLE_STRING);
    constant VERTICAL_SCALE_TITLE_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - VERTICAL_SCALE_TITLE_STRING'length) / 2;
    constant VERTICAL_SCALE_STRING : string := "mV/div";
    constant VERTICAL_SCALE_DISPLAY : std_logic_vector(8 * VERTICAL_SCALE_STRING'length - 1 downto 0) := to_slv(VERTICAL_SCALE_STRING);
    -- We add 4 to account for the measurement display
    constant VERTICAL_SCALE_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - (VERTICAL_SCALE_STRING'length + 4)) / 2;

    constant TRIGGER_TITLE_STRING : string := "Trigger Settings";
    constant TRIGGER_TITLE : std_logic_vector(8 * TRIGGER_TITLE_STRING'length - 1 downto 0) := to_slv(TRIGGER_TITLE_STRING);
    constant TRIGGER_TITLE_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - TRIGGER_TITLE_STRING'length) / 2;
    constant TRIGGER_RISING_EDGE_STRING  : string := "Type:  Rising Edge";
    constant TRIGGER_RISING_EDGE : std_logic_vector(8 * TRIGGER_RISING_EDGE_STRING'length - 1 downto 0) := to_slv(TRIGGER_RISING_EDGE_STRING);
    constant TRIGGER_RISING_EDGE_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - TRIGGER_RISING_EDGE_STRING'length) / 2;
    constant TRIGGER_FALLING_EDGE_STRING : string := "Type: Falling Edge";
    constant TRIGGER_FALLING_EDGE : std_logic_vector(8 * TRIGGER_FALLING_EDGE_STRING'length - 1 downto 0) := to_slv(TRIGGER_FALLING_EDGE_STRING);
    constant TRIGGER_FALLING_EDGE_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - TRIGGER_FALLING_EDGE_STRING'length) / 2;
    constant TRIGGER_LEVEL_STRING : string := "Level: ";
    constant TRIGGER_LEVEL_DISPLAY : std_logic_vector(8 * TRIGGER_LEVEL_STRING'length - 1 downto 0) := to_slv(TRIGGER_LEVEL_STRING);
    -- We add 6 to account for the measurement display
    constant TRIGGER_LEVEL_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - (TRIGGER_LEVEL_STRING'length + 6)) / 2;
    constant TRIGGER_FREQUENCY_STRING : string := "Frequency: ";
    constant TRIGGER_FREQUENCY_DISPLAY : std_logic_vector(8 * TRIGGER_FREQUENCY_STRING'length - 1 downto 0) := to_slv(TRIGGER_FREQUENCY_STRING);
    -- We add 10 to account for the measurement display
    constant TRIGGER_FREQUENCY_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - (TRIGGER_FREQUENCY_STRING'length + 10)) / 2;

    constant VOLTAGE_TITLE_STRING : string := "Measurements";
    constant VOLTAGE_TITLE : std_logic_vector(8 * VOLTAGE_TITLE_STRING'length - 1 downto 0) := to_slv(VOLTAGE_TITLE_STRING);
    constant VOLTAGE_TITLE_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - VOLTAGE_TITLE_STRING'length) / 2;
    constant VOLTAGE_PP_STRING : string := "Voltage (p-p): ";
    constant VOLTAGE_AVG_STRING : string := "Voltage (avg): ";
    constant VOLTAGE_MAX_STRING : string := "Voltage (max): ";
    constant VOLTAGE_MIN_STRING : string := "Voltage (min): ";
    constant VOLTAGE_PP_DISPLAY : std_logic_vector(8 * VOLTAGE_PP_STRING'length - 1 downto 0) := to_slv(VOLTAGE_PP_STRING);
    constant VOLTAGE_AVG_DISPLAY : std_logic_vector(8 * VOLTAGE_AVG_STRING'length - 1 downto 0) := to_slv(VOLTAGE_AVG_STRING);
    constant VOLTAGE_MAX_DISPLAY : std_logic_vector(8 * VOLTAGE_MAX_STRING'length - 1 downto 0) := to_slv(VOLTAGE_MAX_STRING);
    constant VOLTAGE_MIN_DISPLAY : std_logic_vector(8 * VOLTAGE_MIN_STRING'length - 1 downto 0) := to_slv(VOLTAGE_MIN_STRING);
    -- We add 6 to account for the measurement display
    constant VOLTAGE_PP_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - (VOLTAGE_PP_STRING'length + 6)) / 2;
    constant VOLTAGE_AVG_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - (VOLTAGE_AVG_STRING'length + 6)) / 2;
    constant VOLTAGE_MAX_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - (VOLTAGE_MAX_STRING'length + 6)) / 2;
    constant VOLTAGE_MIN_START : integer := TEXT_COL_RANGE - TEXT_DISPLAY_WIDTH + (TEXT_DISPLAY_WIDTH - (VOLTAGE_MIN_STRING'length + 6)) / 2;

begin

    text_generator : process (clock, reset)
        variable t_row : integer range 0 to TEXT_ROW_RANGE - 1;
        variable t_col : integer range 0 to TEXT_COL_RANGE - 1;
    begin
        if (reset = '1') then
            ascii <= (others => '0');
            rgb <= (others => '0');
        elsif (rising_edge(clock)) then
            t_row := to_integer(unsigned(text_row));
            t_col := to_integer(unsigned(text_col));

            -- default values
            ascii <= (others => '0');
            rgb <= (others => '0');

            case t_row is
            when TITLE_ROW =>
                if (t_col >= TITLE_START and t_col < TITLE_START + TITLE_STRING'length) then
                    ascii <= TITLE(8 * (t_col - TITLE_START) + 6 downto 8 * (t_col - TITLE_START));
                    rgb <= TEXT_COLOR;
                end if;
            when TITLE_ROW + 1 =>
                if (t_col >= AUTHORS_START and t_col < AUTHORS_START + AUTHORS_STRING'length) then
                    ascii <= AUTHORS(8 * (t_col - AUTHORS_START) + 6 downto 8 * (t_col - AUTHORS_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW =>
                if (t_col >= HORIZONTAL_SCALE_TITLE_START and t_col < HORIZONTAL_SCALE_TITLE_START + HORIZONTAL_SCALE_TITLE_STRING'length) then
                    ascii <= HORIZONTAL_SCALE_TITLE(8 * (t_col - HORIZONTAL_SCALE_TITLE_START) + 6 downto 8 * (t_col - HORIZONTAL_SCALE_TITLE_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 1 =>
                if (t_col >= DIVIDER_START and t_col < DIVIDER_START + DIVIDER_STRING'length) then
                    ascii <= DIVIDER(8 * (t_col - DIVIDER_START) + 6 downto 8 * (t_col - DIVIDER_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 2 =>
                if (t_col = HORIZONTAL_SCALE_START and horizontal_scale(15 downto 12) /= x"0") then
                    ascii <= to_ascii(horizontal_scale(15 downto 12));
                    rgb <= TEXT_COLOR;
                elsif (t_col = HORIZONTAL_SCALE_START + 1 and horizontal_scale(15 downto 8) /= x"00") then
                    ascii <= to_ascii(horizontal_scale(11 downto 8));
                    rgb <= TEXT_COLOR;
                elsif (t_col = HORIZONTAL_SCALE_START + 2 and horizontal_scale(15 downto 4) /= x"000") then
                    ascii <= to_ascii(horizontal_scale(7 downto 4));
                    rgb <= TEXT_COLOR;
                elsif (t_col = HORIZONTAL_SCALE_START + 3) then
                    ascii <= to_ascii(horizontal_scale(3 downto 0));
                    rgb <= TEXT_COLOR;
                elsif (t_col >= HORIZONTAL_SCALE_START + 4 and t_col < HORIZONTAL_SCALE_START + 4 + HORIZONTAL_SCALE_STRING'length) then
                    ascii <= HORIZONTAL_SCALE_DISPLAY(8 * (t_col - (HORIZONTAL_SCALE_START + 4)) + 6 downto 8 * (t_col - (HORIZONTAL_SCALE_START + 4)));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 5 =>
                if (t_col >= VERTICAL_SCALE_TITLE_START and t_col < VERTICAL_SCALE_TITLE_START + VERTICAL_SCALE_TITLE_STRING'length) then
                    ascii <= VERTICAL_SCALE_TITLE(8 * (t_col - VERTICAL_SCALE_TITLE_START) + 6 downto 8 * (t_col - VERTICAL_SCALE_TITLE_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 6 =>
                if (t_col >= DIVIDER_START and t_col < DIVIDER_START + DIVIDER_STRING'length) then
                    ascii <= DIVIDER(8 * (t_col - DIVIDER_START) + 6 downto 8 * (t_col - DIVIDER_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 7 =>
                if (t_col = VERTICAL_SCALE_START and vertical_scale(15 downto 12) /= x"0") then
                    ascii <= to_ascii(vertical_scale(15 downto 12));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VERTICAL_SCALE_START + 1 and vertical_scale(15 downto 8) /= x"00") then
                    ascii <= to_ascii(vertical_scale(11 downto 8));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VERTICAL_SCALE_START + 2 and vertical_scale(15 downto 4) /= x"000") then
                    ascii <= to_ascii(vertical_scale(7 downto 4));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VERTICAL_SCALE_START + 3) then
                    ascii <= to_ascii(vertical_scale(3 downto 0));
                    rgb <= TEXT_COLOR;
                elsif (t_col >= VERTICAL_SCALE_START + 4 and t_col < VERTICAL_SCALE_START + 4 + VERTICAL_SCALE_STRING'length) then
                    ascii <= VERTICAL_SCALE_DISPLAY(8 * (t_col - (VERTICAL_SCALE_START + 4)) + 6 downto 8 * (t_col - (VERTICAL_SCALE_START + 4)));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 10 =>
                if (t_col >= TRIGGER_TITLE_START and t_col < TRIGGER_TITLE_START + TRIGGER_TITLE_STRING'length) then
                    ascii <= TRIGGER_TITLE(8 * (t_col - TRIGGER_TITLE_START) + 6 downto 8 * (t_col - TRIGGER_TITLE_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 11 =>
                if (t_col >= DIVIDER_START and t_col < DIVIDER_START + DIVIDER_STRING'length) then
                    ascii <= DIVIDER(8 * (t_col - DIVIDER_START) + 6 downto 8 * (t_col - DIVIDER_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 12 =>
                if (trigger_type = '1') then
                    if (t_col >= TRIGGER_RISING_EDGE_START and t_col < TRIGGER_RISING_EDGE_START + TRIGGER_RISING_EDGE_STRING'length) then
                        ascii <= TRIGGER_RISING_EDGE(8 * (t_col - TRIGGER_RISING_EDGE_START) + 6 downto 8 * (t_col - TRIGGER_RISING_EDGE_START));
                        rgb <= TEXT_COLOR;
                    end if;
                else
                    if (t_col >= TRIGGER_FALLING_EDGE_START and t_col < TRIGGER_FALLING_EDGE_START + TRIGGER_FALLING_EDGE_STRING'length) then
                        ascii <= TRIGGER_FALLING_EDGE(8 * (t_col - TRIGGER_FALLING_EDGE_START) + 6 downto 8 * (t_col - TRIGGER_FALLING_EDGE_START));
                        rgb <= TEXT_COLOR;
                    end if;
                end if;
            when DISPLAY_ROW + 13 =>
                if (t_col >= TRIGGER_LEVEL_START and t_col < TRIGGER_LEVEL_START + TRIGGER_LEVEL_STRING'length) then
                    ascii <= TRIGGER_LEVEL_DISPLAY(8 * (t_col - TRIGGER_LEVEL_START) + 6 downto 8 * (t_col - TRIGGER_LEVEL_START));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_LEVEL_START + TRIGGER_LEVEL_STRING'length) then
                    ascii <= to_ascii(trigger_level(15 downto 12));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_LEVEL_START + TRIGGER_LEVEL_STRING'length + 1) then
                    ascii <= ASCII_DOT;
                    rgb <= TEXT_COLOR;
                elsif (t_col >= TRIGGER_LEVEL_START + TRIGGER_LEVEL_STRING'length + 2 and t_col < TRIGGER_LEVEL_START + TRIGGER_LEVEL_STRING'length + 5) then
                    ascii <= to_ascii(trigger_level(4 * (TRIGGER_LEVEL_START + TRIGGER_LEVEL_STRING'length + 4 - t_col) + 3 downto 4 * (TRIGGER_LEVEL_START + TRIGGER_LEVEL_STRING'length + 4 - t_col)));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_LEVEL_START + TRIGGER_LEVEL_STRING'length + 5) then
                    ascii <= ASCII_V;
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 14 =>
                if (t_col >= TRIGGER_FREQUENCY_START and t_col < TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length) then
                    ascii <= TRIGGER_FREQUENCY_DISPLAY(8 * (t_col - TRIGGER_FREQUENCY_START) + 6 downto 8 * (t_col - TRIGGER_FREQUENCY_START));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length and trigger_frequency(23 downto 20) /= x"0") then
                    ascii <= to_ascii(trigger_frequency(23 downto 20));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 1 and trigger_frequency(23 downto 16) /= x"00") then
                    ascii <= to_ascii(trigger_frequency(19 downto 16));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 2) then
                    ascii <= to_ascii(trigger_frequency(15 downto 12));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 3) then
                    ascii <= ASCII_DOT;
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 4) then
                    ascii <= to_ascii(trigger_frequency(11 downto 8));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 5) then
                    ascii <= to_ascii(trigger_frequency(7 downto 4));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 6) then
                    ascii <= to_ascii(trigger_frequency(3 downto 0));
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 7) then
                    ascii <= ASCII_k;
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 8) then
                    ascii <= ASCII_H;
                    rgb <= TEXT_COLOR;
                elsif (t_col = TRIGGER_FREQUENCY_START + TRIGGER_FREQUENCY_STRING'length + 9) then
                    ascii <= ASCII_z;
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 17 =>
                if (t_col >= VOLTAGE_TITLE_START and t_col < VOLTAGE_TITLE_START + VOLTAGE_TITLE_STRING'length) then
                    ascii <= VOLTAGE_TITLE(8 * (t_col - VOLTAGE_TITLE_START) + 6 downto 8 * (t_col - VOLTAGE_TITLE_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 18 =>
                if (t_col >= DIVIDER_START and t_col < DIVIDER_START + DIVIDER_STRING'length) then
                    ascii <= DIVIDER(8 * (t_col - DIVIDER_START) + 6 downto 8 * (t_col - DIVIDER_START));
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 19 =>
                if (t_col >= VOLTAGE_PP_START and t_col < VOLTAGE_PP_START + VOLTAGE_PP_STRING'length) then
                    ascii <= VOLTAGE_PP_DISPLAY(8 * (t_col - VOLTAGE_PP_START) + 6 downto 8 * (t_col - VOLTAGE_PP_START));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_PP_START + VOLTAGE_PP_STRING'length) then
                    ascii <= to_ascii(voltage_pp(15 downto 12));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_PP_START + VOLTAGE_PP_STRING'length + 1) then
                    ascii <= ASCII_DOT;
                    rgb <= TEXT_COLOR;
                elsif (t_col >= VOLTAGE_PP_START + VOLTAGE_PP_STRING'length + 2 and t_col < VOLTAGE_PP_START + VOLTAGE_PP_STRING'length + 5) then
                    ascii <= to_ascii(voltage_pp(4 * (VOLTAGE_PP_START + VOLTAGE_PP_STRING'length + 4 - t_col) + 3 downto 4 * (VOLTAGE_PP_START + VOLTAGE_PP_STRING'length + 4 - t_col)));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_PP_START + VOLTAGE_PP_STRING'length + 5) then
                    ascii <= ASCII_V;
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 20 =>
                if (t_col >= VOLTAGE_AVG_START and t_col < VOLTAGE_AVG_START + VOLTAGE_AVG_STRING'length) then
                    ascii <= VOLTAGE_AVG_DISPLAY(8 * (t_col - VOLTAGE_AVG_START) + 6 downto 8 * (t_col - VOLTAGE_AVG_START));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_AVG_START + VOLTAGE_AVG_STRING'length) then
                    ascii <= to_ascii(voltage_avg(15 downto 12));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_AVG_START + VOLTAGE_AVG_STRING'length + 1) then
                    ascii <= ASCII_DOT;
                    rgb <= TEXT_COLOR;
                elsif (t_col >= VOLTAGE_AVG_START + VOLTAGE_AVG_STRING'length + 2 and t_col < VOLTAGE_AVG_START + VOLTAGE_AVG_STRING'length + 5) then
                    ascii <= to_ascii(voltage_avg(4 * (VOLTAGE_AVG_START + VOLTAGE_AVG_STRING'length + 4 - t_col) + 3 downto 4 * (VOLTAGE_AVG_START + VOLTAGE_AVG_STRING'length + 4 - t_col)));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_AVG_START + VOLTAGE_AVG_STRING'length + 5) then
                    ascii <= ASCII_V;
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 21 =>
                if (t_col >= VOLTAGE_MAX_START and t_col < VOLTAGE_MAX_START + VOLTAGE_MAX_STRING'length) then
                    ascii <= VOLTAGE_MAX_DISPLAY(8 * (t_col - VOLTAGE_MAX_START) + 6 downto 8 * (t_col - VOLTAGE_MAX_START));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_MAX_START + VOLTAGE_MAX_STRING'length) then
                    ascii <= to_ascii(voltage_max(15 downto 12));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_MAX_START + VOLTAGE_MAX_STRING'length + 1) then
                    ascii <= ASCII_DOT;
                    rgb <= TEXT_COLOR;
                elsif (t_col >= VOLTAGE_MAX_START + VOLTAGE_MAX_STRING'length + 2 and t_col < VOLTAGE_MAX_START + VOLTAGE_MAX_STRING'length + 5) then
                    ascii <= to_ascii(voltage_max(4 * (VOLTAGE_MAX_START + VOLTAGE_MAX_STRING'length + 4 - t_col) + 3 downto 4 * (VOLTAGE_MAX_START + VOLTAGE_MAX_STRING'length + 4 - t_col)));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_MAX_START + VOLTAGE_MAX_STRING'length + 5) then
                    ascii <= ASCII_V;
                    rgb <= TEXT_COLOR;
                end if;
            when DISPLAY_ROW + 22 =>
                if (t_col >= VOLTAGE_MIN_START and t_col < VOLTAGE_MIN_START + VOLTAGE_MIN_STRING'length) then
                    ascii <= VOLTAGE_MIN_DISPLAY(8 * (t_col - VOLTAGE_MIN_START) + 6 downto 8 * (t_col - VOLTAGE_MIN_START));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_MIN_START + VOLTAGE_MIN_STRING'length) then
                    ascii <= to_ascii(voltage_min(15 downto 12));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_MIN_START + VOLTAGE_MIN_STRING'length + 1) then
                    ascii <= ASCII_DOT;
                    rgb <= TEXT_COLOR;
                elsif (t_col >= VOLTAGE_MIN_START + VOLTAGE_MIN_STRING'length + 2 and t_col < VOLTAGE_MIN_START + VOLTAGE_MIN_STRING'length + 5) then
                    ascii <= to_ascii(voltage_min(4 * (VOLTAGE_MIN_START + VOLTAGE_MIN_STRING'length + 4 - t_col) + 3 downto 4 * (VOLTAGE_MIN_START + VOLTAGE_MIN_STRING'length + 4 - t_col)));
                    rgb <= TEXT_COLOR;
                elsif (t_col = VOLTAGE_MIN_START + VOLTAGE_MIN_STRING'length + 5) then
                    ascii <= ASCII_V;
                    rgb <= TEXT_COLOR;
                end if;
            when others =>
                null;
            end case;
        end if;
    end process;

end architecture;
