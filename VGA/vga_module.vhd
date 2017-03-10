--------------------------------------------------------------------------------
--
--   FileName:         vga_timing_generator.vhd
--   Dependencies:     none
--   ZeYu.Yang
--   260447989
-- 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY vga_module IS
  GENERIC(
    h_pulse  :  INTEGER   := 512;   --horiztonal sync pulse width in pixels
    h_bp     :  INTEGER   := 64;   --horiztonal back porch width in pixels
    h_pixels :  INTEGER   := 120;  --horiztonal display width in pixels
    h_fp     :  INTEGER   := 56;   --horiztonal front porch width in pixels
	 h_pol    :  STD_LOGIC := '0';   --horizontal sync pulse polarity (1 = positive, 0 = negative)
    v_pulse  :  INTEGER   := 512;     --vertical sync pulse width in rows
    v_bp     :  INTEGER   := 23;    --vertical back porch width in rows
    v_pixels :  INTEGER   := 6;  --vertical display width in rows
    v_fp     :  INTEGER   := 37;
	 v_pol    :  STD_LOGIC := '1');  

  
  PORT(
	pixel_clk :  IN   STD_LOGIC;  --pixel clock at frequency of VGA mode being used
   reset_n   :  IN   STD_LOGIC;  --active low asycnchronous reset
   column    :  OUT  INTEGER;    --horizontal pixel coordinate
   row       :  OUT  INTEGER;    --vertical pixel coordinate
	h_sync    :  OUT  STD_LOGIC;  --horiztonal sync pulse
   v_sync    :  OUT  STD_LOGIC;  --vertical sync pulse
	blank  	 :  OUT  STD_LOGIC;  --direct blacking output
	dis_en    :  OUT  STD_LOGIC);  --display enable ('1' = display time, '0' = blanking time)
END vga_module;

ARCHITECTURE behavior OF vga_module IS
  CONSTANT  h_period  :  INTEGER := h_pulse + h_bp + h_pixels + h_fp;  --total number of pixel clocks in a row
  CONSTANT  v_period  :  INTEGER := v_pulse + v_bp + v_pixels + v_fp;  --total number of rows in column
  
BEGIN

  n_blank <= '1';  --no direct blanking
  
  PROCESS(pixel_clk, reset_n)
    VARIABLE h_count  :  INTEGER RANGE 0 TO h_period - 1 := 0;  --horizontal counter (counts the columns)
    VARIABLE v_count  :  INTEGER RANGE 0 TO v_period - 1 := 0;  --vertical counter (counts the rows)
  BEGIN
  
    IF(reset_n = '0') THEN  --reset asserted
      h_count := 0;         --reset horizontal counter
      v_count := 0;         --reset vertical counter
      h_sync <= NOT h_pol;  --deassert horizontal sync
      v_sync <= NOT v_pol;  --deassert vertical sync
      disp_ena <= '0';      --disable display
      column <= 0;          --reset column pixel coordinate
      row <= 0;             --reset row pixel coordinate
      
    ELSIF(pixel_clk'EVENT AND pixel_clk = '1') THEN

      --counters
      IF(h_count < h_period - 1) THEN    --horizontal counter (pixels)
        h_count := h_count + 1;
      ELSE
        h_count := 0;
        IF(v_count < v_period - 1) THEN  --veritcal counter (rows)
          v_count := v_count + 1;
        ELSE
          v_count := 0;
        END IF;
      END IF;

      --horizontal sync signal
      IF(h_count < h_pixels + h_fp OR h_count > h_pixels + h_fp + h_pulse) THEN
        h_sync <= NOT h_pol;    --deassert horiztonal sync pulse
      ELSE
        h_sync <= h_pol;        --assert horiztonal sync pulse
      END IF;
      
      --vertical sync signal
      IF(v_count < v_pixels + v_fp OR v_count > v_pixels + v_fp + v_pulse) THEN
        v_sync <= NOT v_pol;    --deassert vertical sync pulse
      ELSE
        v_sync <= v_pol;        --assert vertical sync pulse
      END IF;
      
      --set pixel coordinates
      IF(h_count < h_pixels) THEN  --horiztonal display time
        column <= h_count;         --set horiztonal pixel coordinate
      END IF;
      IF(v_count < v_pixels) THEN  --vertical display time
        row <= v_count;            --set vertical pixel coordinate
      END IF;

      --set display enable output
      IF(h_count < h_pixels AND v_count < v_pixels) THEN  --display time
        dis_en <= '1';                                  --enable display
      ELSE                                                --blanking time
        dis_en <= '0';                                  --disable display
      END IF;

    END IF;
  END PROCESS;

END behavior;
