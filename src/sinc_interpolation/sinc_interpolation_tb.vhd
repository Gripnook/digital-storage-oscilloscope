library ieee;
library lpm;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;
use work.filter_parameters.all;

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
            READ_ADDR_WIDTH : integer := 4;
            WRITE_ADDR_WIDTH : integer := 4;
            DATA_WIDTH : integer := 8;
            MAX_UPSAMPLE : integer := 8
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

    constant DATA_WIDTH : integer := 8;
    constant PROCESSING_ADDR_WIDTH : integer := 10;
    constant clock_period : time := 20 ns;
    signal clock : std_logic;
    signal reset : std_logic;
    signal upsample : integer range 0 to 8;

    signal mem_bus_grant : std_logic;
    signal mem_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem_bus_acquire : std_logic;
    signal mem_address : std_logic_vector(PROCESSING_ADDR_WIDTH - 1 downto 0);

    signal read_bus_grant : std_logic;
    signal read_data : std_logic_vector(7 downto 0);
    signal read_bus_acquire : std_logic;
    signal read_address : std_logic_vector(3 downto 0);    

    signal write_bus_grant : std_logic;
    signal write_bus_acquire : std_logic;
    signal write_address : std_logic_vector(3 downto 0);
    signal write_en : std_logic;
    signal write_data : std_logic_vector(7 downto 0);

    signal write_bus_acquire1 : std_logic := '0';
    signal write_address1 : std_logic_vector(PROCESSING_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal write_en1 : std_logic := '0';
    signal write_data1 : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal write_bus_grant1 : std_logic := '0';

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
    interpol : sinc_interpolation
        port map (
            clock => clock,
            reset => reset,
            upsample => upsample,
            read_bus_grant => read_bus_grant,
            read_data => read_data,
            read_bus_acquire => read_bus_acquire,
            read_address => read_address,
        
            write_bus_grant => write_bus_grant,
            write_bus_acquire => write_bus_acquire,
            write_address => write_address,
            write_en => write_en,
            write_data => write_data
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

        --- upsample disabled
        upsample <= 0;
        read_bus_grant <= '0';
        write_bus_grant <= '0';
        wait until rising_edge(clock);
        read_bus_grant <= '1';        
        wait until rising_edge(clock);
        write_bus_grant <= '1';
        wait for 14 ms;
        
        --- upsample rate = 2
        upsample <= 1;
        read_bus_grant <= '0';
        write_bus_grant <= '0';
        wait until rising_edge(clock);
        read_bus_grant <= '1';        
        wait until rising_edge(clock);
        write_bus_grant <= '1';
        wait for 14 ms;

        --- upsample rate = 4
        upsample <= 2;
        read_bus_grant <= '0';
        write_bus_grant <= '0';
        wait until rising_edge(clock);
        read_bus_grant <= '1';        
        wait until rising_edge(clock);
        write_bus_grant <= '1';
        wait for 14 ms;

        --- upsample rate = 8
        upsample <= 4;
        read_bus_grant <= '0';
        write_bus_grant <= '0';
        wait until rising_edge(clock);
        read_bus_grant <= '1';        
        wait until rising_edge(clock);
        write_bus_grant <= '1';
        wait for 14 ms;

        --- upsample rate = 16
        upsample <= 8;
        read_bus_grant <= '0';
        write_bus_grant <= '0';
        wait until rising_edge(clock);
        read_bus_grant <= '1';        
        wait until rising_edge(clock);
        write_bus_grant <= '1';
        wait for 14 ms;
    end process;
        

end arch;