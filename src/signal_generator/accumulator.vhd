-- Implements an accumulator cell that adds an input A with carry-in Cin
-- to an internal sum and produces a carry-out signal Cout on every rising clock edge.

library ieee;
use ieee.std_logic_1164.all;

entity accumulator is
    port (clock : in std_logic;
          reset : in std_logic;
          A : in std_logic;
          Cin : in std_logic;
          Cout : out std_logic);
end accumulator;

architecture arch of accumulator is

    signal B : std_logic;
    signal B_next : std_logic;
    signal Cout_next : std_logic;

begin
    
    B_next <= A xor B xor Cin;
    Cout_next <= (A and B) or (A and Cin) or (B and Cin);

    regs : process (clock, reset)
    begin
        if (reset = '1') then
            B <= '0';
            Cout <= '0';
        elsif (rising_edge(clock)) then
            B <= B_next;
            Cout <= Cout_next;
        end if;
    end process;

end architecture;
