library ieee;
use ieee.std_logic_1164.all;

entity sinc_interpolation is
    generic (
        READ_ADDR_WIDTH : integer := 10;
        READ_DATA_WIDTH : integer := 12;
        WRITE_ADDR_WIDTH : integer := 9;
        WRITE_DATA_WIDTH : integer := 12
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        -- read bus
        read_bus_grant : in std_logic;
        read_data : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0);
        read_bus_acquire : out std_logic;
        read_address : out std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
        -- up-sampling rate
        upsample : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0);
        -- write bus
        write_bus_grant : in std_logic;
        write_bus_acquire : out std_logic;
        write_address : out std_logic_vector(WRITE_ADDR_WIDTH - 1 downto 0);
        write_en : out std_logic;
        write_data : out std_logic_vector(WRITE_DATA_WIDTH - 1 downto 0)
    );
end sinc_interpolation;

architecture arch of sinc_interpolation is
begin

end architecture;
