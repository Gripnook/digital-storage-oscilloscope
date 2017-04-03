library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sampling_selector is

   generic (
        READ_DATA_WIDTH : integer := 12;
        WRITE_DATA_WIDTH : integer := 12
    );
    port( 
        clock : in std_logic; 
        enable : in std_logic; 
        reset :   in std_logic; 
        upsample : in std_logic_vector(2 downto 0);
        read_in : in std_logic_vector(READ_DATA_WIDTH - 1 downto 0); -- input from reading by sinc_interpol, needs to add a 0 to MSB to make it sfix13,
        write_out : out std_logic_vector(WRITE_DATA_WIDTH - 1 downto 0)  -- sfix30_En16 taken from Hlp processed to 12 bit before giving to sinc_interpol
    );

end sampling_selector;

architecture arch of sampling_selector is

    component Hlp2 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0);
            filter_out : out std_logic_vector(29 downto 0)
        );
    end component;

    component Hlp4 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0);
            filter_out : out std_logic_vector(29 downto 0)
        );
    end component;

    component Hlp8 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0);
            filter_out : out std_logic_vector(29 downto 0)
        );
    end component;

    component Hlp16 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0);
            filter_out : out std_logic_vector(29 downto 0)
        );
    end component;

    component Hlp32 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0);
            filter_out : out std_logic_vector(29 downto 0)
        );
    end component;
    signal filter_in : std_logic_vector(12 downto 0); 
    signal filter_out : std_logic_vector (29 downto 0); 
    signal hlp_enable : std_logic_vector (4 downto 0);


begin
    
    filter_2 : Hlp2
        port map (
            clock => clock,
            enable => hlp_enable(0),
            reset => reset,
            filter_in => filter_in,
            filter_out => filter_out            
        );

    filter_4 : Hlp4
        port map (
            clock => clock,
            enable => hlp_enable(1),
            reset => reset,
            filter_in => filter_in,
            filter_out => filter_out            
        );

    filter_8 : Hlp8
        port map (
            clock => clock,
            enable => hlp_enable(2),
            reset => reset,
            filter_in => filter_in,
            filter_out => filter_out            
        );

    filter_16 : Hlp16
        port map (
            clock => clock,
            enable => hlp_enable(3),
            reset => reset,
            filter_in => filter_in,
            filter_out => filter_out            
        );

    filter_32 : Hlp32
        port map (
            clock => clock,
            enable => hlp_enable(4),
            reset => reset,
            filter_in => filter_in,
            filter_out => filter_out            
        );
    ---decide which hlp to use
    select_hlp : process (clock, reset, upsample)
    begin
        if (reset = '1') then
            hlp_enable <= "00000";
        elsif (rising_edge(clock) and enable = '1') then  
            case upsample is 
                when "001" => hlp_enable <= "00001";
                when "010" => hlp_enable <= "00010";
                when "011" => hlp_enable <= "00100";
                when "100" => hlp_enable <= "01000";                
                when "101" => hlp_enable <= "10000";
                when others => hlp_enable <= "00000"; 
             end case;    
        end if;
    end process;

    --this process adds a '0' to the MSB of read_in for the hlp and trucate the decimal digits of the output for following modules
    signal_shifter : process (clock, reset, upsample)
    begin
        if (reset = '1') then
            write_out <= "000000000000";
        elsif (rising_edge(clock) and enable = '1') then
            filter_in <= (12 downto read_in'length => '0') & read_in; ---add leading 0s according to the length of read_in
            case upsample is 
                when "001" => write_out <= filter_out sll 1 (29 downto 19); --problem here, my intention was to shift the input according to the sampling rate, then truncate the least significant bits (16 bits are after decimal point)
                when "010" => write_out <= filter_out sll 2 (29 downto 19); --but it gives me compile errors.
                when "011" => write_out <= filter_out sll 3 (29 downto 19);
                when "100" => write_out <= filter_out sll 4 (29 downto 19);                
                when "101" => write_out <= filter_out sll 5 (29 downto 19);
                when others => write_out <= read_in; --when hlp is not enabled, take input directly without processing
                                                     --may need to add buffer for consistent timing.
             end case; 
        end if;
    end process;

end architecture;