-- Implements a frequency synthesizer that uses an N-bit input to select the output frequency.
-- The output frequency is given by frequency_control * clock_rate / 2 ** N
-- 
-- Uses a pipelined adder with delay equalizer as part of an accumulator to generate the frequency.

library ieee;
use ieee.std_logic_1164.all;

entity pipelined_frequency_synthesizer is
    generic (N : integer := 5);
    port (clock : in std_logic;
          reset : in std_logic;
          update : in std_logic;
          frequency_control : in std_logic_vector(N-1 downto 0);
          frequency : out std_logic);
end pipelined_frequency_synthesizer;

architecture arch of pipelined_frequency_synthesizer is

    component bit_slice is
        port (clock : in std_logic;
              reset : in std_logic;
              frequency_control : in std_logic;
              update_in : in std_logic;
              Cin : in std_logic;
              update_out : out std_logic;
              Cout : out std_logic);
    end component;

    constant HIGH : std_logic := '1';
    constant LOW  : std_logic := '0';

    signal updates : std_logic_vector(0 to N); -- update propagation chain
    signal C : std_logic_vector(0 to N); -- carry propagation chain

begin

    accumulator : for i in 0 to N-1 generate
        bits : bit_slice
        port map (clock => clock,
                  reset => reset,
                  frequency_control => frequency_control(i),
                  update_in => updates(i),
                  Cin => C(i),
                  update_out => updates(i+1),
                  Cout => C(i+1));
    end generate accumulator;

    updates(0) <= update;
    C(0) <= LOW;
    frequency <= C(N);

end architecture;
