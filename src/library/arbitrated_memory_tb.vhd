library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbitrated_memory_tb is
end arbitrated_memory_tb;

architecture arch of arbitrated_memory_tb is

    component arbitrated_memory is
        generic (
            ADDR_WIDTH : integer := 4;
            DATA_WIDTH : integer := 8
        );
        port (
            clock : in std_logic;
            reset : in std_logic;
            -- write bus
            write_bus_acquire : in std_logic;
            write_address : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            write_en : in std_logic;
            write_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            write_bus_grant : out std_logic;
            -- read bus
            read_bus_acquire : in std_logic;
            read_address : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            read_bus_grant : out std_logic;
            read_data : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    procedure assert_equal(actual, expected : in std_logic_vector(7 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & integer'image(to_integer(unsigned(expected))) & " but was " & integer'image(to_integer(unsigned(actual))) severity error;
    end assert_equal;

    constant clock_period : time := 20 ns;

    signal clock : std_logic;
    signal reset : std_logic;

    signal write_bus_acquire : std_logic;
    signal write_address : std_logic_vector(3 downto 0);
    signal write_en : std_logic;
    signal write_data : std_logic_vector(7 downto 0);
    signal write_bus_grant : std_logic;

    signal read_bus_acquire : std_logic;
    signal read_address : std_logic_vector(3 downto 0);
    signal read_bus_grant : std_logic;
    signal read_data : std_logic_vector(7 downto 0);

begin

    dut : arbitrated_memory
        port map (
            clock => clock,
            reset => reset,
            write_bus_acquire => write_bus_acquire,
            write_address => write_address,
            write_en => write_en,
            write_data => write_data,
            write_bus_grant => write_bus_grant,
            read_bus_acquire => read_bus_acquire,
            read_address => read_address,
            read_bus_grant => read_bus_grant,
            read_data => read_data
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    test_process : process
        variable error_count : integer := 0;
    begin
        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';

        write_bus_acquire <= '0';
        write_address <= x"0";
        write_en <= '0';
        write_data <= x"00";
        read_bus_acquire <= '0';
        read_address <= x"0";

        write_bus_acquire <= '1';
        wait until write_bus_grant = '1';
        wait until rising_edge(clock);
        wait until falling_edge(clock);

        read_bus_acquire <= '1';

        write_en <= '1';

        write_address <= x"0";
        write_data <= x"80";
        wait for clock_period;

        write_address <= x"1";
        write_data <= x"90";
        wait for clock_period;

        write_address <= x"2";
        write_data <= x"A0";
        wait for clock_period;

        write_address <= x"3";
        write_data <= x"B0";
        wait for clock_period;

        write_bus_acquire <= '0';
        wait until read_bus_grant = '1';
        wait until rising_edge(clock);
        wait until falling_edge(clock);

        read_address <= x"3";
        wait for clock_period;

        read_address <= x"2";
        wait for clock_period;
        assert_equal(read_data, x"B0", error_count);

        read_address <= x"1";
        wait for clock_period;
        assert_equal(read_data, x"A0", error_count);

        read_address <= x"0";
        wait for clock_period;
        assert_equal(read_data, x"90", error_count);

        wait for clock_period;
        assert_equal(read_data, x"80", error_count);

        read_bus_acquire <= '0';

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture;
