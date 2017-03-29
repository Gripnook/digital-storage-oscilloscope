-- A module that acquires data sampled by an ADC and writes captured waveforms to an
-- external memory block. In order to generate stable waveforms, the module waits for
-- a trigger signal before it begins processing the data. It then saves data from
-- before the trigger point and after the trigger point, such that the trigger
-- signal always corresponds to the midpoint of the captured waveform.
-- 
-- The module also upsamples the waveform according to the specified upsampling rate.
-- This corresponds to inserting zeros between sample points, and this can be used
-- to interpolate the waveform at those points in a later processing step.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity data_acquisition is
    generic (
        ADDR_WIDTH : integer;
        DATA_WIDTH : integer;
        MAX_UPSAMPLE : integer
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        -- ADC
        adc_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        adc_sample : in std_logic;
        -- trigger signal
        trigger : in std_logic;
        -- configuration
        upsample : in integer range 0 to MAX_UPSAMPLE; -- up-sampling rate is 2 ** upsample
        -- write bus
        write_bus_grant : in std_logic;
        write_bus_acquire : out std_logic;
        write_address : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        write_en : out std_logic;
        write_data : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end data_acquisition;

architecture arch of data_acquisition is
    
    type state_type is (IDLE, TRIGGERED, BUS_WAIT, RAM_READ_ADDR, RAM_READ_DATA, BUS_WRITE);
    signal state : state_type := IDLE;

    constant RAM_ADDR_WIDTH : integer := ADDR_WIDTH + 1; -- we store twice the data to be able to continuously sample

    signal adc_address : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
    signal ram_address : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
    signal ram_address_en, ram_address_load : std_logic;
    signal address : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);

    signal write_data_internal : std_logic_vector(DATA_WIDTH - 1 downto 0);

    signal input_reg_en : std_logic;
    signal upsample_internal : integer range 0 to MAX_UPSAMPLE;
    signal upsample_ceil : std_logic_vector(MAX_UPSAMPLE - 1 downto 0);
    signal trigger_address : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
    
    signal upsample_count : std_logic_vector(MAX_UPSAMPLE - 1 downto 0);
    signal upsample_cnt_en, upsample_cnt_clr : std_logic;
    signal upsample_off : std_logic;
    signal upsample_done : std_logic;

    signal trigger_interval : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
    signal trigger_start_address : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
    signal trigger_end_address : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
    signal data_acquired : std_logic;
    signal data_written : std_logic;

    signal write_address_en, write_address_clr : std_logic;

