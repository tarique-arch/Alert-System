library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity uart_rx is
    port(
        clk : in std_logic; -- 50MHz clock
        rstn : in std_logic; -- Reset (active high)
        rx : in std_logic; -- UART input (from PC)
       
        data_out : out std_logic_vector(7 downto 0); -- Received byte
        data_ready : out std_logic; -- 1-clock pulse
        framing_error : out std_logic -- High if stop bit invalid
    );
end uart_rx;
architecture Behavioral of uart_rx is
    -- UART parameters
    constant BAUD_RATE : integer := 9600;
    constant CLK_FREQ : integer := 50000000;
    constant TICKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
   
    -- Receiver states
    type rx_state_type is (IDLE, START_BIT, RECEIVE_BITS, STOP_BIT);
    signal state : rx_state_type := IDLE;
   
    -- Synchronizer for metastability protection
    signal rx_sync : std_logic_vector(1 downto 0) := "11";
   
    -- Internal signals
    signal bit_index : integer range 0 to 7 := 0;
    signal tick_count : integer := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
   
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Synchronizer for external rx signal (metastability protection)
            rx_sync <= rx_sync(0) & rx;
           
            if rstn = '0' then
                -- Reset all signals
                state <= IDLE;
                data_ready <= '0';
                framing_error <= '0';
                tick_count <= 0;
                bit_index <= 0;
                shift_reg <= (others => '0');
               
            else
                -- Default: outputs are low each clock
                data_ready <= '0';
                framing_error <= '0';
               
                case state is
                    ----------------------------------------------------------
                    -- IDLE: WAIT FOR START BIT (line goes LOW)
                    ----------------------------------------------------------
                    when IDLE =>
                        if rx_sync(1) = '0' then -- detect start bit
                            tick_count <= TICKS_PER_BIT/2; -- sample in middle
                            state <= START_BIT;
                        end if;
                   
                    ----------------------------------------------------------
                    -- START_BIT: SAMPLE START BIT AT MIDDLE
                    ----------------------------------------------------------
                    when START_BIT =>
                        if tick_count = 0 then
                            if rx_sync(1) = '0' then -- valid start bit
                                tick_count <= TICKS_PER_BIT;
                                bit_index <= 0;
                                state <= RECEIVE_BITS;
                            else -- false start
                                state <= IDLE;
                            end if;
                        else
                            tick_count <= tick_count - 1;
                        end if;
                   
                    ----------------------------------------------------------
                    -- RECEIVE_BITS: RECEIVE 8 DATA BITS (LSB first)
                    ----------------------------------------------------------
                    when RECEIVE_BITS =>
                        if tick_count = 0 then
                            shift_reg(bit_index) <= rx_sync(1); -- sample bit
                           
                            if bit_index = 7 then -- received all 8 bits
                                state <= STOP_BIT;
                                tick_count <= TICKS_PER_BIT;
                            else
                                bit_index <= bit_index + 1;
                                tick_count <= TICKS_PER_BIT;
                            end if;
                        else
                            tick_count <= tick_count - 1;
                        end if;
                   
                    ----------------------------------------------------------
                    -- STOP_BIT: CHECK STOP BIT, OUTPUT DATA
                    ----------------------------------------------------------
                    when STOP_BIT =>
                        if tick_count = 0 then
                            if rx_sync(1) = '1' then -- valid stop bit
                                data_out <= shift_reg;
                                data_ready <= '1'; -- 1-clock pulse (valid data)
                            else -- invalid stop bit
                                framing_error <= '1'; -- 1-clock pulse (error)
                            end if;
                            state <= IDLE;
                        else
                            tick_count <= tick_count - 1;
                        end if;
                       
                end case;
            end if;
        end if;
    end process;
end Behavioral;
