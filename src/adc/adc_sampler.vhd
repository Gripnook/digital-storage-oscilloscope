library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use lpm.lpm_components.all;

entity adc_sampler is
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
end adc_sampler;

architecture arch of adc_sampler is

    constant ADC_CONVST_PERIOD_WIDTH : integer := integer(ceil(log2(real(ADC_CONVST_PERIOD))));

    constant ADC_DIN_WORD_LENGTH : integer := 6;
    constant ADC_DIN_WORD : std_logic_vector(0 to ADC_DIN_WORD_LENGTH - 1) := "100010"; -- Channel 1
    constant ADC_DIN_WORD_START : integer := ADC_CONVST_PERIOD / 2 - 1;

    signal adc_convst_count : std_logic_vector(ADC_CONVST_PERIOD_WIDTH - 1 downto 0);
    signal adc_data_internal : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);

begin

    adc_convst_counter : lpm_counter
        generic map (
            LPM_WIDTH => ADC_CONVST_PERIOD_WIDTH,
            LPM_MODULUS => ADC_CONVST_PERIOD
        )
        port map (
            clock => clock,
            aclr => reset,
            q => adc_convst_count
        );

    adc_sclk <= clock;
    adc_din <= ADC_DIN_WORD(to_integer(unsigned(adc_convst_count)) - ADC_DIN_WORD_START) when
        unsigned(adc_convst_count) >= ADC_DIN_WORD_START and unsigned(adc_convst_count) < ADC_DIN_WORD_START + ADC_DIN_WORD_LENGTH else '0';
    adc_convst <= '1' when unsigned(adc_convst_count) < ADC_CONVST_PERIOD / 2 else '0';

    adc_shiftreg : process (clock, reset)
    begin
        if (reset = '1') then
            adc_data_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (unsigned(adc_convst_count) >= ADC_DIN_WORD_START and unsigned(adc_convst_count) < ADC_DIN_WORD_START + ADC_DATA_WIDTH) then
                adc_data_internal(ADC_DATA_WIDTH - 1 downto 1) <= adc_data_internal(ADC_DATA_WIDTH - 2 downto 0);
                adc_data_internal(0) <= adc_dout;
            end if;
        end if;
    end process;

    adc_sample <= '1' when unsigned(adc_convst_count) = ADC_DIN_WORD_START + ADC_DATA_WIDTH else '0';
    adc_data <= adc_data_internal;

end architecture;
