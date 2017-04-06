library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_acquisition_tb is
end data_acquisition_tb;

architecture arch of data_acquisition_tb is

    component data_acquisition is
        generic (
            ADDR_WIDTH : integer := 4;
            DATA_WIDTH : integer := 8;
            MAX_UPSAMPLE : integer := 4;
            MAX_DOWNSAMPLE : integer := 3
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
            upsample : in integer range 0 to MAX_UPSAMPLE; -- upsampling rate is 2 ** upsample
            downsample : in integer range 0 to MAX_DOWNSAMPLE; -- downsampling rate is 2 ** downsample
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
            DATA_WIDTH : integer := 8
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            adc_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            adc_sample : in std_logic;
            trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
            trigger_ref : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            trigger : out std_logic;
            trigger_frequency : out std_logic_vector(31 downto 0) -- Hz
        );
    end component;

    component arbitrated_memory is
        generic (
            ADDR_WIDTH : integer := 4;
            DATA_WIDTH : integer := 8
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
            read_bus_acquire : in std_logic := '0';
            read_address : in std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
            read_bus_grant : out std_logic := '0';
            read_data : out std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0')
        );
    end component;

    component analog_waveform_generator is
        generic (N : integer := 16);
        port (
            clock : in std_logic;
            reset : in std_logic;
            update : in std_logic := '1';
            frequency_control : in std_logic_vector(N-1 downto 0);
            analog_waveform : out std_logic_vector(7 downto 0)
        );
    end component;

    procedure assert_equal(actual, expected : in std_logic_vector(15 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & integer'image(to_integer(signed(expected))) & " but was " & integer'image(to_integer(signed(actual))) severity error;
    end assert_equal;

    constant clock_period : time := 20 ns;
    constant sample_period : time := 2 us;

    signal clock : std_logic;
    signal reset : std_logic;

    signal adc_data : std_logic_vector(7 downto 0);
    signal adc_sample : std_logic;
    signal upsample : integer range 0 to 4;
    signal downsample : integer range 0 to 3;

    signal write_bus_grant : std_logic;
    signal write_bus_acquire : std_logic;
    signal write_address : std_logic_vector(3 downto 0);
    signal write_en : std_logic;
    signal write_data : std_logic_vector(7 downto 0);

    signal trigger_type : std_logic;
    signal trigger_ref : std_logic_vector(7 downto 0);
    signal trigger : std_logic;
    signal trigger_frequency : std_logic_vector(31 downto 0);

    signal frequency_control : std_logic_vector(15 downto 0);

begin

    dut : data_acquisition
        port map (
            clock => clock,
            reset => reset,
            adc_data => adc_data,
            adc_sample => adc_sample,
            trigger => trigger,
            upsample => upsample,
            downsample => downsample,
            write_bus_grant => write_bus_grant,
            write_bus_acquire => write_bus_acquire,
            write_address => write_address,
            write_en => write_en,
            write_data => write_data
        );

    trigger_gen : triggering
        port map (
            clock => clock,
            reset => reset,
            adc_data => adc_data,
            adc_sample => adc_sample,
            trigger_type => trigger_type,
            trigger_ref => trigger_ref,
            trigger => trigger,
            trigger_frequency => trigger_frequency
        );

    mem : arbitrated_memory
        port map (
            clock => clock,
            reset => reset,
            write_bus_acquire => write_bus_acquire,
            write_address => write_address,
            write_en => write_en,
            write_data => write_data,
            write_bus_grant => write_bus_grant
        );

    sig_gen : analog_waveform_generator
        port map (
            clock => clock,
            reset => reset,
            frequency_control => frequency_control,
            analog_waveform => adc_data
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    sampling_process : process
    begin
        adc_sample <= '0';
        wait for sample_period - clock_period;
        adc_sample <= '1';
        wait for clock_period;
    end process;

    test_process : process
        variable error_count : integer := 0;
    begin
        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';

        upsample <= 0;
        downsample <= 0;
        trigger_ref <= x"80";
        trigger_type <= '1';

        -- 10 kHz
        frequency_control <= x"051F";

        wait;
    end process;

end architecture;
