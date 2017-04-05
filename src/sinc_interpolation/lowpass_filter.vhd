library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lowpass_filter is
    generic (MAX_UPSAMPLE : integer);
    port (
        clock : in std_logic;
        enable : in std_logic;
        reset : in std_logic;
        upsample : in integer range 0 to MAX_UPSAMPLE; -- upsampling rate is 2 ** upsample
        filter_in : in std_logic_vector(11 downto 0);
        filter_out : out std_logic_vector(11 downto 0)
    );
end lowpass_filter;

architecture arch of lowpass_filter is

    component Hlp2 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0); -- sfix13
            filter_out : out std_logic_vector(29 downto 0) -- sfix30_En16
        );
    end component;

    component Hlp4 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0); -- sfix13
            filter_out : out std_logic_vector(30 downto 0) -- sfix31_En17
        );
    end component;

    component Hlp8 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0); -- sfix13
            filter_out : out std_logic_vector(31 downto 0) -- sfix32_En18
        );
    end component;

    component Hlp16 is
        port (
            clock : in std_logic;
            enable : in std_logic;
            reset : in std_logic;
            filter_in : in std_logic_vector(12 downto 0); -- sfix13
            filter_out : out std_logic_vector(32 downto 0) -- sfix33_En19
        );
    end component;

    signal filter_in_internal : std_logic_vector(12 downto 0); -- sfix13

    signal filter_out_1 : std_logic_vector(11 downto 0);
    signal filter_out_2 : std_logic_vector(29 downto 0); -- sfix30_En16
    signal filter_out_4 : std_logic_vector(30 downto 0); -- sfix31_En17
    signal filter_out_8 : std_logic_vector(31 downto 0); -- sfix32_En18
    signal filter_out_16 : std_logic_vector(32 downto 0); -- sfix33_En19

begin

    filter_1 : process (clock, reset)
    begin
        if (reset = '1') then
            filter_out_1 <= (others => '0');
        elsif (rising_edge(clock)) then
            if (enable = '1') then
                filter_out_1 <= filter_in;
            end if;
        end if;
    end process;

    filter_2 : Hlp2
        port map (
            clock => clock,
            enable => enable,
            reset => reset,
            filter_in => filter_in_internal,
            filter_out => filter_out_2
        );

    filter_4 : Hlp4
        port map (
            clock => clock,
            enable => enable,
            reset => reset,
            filter_in => filter_in_internal,
            filter_out => filter_out_4
        );

    filter_8 : Hlp8
        port map (
            clock => clock,
            enable => enable,
            reset => reset,
            filter_in => filter_in_internal,
            filter_out => filter_out_8
        );

    filter_16 : Hlp16
        port map (
            clock => clock,
            enable => enable,
            reset => reset,
            filter_in => filter_in_internal,
            filter_out => filter_out_16
        );

    filter_in_internal <= '0' & filter_in;

    output_mux : process (upsample, filter_out_1, filter_out_2, filter_out_4, filter_out_8, filter_out_16)
    begin
        -- default output
        filter_out <= filter_out_1;
        
        case upsample is
        when 1 =>
            filter_out <= filter_out_2(26 downto 15);
        when 2 =>
            filter_out <= filter_out_4(26 downto 15);
        when 3 =>
            filter_out <= filter_out_8(26 downto 15);
        when 4 =>
            filter_out <= filter_out_16(26 downto 15);
        when others =>
            null;
        end case;
    end process;

end architecture;
