library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library lpm;
use lpm.lpm_components.all;

entity vga_timing_generator is
    generic (
        H_PIXELS : integer   := 800; --horizontal display width in pixels
        H_PULSE  : integer   := 120; --horizontal sync pulse width in pixels
        H_FP     : integer   := 56; --horizontal front porch width in pixels
        H_BP     : integer   := 64; --horizontal back porch width in pixels
        H_POL    : std_logic := '1'; --horizontal sync pulse polarity (1 = positive, 0 = negative)
        V_PIXELS : integer   := 600; --vertical display width in rows
        V_PULSE  : integer   := 6; --vertical sync pulse width in rows
        V_FP     : integer   := 37;
        V_BP     : integer   := 23; --vertical back porch width in rows
        V_POL    : std_logic := '1'
    );
    port (
        clock   : in  std_logic; -- pixel clock at frequency of VGA mode being used
        reset   : in  std_logic; -- asynchronous reset
        row     : out integer range 0 to H_PIXELS - 1; -- vertical pixel coordinate
        column  : out integer range 0 to V_PIXELS - 1; -- horizontal pixel coordinate
        hsync   : out std_logic; -- horizontal sync pulse
        vsync   : out std_logic; -- vertical sync pulse
        blank_n : out std_logic -- active low blanking output
    );
end vga_timing_generator;

architecture behavior of vga_timing_generator is
    constant H_PERIOD  :  integer := H_PULSE + H_FP + H_PIXELS + H_BP;  --total number of pixel clocks in a row
    constant V_PERIOD  :  integer := V_PULSE + V_FP + V_PIXELS + V_BP;  --total number of rows in column

    constant H_BIT_LENGTH : integer := integer(ceil(log2(real(H_PERIOD))));
    constant V_BIT_LENGTH : integer := integer(ceil(log2(real(V_PERIOD))));
    
    
    signal h_count_internal : std_logic_vector(H_BIT_LENGTH - 1 downto 0);
    signal h_count : integer range 0 to H_PERIOD - 1;
    signal v_count_internal : std_logic_vector(V_BIT_LENGTH - 1 downto 0);
    signal v_count : integer range 0 to V_PERIOD - 1;
    signal count_en_v : std_logic;
    signal h_clr : std_logic;
    signal v_clr : std_logic;

begin

    h_count_internaler : lpm_counter
        generic map (LPM_WIDTH => H_BIT_LENGTH)
        port map (clock => clock, aclr => reset, sclr => h_clr, q => h_count_internal)
    h_count <= to_integer(unsigned(h_count_internal));
    
    with h_count select h_clr <=
        '1' when H_PERIOD - 1,
        '0' when others;

    v_count_internaler : lpm_counter
        generic map (LPM_WIDTH => V_BIT_LENGTH)
        port map (clock => clock, aclr => reset, sclr => v_clr, q => v_count_internal, cnt_en => count_en_v)
    v_count <= to_integer(unsigned(v_count_internal));

    with v_count select v_clr <=
	'1' when V_PERIOD - 1,
	'0' when others;
    with h_count select count_en_y <=
	'1' when H_PERIOD - 1,
	'0' when others;
  
    row <= to_unsigned(v_count - (V_PULSE + V_FP), 10) when (v_count >= V_PULSE + V_FP and v_count <= V_PIXELS + V_PULSE + V_FP) 
           else to_unsigned(599, 10);
    column <= to_unsigned(h_count - (H_PULSE + H_FP) , 10) when (h_count >= H_PULSE + H_FP and h_count <= H_PIXELS + H_PULSE + H_FP) 
           else to_unsigned(799, 10);
    blank_n <= '1' when ((v_count < V_PULSE + V_FP or v_count > V_PIXELS + V_PULSE + V_FP) or ((h_count < H_PULSE + H_FP or h_count > H_PIXELS + H_PULSE + H_FP))) 
           else '0';
	
    hsync <= '0' when (h_count < 120) else
		'1';
    vsync <= '0' when (v_count < 6) else
		'1';

end behavior;
