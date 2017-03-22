library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity oscilloscope is
    generic (
        ADC_DATA_WIDTH : integer := 12;
        TEST_FREQUENCY_WIDTH : integer := 6
    );
    port (
        clock : in std_logic;
        reset_n : in std_logic;
        timebase : in std_logic_vector(2 downto 0);
        trigger_up_n : in std_logic;
        trigger_down_n : in std_logic;
        trigger_type : in std_logic;
        test_frequency : in std_logic_vector(TEST_FREQUENCY_WIDTH - 1 downto 0);
        pixel_clock : out std_logic;
        hsync, vsync : out std_logic;
        r, g, b : out std_logic_vector(7 downto 0)
    );
end oscilloscope;

architecture arch of oscilloscope is

    component analog_waveform_generator is
        generic (N : integer);
        port (clock : in std_logic;
              reset : in std_logic;
              update : in std_logic := '1';
              frequency_control : in std_logic_vector(N-1 downto 0);
              analog_waveform : out std_logic_vector(7 downto 0));
    end component;

    component data_acquisition is
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
            adc_en : in std_logic;
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
    end component;

    component triggering is
        generic (
            DATA_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            adc_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            trigger_type : in std_logic;
            trigger_ref : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            trigger : out std_logic;
            trigger_frequency : out std_logic_vector(31 downto 0)
        );
    end component;

    component vga is
        generic (
            READ_ADDR_WIDTH : integer;
            READ_DATA_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            horizontal_scale : in std_logic_vector(31 downto 0);
            vertical_scale : in std_logic_vector(31 downto 0) := x"00000200";
            trigger_type : in std_logic;
            trigger_level : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0);
            trigger_frequency : in std_logic_vector(31 downto 0);
            voltage_pp : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0) := x"000";
            voltage_avg : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0) := x"000";
            voltage_max : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0) := x"000";
            voltage_min : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0) := x"000";
            mem_bus_grant : in std_logic;
            mem_data : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0);
            mem_bus_acquire : out std_logic;
            mem_address : out std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
            pixel_clock : out std_logic;
            rgb : out std_logic_vector(23 downto 0);
            hsync : out std_logic;
            vsync : out std_logic
        );
    end component;

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

    constant ADDR_WIDTH : integer := 9;
    constant MAX_UPSAMPLE : integer := 5;

    signal reset : std_logic;

    signal frequency_control : std_logic_vector(15 downto 0);
    signal analog_waveform : std_logic_vector(7 downto 0);
    signal adc_data : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal adc_en : std_logic;
    signal temp_cnt : integer range 0 to 99;

    signal upsample : integer range 0 to MAX_UPSAMPLE;
    signal horizontal_scale : std_logic_vector(31 downto 0);

    signal trigger : std_logic;
    signal trigger_ref : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal trigger_ref_up : std_logic;
    signal trigger_ref_en : std_logic;
    signal trigger_control : std_logic_vector(31 downto 0);
    signal trigger_control_clr : std_logic;
    signal trigger_frequency : std_logic_vector(31 downto 0);

    signal write_bus_grant : std_logic;
    signal write_bus_acquire : std_logic;
    signal write_address : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal write_en : std_logic;
    signal write_data : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);

    signal read_bus_acquire : std_logic;
    signal read_address : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal read_bus_grant : std_logic;
    signal read_data : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);

    signal rgb : std_logic_vector(23 downto 0);

begin

    reset <= not reset_n;

    arb_gen : analog_waveform_generator
        generic map (N => 16)
        port map (
            clock => clock,
            reset => reset,
            frequency_control => frequency_control,
            analog_waveform => analog_waveform
        );
    frequency_control(15 downto TEST_FREQUENCY_WIDTH + 4) <= (others => '0');
    frequency_control(TEST_FREQUENCY_WIDTH + 3 downto 4) <= test_frequency;
    frequency_control(3 downto 0) <= (others => '1'); -- min frequency

    adc_processing : process (clock, reset)
    begin
        if (reset = '1') then
            temp_cnt <= 0;
            adc_data <= (others => '0');
            adc_en <= '0';
        elsif (rising_edge(clock)) then
            adc_en <= '0';
            if (temp_cnt = 99) then
                temp_cnt <= 0;
                adc_en <= '1';
                adc_data <= analog_waveform & "0000";
            else
                temp_cnt <= temp_cnt + 1;
            end if;
        end if;
    end process;

    trigger_controls_counter : lpm_counter
        generic map (LPM_WIDTH => 32)
        port map (clock => clock, aclr => reset, sclr => trigger_control_clr, q => trigger_control);
    trigger_control_clr <= '1' when trigger_control = std_logic_vector(to_unsigned(20000, 32)) else '0';

    trigger_ref_counter : lpm_counter
        generic map (LPM_WIDTH => ADC_DATA_WIDTH)
        port map (
            clock => clock,
            aclr => reset,
            updown => trigger_ref_up,
            cnt_en => trigger_ref_en,
            q => trigger_ref
        );
    trigger_ref_en <= trigger_control_clr and (trigger_up_n xor trigger_down_n);
    trigger_ref_up <= not trigger_up_n;

    data_acquisition_subsystem : data_acquisition
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => ADC_DATA_WIDTH,
            MAX_UPSAMPLE => MAX_UPSAMPLE
        )
        port map (
            clock => clock,
            reset => reset,
            adc_data => adc_data,
            adc_en => adc_en,
            trigger => trigger,
            upsample => upsample,
            write_bus_grant => write_bus_grant,
            write_bus_acquire => write_bus_acquire,
            write_address => write_address,
            write_en => write_en,
            write_data => write_data
        );
    upsample <= to_integer(unsigned(timebase)) when to_integer(unsigned(timebase)) <= MAX_UPSAMPLE else MAX_UPSAMPLE;
    process (upsample)
    begin
        horizontal_scale <= (others => '0');
        horizontal_scale(7 - upsample) <= '1';
    end process;

    triggering_subsystem : triggering
        generic map (
            DATA_WIDTH => ADC_DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            adc_data => adc_data,
            trigger_type => trigger_type,
            trigger_ref => trigger_ref,
            trigger => trigger,
            trigger_frequency => trigger_frequency
        );

    data_acquisition_vga_memory : arbitrated_memory
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => ADC_DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            write_bus_acquire => write_bus_acquire,
            write_address => write_address,
            write_en => write_en,
            write_data => write_data,
            write_bus_grant => write_bus_grant,
            read_bus_acquire => read_bus_acquire,
            read_address => read_address,
            read_bus_grant => read_bus_grant,
            read_data => read_data
        );

    vga_subsystem : vga
        generic map (
            READ_ADDR_WIDTH => ADDR_WIDTH,
            READ_DATA_WIDTH => ADC_DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            horizontal_scale => horizontal_scale,
            trigger_type => trigger_type,
            trigger_level => trigger_ref,
            trigger_frequency => trigger_frequency,
            mem_bus_grant => read_bus_grant,
            mem_data => read_data,
            mem_bus_acquire => read_bus_acquire,
            mem_address => read_address,
            pixel_clock => pixel_clock,
            rgb => rgb,
            hsync => hsync,
            vsync => vsync
        );

    r <= rgb(23 downto 16);
    g <= rgb(15 downto 8);
    b <= rgb(7 downto 0);

end architecture;
