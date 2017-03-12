-- A memory module which supports separate readers and writers on different buses.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use lpm.lpm_components.all;

entity memory_arbiter is
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
end memory_arbiter;

architecture arch of memory_arbiter is

    type state_type is (BUS_IDLE, BUS_WRITE, BUS_READ);
    signal state : state_type := BUS_IDLE;

    signal address : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal we : std_logic;

begin

    mem : lpm_ram_dq
        generic map (
            LPM_WIDTH => DATA_WIDTH,
            LPM_WIDTHAD => ADDR_WIDTH
        )
        port map (
            data => write_data,
            address => address,
            inclock => clock,
            outclock => clock,
            we => we,
            q => read_data
        );

    state_transistion : process (clock, reset)
    begin
        if (reset = '1') then
            state <= BUS_IDLE;
        elsif (rising_edge(clock)) then
            case state is
            when BUS_IDLE =>
                -- we give priority to writes
                if (write_bus_acquire = '1') then
                    state <= BUS_WRITE;
                elsif (read_bus_acquire = '1') then
                    state <= BUS_READ;
                else
                    state <= BUS_IDLE;
                end if;
            when BUS_WRITE =>
                if (write_bus_acquire = '0') then
                    state <= BUS_IDLE;
                else
                    state <= BUS_WRITE;
                end if;
            when BUS_READ =>
                if (read_bus_acquire = '0') then
                    state <= BUS_IDLE;
                else
                    state <= BUS_READ;
                end if;
            when others =>
                null;
            end case;
        end if;
    end process;

    outputs : process (state, write_bus_acquire, read_bus_acquire, write_address, write_en, read_address)
    begin
        -- default outputs
        write_bus_grant <= '0';
        read_bus_grant <= '0';
        address <= (others => '0');
        we <= '0';

        case state is
        when BUS_IDLE =>
            if (write_bus_acquire = '1') then
                write_bus_grant <= '1';
            elsif (read_bus_acquire = '1') then
                read_bus_grant <= '1';
            end if;
        when BUS_WRITE =>
            write_bus_grant <= '1';
            address <= write_address;
            we <= write_en;
        when BUS_READ =>
            read_bus_grant <= '1';
            address <= read_address;
        when others =>
            null;
        end case;
    end process;

end architecture;
