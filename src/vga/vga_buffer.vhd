-- A video buffer module that gathers the waveform data to be displayed during the
-- idle time between frames, as determined by the VSYNC signal. It outputs both the
-- current data point being displayed and the next one in order to allow for vertical
-- interpolation. If the next data point does not exist, the current data point is
-- duplicated in the outputs.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;
use work.vga_parameters.all;

entity vga_buffer is
    generic (
        READ_ADDR_WIDTH : integer;
        READ_DATA_WIDTH : integer
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        display_time : in integer range 0 to PLOT_WIDTH - 1;
        vsync : in std_logic;
        mem_bus_grant : in std_logic;
        mem_data : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0);
        mem_bus_acquire : out std_logic;
        mem_address : out std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
        data_1 : out integer range 0 to PLOT_HEIGHT - 1;
        data_2 : out integer range 0 to PLOT_HEIGHT - 1
    );
end vga_buffer;

architecture arch of vga_buffer is

    type state_type is (BUFF_IDLE, BUS_ACQ, BUFF_READ_ADDR, BUFF_READ_DATA, BUFF_WRITE, BUFF_DONE);
    signal state : state_type := BUFF_IDLE;
    
    type memory is array(0 to PLOT_WIDTH - 1) of integer range 0 to PLOT_HEIGHT - 1;
    signal mem : memory;

    signal write_en : std_logic;

    signal address : integer range 0 to PLOT_WIDTH - 1;
    signal addr_sel : std_logic;

    signal count_internal : std_logic_vector(PLOT_WIDTH_BIT_LENGTH - 1 downto 0);
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
                if (vsync /= V_POL) then
                    state <= BUS_ACQ;
                else
                    state <= BUFF_IDLE;
                end if;
            when BUS_ACQ =>
                if (mem_bus_grant = '1') then
                    state <= BUFF_READ_ADDR;
                else
                    state <= BUS_ACQ;
                end if;
            when BUFF_READ_ADDR =>
                state <= BUFF_READ_DATA;
            when BUFF_READ_DATA =>
                state <= BUFF_WRITE;
            when BUFF_WRITE =>
                if (count = PLOT_WIDTH - 1) then
                    state <= BUFF_DONE;
                else
                    state <= BUFF_READ_ADDR;
                end if;
            when BUFF_DONE =>
                if (vsync = V_POL) then
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
            if (vsync /= V_POL) then
                mem_bus_acquire <= '1';
            end if;
        when BUS_ACQ =>
            mem_bus_acquire <= '1';
        when BUFF_READ_ADDR =>
            mem_bus_acquire <= '1';
            addr_sel <= '1';
        when BUFF_READ_DATA =>
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

    address_counter : lpm_counter
        generic map (LPM_WIDTH => PLOT_WIDTH_BIT_LENGTH)
        port map (
            clock => clock,
            aclr => reset,
            sclr => count_clr,
            cnt_en => count_en,
            q => count_internal
        );
    count <= to_integer(unsigned(count_internal));

    with addr_sel select address <=
        count when '1',
        display_time when others;
    mem_address <= std_logic_vector(to_unsigned(address, READ_ADDR_WIDTH));

    mem_process : process (clock)
    begin
        if (rising_edge(clock)) then
            if (write_en = '1') then
                mem(address) <= to_integer(unsigned(mem_data(READ_DATA_WIDTH - 1 downto READ_DATA_WIDTH - PLOT_HEIGHT_BIT_LENGTH)));
            end if;

            data_1 <= mem(address);
            if (address = PLOT_WIDTH - 1) then
                data_2 <= mem(address);
            else
                data_2 <= mem(address + 1);
            end if;
        end if;
    end process;

end architecture;
