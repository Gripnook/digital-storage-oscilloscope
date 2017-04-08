library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package vga_parameters is

    constant FRAME_RATE : integer := 72; -- Hz
    constant DATA_UPDATE_RATE : integer := 4; -- Hz
    constant CLOCK_RATE : integer := 50000000; -- Hz

    constant H_PIXELS : integer   := 800; -- horizontal display width in pixels
    constant H_PULSE  : integer   := 120; -- horizontal sync pulse width in pixels
    constant H_BP     : integer   := 56;  -- horizontal back porch width in pixels
    constant H_FP     : integer   := 64;  -- horizontal front porch width in pixels
    constant H_POL    : std_logic := '1'; -- horizontal sync pulse polarity (1 = positive, 0 = negative)
    constant V_PIXELS : integer   := 600; -- vertical display width in rows
    constant V_PULSE  : integer   := 6;   -- vertical sync pulse width in rows
    constant V_BP     : integer   := 37;  -- vertical back porch width in rows
    constant V_FP     : integer   := 23;  -- vertical front porch width in rows
    constant V_POL    : std_logic := '1'; -- vertical sync pulse polarity (1 = positive, 0 = negative)

    constant H_PIXELS_BIT_LENGTH : integer := integer(ceil(log2(real(H_PIXELS))));
    constant V_PIXELS_BIT_LENGTH : integer := integer(ceil(log2(real(V_PIXELS))));

    constant TEXT_ROW_RANGE : integer := (V_PIXELS + 15) / 16;
    constant TEXT_COL_RANGE : integer := (H_PIXELS + 7) / 8;

    constant TEXT_ROW_BIT_LENGTH : integer := integer(ceil(log2(real(TEXT_ROW_RANGE))));
    constant TEXT_COL_BIT_LENGTH : integer := integer(ceil(log2(real(TEXT_COL_RANGE))));

    constant PLOT_WIDTH : integer := 512;
    constant PLOT_HEIGHT : integer := 512;

    constant PLOT_WIDTH_BIT_LENGTH : integer := integer(ceil(log2(real(PLOT_WIDTH))));
    constant PLOT_HEIGHT_BIT_LENGTH : integer := integer(ceil(log2(real(PLOT_HEIGHT))));

    -- start coordinates for the waveform plot (bottom-left corner)
    constant X0 : integer := 16;
    constant Y0 : integer := 16;

    constant GRID_WIDTH : integer := PLOT_WIDTH / 8;
    constant GRID_HEIGHT : integer := PLOT_HEIGHT / 8;

    constant GRID_WIDTH_BIT_LENGTH : integer := integer(ceil(log2(real(GRID_WIDTH))));
    constant GRID_HEIGHT_BIT_LENGTH : integer := integer(ceil(log2(real(GRID_HEIGHT))));

    constant X0_GRID_VECTOR : unsigned(GRID_WIDTH_BIT_LENGTH - 1 downto 0) := to_unsigned(X0, GRID_WIDTH_BIT_LENGTH);
    constant Y0_GRID_VECTOR : unsigned(GRID_HEIGHT_BIT_LENGTH - 1 downto 0) := to_unsigned(Y0, GRID_HEIGHT_BIT_LENGTH);

    constant TEXT_DISPLAY_WIDTH : integer := 32;

    constant TITLE_ROW : integer := 1;
    constant DISPLAY_ROW : integer := 8;

    constant BACKGROUND_COLOR : std_logic_vector(23 downto 0) := x"080808";
    constant GRID_COLOR : std_logic_vector(23 downto 0) := x"202020";
    constant WAVEFORM_COLOR : std_logic_vector(23 downto 0) := x"FFFF00";
    constant TRIGGER_COLOR : std_logic_vector(23 downto 0) := x"404070";
    constant TEXT_COLOR : std_logic_vector(23 downto 0) := x"FFFFFF";

end package;
