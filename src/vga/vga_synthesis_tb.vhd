library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity vga_synthesis_tb is
    port (
        clock : in std_logic;
        reset : in std_logic;
        pixel_clock : out std_logic;
        hsync, vsync : out std_logic;
        r, g, b : out std_logic_vector(7 downto 0)
    );
end vga_synthesis_tb;

architecture arch of vga_synthesis_tb is

    component vga is
        generic (
            READ_ADDR_WIDTH : integer := 9;
            READ_DATA_WIDTH : integer := 12
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            mem_bus_grant : in std_logic;
            mem_data : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0);
            mem_bus_acquire : out std_logic;
            mem_address : out std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
            pixel_clock : out std_logic;
            rgb : out std_logic_vector(23 downto 0);
            hsync : out std_logic;
            vsync : out std_logic
        );
    end component;

    component arbitrated_memory is
        generic (
            ADDR_WIDTH : integer;
            DATA_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            -- write bus
            write_bus_acquire : in std_logic;
            write_address : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            write_en : in std_logic;
            write_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            write_bus_grant : out std_logic;
            -- read bus
            read_bus_acquire : in std_logic;
            read_address : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            read_bus_grant : out std_logic;
            read_data : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    constant HI  : std_logic := '1';
    constant LOW : std_logic := '0';

    constant ADDR_WIDTH : integer := 9;
    constant DATA_WIDTH : integer := 12;

    signal mem_bus_grant : std_logic;
    signal mem_data : std_logic_vector(11 downto 0);
    signal mem_bus_acquire : std_logic;
    signal mem_address : std_logic_vector(8 downto 0);
    signal rgb : std_logic_vector(23 downto 0);

    signal write_bus_acquire : std_logic := '0';
    signal write_address : std_logic_vector(8 downto 0) := (others => '0');
    signal write_en : std_logic := '0';
    signal write_data : std_logic_vector(11 downto 0) := (others => '0');
    signal write_bus_grant : std_logic := '0';

begin

    dut : vga
        generic map (
            READ_ADDR_WIDTH => ADDR_WIDTH,
            READ_DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            mem_bus_grant => mem_bus_grant,
            mem_data => mem_data,
            mem_bus_acquire => mem_bus_acquire,
            mem_address => mem_address,
            pixel_clock => pixel_clock,
            rgb => rgb,
            hsync => hsync,
            vsync => vsync 
        );

    rom : arbitrated_memory
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            write_bus_acquire => write_bus_acquire,
            write_address => write_address,
            write_en => write_en,
            write_data => write_data,
            write_bus_grant => write_bus_grant,
            read_bus_acquire => mem_bus_acquire,
            read_address => mem_address,
            read_bus_grant => mem_bus_grant,
            read_data => mem_data
        );

    r <= rgb(23 downto 16);
    g <= rgb(15 downto 8);
    b <= rgb(7 downto 0);

end architecture;
