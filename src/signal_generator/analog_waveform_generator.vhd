-- Implements a basic analog sine wave generator. The output of the frequency synthesizer is
-- used as an enable signal to a counter which controls the output of a ROM. The ROM
-- stores precomputed value for a shifted sine wave. The update signal must be asserted for
-- N clock cycles when changing the frequency_control input in order to avoid phase discontinuity.
-- 
-- The output frequency is related to frequency_control and the clock rate by
-- output frequency = 1/100 * frequency_control * clock_rate / 2 ** N

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use lpm.lpm_components.all;

entity analog_waveform_generator is
    generic (N : integer);
    port (
        clock : in std_logic;
        reset : in std_logic;
        update : in std_logic;
        frequency_control : in std_logic_vector(N-1 downto 0);
        analog_waveform : out std_logic_vector(7 downto 0)
    );
end analog_waveform_generator;

architecture arch of analog_waveform_generator is

    component pipelined_frequency_synthesizer is
        generic (N : integer);
        port (
            clock : in std_logic;
            reset : in std_logic;
            update : in std_logic;
            frequency_control : in std_logic_vector(N-1 downto 0);
            frequency : out std_logic
        );
    end component;

    constant ROM_SIZE : integer := 100;
    constant ROM_SIZE_WIDTH : integer := integer(ceil(log2(real(ROM_SIZE))));

    signal frequency : std_logic;
    signal count : std_logic_vector(ROM_SIZE_WIDTH - 1 downto 0);

begin

    synthesizer : pipelined_frequency_synthesizer
        generic map (N => N)
        port map (
            clock => clock,
            reset => reset,
            update => update,
            frequency_control => frequency_control,
            frequency => frequency
        );

    counter : lpm_counter
        generic map (
            LPM_WIDTH => ROM_SIZE_WIDTH,
            LPM_MODULUS => ROM_SIZE
        )
        port map (
            clock => clock,
            aclr => reset,
            cnt_en => frequency,
            q => count
        );

    rom : lpm_rom
        generic map (
            LPM_WIDTH => 8,
            LPM_WIDTHAD => ROM_SIZE_WIDTH,
            LPM_NUMWORDS => ROM_SIZE,
            LPM_FILE => "signal_generator/waveform.mif"
        )
        port map (
            address => count,
            inclock => clock,
            outclock => clock,
            q => analog_waveform
        );

end architecture;
