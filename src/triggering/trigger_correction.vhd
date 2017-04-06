library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity trigger_correction is
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
end trigger_correction;

architecture arch of trigger_correction is

    constant MID_TRIGGER_ADDRESS : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(2 ** (READ_ADDR_WIDTH - 1), READ_ADDR_WIDTH));
    constant MIN_TRIGGER_ADDRESS : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(2 ** (READ_ADDR_WIDTH - 1) - 2 ** MAX_UPSAMPLE, READ_ADDR_WIDTH));

    type state_type is (S_READ_BUS_REQ, S_TRIG_READ_ADDR, S_TRIG_READ_DATA, S_TRIG_CHECK, S_READ_SETUP, S_READ_ADDR, S_READ_DATA, S_WRITE_INTERNAL, S_WRITE_BUS_REQ, S_READ_INTERNAL, S_WRITE_DATA);
    signal state : state_type := S_READ_BUS_REQ;

    type memory is array(0 to 2 ** WRITE_ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem : memory;

    constant WRITE_ADDR_MAX : std_logic_vector(WRITE_ADDR_WIDTH - 1 downto 0) := (others => '1');

    signal memwrite : std_logic;

    signal read_address_internal : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
    signal read_address_en : std_logic;
    signal read_address_load : std_logic;
    signal read_address_sel : std_logic;

    signal write_address_internal : std_logic_vector(WRITE_ADDR_WIDTH - 1 downto 0);
    signal write_address_en : std_logic;
    signal write_address_clr : std_logic;

    signal start_address : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
    signal end_address : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);

    signal input_reg_en : std_logic;
    signal trigger_type_internal : std_logic;
    signal trigger_ref_internal : std_logic_vector(DATA_WIDTH - 1 downto 0);

    signal trigger_address_count : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
    signal trigger_address_count_en : std_logic;
    signal trigger_address_count_load : std_logic;

    signal trigger : std_logic;
    signal trigger_address : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
    signal trigger_address_en : std_logic;
    signal trigger_address_load : std_logic;

