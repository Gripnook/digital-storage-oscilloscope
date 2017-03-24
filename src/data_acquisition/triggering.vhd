library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity triggering is
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
end triggering;

architecture arch of triggering is

    component divider is
        generic (
            DATA_WIDTH : integer
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            dividend : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            divisor : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            start : in std_logic;
            quotient : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            remainder : out std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0'); -- unused
            done : out std_logic
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

    constant CLOCK_RATE : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(50000000, 32));
    constant ONE : std_logic_vector(31 downto 0) := x"00000001";

    signal adc_data_delayed : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal trigger_internal : std_logic;
    signal trigger_delayed : std_logic;
    signal trigger_period : std_logic_vector(31 downto 0);
    signal average_trigger_period : std_logic_vector(31 downto 0);
    signal trigger_frequency_internal : std_logic_vector(31 downto 0);
    signal trigger_division_done : std_logic;

begin

    delay_registers : process (clock, reset)
    begin
        if (reset = '1') then
            adc_data_delayed <= (others => '0');
            trigger_delayed <= '0';
        elsif (rising_edge(clock)) then
            adc_data_delayed <= adc_data;
            trigger_delayed <= trigger_internal;
        end if;
    end process;

    trigger_comparator : process (trigger_type, trigger_ref, adc_data, adc_data_delayed)
    begin
        -- default outputs
        trigger_internal <= '0';

        if (trigger_type = '1' and adc_data_delayed <= trigger_ref and adc_data > trigger_ref) then
            trigger_internal <= '1';
        elsif (trigger_type = '0' and adc_data_delayed >= trigger_ref and adc_data < trigger_ref) then
            trigger_internal <= '1';
        end if;
    end process;

    trigger <= trigger_internal;

    trigger_period_counter : lpm_counter
        generic map (LPM_WIDTH => 32)
        port map (
            clock => clock,
            aclr => reset,
            sload => trigger_internal,
            data => ONE,
            q => trigger_period
        );

    averaging : running_average
        generic map (
            DATA_WIDTH => 32,
            POP_SIZE_WIDTH => 4
        )
        port map (
            clock => clock,
            reset => reset,
            load => trigger_internal,
            data_in => trigger_period,
            average => average_trigger_period
        );

    div : divider
        generic map (DATA_WIDTH => 32)
        port map (
            clock => clock,
            reset => reset,
            dividend => CLOCK_RATE,
            divisor => average_trigger_period,
            start => trigger_delayed,
            quotient => trigger_frequency_internal,
            done => trigger_division_done
        );

    frequency_counter_reg : process (clock, reset)
    begin
        if (reset = '1') then
            trigger_frequency <= (others => '0');
        elsif (rising_edge(clock)) then
            if (trigger_division_done = '1') then
                trigger_frequency <= trigger_frequency_internal;
            end if;
        end if;
    end process;

end architecture;
