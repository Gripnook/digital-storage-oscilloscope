library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use lpm.lpm_components.all;


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

    constant WRITE_ADDR_WIDTH_BIT_LENGTH : integer := integer(ceil(log2(real(WRITE_ADDR_WIDTH))));
    type state_type is (READ_BUS_REQ, SINC_READ_ADDR, SINC_READ_DATA, SINC_PROC, SINC_WRITE_IN, WRITE_BUS_REQ, SINC_WRITE_ADDR, SINC_WRITE_DATA, SINC_DONE);
    signal state : state_type := BUS_ACQ;
    type memory is array(0 to WRITE_ADDR_WIDTH - 1) of integer range 0 to WRITE_DATA_WIDTH - 1;
    signal mem : memory;
    signal write_en : std_logic;
    signal addr_sel : std_logic;
    signal address : integer range 0 to WRITE_ADDR_WIDTH - 1; 
    signal count_internal : std_logic_vector(WRITE_ADDR_WIDTH_BIT_LENGTH - 1 downto 0);
    signal count : integer range 0 to WRITE_ADDR_WIDTH - 1;
    signal count_en : std_logic;
    signal count_clr : std_logic;

begin

    state_transition : process (clock, reset)
    begin
        if (reset = '1') then
            state <= READ_BUS_REQ; -- when idle, always request read bus to read the input;
        elsif (rising_edge(clock)) then
            case state is
            when READ_BUS_REQ =>  
                if (read_bus_grant = '1') then
                    state <= SINC_READ_ADDR; --if read bus is granted, send the address where the date will be read;
                else
                    state <= READ_BUS_ACQ;
                end if;
            when SINC_READ_ADDR =>
                state <= SINC_READ_DATA; --read the data of sent address;
            when SINC_READ_DATA =>
                state <= SINC_PROC; --process the data;
            when SINC_PROC =>
                state <= SINC_WRITE_IN; --write the data to internal storage;
            when SINC_WRITE_IN =>
                if (count = WRITE_DATA_WIDTH - 1) then
                    state <= WRITE_BUS_REQ; -- internal storage filled, requesting to burst write to the SRAM for display, also clears the counter;
                else
                    state <= SINC_READ_ADDR; -- burst read until the write buffer is filled and ready for burst write;
                end if;
            when WRITE_BUS_REQ => 
                if (write_bus_grant = '1') then
                    state <= SINC_WRITE_ADDR; -- sends the address to write to the SRAM;
                else
                    state <= WRITE_BUS_REQ;
                end if;
            when SINC_WRITE_ADDR =>
                state <= SINC_WRITE_DATA; --write the data to the sent address in the SRAM;
            when SINC_WRITE_DATA =>
                if (count = WRITE_DATA_WIDTH - 1) then
                    state <= READ_BUS_REQ; -- back to starting stage, request the reading bus again;
                else
                    state <= SINC_WRITE_ADDR; -- burst write until the data in the buffer are all written to the SRAM;
                end if;
            when others =>
                 null;
            end case;
        end if;
    end process;

end architecture;