begin

    input_register : process (clock, reset)
    begin
        if (reset = '1') then
            trigger_type_internal <= '0';
            trigger_ref_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (input_reg_en = '1') then
                trigger_type_internal <= trigger_type;
                trigger_ref_internal <= trigger_ref;
            end if;
        end if;
    end process;

    memory_process : process (clock)
    begin
        if (rising_edge(clock)) then
            if (memwrite = '1') then
                mem(to_integer(unsigned(write_address_internal))) <= read_data;
            end if;
            write_data <= mem(to_integer(unsigned(write_address_internal)));
        end if;
    end process;

    trigger_address_counter : lpm_counter
        generic map (
            LPM_WIDTH => READ_ADDR_WIDTH,
            LPM_DIRECTION => "DOWN"
        )
        port map (
            clock => clock,
            aclr => reset,
            sload => trigger_address_count_load,
            data => MID_TRIGGER_ADDRESS,
            cnt_en => trigger_address_count_en,
            q => trigger_address_count
        );

    write_address_counter : lpm_counter
        generic map (LPM_WIDTH => WRITE_ADDR_WIDTH)
        port map (
            clock => clock,
            aclr => reset,
            sclr => write_address_clr,
            cnt_en => write_address_en,
            q => write_address_internal
        );
    write_address <= write_address_internal;

    read_address_counter : lpm_counter
        generic map (LPM_WIDTH => READ_ADDR_WIDTH)
        port map (
            clock => clock,
            aclr => reset,
            sload => read_address_load,
            data => start_address,
            cnt_en => read_address_en,
            q => read_address_internal
        );
    read_address <= trigger_address_count when read_address_sel = '1' else read_address_internal;

    trigger_comparator : process (trigger_type_internal, trigger_ref_internal, read_data)
    begin
        trigger <= '0'; -- default output
        if (trigger_type_internal = '1' and read_data <= trigger_ref_internal) then
            trigger <= '1';
        elsif (trigger_type_internal = '0' and read_data >= trigger_ref_internal) then
            trigger <= '1';
        end if;
    end process;

    trigger_address_reg : process (clock, reset)
    begin
        if (reset = '1') then
            trigger_address <= (others => '0');
        elsif (rising_edge(clock)) then
            if (trigger_address_en = '1') then
                trigger_address <= std_logic_vector(unsigned(trigger_address_count) + 1);
            elsif (trigger_address_load = '1') then
                trigger_address <= MID_TRIGGER_ADDRESS;
            end if;
        end if;
    end process;

    start_address <= std_logic_vector(unsigned(trigger_address) - 2 ** (WRITE_ADDR_WIDTH - 1));
    end_address <= std_logic_vector(unsigned(trigger_address) + 2 ** (WRITE_ADDR_WIDTH - 1) - 1);

    state_transition : process (clock, reset)
    begin
        if (reset = '1') then
            state <= S_READ_BUS_REQ;
        elsif (rising_edge(clock)) then
            case state is
            when S_READ_BUS_REQ =>
                if (read_bus_grant = '1') then
                    if (enable = '1') then
                        state <= S_TRIG_READ_ADDR;
                    else
                        state <= S_READ_SETUP;
                    end if;
                else
                    state <= S_READ_BUS_REQ;
                end if;
            when S_TRIG_READ_ADDR =>
                state <= S_TRIG_READ_DATA;
            when S_TRIG_READ_DATA =>
                state <= S_TRIG_CHECK;
            when S_TRIG_CHECK =>
                if (trigger = '1') then
                    state <= S_READ_SETUP;
                elsif (trigger_address_count = MIN_TRIGGER_ADDRESS) then
                    state <= S_READ_SETUP;
                else
                    state <= S_TRIG_READ_ADDR;
                end if;
            when S_READ_SETUP =>
                state <= S_READ_ADDR;
            when S_READ_ADDR =>
                state <= S_READ_DATA;
            when S_READ_DATA =>
                state <= S_WRITE_INTERNAL;
            when S_WRITE_INTERNAL =>
                if (read_address_internal = end_address) then
                    state <= S_WRITE_BUS_REQ;
                else
                    state <= S_READ_ADDR;
                end if;
            when S_WRITE_BUS_REQ =>
                if (write_bus_grant = '1') then
                    state <= S_READ_INTERNAL;
                else
                    state <= S_WRITE_BUS_REQ;
                end if;
            when S_READ_INTERNAL =>
                state <= S_WRITE_DATA;
            when S_WRITE_DATA =>
                if (write_address_internal = WRITE_ADDR_MAX) then
                    state <= S_READ_BUS_REQ;
                else
                    state <= S_READ_INTERNAL;
                end if;
            when others =>
                null;
            end case;
        end if;
    end process;

    outputs : process (state, read_bus_grant, write_bus_grant, enable, trigger, trigger_address_count)
    begin
        -- default outputs
        read_bus_acquire <= '0';
        write_bus_acquire <= '0';
        read_address_en <= '0';
        read_address_load <= '0';
        read_address_sel <= '0';
        write_address_en <= '0';
        write_address_clr <= '0';
        memwrite <= '0';
        write_en <= '0';
        trigger_address_count_en <= '0';
        trigger_address_count_load <= '0';
        input_reg_en <= '0';
        trigger_address_en <= '0';
        trigger_address_load <= '0';

        case state is
        when S_READ_BUS_REQ =>
            read_bus_acquire <= '1';
            if (read_bus_grant = '1') then
                if (enable = '1') then
                    read_address_sel <= '1';
                    trigger_address_count_load <= '1';
                    input_reg_en <= '1';
                else
                    trigger_address_load <= '1';
                end if;
            end if;
        when S_TRIG_READ_ADDR =>
            read_bus_acquire <= '1';
            read_address_sel <= '1';
        when S_TRIG_READ_DATA =>
            read_bus_acquire <= '1';
            read_address_sel <= '1';
        when S_TRIG_CHECK =>
            read_bus_acquire <= '1';
            read_address_sel <= '1';
            if (trigger = '1') then
                trigger_address_en <= '1';
            elsif (trigger_address_count = MIN_TRIGGER_ADDRESS) then
                trigger_address_load <= '1';
            else
                trigger_address_count_en <= '1';
            end if;
        when S_READ_SETUP =>
            read_bus_acquire <= '1';
            read_address_load <= '1';
            write_address_clr <= '1';
        when S_READ_ADDR =>
            read_bus_acquire <= '1';
        when S_READ_DATA =>
            read_bus_acquire <= '1';
        when S_WRITE_INTERNAL =>
            read_bus_acquire <= '1';
            read_address_en <= '1';
            write_address_en <= '1';
            memwrite <= '1';
        when S_WRITE_BUS_REQ =>
            write_bus_acquire <= '1';
            if (write_bus_grant = '1') then
                write_address_clr <= '1';
            end if;
        when S_READ_INTERNAL =>
            write_bus_acquire <= '1';
        when S_WRITE_DATA =>
            write_bus_acquire <= '1';
            write_address_en <= '1';
            write_en <= '1';
        when others =>
            null;
        end case;
    end process;

end architecture;
