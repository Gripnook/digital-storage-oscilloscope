-- An unsigned divider for numbers from 0 to 2 ** (DATA_WIDTH - 1) - 1. The divider uses multiple
-- clock cycles to perform its task. The inputs are read on the rising edge of the clock when the
-- start signal is asserted, and completion is signaled through the done signal. The start signal
-- must be deasserted following completion for the module to be reset.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use lpm.lpm_components.all;

entity divider is
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
        remainder : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        done : out std_logic
    );
end divider;

architecture arch of divider is
    
    constant DATA_WIDTH_LENGTH : integer := integer(ceil(log2(real(DATA_WIDTH))));

    constant ZERO : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    constant LOW : std_logic := '0';

    type state_type is (S_IDLE, S_PRESHIFT, S_DIVIDE, S_DONE);
    signal state : state_type := S_IDLE;

    signal dividend_in : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal dividend_internal : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal dividend_in_select : std_logic;
    signal dividend_in_load : std_logic;

    signal divisor_internal : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal divisor_enable : std_logic;
    signal divisor_load : std_logic;
    signal divisor_shiftleft : std_logic;

    signal quotient_internal : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal quotient_clear : std_logic;
    signal quotient_shift : std_logic;

    signal sub_result : signed(DATA_WIDTH downto 0) := (others => '0');
    signal sub_nonnegative : std_logic;

    signal bit_count : std_logic_vector(DATA_WIDTH_LENGTH - 1 downto 0);
    signal bit_count_enable : std_logic;
    signal bit_count_updown : std_logic;
    signal bit_count_done : std_logic;

begin

    with dividend_in_select select dividend_in <=
        dividend when '1',
        std_logic_vector(sub_result(DATA_WIDTH - 1 downto 0)) when others;

    dividend_reg : process (clock, reset)
    begin
        if (reset = '1') then
            dividend_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (dividend_in_load = '1') then
                dividend_internal <= dividend_in;
            end if;
        end if;
    end process;

    divisor_shiftreg : process (clock, reset)
    begin
        if (reset = '1') then
            divisor_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (divisor_enable = '1') then
                if (divisor_load = '1') then
                    divisor_internal <= divisor;
                elsif (divisor_shiftleft = '1') then
                    divisor_internal(DATA_WIDTH - 1 downto 1) <= divisor_internal(DATA_WIDTH - 2 downto 0);
                    divisor_internal(0) <= '0';
                else
                    divisor_internal(DATA_WIDTH - 2 downto 0) <= divisor_internal(DATA_WIDTH - 1 downto 1);
                    divisor_internal(DATA_WIDTH - 1) <= '0';
                end if;
            end if;
        end if;
    end process;

    quotient_shiftreg : process (clock, reset)
    begin
        if (reset = '1') then
            quotient_internal <= (others => '0');
        elsif (rising_edge(clock)) then
            if (quotient_clear = '1') then
                quotient_internal <= (others => '0');
            elsif (quotient_shift = '1') then
                quotient_internal(DATA_WIDTH - 1 downto 1) <= quotient_internal(DATA_WIDTH - 2 downto 0);
                quotient_internal(0) <= sub_nonnegative;
            end if;
        end if;
    end process;

    sub_result <= signed("0" & dividend_internal) - signed("0" & divisor_internal);
    sub_nonnegative <= '1' when sub_result >= 0 else '0';

    quotient <= quotient_internal;
    remainder <= dividend_internal;

    bit_counter : lpm_counter
        generic map (LPM_WIDTH => DATA_WIDTH_LENGTH)
        port map (
            clock => clock,
            aclr => reset,
            updown => bit_count_updown,
            cnt_en => bit_count_enable,
            q => bit_count
        );

    bit_count_nor_gate : process (bit_count)
        variable bit_count_nonzero : std_logic;
    begin
        bit_count_nonzero := '0';
        for i in 0 to DATA_WIDTH_LENGTH - 1 loop
            bit_count_nonzero := bit_count_nonzero or bit_count(i);
        end loop;
        bit_count_done <= not bit_count_nonzero;
    end process;

    state_transition : process (clock, reset)
    begin
        if (reset = '1') then
            state <= S_IDLE;
        elsif (rising_edge(clock)) then
            case state is
            when S_IDLE =>
                if (start = '1') then
                    if (divisor = ZERO) then
                        state <= S_DONE;
                    else
                        state <= S_PRESHIFT;
                    end if;
                else
                    state <= S_IDLE;
                end if;
            when S_PRESHIFT =>
                if (sub_nonnegative = '0') then
                    state <= S_DIVIDE;
                else
                    state <= S_PRESHIFT;
                end if;
            when S_DIVIDE =>
                if (bit_count_done = '1') then
                    state <= S_DONE;
                else
                    state <= S_DIVIDE;
                end if;
            when S_DONE =>
                if (start = '0') then
                    state <= S_IDLE;
                else
                    state <= S_DONE;
                end if;
            when others =>
                null;
            end case;
        end if;
    end process;

    outputs : process (state, start, bit_count_done, sub_nonnegative)
    begin
        -- default outputs
        dividend_in_select <= '0';
        dividend_in_load <= '0';
        divisor_enable <= '0';
        divisor_load <= '0';
        divisor_shiftleft <= '0';
        quotient_clear <= '0';
        quotient_shift <= '0';
        bit_count_enable <= '0';
        bit_count_updown <= '0';
        done <= '0';

        case state is
        when S_IDLE =>
            if (start = '1') then
                dividend_in_select <= '1';
                dividend_in_load <= '1';
                divisor_enable <= '1';
                divisor_load <= '1';
                quotient_clear <= '1';
            end if;
        when S_PRESHIFT =>
            bit_count_enable <= '1';
            bit_count_updown <= '1';
            if (sub_nonnegative = '1') then
                divisor_enable <= '1';
                divisor_shiftleft <= '1';
            end if;
        when S_DIVIDE =>
            if (bit_count_done = '0') then
                divisor_enable <= '1';
                quotient_shift <= '1';
                bit_count_enable <= '1';
                if (sub_nonnegative = '1') then
                    dividend_in_load <= '1';
                end if;
            end if;
        when S_DONE =>
            done <= '1';
        when others =>
            null;
        end case;
    end process;

end architecture;
