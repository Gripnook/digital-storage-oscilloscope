-- A module that converts the VGA row and column signals into a new coordinate system
-- that separates the display area into text characters, and text characters into pixels.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_parameters.all;

entity vga_text_address_generator is
    port (
        row : in integer range 0 to V_PIXELS - 1;
        column : in integer range 0 to H_PIXELS - 1;
        text_row : out std_logic_vector(TEXT_ROW_BIT_LENGTH - 1 downto 0);
        text_col : out std_logic_vector(TEXT_COL_BIT_LENGTH - 1 downto 0);
        font_row : out std_logic_vector(3 downto 0);
        font_col : out std_logic_vector(2 downto 0)
    );
end vga_text_address_generator;

architecture arch of vga_text_address_generator is

    signal row_vector : std_logic_vector(V_PIXELS_BIT_LENGTH - 1 downto 0);
    signal column_vector : std_logic_vector(H_PIXELS_BIT_LENGTH - 1 downto 0);

begin

    row_vector <= std_logic_vector(to_unsigned(row, V_PIXELS_BIT_LENGTH));
    column_vector <= std_logic_vector(to_unsigned(column, H_PIXELS_BIT_LENGTH));

    text_row <= row_vector(V_PIXELS_BIT_LENGTH - 1 downto 4);
    text_col <= column_vector(H_PIXELS_BIT_LENGTH - 1 downto 3);

    font_row <= row_vector(3 downto 0);
    font_col <= column_vector(2 downto 0);

end architecture;
