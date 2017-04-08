-- A module that performs interpolation of upsampled data using the sin(x)/x interpolation
-- method. It takes as input the rate at which the signal has been upsampled, and it interfaces
-- with an arbitrated memory block which contains the signal in question. It then processes the
-- signal and outputs it to a second arbitrated memory block. In order to keep the waveform
-- centered on the trigger point, it shifts the output waveform according to the delay parameters
-- of each filter, as specified in the filter_parameters package.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;
use work.filter_parameters.all;

entity sinc_interpolation is
    generic (
        READ_ADDR_WIDTH : integer;
        WRITE_ADDR_WIDTH : integer;
        DATA_WIDTH : integer range 8 to 12;
        MAX_UPSAMPLE : integer
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
end sinc_interpolation;

architecture arch of sinc_interpolation is

    component lowpass_filter is
        generic (MAX_UPSAMPLE : integer);
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            upsample : in integer range 0 to MAX_UPSAMPLE; -- upsampling rate is 2 ** upsample
            filter_in : in std_logic_vector(11 downto 0);
            filter_out : out std_logic_vector(11 downto 0)
        );
    end component;

    constant HLP1_START_ADDR : integer := 2 ** (READ_ADDR_WIDTH - 1) - 2 ** (WRITE_ADDR_WIDTH - 1);
    constant HLP1_END_ADDR : integer := HLP1_START_ADDR + 2 ** WRITE_ADDR_WIDTH - 1;

    constant HLP2_START_ADDR : integer := 2 ** (READ_ADDR_WIDTH - 1) - 2 ** (WRITE_ADDR_WIDTH - 1) + HLP2_LENGTH / 2 + HLP2_PIPELINE_LENGTH;
    constant HLP2_END_ADDR : integer := HLP2_START_ADDR + 2 ** WRITE_ADDR_WIDTH - 1;

    constant HLP4_START_ADDR : integer := 2 ** (READ_ADDR_WIDTH - 1) - 2 ** (WRITE_ADDR_WIDTH - 1) + HLP4_LENGTH / 2 + HLP4_PIPELINE_LENGTH;
    constant HLP4_END_ADDR : integer := HLP4_START_ADDR + 2 ** WRITE_ADDR_WIDTH - 1;

    constant HLP8_START_ADDR : integer := 2 ** (READ_ADDR_WIDTH - 1) - 2 ** (WRITE_ADDR_WIDTH - 1) + HLP8_LENGTH / 2 + HLP8_PIPELINE_LENGTH;
    constant HLP8_END_ADDR : integer := HLP8_START_ADDR + 2 ** WRITE_ADDR_WIDTH - 1;

    constant HLP16_START_ADDR : integer := 2 ** (READ_ADDR_WIDTH - 1) - 2 ** (WRITE_ADDR_WIDTH - 1) + HLP16_LENGTH / 2 + HLP16_PIPELINE_LENGTH;
    constant HLP16_END_ADDR : integer := HLP16_START_ADDR + 2 ** WRITE_ADDR_WIDTH - 1;

    type state_type is (READ_BUS_REQ, SINC_READ_ADDR, SINC_READ_DATA, SINC_PROC, SINC_WRITE_INTERNAL, WRITE_BUS_REQ, SINC_READ_INTERNAL, SINC_WRITE);
    signal state : state_type := READ_BUS_REQ;

    type memory is array(0 to 2 ** READ_ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem : memory;

    constant READ_ADDR_MAX : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0) := (others => '1');

    signal memwrite : std_logic;

    signal read_address_internal : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
    signal read_address_en : std_logic;
    signal read_address_load : std_logic;
    signal read_address_clr : std_logic;

    signal write_address_en : std_logic;
    signal write_address_clr : std_logic;

    signal upsample_internal : integer range 0 to MAX_UPSAMPLE;
    signal input_reg_en : std_logic;

    signal start_address : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
    signal end_address : std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);

    signal filter_en : std_logic;
    signal filter_in : std_logic_vector(11 downto 0) := (others => '0');
    signal filter_out : std_logic_vector(11 downto 0);

