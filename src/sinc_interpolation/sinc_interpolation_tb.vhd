library ieee;
library lpm;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity sinc_interpolation_tb is
end sinc_interpolation_tb;

architecture arch of sinc_interpolation_tb is

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

    component sinc_interpolation is
        generic (
            READ_ADDR_WIDTH : integer;
            WRITE_ADDR_WIDTH : integer;
            DATA_WIDTH : integer range 8 to 12;
            MAX_UPSAMPLE : integer := 5
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            upsample : in integer range 0 to MAX_UPSAMPLE; -- upsampling rate is 2 ** upsample
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

    constant DATA_WIDTH : integer := 12;
    constant ADDR_WIDTH : integer := 10;

    constant clock_period : time := 20 ns;
    signal clock : std_logic;

    signal reset : std_logic;
    signal upsample : integer range 0 to 4;

    signal read_bus_grant1 : std_logic;
    signal read_data1 : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal read_bus_acquire1 : std_logic;
    signal read_address1 : std_logic_vector(ADDR_WIDTH - 1 downto 0);

    signal write_bus_grant1 : std_logic := '0';
    signal write_bus_acquire1 : std_logic := '0';
    signal write_address1 : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal write_en1 : std_logic := '0';
    signal write_data1 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

    signal read_bus_grant2 : std_logic := '0';
    signal read_data2 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal read_bus_acquire2 : std_logic := '0';
    signal read_address2 : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');

    signal write_bus_grant2 : std_logic;
    signal write_bus_acquire2 : std_logic;
    signal write_address2 : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal write_en2 : std_logic;
    signal write_data2 : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

    rom : arbitrated_memory
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
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
            read_bus_acquire => read_bus_acquire1,
            read_address => read_address1,
            read_bus_grant => read_bus_grant1,
            read_data => read_data1
        );

    interpolation : sinc_interpolation
        generic map (
            READ_ADDR_WIDTH => ADDR_WIDTH,
            WRITE_ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            upsample => upsample,
            read_bus_grant => read_bus_grant1,
            read_data => read_data1,
            read_bus_acquire => read_bus_acquire1,
            read_address => read_address1,
            write_bus_grant => write_bus_grant2,
            write_bus_acquire => write_bus_acquire2,
            write_address => write_address2,
            write_en => write_en2,
            write_data => write_data2
        );

    mem : arbitrated_memory
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
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
            read_bus_acquire => read_bus_acquire2,
            read_address => read_address2,
            read_bus_grant => read_bus_grant2,
            read_data => read_data2
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    test_process : process
    begin
        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';

        --- upsample rate = 2
        upsample <= 1;
        wait until rising_edge(clock);
        wait for 1000 us;

        --- upsample rate = 16
        upsample <= 4;
        wait until rising_edge(clock);
        wait for 1000 us;

        wait;
    end process;

end architecture;
