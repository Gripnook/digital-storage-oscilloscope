library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity trigger_correction_tb is
end trigger_correction_tb;

architecture arch of trigger_correction_tb is

    component trigger_correction is
        generic (
            READ_ADDR_WIDTH : integer;
            WRITE_ADDR_WIDTH : integer;
            DATA_WIDTH : integer;
            MAX_UPSAMPLE : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            enable : in std_logic;
            trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
            trigger_ref : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            -- read bus
            read_bus_grant : in std_logic;
            read_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            read_bus_acquire : out std_logic;
            read_address : out std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
            -- write bus
            write_bus_grant : in std_logic;
            write_bus_acquire : out std_logic;
            write_address : out std_logic_vector(WRITE_ADDR_WIDTH - 1 downto 0);
            write_en : out std_logic;
            write_data : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    component vga is
        generic (
            READ_ADDR_WIDTH : integer;
            READ_DATA_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            horizontal_scale : in std_logic_vector(31 downto 0) := x"00000008"; -- us/div
            vertical_scale : in std_logic_vector(31 downto 0) := x"00000200"; -- mV/div
            trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
            trigger_level : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0); -- mV
            trigger_frequency : in std_logic_vector(31 downto 0) := x"00001000"; -- Hz
            voltage_pp : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0) := x"000"; -- mV
            voltage_avg : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0) := x"000"; -- mV
            voltage_max : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0) := x"000"; -- mV
            voltage_min : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0) := x"000"; -- mV
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

    constant space : string := " ";
    constant colon : string := ":";

    constant clock_period : time := 20 ns;

    constant PROCESSING_ADDR_WIDTH : integer := 10;
    constant VGA_ADDR_WIDTH : integer := 9;
    constant DATA_WIDTH : integer := 12;
    constant MAX_UPSAMPLE : integer := 4;

    signal clock : std_logic;
    signal reset : std_logic;

    signal enable : std_logic := '1';
    signal trigger_type : std_logic := '1';
    signal trigger_ref : std_logic_vector(DATA_WIDTH - 1 downto 0) := x"800";

    signal write_bus_acquire1 : std_logic := '0';
    signal write_address1 : std_logic_vector(PROCESSING_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal write_en1 : std_logic := '0';
    signal write_data1 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal write_bus_grant1 : std_logic := '0';

    signal read_bus_grant : std_logic;
    signal read_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal read_bus_acquire : std_logic;
    signal read_address : std_logic_vector(PROCESSING_ADDR_WIDTH - 1 downto 0);

    signal write_bus_acquire2 : std_logic;
    signal write_address2 : std_logic_vector(VGA_ADDR_WIDTH - 1 downto 0);
    signal write_en2 : std_logic;
    signal write_data2 : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal write_bus_grant2 : std_logic;

    signal mem_bus_grant : std_logic;
    signal mem_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem_bus_acquire : std_logic;
    signal mem_address : std_logic_vector(VGA_ADDR_WIDTH - 1 downto 0);
    signal pixel_clock : std_logic;
    signal rgb : std_logic_vector(23 downto 0);
    signal hsync : std_logic;
    signal vsync : std_logic;

    signal r : std_logic_vector(7 downto 0);
    signal g : std_logic_vector(7 downto 0);
    signal b : std_logic_vector(7 downto 0);

begin

    rom : arbitrated_memory
        generic map (
            ADDR_WIDTH => PROCESSING_ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            write_bus_acquire => write_bus_acquire1,
            write_address => write_address1,
            write_en => write_en1,
            write_data => write_data1,
            write_bus_grant => write_bus_grant1,
            read_bus_acquire => read_bus_acquire,
            read_address => read_address,
            read_bus_grant => read_bus_grant,
            read_data => read_data
        );

    dut : trigger_correction
        generic map (
            READ_ADDR_WIDTH => PROCESSING_ADDR_WIDTH,
            WRITE_ADDR_WIDTH => VGA_ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH,
            MAX_UPSAMPLE => MAX_UPSAMPLE
        )
        port map (
            clock => clock,
            reset => reset,
            enable => enable,
            trigger_type => trigger_type,
            trigger_ref => trigger_ref,
            read_bus_grant => read_bus_grant,
            read_data => read_data,
            read_bus_acquire => read_bus_acquire,
            read_address => read_address,
            write_bus_grant => write_bus_grant2,
            write_bus_acquire => write_bus_acquire2,
            write_address => write_address2,
            write_en => write_en2,
            write_data => write_data2
        );

    mem : arbitrated_memory
        generic map (
            ADDR_WIDTH => VGA_ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            write_bus_acquire => write_bus_acquire2,
            write_address => write_address2,
            write_en => write_en2,
            write_data => write_data2,
            write_bus_grant => write_bus_grant2,
            read_bus_acquire => mem_bus_acquire,
            read_address => mem_address,
            read_bus_grant => mem_bus_grant,
            read_data => mem_data
        );

    vga_module : vga
        generic map (
            READ_ADDR_WIDTH => VGA_ADDR_WIDTH,
            READ_DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            trigger_type => trigger_type,
            trigger_level => trigger_ref,
            mem_bus_grant => mem_bus_grant,
            mem_data => mem_data,
            mem_bus_acquire => mem_bus_acquire,
            mem_address => mem_address,
            pixel_clock => pixel_clock,
            rgb => rgb,
            hsync => hsync,
            vsync => vsync 
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    r <= rgb(23 downto 16);
    g <= rgb(15 downto 8);
    b <= rgb(7 downto 0);

    output_process : process (clock)
        file vga_log : text is out "triggering/test-results/trigger_correction_log.txt";
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
