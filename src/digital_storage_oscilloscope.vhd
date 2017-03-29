library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity digital_storage_oscilloscope is
    generic (
        ADC_DATA_WIDTH : integer := 12;
        MAX_UPSAMPLE : integer := 5
    );
    port (
        clock : in std_logic;
        reset_n : in std_logic;
        timebase : in std_logic_vector(2 downto 0);
        trigger_up_n : in std_logic;
        trigger_down_n : in std_logic;
        trigger_type : in std_logic;
        adc_sclk : out std_logic;
        adc_din : out std_logic;
        adc_dout : in std_logic;
        adc_convst : out std_logic;
        pixel_clock : out std_logic;
        hsync, vsync : out std_logic;
        r, g, b : out std_logic_vector(7 downto 0)
    );
end digital_storage_oscilloscope;

architecture arch of digital_storage_oscilloscope is

    component oscilloscope is
        generic (
            ADC_DATA_WIDTH : integer;
            MAX_UPSAMPLE : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            horizontal_scale : in std_logic_vector(31 downto 0); -- us/div
            vertical_scale : in std_logic_vector(31 downto 0); -- mV/div
            upsample : in integer range 0 to MAX_UPSAMPLE; -- up-sampling rate is 2 ** upsample
            trigger_type : in std_logic; -- '1' for rising edge, '0' for falling edge
            trigger_ref : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
            adc_data : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
            adc_sample : in std_logic;
            pixel_clock : out std_logic;
            hsync, vsync : out std_logic;
            r, g, b : out std_logic_vector(7 downto 0)
        );
    end component;

    component adc_clock is
        port (
            refclk   : in  std_logic := '0'; -- refclk.clk
            rst      : in  std_logic := '0'; -- reset.reset
            outclk_0 : out std_logic         -- outclk0.clk
        );
    end component;

    component adc_sampler is
        generic (
            ADC_DATA_WIDTH : integer := 12;
            ADC_CONVST_PERIOD : integer := 80
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            adc_sclk : out std_logic;
            adc_din : out std_logic;
            adc_dout : in std_logic;
            adc_convst : out std_logic;
            adc_sample : out std_logic;
            adc_data : out std_logic_vector(ADC_DATA_WIDTH - 1 downto 0)
        );
    end component;

    signal reset : std_logic;

    signal adc_clk : std_logic;
    signal adc_sample_clk1 : std_logic;
    signal adc_sample_clk2 : std_logic;
    signal adc_data_clk1 : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal adc_data_clk2 : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);

    signal adc_data : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal adc_sample : std_logic;
    signal adc_sample_count : integer range 0 to 99;

    signal horizontal_scale : std_logic_vector(31 downto 0);
    signal vertical_scale : std_logic_vector(31 downto 0) := x"00000200";
    signal upsample : integer range 0 to MAX_UPSAMPLE;
    
    signal trigger_ref : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal trigger_ref_up : std_logic;
    signal trigger_ref_en : std_logic;
    signal trigger_control : std_logic_vector(31 downto 0);
    signal trigger_control_clr : std_logic;

begin
    
    reset <= not reset_n;

    scope : oscilloscope
        generic map (
            ADC_DATA_WIDTH => ADC_DATA_WIDTH,
            MAX_UPSAMPLE => MAX_UPSAMPLE
        )
        port map (
            clock => clock,
            reset => reset,
            horizontal_scale => horizontal_scale,
            vertical_scale => vertical_scale,
            upsample => upsample,
            trigger_type => trigger_type,
            trigger_ref => trigger_ref,
            adc_data => adc_data,
            adc_sample => adc_sample,
            pixel_clock => pixel_clock,
            hsync => hsync,
            vsync => vsync,
            r => r,
            g => g,
            b => b
        );

    adc_clk_pll : adc_clock
        port map (
            refclk => clock,
            rst => reset,
            outclk_0 => adc_clk
        );

    adc_sampler_module : adc_sampler
        generic map (
            ADC_DATA_WIDTH => ADC_DATA_WIDTH
        )
        port map (
            clock => adc_clk,
            reset => reset,
            adc_sclk => adc_sclk,
            adc_din => adc_din,
            adc_dout => adc_dout,
            adc_convst => adc_convst,
            adc_sample => adc_sample_clk1,
            adc_data => adc_data_clk1
        );

    clock_domain1_reg : process (adc_clk, reset)
    begin
        if (reset = '1') then
            adc_sample_clk2 <= '0';
            adc_data_clk2 <= (others => '0');
        elsif (rising_edge(adc_clk)) then
            adc_sample_clk2 <= adc_sample_clk1;
            adc_data_clk2 <= adc_data_clk1;
        end if;
    end process;

    clock_domain2_reg : process (clock, reset)
    begin
        if (reset = '1') then
            adc_sample <= '0';
            adc_data <= (others => '0');
        elsif (rising_edge(clock)) then
            adc_sample <= adc_sample_clk2;
            adc_data <= adc_data_clk2;
        end if;
    end process;

    upsample <= to_integer(unsigned(timebase)) when to_integer(unsigned(timebase)) <= MAX_UPSAMPLE else MAX_UPSAMPLE;
    process (upsample)
    begin
        horizontal_scale <= (others => '0');
        horizontal_scale(7 - upsample) <= '1';
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

end architecture;
