library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sampling_selector is
   port( clock                           :   in    std_logic; 
         enable                          :   in    std_logic; 
         reset                           :   in    std_logic; 
         upsample                        :   in std_logic_vector(2 downto 0);
         filter_in                       :   in    std_logic_vector(11 downto 0); -- input from reading by sinc_interpol, needs to add a 0 to MSB to make it sfix13,
         filter_out                      :   in   std_logic_vector(29 downto 0)  -- sfix30_En16 taken from Hlp, need to process it before giving to sinc_interpol
         write_data                      :   out std_logic_vector(WRITE_DATA_WIDTH - 1 downto 0)
         );

end sampling_selector;


