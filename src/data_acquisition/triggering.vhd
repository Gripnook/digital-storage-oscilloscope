library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity triggering is
    generic (
        DATA_WIDTH : integer := 12;
        FREQUENCY_WIDTH : integer := 32
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        adc_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        trigger_type : in std_logic;
        trigger_ref : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        trigger : out std_logic;
        trigger_frequency : out std_logic_vector(FREQUENCY_WIDTH - 1 downto 0)
    );
end triggering;

architecture arch of triggering is

    signal adc_data_delayed : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal trigger_period : std_logic_vector(31 downto 0);
    signal trigger_period_clr : std_logic;

begin

    delay_register : process (clock, reset)
    begin
        if (reset = '1') then
            adc_data_delayed <= (others => '0');
        elsif (rising_edge(clock)) then
            adc_data_delayed <= adc_data;
        end if;
    end process;

    -- TODO: Extract division into a multi-cycle module
    -- TODO: Averaging for the frequency
    trigger_comparator : process (clock, reset)
    begin
        if (reset = '1') then
            trigger <= '0';
            trigger_frequency <= (others => '0');
            trigger_period_clr <= '0';
        elsif (rising_edge(clock)) then
            -- default outputs
            trigger <= '0';
            trigger_period_clr <= '0';

            if (trigger_type = '1' and adc_data_delayed <= trigger_ref and adc_data > trigger_ref) then
                trigger <= '1';
                trigger_frequency <= std_logic_vector(to_unsigned(50000000 / to_integer(unsigned(trigger_period)), FREQUENCY_WIDTH));
                trigger_period_clr <= '1';
            elsif (trigger_type = '0' and adc_data_delayed >= trigger_ref and adc_data < trigger_ref) then
                trigger <= '1';
                trigger_frequency <= std_logic_vector(to_unsigned(50000000 / to_integer(unsigned(trigger_period)), FREQUENCY_WIDTH));
                trigger_period_clr <= '1';
            end if;
        end if;
    end process;

    trigger_period_counter : lpm_counter
        generic map (LPM_WIDTH => 32)
        port map (
            clock => clock,
            aclr => reset,
            sclr => trigger_period_clr,
            q => trigger_period
        );

end architecture;
