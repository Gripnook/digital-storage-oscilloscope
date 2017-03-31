library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity digital_storage_oscilloscope is
    generic (
        ADC_DATA_WIDTH : integer := 12;
        MAX_UPSAMPLE : integer := 5;
        MAX_DOWNSAMPLE : integer := 2
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
            MAX_UPSAMPLE : integer;
            MAX_DOWNSAMPLE : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            horizontal_scale : in std_logic_vector(31 downto 0); -- us/div
            vertical_scale : in std_logic_vector(31 downto 0); -- mV/div
            upsample : in integer range 0 to MAX_UPSAMPLE; -- upsampling rate is 2 ** upsample
            downsample : in integer range 0 to MAX_DOWNSAMPLE; -- downsampling rate is 2 ** downsample
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
            ADC_SAMPLE_PERIOD : integer := 80 -- 2 us in clock cycles
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

    component fifo is
        port (
            aclr : in std_logic := '0';
            data : in std_logic_vector(11 downto 0);
            rdclk : in std_logic;
            rdreq : in std_logic;
            wrclk : in std_logic;
            wrreq : in std_logic;
            q : out std_logic_vector(11 downto 0);
            rdempty : out std_logic;
            wrfull : out std_logic
        );
    end component;

    signal reset : std_logic;
    signal reset_clk1 : std_logic;
    signal reset_clk1_temp : std_logic;
    signal reset_clk2 : std_logic;
    signal reset_clk2_temp : std_logic;

    signal adc_clk : std_logic;

    signal adc_data : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal adc_sample_clk1 : std_logic;
    signal adc_sample_clk2 : std_logic;

    signal fifo_data : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal fifo_rdreq : std_logic;
    signal fifo_wrreq : std_logic;
    signal fifo_rdempty : std_logic;
    signal fifo_rdempty_delayed : std_logic;
    signal fifo_rdempty_n : std_logic;
    signal fifo_wrfull : std_logic;

    signal horizontal_scale : std_logic_vector(31 downto 0);
    signal vertical_scale : std_logic_vector(31 downto 0) := x"00000200";
    signal upsample : integer range 0 to MAX_UPSAMPLE;
    signal downsample : integer range 0 to MAX_DOWNSAMPLE;
    
    signal trigger_ref : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal trigger_ref_up : std_logic;
    signal trigger_ref_en : std_logic;
    signal trigger_control : std_logic_vector(31 downto 0);
    signal trigger_control_clr : std_logic;

begin
    
    reset <= not reset_n;

    reset_synchronization_clk1 : process (adc_clk, reset_n)
    begin
        if (reset_n = '0') then
            reset_clk1_temp <= '1';
            reset_clk1 <= '1';
        elsif (rising_edge(adc_clk)) then
            reset_clk1_temp <= '0';
            reset_clk1 <= reset_clk1_temp;
        end if;
    end process;

    reset_synchronization_clk2 : process (clock, reset_n)
    begin
        if (reset_n = '0') then
            reset_clk2_temp <= '1';
            reset_clk2 <= '1';
        elsif (rising_edge(clock)) then
            reset_clk2_temp <= '0';
            reset_clk2 <= reset_clk2_temp;
        end if;
    end process;

    scope : oscilloscope
        generic map (
            ADC_DATA_WIDTH => ADC_DATA_WIDTH,
            MAX_UPSAMPLE => MAX_UPSAMPLE,
            MAX_DOWNSAMPLE => MAX_DOWNSAMPLE
        )
        port map (
            clock => clock,
            reset => reset_clk2,
            horizontal_scale => horizontal_scale,
            vertical_scale => vertical_scale,
            upsample => upsample,
            downsample => downsample,
            trigger_type => trigger_type,
            trigger_ref => trigger_ref,
            adc_data => adc_data,
            adc_sample => adc_sample_clk2,
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
            rst => reset_clk2,
            outclk_0 => adc_clk
        );

    adc_sampler_module : adc_sampler
        generic map (
            ADC_DATA_WIDTH => ADC_DATA_WIDTH
        )
        port map (
            clock => adc_clk,
            reset => reset_clk1,
            adc_sclk => adc_sclk,
            adc_din => adc_din,
            adc_dout => adc_dout,
            adc_convst => adc_convst,
            adc_sample => adc_sample_clk1,
            adc_data => fifo_data
        );

    clock_domain_crossing : fifo
        port map (
            aclr => reset,
            data => fifo_data,
            rdclk => clock,
            rdreq => fifo_rdempty_n,
            wrclk => adc_clk,
            wrreq => fifo_wrreq,
            q => adc_data,
            rdempty => fifo_rdempty,
            wrfull => fifo_wrfull
        );

    fifo_rdempty_n <= not fifo_rdempty;
    fifo_wrreq <= adc_sample_clk1 and (not fifo_wrfull);
    adc_sample_clk2 <= fifo_rdempty and (not fifo_rdempty_delayed);

    delay_register : process (clock, reset_clk2)
    begin
        if (reset_clk2 = '1') then
            fifo_rdempty_delayed <= '0';
        elsif (rising_edge(clock)) then
            fifo_rdempty_delayed <= fifo_rdempty;
        end if;
    end process;

    horizontal_configuration : process (timebase)
    begin
        -- default outputs
        horizontal_scale <= (others => '0');
        upsample <= 0;
        downsample <= 0;
        
        case timebase is
        when "000" =>
            horizontal_scale <= x"00000004";
            upsample <= 5;
            downsample <= 0;
        when "001" =>
            horizontal_scale <= x"00000008";
            upsample <= 4;
            downsample <= 0;
        when "010" =>
            horizontal_scale <= x"00000010";
            upsample <= 3;
            downsample <= 0;
        when "011" =>
            horizontal_scale <= x"00000020";
            upsample <= 2;
            downsample <= 0;
        when "100" =>
            horizontal_scale <= x"00000040";
            upsample <= 1;
            downsample <= 0;
        when "101" =>
            horizontal_scale <= x"00000080";
            upsample <= 0;
            downsample <= 0;
        when "110" =>
            horizontal_scale <= x"00000100";
            upsample <= 0;
            downsample <= 1;
        when "111" =>
            horizontal_scale <= x"00000200";
            upsample <= 0;
            downsample <= 2;
        when others =>
            null;
        end case;
    end process;

    trigger_controls_counter : lpm_counter
        generic map (LPM_WIDTH => 32)
        port map (clock => clock, aclr => reset_clk2, sclr => trigger_control_clr, q => trigger_control);
    trigger_control_clr <= '1' when trigger_control = std_logic_vector(to_unsigned(20000, 32)) else '0';

    trigger_ref_counter : lpm_counter
        generic map (LPM_WIDTH => ADC_DATA_WIDTH)
        port map (
            clock => clock,
            aclr => reset_clk2,
            updown => trigger_ref_up,
            cnt_en => trigger_ref_en,
            q => trigger_ref
        );
    trigger_ref_en <= trigger_control_clr and (trigger_up_n xor trigger_down_n);
    trigger_ref_up <= not trigger_up_n;

end architecture;
