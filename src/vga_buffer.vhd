library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity vga_buffer is 
    generic (
        V_POL : std_logic := '0';
        PLOT_HEIGHT : integer := 512;
        PLOT_WIDTH : integer := 512
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        display_time : in integer range 0 to PLOT_WIDTH - 1;
        vsync : in std_logic;
        mem_bus_grant : in std_logic;
        mem_data : in std_logic_vector(11 downto 0);
        mem_bus_acquire : out std_logic;
        mem_address : out std_logic_vector(8 downto 0);
        data_1 : out integer range 0 to PLOT_HEIGHT - 1;
        data_2 : out integer range 0 to PLOT_HEIGHT - 1
    );
end vga_buffer;

architecture arch of vga_buffer is

    type state_type is (BUFF_IDLE, BUS_ACQ, BUFF_READ, BUFF_WRITE, BUFF_DONE);
    signal state : state_type := BUFF_IDLE;
    
    type memory is array(0 to PLOT_WIDTH - 1) of integer range 0 to PLOT_HEIGHT - 1;
    signal mem : memory;

    signal write_en : std_logic;

    signal address : integer range 0 to PLOT_WIDTH - 1;
    signal addr_sel : std_logic;

    signal count : integer range 0 to PLOT_WIDTH - 1;
    signal count_en : std_logic;
    signal count_clr : std_logic;

begin

    state_transition : process (clock, reset)
    begin
        if (reset = '1') then
            state <= BUFF_IDLE;
        elsif (rising_edge(clock)) then
            case state is
            when BUFF_IDLE =>
                if (vsync = V_POL) then
                    state <= BUS_ACQ;
                else
                    state <= BUFF_IDLE;
                end if;
            when BUS_ACQ =>
                if (mem_bus_grant = '1') then
                    state <= BUFF_READ;
                else
                    state <= BUS_ACQ;
                end if;
            when BUFF_READ =>
                state <= BUFF_WRITE;
            when BUFF_WRITE =>
                if (count = PLOT_WIDTH - 1) then
                    state <= BUFF_DONE;
                else
                    state <= BUFF_READ;
                end if;
            when BUFF_DONE =>
                if (vsync /= V_POL) then
                    state <= BUFF_IDLE;
                else
                    state <= BUFF_DONE;
                end if;
            when others =>
                 null;
            end case;
        end if;
    end process;

    outputs : process (state, vsync, count)
    begin
        -- default outputs
        mem_bus_acquire <= '0';
        write_en <= '0';
        addr_sel <= '0';
        count_en <= '0';
        count_clr <= '0';

        case state is
        when BUFF_IDLE =>
            if (vsync = '1') then
                mem_bus_acquire <= '1';
            end if;
        when BUS_ACQ =>
            mem_bus_acquire <= '1';
        when BUFF_READ =>
            mem_bus_acquire <= '1';
            addr_sel <= '1';
        when BUFF_WRITE =>
            mem_bus_acquire <= '1';
            write_en <= '1';
            addr_sel <= '1';
            if (count = PLOT_WIDTH - 1) then
                count_clr <= '1';
            else
                count_en <= '1';
            end if;
        when BUFF_DONE =>
            null;
        when others =>
            null;
        end case;
    end process;

    counter : process (clock, reset)
    begin
        if (reset = '1') then
            count <= 0;
        elsif (rising_edge(clock)) then
            if (count_clr = '1') then
                count <= 0;
            elsif (count_en = '1') then
                count <= count + 1;
            end if;
        end if;
    end process;

    with addr_sel select address <=
        count when '1',
        display_time when others;
    mem_address <= std_logic_vector(to_unsigned(address, 9));

    mem_process : process (clock)
    begin
        if (rising_edge(clock)) then
            if (write_en = '1') then
                mem(address) <= to_integer(unsigned(mem_data(11 downto 3)));
            end if;

            data_1 <= mem(address);
            if (address = PLOT_HEIGHT - 1) then
                data_2 <= mem(address);
            else
                data_2 <= mem(address + 1);
            end if;
        end if;
    end process;

end architecture;
