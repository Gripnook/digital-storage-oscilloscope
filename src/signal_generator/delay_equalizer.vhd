-- Implements a delay equalizer that updates the frequency_control_out signal with
-- the value of the frequency_control_in signal when the asserted update_in signal has propagated
-- through the internal registers. Otherwise, the previous value is stored and output.
-- 
-- A chain of delay equalizers will ensure that the outputs change at a rate of one-bit per clock
-- cycle when a new input is asserted and the update_in signal is propagated through the chain.

library ieee;
use ieee.std_logic_1164.all;

entity delay_equalizer is
    port (clock : in std_logic;
          reset : in std_logic;
          frequency_control_in : in std_logic;
          update_in : in std_logic;
          frequency_control_out : out std_logic;
          update_out : out std_logic);
end delay_equalizer;

architecture arch of delay_equalizer is

    signal update_internal : std_logic;
    signal frequency_control_internal : std_logic;
    signal frequency_control_next : std_logic;

begin
    
    regs : process (clock, reset)
    begin
        if (reset = '1') then
            frequency_control_internal <= '0';
            update_internal <= '0';
        elsif (rising_edge(clock)) then
            frequency_control_internal <= frequency_control_next;
            update_internal <= update_in;
        end if;
    end process;

    with update_internal select frequency_control_next <=
        frequency_control_in when '1',
        frequency_control_internal when others;

    update_out <= update_internal;
    frequency_control_out <= frequency_control_internal;

end architecture;
