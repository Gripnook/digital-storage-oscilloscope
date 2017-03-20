library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_text_address_generator is
    port (
        row : in integer range 0 to 599;
        column : in integer range 0 to 799;
        text_row : out std_logic_vector(5 downto 0);
        text_col : out std_logic_vector(6 downto 0);
        font_row : out std_logic_vector(3 downto 0);
        font_col : out std_logic_vector(2 downto 0)
    );
end vga_text_address_generator;

architecture arch of vga_text_address_generator is
    
    signal row_vector : std_logic_vector(9 downto 0);
    signal column_vector : std_logic_vector(9 downto 0);

begin

    row_vector <= std_logic_vector(to_unsigned(row, 10));
    column_vector <= std_logic_vector(to_unsigned(column, 10));

    text_row <= row_vector(9 downto 4);
    text_col <= column_vector(9 downto 3);

    font_row <= row_vector(3 downto 0);
    font_col <= column_vector(2 downto 0);

end architecture;
