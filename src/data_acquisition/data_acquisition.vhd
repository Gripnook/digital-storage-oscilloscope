library ieee;
use ieee.std_logic_1164.all;

entity data_acquisition is
    generic (
        ADC_DATA_WIDTH : integer := 12;
        WRITE_ADDR_WIDTH : integer := 10;
        WRITE_DATA_WIDTH : integer := 12
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        -- ADC
        adc_data : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
        adc_en : in std_logic;
        -- trigger signal
        trigger : in std_logic;
        -- configuration
        upsample : in std_logic_vector(WRITE_DATA_WIDTH - 1 downto 0);
        -- write bus
        write_bus_grant : in std_logic;
        write_bus_acquire : out std_logic;
        write_address : out std_logic_vector(WRITE_ADDR_WIDTH - 1 downto 0);
        write_en : out std_logic;
        write_data : out std_logic_vector(WRITE_DATA_WIDTH - 1 downto 0)
    );
end data_acquisition;

architecture arch of data_acquisition is
begin

end architecture;
