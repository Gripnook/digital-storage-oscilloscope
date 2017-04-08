-- A VGA driver module that converts a captured waveform and a set of measurements
-- and settings to VGA signals that can be used to drive a video DAC. The measurements
-- and settings are processed through BCD converters in order to be displayed in
-- decimal encoding, and the waveform is vertically interpolated between samples in order
-- to provide a continuous graph on the display.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;
use work.vga_parameters.all;

entity vga is
    generic (
        READ_ADDR_WIDTH : integer;
        READ_DATA_WIDTH : integer
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        horizontal_scale : in std_logic_vector(31 downto 0); -- us/div
        vertical_scale : in std_logic_vector(31 downto 0); -- mV/div
        trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
        trigger_level : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0); -- mV
        trigger_frequency : in std_logic_vector(31 downto 0); -- Hz
        voltage_pp : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0); -- mV
        voltage_avg : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0); -- mV
        voltage_max : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0); -- mV
        voltage_min : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0); -- mV
        mem_bus_grant : in std_logic;
        mem_data : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0);
        mem_bus_acquire : out std_logic;
        mem_address : out std_logic_vector(READ_ADDR_WIDTH - 1 downto 0);
        pixel_clock : out std_logic;
        rgb : out std_logic_vector(23 downto 0);
        hsync : out std_logic;
        vsync : out std_logic
    );
end vga;

