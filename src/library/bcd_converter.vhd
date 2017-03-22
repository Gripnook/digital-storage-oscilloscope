library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use lpm.lpm_components.all;

entity bcd_converter is
    generic (
        INPUT_WIDTH : integer;
        BCD_DIGITS : integer
    );
    port (
        clock : in std_logic;
        reset : in std_logic;
        binary : in std_logic_vector(INPUT_WIDTH - 1 downto 0);
        start : in std_logic;
        bcd : out std_logic_vector(4 * BCD_DIGITS - 1 downto 0);
        done : out std_logic
    );
end bcd_converter;

architecture arch of bcd_converter is

    constant INPUT_WIDTH_LENGTH : integer := integer(ceil(log2(real(INPUT_WIDTH)))) + 1;

    constant LOW : std_logic := '0';

    type state_type is (S_IDLE, S_ADD, S_SHIFT, S_DONE);
    signal state : state_type := S_IDLE;

    signal binary_load : std_logic;
    signal binary_enable : std_logic;
    signal binary_shiftout : std_logic;

    signal bcd_internal : std_logic_vector(4 * BCD_DIGITS - 1 downto 0);
    signal bcd_sums : std_logic_vector(4 * BCD_DIGITS - 1 downto 0);
    signal bcd_shifts : std_logic_vector(0 to BCD_DIGITS);
    signal bcd_enables : std_logic_vector(0 to BCD_DIGITS - 1);
    signal bcd_load : std_logic;
    signal bcd_enable : std_logic;
    signal bcd_clr : std_logic;

    signal shift_count : std_logic_vector(INPUT_WIDTH_LENGTH - 1 downto 0);
    signal shift_count_clr : std_logic;
    signal shift_count_en : std_logic;
    signal shift_count_done : std_logic;

begin

    input_shiftreg : lpm_shiftreg
        generic map (
            LPM_WIDTH => INPUT_WIDTH,
            LPM_DIRECTION => "LEFT"
        )
        port map (
            clock => clock,
            aclr => reset,
            data => binary,
            load => binary_load,
            enable => binary_enable,
            shiftin => LOW,
            shiftout => binary_shiftout
        );

    shift_counter : lpm_counter
        generic map (LPM_WIDTH => INPUT_WIDTH_LENGTH)
        port map (
            clock => clock,
            aclr => reset,
            sclr => shift_count_clr,
            cnt_en => shift_count_en,
            q => shift_count
        );
    shift_count_done <= '1' when shift_count = std_logic_vector(to_unsigned(INPUT_WIDTH, INPUT_WIDTH_LENGTH)) else '0';

    gen_digits : for i in 0 to BCD_DIGITS - 1 generate
    
        digit_shiftreg : lpm_shiftreg
            generic map (
                LPM_WIDTH => 4,
                LPM_DIRECTION => "LEFT"
            )
            port map (
                clock => clock,
                aclr => reset,
                sclr => bcd_clr,
                data => bcd_sums(4 * i + 3 downto 4 * i),
                load => bcd_load,
                enable => bcd_enables(i),
                shiftin => bcd_shifts(i),
                shiftout => bcd_shifts(i+1),
                q => bcd_internal(4 * i + 3 downto 4 * i)
            );

        bcd_sums(4 * i + 3 downto 4 * i) <= std_logic_vector(unsigned(bcd_internal(4 * i + 3 downto 4 * i)) + x"3");
        bcd_enables(i) <= bcd_enable when (bcd_load = '0') or ((bcd_load = '1') and (bcd_internal(4 * i + 3 downto 4 * i) > x"4")) else '0';

    end generate;

    bcd_shifts(0) <= binary_shiftout;

    bcd <= bcd_internal;

    state_transitions : process (clock, reset)
    begin
        if (reset = '1') then
            state <= S_IDLE;
        elsif (rising_edge(clock)) then
            case state is
            when S_IDLE =>
                if (start = '1') then
                    state <= S_ADD;
                else
                    state <= S_IDLE;
                end if;
            when S_ADD =>
                if (shift_count_done = '1') then
                    state <= S_DONE;
                else
                    state <= S_SHIFT;
                end if;
            when S_SHIFT =>
                state <= S_ADD;
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

    outputs : process (state, start, shift_count_done)
    begin
        -- default outputs
        binary_load <= '0';
        binary_enable <= '0';
        bcd_clr <= '0';
        bcd_enable <= '0';
        bcd_load <= '0';
        shift_count_clr <= '0';
        shift_count_en <= '0';
        done <= '0';

        case state is
        when S_IDLE =>
            if (start = '1') then
                binary_enable <= '1';
                binary_load <= '1';
                bcd_enable <= '1';
                bcd_clr <= '1';
                shift_count_clr <= '1';
            end if;
        when S_ADD =>
            if (shift_count_done = '0') then
                bcd_enable <= '1';
                bcd_load <= '1';
            end if;
        when S_SHIFT =>
            binary_enable <= '1';
            bcd_enable <= '1';
            shift_count_en <= '1';
        when S_DONE =>
            done <= '1';
        when others =>
            null;
        end case;
    end process;

end architecture;
