-- Generates a running average for a population of 2 ** POP_SIZE_WIDTH

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity running_average is
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
end running_average;

architecture arch of running_average is

    type registers is array(0 to 2 ** POP_SIZE_WIDTH) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal regs : registers;

    signal running_sum : std_logic_vector(DATA_WIDTH + POP_SIZE_WIDTH downto 0);
    signal difference : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

    regs(0) <= data_in;
    difference <= std_logic_vector(signed(regs(0)) - signed(regs(2 ** POP_SIZE_WIDTH)));

    gen_regs : for i in 0 to 2 ** POP_SIZE_WIDTH - 1 generate
        pipeline_reg : process (clock, reset)
        begin
            if (reset = '1') then
                regs(i+1) <= (others => '0');
            elsif (rising_edge(clock)) then
                if (load = '1') then
                    regs(i+1) <= regs(i);
                end if;
            end if;
        end process;
    end generate;

    running_sum_reg : process (clock, reset)
    begin
        if (reset = '1') then
            running_sum <= (others => '0');
        elsif (rising_edge(clock)) then
            if (load = '1') then
                running_sum <= std_logic_vector(signed(running_sum) + signed(difference));
            end if;
        end if;
    end process;

    average <= running_sum(DATA_WIDTH + POP_SIZE_WIDTH - 1 downto POP_SIZE_WIDTH);

end architecture;