begin

    adc_address_counter : lpm_counter
        generic map (LPM_WIDTH => RAM_ADDR_WIDTH)
        port map (
            clock => clock,
            aclr => reset,
            q => adc_address,
            cnt_en => adc_sample
        );

    ram_address_counter : lpm_counter
        generic map (LPM_WIDTH => RAM_ADDR_WIDTH)
        port map (
            clock => clock,
            aclr => reset,
            data => trigger_start_address,
            sload => ram_address_load,
            q => ram_address,
            cnt_en => ram_address_en
        );

    mem : lpm_ram_dq
        generic map (
            LPM_WIDTH => DATA_WIDTH,
            LPM_WIDTHAD => RAM_ADDR_WIDTH
        )
        port map (
            data => adc_data,
            address => address,
            inclock => clock,
            outclock => clock,
            we => adc_sample,
            q => write_data_internal
        );

    with adc_sample select address <=
        adc_address when '1',
        ram_address when others;

    upsample_counter : lpm_counter
        generic map (LPM_WIDTH => MAX_UPSAMPLE)
        port map (
            clock => clock,
            aclr => reset,
            sclr => upsample_cnt_clr,
            q => upsample_count,
            cnt_en => upsample_cnt_en
        );

    upsample_nor_gate : process (upsample_count)
        variable upsample_on : std_logic;
    begin
        upsample_on := '0';
        for i in 0 to MAX_UPSAMPLE - 1 loop
            upsample_on := upsample_on or upsample_count(i);
        end loop;
        upsample_off <= not upsample_on;
    end process;

    with upsample_off select write_data <=
        write_data_internal when '1',
        (others => '0') when others;

    input_registers : process (clock, reset)
    begin
        if (reset = '1') then
            upsample_internal <= 0;
            trigger_address <= (others => '0');
        elsif (rising_edge(clock)) then
            if (input_reg_en = '1') then
                upsample_internal <= upsample;
                trigger_address <= adc_address;
            end if;
        end if;
    end process;

    process (upsample_internal)
        variable upsample_upper_bound : std_logic_vector(MAX_UPSAMPLE downto 0);
    begin
        upsample_upper_bound := (others => '0');
        upsample_upper_bound(upsample_internal) := '1';

        upsample_upper_bound := std_logic_vector(unsigned(upsample_upper_bound) - 1);
        upsample_ceil <= upsample_upper_bound(MAX_UPSAMPLE - 1 downto 0);
    end process;

    upsample_done <= '1' when upsample_count = upsample_ceil else '0';

    process (upsample_internal)
    begin
        trigger_interval <= (others => '0');
        trigger_interval(ADDR_WIDTH - upsample_internal) <= '1';
    end process;

    trigger_start_address <= std_logic_vector(unsigned(trigger_address) - unsigned(trigger_interval(RAM_ADDR_WIDTH - 1 downto 1)));
    trigger_end_address <= std_logic_vector(unsigned(trigger_address) + unsigned(trigger_interval(RAM_ADDR_WIDTH - 1 downto 1)));

    data_acquired <= '1' when adc_address = trigger_end_address else '0';
    data_written <= '1' when ram_address = trigger_end_address else '0';

    write_address_counter : lpm_counter
        generic map (LPM_WIDTH => ADDR_WIDTH)
        port map (
            clock => clock,
            aclr => reset,
            sclr => write_address_clr,
            q => write_address,
            cnt_en => write_address_en
        );

    state_transition : process (clock, reset)
    begin
        if (reset = '1') then
            state <= IDLE;
        elsif (rising_edge(clock)) then
            case state is
            when IDLE =>
                if (trigger = '1') then
                    state <= TRIGGERED;
                else
                    state <= IDLE;
                end if;
            when TRIGGERED =>
                if (data_acquired = '1') then
                    state <= BUS_WAIT;
                else
                    state <= TRIGGERED;
                end if;
            when BUS_WAIT =>
                if (write_bus_grant = '1') then
                    state <= RAM_READ_ADDR;
                else
                    state <= BUS_WAIT;
                end if;
            when RAM_READ_ADDR =>
                if (data_written = '1') then
                    state <= IDLE;
                elsif (adc_sample = '1') then
                    state <= RAM_READ_ADDR; -- we wait for the ADC write to complete
                else
                    state <= RAM_READ_DATA;
                end if;
            when RAM_READ_DATA =>
                state <= BUS_WRITE;
            when BUS_WRITE =>
                if (upsample_done = '1') then
                    state <= RAM_READ_ADDR;
                else
                    state <= BUS_WRITE;
                end if;
            when others =>
                null;
            end case;
        end if;
    end process;

    outputs : process (state, trigger, data_acquired, write_bus_grant, upsample_done)
    begin
        -- default outputs
        write_bus_acquire <= '0';
        write_en <= '0';
        input_reg_en <= '0';
        ram_address_en <= '0';
        ram_address_load <= '0';
        write_address_en <= '0';
        write_address_clr <= '0';
        upsample_cnt_en <= '0';
        upsample_cnt_clr <= '0';

        case state is
        when IDLE =>
            if (trigger = '1') then
                input_reg_en <= '1';
            end if;
        when TRIGGERED =>
            if (data_acquired = '1') then
                write_bus_acquire <= '1';
            end if;
        when BUS_WAIT =>
            write_bus_acquire <= '1';
            if (write_bus_grant = '1') then
                ram_address_load <= '1';
                write_address_clr <= '1';
                upsample_cnt_clr <= '1';
            end if;
        when RAM_READ_ADDR =>
            write_bus_acquire <= '1';
        when RAM_READ_DATA =>
            write_bus_acquire <= '1';
        when BUS_WRITE =>
            write_bus_acquire <= '1';
            write_en <= '1';
            write_address_en <= '1';
            if (upsample_done = '1') then
                ram_address_en <= '1';
                upsample_cnt_clr <= '1';
            else
                upsample_cnt_en <= '1';
            end if;
        when others =>
            null;
        end case;
    end process;

end architecture;