architecture arch of vga is

    component vga_timing_generator is
        generic (
            H_PIXELS : integer; -- horizontal display width in pixels
            H_PULSE  : integer; -- horizontal sync pulse width in pixels
            H_BP     : integer; -- horizontal back porch width in pixels
            H_FP     : integer; -- horizontal front porch width in pixels
            H_POL    : std_logic; -- horizontal sync pulse polarity (1 = positive, 0 = negative)
            V_PIXELS : integer; -- vertical display width in rows
            V_PULSE  : integer; -- vertical sync pulse width in rows
            V_BP     : integer; -- vertical back porch width in rows
            V_FP     : integer; -- vertical front porch width in rows
            V_POL    : std_logic -- vertical sync pulse polarity (1 = positive, 0 = negative)
        );
        port (
            clock   : in  std_logic; -- pixel clock at frequency of VGA mode being used
            reset   : in  std_logic; -- asynchronous reset
            row     : out integer range 0 to V_PIXELS - 1; -- vertical pixel coordinate
            column  : out integer range 0 to H_PIXELS - 1; -- horizontal pixel coordinate
            hsync   : out std_logic; -- horizontal sync pulse
            vsync   : out std_logic; -- vertical sync pulse
            blank_n : out std_logic -- active low blanking output
        );
    end component;

    component vga_rom is
        port (
            clock : in std_logic;
            reset : in std_logic;
            row : in integer range 0 to V_PIXELS - 1;
            column : in integer range 0 to H_PIXELS - 1;
            horizontal_scale : in std_logic_vector(15 downto 0); -- BCD in us/div
            vertical_scale : in std_logic_vector(15 downto 0); -- BCD in mV/div
            trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
            trigger_frequency : in std_logic_vector(23 downto 0); -- BCD in Hz
            trigger_level : in std_logic_vector(15 downto 0); -- BCD in mV
            voltage_pp : in std_logic_vector(15 downto 0); -- BCD in mV
            voltage_avg : in std_logic_vector(15 downto 0); -- BCD in mV
            voltage_max : in std_logic_vector(15 downto 0); -- BCD in mV
            voltage_min : in std_logic_vector(15 downto 0); -- BCD in mV
            rgb : out std_logic_vector(23 downto 0)
        );
    end component;

    component vga_buffer is
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
    end component;

    component running_average is
        generic (
            DATA_WIDTH : integer;
            POP_SIZE_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            load : in std_logic;
            data_in : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            average : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    component bcd_converter is
        generic (
            DATA_WIDTH : integer;
            BCD_DIGITS : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            binary : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            start : in std_logic;
            bcd : out std_logic_vector(4 * BCD_DIGITS - 1 downto 0);
            done : out std_logic
        );
    end component;

    signal row : integer range 0 to V_PIXELS - 1;
    signal column : integer range 0 to H_PIXELS - 1;
    signal row_delayed : integer range 0 to V_PIXELS - 1;
    signal column_delayed : integer range 0 to H_PIXELS - 1;
    signal hsync_internal : std_logic;
    signal hsync_delayed : std_logic;
    signal vsync_internal : std_logic;
    signal vsync_delayed : std_logic;
    signal blank_n : std_logic;
    signal blank_n_delayed : std_logic;
    signal blank_n_delayed2 : std_logic;

    signal background_rgb : std_logic_vector(23 downto 0);

    signal display_time : integer range 0 to PLOT_WIDTH - 1;
    signal data_1, data_2 : integer range 0 to PLOT_HEIGHT - 1;
    signal display_data : std_logic;
    signal display_data_delayed : std_logic;

    signal mem_bus_grant_delayed : std_logic;

    signal frame_count : std_logic_vector(31 downto 0);
    signal frame_count_en : std_logic;

    signal averaging_load : std_logic;
    signal average_trigger_frequency : std_logic_vector(31 downto 0);

    signal bcd_start : std_logic;
    signal horizontal_scale_bcd : std_logic_vector(15 downto 0);
    signal vertical_scale_bcd : std_logic_vector(15 downto 0);
    signal trigger_frequency_bcd : std_logic_vector(23 downto 0);
    signal trigger_level_bcd : std_logic_vector(15 downto 0);
    signal voltage_pp_bcd : std_logic_vector(15 downto 0);
    signal voltage_avg_bcd : std_logic_vector(15 downto 0);
    signal voltage_max_bcd : std_logic_vector(15 downto 0);
    signal voltage_min_bcd : std_logic_vector(15 downto 0);

    signal trigger_level_internal : std_logic_vector(READ_DATA_WIDTH - 1 downto 0);
    signal display_trigger : std_logic;

begin

    timing_generator : vga_timing_generator
        generic map (
            H_PIXELS => H_PIXELS,
            H_PULSE  => H_PULSE,
            H_BP     => H_BP,
            H_FP     => H_FP,
            H_POL    => H_POL,
            V_PIXELS => V_PIXELS,
            V_PULSE  => V_PULSE,
            V_BP     => V_BP,
            V_FP     => V_FP,
            V_POL    => V_POL
        )
        port map (
            clock => clock,
            reset => reset,
            row => row,
            column => column,
            hsync => hsync_internal,
            vsync => vsync_internal,
            blank_n => blank_n
        );

    background : vga_rom
        port map (
            clock => clock,
            reset => reset,
            row => row,
            column => column,
            horizontal_scale => horizontal_scale_bcd,
            vertical_scale => vertical_scale_bcd,
            trigger_type => trigger_type,
            trigger_frequency => trigger_frequency_bcd,
            trigger_level => trigger_level_bcd,
            voltage_pp => voltage_pp_bcd,
            voltage_avg => voltage_avg_bcd,
            voltage_max => voltage_max_bcd,
            voltage_min => voltage_min_bcd,
            rgb => background_rgb
        );

    buff : vga_buffer
        generic map (
            READ_ADDR_WIDTH => READ_ADDR_WIDTH,
            READ_DATA_WIDTH => READ_DATA_WIDTH
        )
        port map (
            clock => clock,
            reset => reset,
            display_time => display_time,
            vsync => vsync_internal,
            mem_bus_grant => mem_bus_grant,
            mem_data => mem_data,
            mem_bus_acquire => mem_bus_acquire,
            mem_address => mem_address,
            data_1 => data_1,
            data_2 => data_2
        );

    frame_counter : lpm_counter
        generic map (
            LPM_WIDTH => 32,
            LPM_MODULUS => FRAME_RATE / DATA_UPDATE_RATE
        )
        port map (
            clock => clock,
            aclr => reset,
            cnt_en => frame_count_en,
            q => frame_count
        );
    frame_count_en <= '1' when mem_bus_grant = '1' and mem_bus_grant_delayed /= mem_bus_grant else '0';

    averaging_load <= frame_count_en;

    averaging : running_average
        generic map (
            DATA_WIDTH => 32,
            POP_SIZE_WIDTH => 4
        )
        port map (
            clock => clock,
            reset => reset,
            load => averaging_load,
            data_in => trigger_frequency,
            average => average_trigger_frequency
        );

    bcd_start <= '1' when frame_count_en = '1' and frame_count = x"00000000" else '0';

    hscale_bcd : bcd_converter
        generic map (DATA_WIDTH => 32, BCD_DIGITS => 4)
        port map (
            clock => clock, reset => reset,
            binary => horizontal_scale, start => bcd_start,
            bcd => horizontal_scale_bcd, done => open
        );

    vscale_bcd : bcd_converter
        generic map (DATA_WIDTH => 32, BCD_DIGITS => 4)
        port map (
            clock => clock, reset => reset,
            binary => vertical_scale, start => bcd_start,
            bcd => vertical_scale_bcd, done => open
        );

    trig_freq_bcd : bcd_converter
        generic map (DATA_WIDTH => 32, BCD_DIGITS => 6)
        port map (
            clock => clock, reset => reset,
            binary => average_trigger_frequency, start => bcd_start,
            bcd => trigger_frequency_bcd, done => open
        );

    trig_level_bcd : bcd_converter
        generic map (DATA_WIDTH => READ_DATA_WIDTH, BCD_DIGITS => 4)
        port map (
            clock => clock, reset => reset,
            binary => trigger_level, start => bcd_start,
            bcd => trigger_level_bcd, done => open
        );

    vpp_bcd : bcd_converter
        generic map (DATA_WIDTH => READ_DATA_WIDTH, BCD_DIGITS => 4)
        port map (
            clock => clock, reset => reset,
            binary => voltage_pp, start => bcd_start,
            bcd => voltage_pp_bcd, done => open
        );

    vavg_bcd : bcd_converter
        generic map (DATA_WIDTH => READ_DATA_WIDTH, BCD_DIGITS => 4)
        port map (
            clock => clock, reset => reset,
            binary => voltage_avg, start => bcd_start,
            bcd => voltage_avg_bcd, done => open
        );

    vmax_bcd : bcd_converter
        generic map (DATA_WIDTH => READ_DATA_WIDTH, BCD_DIGITS => 4)
        port map (
            clock => clock, reset => reset,
            binary => voltage_max, start => bcd_start,
            bcd => voltage_max_bcd, done => open
        );

    vmin_bcd : bcd_converter
        generic map (DATA_WIDTH => READ_DATA_WIDTH, BCD_DIGITS => 4)
        port map (
            clock => clock, reset => reset,
            binary => voltage_min, start => bcd_start,
            bcd => voltage_min_bcd, done => open
        );

    trigger_level_register : process (clock, reset)
    begin
        if (reset = '1') then
            trigger_level_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (frame_count_en = '1') then
                trigger_level_internal <= trigger_level;
            end if;
        end if;
    end process;

    display_trigger <= '1' when (column_delayed >= X0 and column_delayed < X0 + PLOT_WIDTH) and
        (to_integer(unsigned(trigger_level_internal(READ_DATA_WIDTH - 1 downto READ_DATA_WIDTH - PLOT_HEIGHT_BIT_LENGTH))) = V_PIXELS - 1 - row_delayed - Y0) else '0';

    display_time <= column - X0 when (column >= X0 and column < X0 + PLOT_WIDTH) else
        PLOT_WIDTH - 1;

    range_comparator : process (data_1, data_2, row_delayed, column_delayed)
        variable data_row : integer range -Y0 to V_PIXELS - 1 - Y0;
    begin
        -- convert the row to the equivalent on the waveform plot
        data_row := V_PIXELS - 1 - row_delayed - Y0;

        display_data <= '0'; -- default output
        if ((column_delayed >= X0 and column_delayed < X0 + PLOT_WIDTH) and
            ((data_row >= data_1 and data_row <= data_2) or
            (data_row <= data_1 and data_row >= data_2))) then
            display_data <= '1';
        end if;
    end process;

    display_mux : process (display_data_delayed, blank_n_delayed2, background_rgb, display_trigger)
    begin
        if (blank_n_delayed2 = '0') then
            rgb <= (others => '0');
        elsif (display_data_delayed = '1') then
            rgb <= WAVEFORM_COLOR;
        elsif (display_trigger = '1') then
            rgb <= TRIGGER_COLOR;
        else
            rgb <= background_rgb;
        end if;
    end process;

    delay_registers : process (clock, reset)
    begin
        if (reset = '1') then
            row_delayed <= 0;
            column_delayed <= 0;
            display_data_delayed <= '0';
            blank_n_delayed <= '0';
            blank_n_delayed2 <= '0';
            hsync_delayed <= '0';
            hsync <= '0';
            vsync_delayed <= '0';
            vsync <= '0';
            mem_bus_grant_delayed <= '0';
        elsif (rising_edge(clock)) then
            row_delayed <= row;
            column_delayed <= column;
            display_data_delayed <= display_data;
            blank_n_delayed <= blank_n;
            blank_n_delayed2 <= blank_n_delayed;
            hsync_delayed <= hsync_internal;
            hsync <= hsync_delayed;
            vsync_delayed <= vsync_internal;
            vsync <= vsync_delayed;
            mem_bus_grant_delayed <= mem_bus_grant;
        end if;
    end process;

    pixel_clock <= clock;

end architecture;
