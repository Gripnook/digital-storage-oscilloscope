library ieee;
library lpm;
use ieee.std_logic_1164.all;
use lpm.lpm_components.all;

entity vga_buffer is 
    generic (
        V_PIXELS : integer := 600;
        V_POL : std_logic := '0';
	DATA_WIDTH : integer;
	ADDR_WIDTH : integer
    );
    port (
	clock : in std_logic;
	reset : in  std_logic;
	read_bus_grant : in std_logic;
	read_data : in std_logic_vector(DATA_WIDTH - 1 downto 0)
        read_en : in  std_logic;
	address : in integer range 0 to ADDR_WIDTH - 1;
	column : in  integer range 0 to V_PIXELS - 1;  
        vsync : in  std_logic; 
        blank_n : in std_logic;
        row : out std_logic_vector(DATA_WIDTH - 1 downto 0); 
        row_nxt : out std_logic_vector(DATA_WIDTH - 1 downto 0) 
    );
end vga_buffer;

architecture arch of vga_buffer is

    type state_type is (BUFF_IDLE, BUS_ACQ, BUFF_READ, BUFF_WRITE);
    signal state : state_type := BUS_IDLE;
    signal addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal counter : integer range 0 to 511;
    signal cnt_en : std_logic;
    signal write_data : std_logic;
    signal read_bus_acquire : std_logic;

    begin

        state_transition : process (clock, reset)
        begin
            if (reset = '1') then 
                state <= BUFF_IDLE;
            elseif (rising_edge(clock)) then
                case state is  
                when BUF_IDLE =>
                    if (vsync = V_POL) then
                        state <= BUS_ACQ;
                    else 
                        state <= BUS_IDLE;
                    end if;
		--Acquiring bus for reading during vsync period
                when BUS_ACQ;
                     if (read_bus_grant = '1') then
                         state <= BUFF_READ;
                     else
                         state <= BUS_ACQ;
                     end if;
                 --Enable reading when read bus is granted
                 when BUFF_READ;
                      if (write_bus_grant = '1') then
                          state <= BUFF_WRITE;
                      else 
                          state <= BUFF_READ;
                      end if;
                 --Enable writing once vsync goes low
                 when BUFF_WRITE;
                      if (cnt_en = '1') then
                          if(counter = 511) then
                              state <= BUFF_IDLE;
                          else
                              state <= BUFF_READ;
                          end if;
                       else
                           state <= BUFF_WRITE;
                       end if;
                  when others =>
                       null;      
                  end case;
              end if;
        end process          
                       
    outputs : process (read_bus_acquire, row, row_nxt, addr, counter, cnt_en, write_data)
    begin
        -- default values
        row = '0';
        row_nxt = '0';
        addr <= (others => '0');
        counter <= '0';
        cnt_en <= '0';
        write_data <= '0';
        read_bus_acquire <= '0';

        case state is
        when BUFF_IDLE =>
            if (vsync = '1') then
                read_bus_acquire <= '1' ;
            end if;
        when BUS_ACQ =>
            addr <= address;
        when BUFF_READ =>
            --todo
        when BUFF_WRITE =>
            --todo
        when others =>
            null;
        end case;
    end process;

end architecture;


        