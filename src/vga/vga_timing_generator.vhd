library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use lpm.lpm_components.all;

entity vga_timing_generator is
    generic (
        H_PIXELS : integer; -- horizontal display width in pixels
        H_PULSE  : integer; -- horizontal sync pulse width in pixels
        H_BP     : integer; -- horizontal back porch width in pixels
        H_FP     : integer; -- horizontal front porch width in pixels
        H_POL    : std_logic; -- horizontal sync pulse polarity (1 = positive, 0 = negative)
        V_PIXELS : integer; -- vertical display width in rows
        V_PULSE  : integer; -- vertical sync pulse width in rows
        V_BP     : integer; -- vertical back porch width in rows
        V_FP     : integer; -- vertical front porch width in rows
        V_POL    : std_logic -- vertical sync pulse polarity (1 = positive, 0 = negative)
    );
    port (
        clock   : in  std_logic; -- pixel clock at frequency of VGA mode being used
        reset   : in  std_logic; -- asynchronous reset
        row     : out integer range 0 to V_PIXELS - 1; -- vertical pixel coordinate
        column  : out integer range 0 to H_PIXELS - 1; -- horizontal pixel coordinate
        hsync   : out std_logic; -- horizontal sync pulse
        vsync   : out std_logic; -- vertical sync pulse
        blank_n : out std_logic -- active low blanking output
    );
end vga_timing_generator;

architecture behavior of vga_timing_generator is

    constant H_PERIOD : integer := H_PULSE + H_BP + H_PIXELS + H_FP;  -- total number of pixel clocks in a row
    constant V_PERIOD : integer := V_PULSE + V_BP + V_PIXELS + V_FP;  -- total number of rows in column
    constant H_BIT_LENGTH : integer := integer(ceil(log2(real(H_PERIOD))));
    constant V_BIT_LENGTH : integer := integer(ceil(log2(real(V_PERIOD))));

    signal h_count_internal : std_logic_vector(H_BIT_LENGTH - 1 downto 0) := (others => '0');
    signal h_count : integer range 0 to H_PERIOD - 1;
    signal v_count_internal : std_logic_vector(V_BIT_LENGTH - 1 downto 0) := (others => '0');
    signal v_count : integer range 0 to V_PERIOD - 1;
    signal v_count_en : std_logic;
    signal h_clr : std_logic;
    signal v_clr : std_logic;

begin

    h_counter : lpm_counter
        generic map (LPM_WIDTH => H_BIT_LENGTH)
        port map (clock => clock, aclr => reset, sclr => h_clr, q => h_count_internal);
    h_count <= to_integer(unsigned(h_count_internal));

    h_clr <= '1' when (h_count = H_PERIOD - 1)
        else '0';

    v_counter : lpm_counter
        generic map (LPM_WIDTH => V_BIT_LENGTH)
        port map (clock => clock, aclr => reset, sclr => v_clr, q => v_count_internal, cnt_en => v_count_en);
    v_count <= to_integer(unsigned(v_count_internal));

    v_clr <= '1' when (v_count = V_PERIOD - 1)
        else '0';
    v_count_en <= h_clr;

    row <= (v_count - (V_PULSE + V_BP)) when (v_count >= V_PULSE + V_BP and v_count < V_PULSE + V_BP + V_PIXELS)
        else V_PIXELS - 1;
    column <= (h_count - (H_PULSE + H_BP)) when (h_count >= H_PULSE + H_BP and h_count < H_PULSE + H_BP + H_PIXELS)
        else H_PIXELS - 1;
    blank_n <= '0' when ((v_count < V_PULSE + V_BP or v_count >= V_PULSE + V_BP + V_PIXELS) or
                        ((h_count < H_PULSE + H_BP or h_count >= H_PULSE + H_BP + H_PIXELS)))
        else '1';

    hsync <= not H_POL when (h_count < H_PULSE) else
        H_POL;
    vsync <= not V_POL when (v_count < V_PULSE) else
        V_POL;

end behavior;
