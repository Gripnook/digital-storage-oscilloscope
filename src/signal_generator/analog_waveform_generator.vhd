-- Implements a basic analog sine wave generator. The output of the frequency synthesizer is
-- used as an enable signal to a counter which controls the output of a ROM. The ROM
-- stores precomputed value for a shifted sine wave. The update signal must be asserted for
-- N clock cycles when changing the frequency_control input in order to avoid phase discontinuity.
-- 
-- The output frequency is related to frequency_control and the clock rate by
-- output frequency = 1/10 * frequency_control * clock_rate / 2 ** N

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity analog_waveform_generator is
    generic (N : integer := 5);
    port (clock : in std_logic;
          reset : in std_logic;
          update : in std_logic;
          frequency_control : in std_logic_vector(N-1 downto 0);
          analog_waveform : out std_logic_vector(7 downto 0));
end analog_waveform_generator;

architecture arch of analog_waveform_generator is

    component pipelined_frequency_synthesizer is
        generic (N : integer := 5);
        port (clock : in std_logic;
              reset : in std_logic;
              update : in std_logic;
              frequency_control : in std_logic_vector(N-1 downto 0);
              frequency : out std_logic);
    end component;

    -- MATLAB generated sine wave (shifted to range [0, 256))
    -- t = 0:9;
    -- sine = ( 128 * ( sin(2*pi/10*t) + 1 ) );
    type rom is array(0 to 9) of std_logic_vector(7 downto 0);
    constant sine_wave : rom := (
        "10000000", "11001011",
        "11111010", "11111010",
        "11001011", "10000000",
        "00110101", "00000110",
        "00000110", "00110101");

    signal frequency : std_logic;
    signal cnt : unsigned(3 downto 0);

begin

    synthesizer : pipelined_frequency_synthesizer
    generic map (N => N)
    port map (clock => clock,
              reset => reset,
              update => update,
              frequency_control => frequency_control,
              frequency => frequency);

    counter : process (clock, reset)
    begin
        if (reset = '1') then
            cnt <= (others => '0');
        elsif (rising_edge(clock)) then
            -- frequency acts as an enable signal
            if (frequency = '1') then
                if (cnt = x"9") then
                    cnt <= (others => '0');
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

    analog_waveform <= sine_wave(to_integer(unsigned(cnt)));

end architecture;
