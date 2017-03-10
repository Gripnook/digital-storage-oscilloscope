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


  n_blank <= '1';  --no direct blanking
  
  process (clock, reset_n)
    variable h_count_internal  :  integer range 0 to H_PERIOD - 1 := 0;  --horizontal counter (counts the columns)
    variable v_count_internal  :  integer range 0 to V_PERIOD - 1 := 0;  --vertical counter (counts the rows)
  begin
  
    if (reset_n = '0') then  --reset asserted
      h_count_internal := 0;         --reset horizontal counter
      v_count_internal := 0;         --reset vertical counter
      hsync <= not H_POL;  --deassert horizontal sync
      vsync <= not V_POL;  --deassert vertical sync
      disp_ena <= '0';      --disable display
      column <= 0;          --reset column pixel coordinate
      row <= 0;             --reset row pixel coordinate
      
    elsif (rising_edge(clock)) then

      --counters
      if (h_count_internal < H_PERIOD - 1) then    --horizontal counter (pixels)
        h_count_internal := h_count_internal + 1;
      else
        h_count_internal := 0;
        if(v_count_internal < V_PERIOD - 1) then  --veritcal counter (rows)
          v_count_internal := v_count_internal + 1;
        else
          v_count_internal := 0;
        end if;
      end if;

      --horizontal sync signal
      if(h_count_internal < H_PIXELS + H_FP or h_count_internal > H_PIXELS + H_FP + H_PULSE) then
        hsync <= not H_POL;    --deassert horiztonal sync pulse
      else
        hsync <= H_POL;        --assert horiztonal sync pulse
      end if;
      
      --vertical sync signal
      if(v_count_internal < V_PIXELS + V_FP or v_count_internal > V_PIXELS + V_FP + V_PULSE) then
        vsync <= not V_POL;    --deassert vertical sync pulse
      else
        vsync <= V_POL;        --assert vertical sync pulse
      end if;
      
      --set pixel coordinates
      if(h_count_internal < H_PIXELS) then  --horiztonal display time
        column <= h_count_internal;         --set horiztonal pixel coordinate
      end if;
      if(v_count_internal < V_PIXELS) then  --vertical display time
        row <= v_count_internal;            --set vertical pixel coordinate
      end if;

      --set display enable output
      if(h_count_internal < H_PIXELS and v_count_internal < V_PIXELS) then  --display time
        blank_n <= '1';                                  --enable display
      else                                                --blanking time
        blank_n <= '0';                                  --disable display
      end if;

    end if;
  end process;

end behavior;