begin

    filter : lowpass_filter
        generic map (MAX_UPSAMPLE => MAX_UPSAMPLE)
        port map (
            clock => clock,
            enable => filter_en,
            reset => reset,
            upsample => upsample_internal,
            filter_in => filter_in,
            filter_out => filter_out
        );
    filter_in(DATA_WIDTH - 1 downto 0) <= read_data;

    memory_process : process (clock)
    begin
        if (rising_edge(clock)) then
            if (memwrite = '1') then
                mem(to_integer(unsigned(read_address_internal))) <= filter_out(DATA_WIDTH - 1 downto 0);
            end if;
            write_data <= mem(to_integer(unsigned(read_address_internal)));
        end if;
    end process;

    read_address_counter : lpm_counter
        generic map (LPM_WIDTH => READ_ADDR_WIDTH)
        port map (
            clock => clock,
            aclr => reset,
            sclr => read_address_clr,
            sload => read_address_load,
            data => start_address,
            cnt_en => read_address_en,
            q => read_address_internal
        );
    read_address <= read_address_internal;

    write_address_counter : lpm_counter
        generic map (LPM_WIDTH => WRITE_ADDR_WIDTH)
        port map (
            clock => clock,
            aclr => reset,
            sclr => write_address_clr,
            cnt_en => write_address_en,
            q => write_address
        );

    input_register : process (clock, reset)
    begin
        if (reset = '1') then
            upsample_internal <= 0;
        elsif (rising_edge(clock)) then
            if (input_reg_en = '1') then
                upsample_internal <= upsample;
            end if;
        end if;
    end process;

    address_bounds_mux : process (upsample_internal)
    begin
        -- default outputs
        start_address <= std_logic_vector(to_unsigned(HLP1_START_ADDR, READ_ADDR_WIDTH));
        end_address <= std_logic_vector(to_unsigned(HLP1_END_ADDR, READ_ADDR_WIDTH));

        case upsample_internal is
        when 1 =>
            start_address <= std_logic_vector(to_unsigned(HLP2_START_ADDR, READ_ADDR_WIDTH));
            end_address <= std_logic_vector(to_unsigned(HLP2_END_ADDR, READ_ADDR_WIDTH));
        when 2 =>
            start_address <= std_logic_vector(to_unsigned(HLP4_START_ADDR, READ_ADDR_WIDTH));
            end_address <= std_logic_vector(to_unsigned(HLP4_END_ADDR, READ_ADDR_WIDTH));
        when 3 =>
            start_address <= std_logic_vector(to_unsigned(HLP8_START_ADDR, READ_ADDR_WIDTH));
            end_address <= std_logic_vector(to_unsigned(HLP8_END_ADDR, READ_ADDR_WIDTH));
        when 4 =>
            start_address <= std_logic_vector(to_unsigned(HLP16_START_ADDR, READ_ADDR_WIDTH));
            end_address <= std_logic_vector(to_unsigned(HLP16_END_ADDR, READ_ADDR_WIDTH));
        when others =>
            null;
        end case;
    end process;

    state_transition : process (clock, reset)
    begin
        if (reset = '1') then
            state <= READ_BUS_REQ;
        elsif (rising_edge(clock)) then
            case state is
            when READ_BUS_REQ =>
                if (read_bus_grant = '1') then
                    state <= SINC_READ_ADDR;
                else
                    state <= READ_BUS_REQ;
                end if;
            when SINC_READ_ADDR =>
                state <= SINC_READ_DATA;
            when SINC_READ_DATA =>
                state <= SINC_PROC;
            when SINC_PROC =>
                state <= SINC_WRITE_INTERNAL;
            when SINC_WRITE_INTERNAL =>
                if (read_address_internal = READ_ADDR_MAX) then
                    state <= WRITE_BUS_REQ;
                else
                    state <= SINC_READ_ADDR;
                end if;
            when WRITE_BUS_REQ =>
                if (write_bus_grant = '1') then
                    state <= SINC_READ_INTERNAL;
                else
                    state <= WRITE_BUS_REQ;
                end if;
            when SINC_READ_INTERNAL =>
                state <= SINC_WRITE;
            when SINC_WRITE =>
                if (read_address_internal = end_address) then
                    state <= READ_BUS_REQ;
                else
                    state <= SINC_READ_INTERNAL;
                end if;
            when others =>
                 null;
            end case;
        end if;
    end process;

    outputs : process (state, read_bus_grant, write_bus_grant)
    begin
        -- default outputs
        read_bus_acquire <= '0';
        write_bus_acquire <= '0';
        write_en <= '0';
        filter_en <= '0';
        memwrite <= '0';
        read_address_en <= '0';
        read_address_load <= '0';
        read_address_clr <= '0';
        write_address_en <= '0';
        write_address_clr <= '0';
        input_reg_en <= '0';

        case state is
        when READ_BUS_REQ =>
            read_bus_acquire <= '1';
            if (read_bus_grant = '1') then
                read_address_clr <= '1';
                input_reg_en <= '1';
            end if;
        when SINC_READ_ADDR =>
            read_bus_acquire <= '1';
        when SINC_READ_DATA =>
            read_bus_acquire <= '1';
        when SINC_PROC =>
            read_bus_acquire <= '1';
            filter_en <= '1';
        when SINC_WRITE_INTERNAL =>
            read_bus_acquire <= '1';
            memwrite <= '1';
            read_address_en <= '1';
        when WRITE_BUS_REQ =>
            write_bus_acquire <= '1';
            if (write_bus_grant = '1') then
                read_address_load <= '1';
                write_address_clr <= '1';
            end if;
        when SINC_READ_INTERNAL =>
            write_bus_acquire <= '1';
        when SINC_WRITE =>
            write_bus_acquire <= '1';
            write_en <= '1';
            read_address_en <= '1';
            write_address_en <= '1';
        when others =>
            null;
        end case;
    end process;

end architecture;
