library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use lpm.lpm_components.all;

entity vga is
    port (
        clock : in std_logic;
        reset : in std_logic;
        mem_bus_grant : in std_logic;
        mem_data : in std_logic_vector(11 downto 0);
        mem_bus_acquire : out std_logic;
        mem_address : out std_logic_vector(8 downto 0);
        pixel_clock : out std_logic;
        rgb : out std_logic_vector(23 downto 0)
    );
end vga;

architecture arch of vga is

    constant H_PIXELS : integer := 800;
    constant V_PIXELS : integer := 600;
    constant BIT_LENGTH : integer := integer(ceil(log2(real(H_PIXELS * V_PIXELS))));

    -- start coordinates for the waveform plot (bottom-left corner)
    constant X0 : integer := 10;
    constant Y0 : integer := 10;
    -- waveform plot dimensions
    constant PLOT_WIDTH : integer := 512;
    constant PLOT_HEIGHT : integer := 512;

    constant YELLOW : std_logic_vector(23 downto 0) := x"00FFFF";

    signal row : integer range 0 to V_PIXELS - 1;
    signal column : integer range 0 to H_PIXELS - 1;
    signal hsync : std_logic;
    signal vsync : std_logic;
    signal blank_n : std_logic;

    signal rom_address : std_logic_vector(BIT_LENGTH - 1 downto 0); 
    signal background_rgb : std_logic_vector(23 downto 0);

    signal data_1, data_2 : integer range 0 to PLOT_HEIGHT - 1;
    signal display_data : std_logic;

begin

    background : lpm_rom
        generic map (
            LPM_FILE => "background.mif",
            LPM_WIDTH => 24,
            LPM_WIDTHAD => BIT_LENGTH
        )
        port map (
            address => rom_address,
            q => background_rgb
        );
    rom_address <= std_logic_vector(to_unsigned(H_PIXELS * row + column, BIT_LENGTH));

    range_comparator : process (data_1, data_2, row)
        variable data_row : integer range -Y0 to V_PIXELS - 1 - Y0;
    begin
        -- convert the row to the equivalent on the waveform plot
        data_row := V_PIXELS - 1 - row - Y0;

        display_data <= '0'; -- default output
        if ((data_row >= data_1 and data_row <= data_2) or (data_row <= data_1 and data_row >= data_2)) then
            display_data <= '1';
        end if;
    end process;

    display_mux : process (display_data, blank_n)
    begin
        if (blank_n = '0') then
            rgb <= (others => '0');
        elsif (display_data = '1') then
            rgb <= YELLOW;
        else
            rgb <= background_rgb;
        end if;
    end process;

    pixel_clock <= clock;

end architecture;
