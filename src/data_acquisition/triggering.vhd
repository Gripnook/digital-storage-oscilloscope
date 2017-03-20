library ieee;
use ieee.std_logic_1164.all;

entity triggering is
    generic (
        DATA_WIDTH : integer := 12
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        adc_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        trigger_ref : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        trigger : out std_logic
    );
end triggering;

architecture arch of triggering is

    signal adc_data_delayed : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

    delay_register : process (clock, reset)
    begin
        if (reset = '1') then
            adc_data_delayed <= (others => '0');
        elsif (rising_edge(clock)) then
            adc_data_delayed <= adc_data;
        end if;
    end process;

    trigger_comparator : process (adc_data, adc_data_delayed, trigger_ref)
    begin
        trigger <= '0'; -- default output
        if (adc_data <= trigger_ref and adc_data_delayed > trigger_ref) then
            trigger <= '1';
        end if;
    end process;

end architecture;
