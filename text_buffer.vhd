library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity text_buffer is
    port (
        clk25     : in  std_logic;
		  rstn      : in  std_logic;
        w_addr    : in  integer range 0 to 2399;
        w_data    : in  std_logic_vector(7 downto 0);
        r_addr    : in  integer range 0 to 2399;
        r_data    : out std_logic_vector(7 downto 0);
        led_sw    : out std_logic_vector(3 downto 0);
        vga_fire  : out std_logic;
        vga_flood : out std_logic
    );
end text_buffer;

architecture rtl of text_buffer is
    type ram_type is array (0 to 2399) of std_logic_vector(7 downto 0);
    signal ram : ram_type := (others => x"20");
    
    signal last_char : std_logic_vector(7 downto 0) := x"20";
    signal led_cmd   : std_logic_vector(3 downto 0) := "0000";
    signal fire_cmd  : std_logic := '0';
    signal flood_cmd : std_logic := '0';

    
begin

    -- Output command signals
    led_sw <= led_cmd;
    vga_fire <= fire_cmd;
    vga_flood <= flood_cmd;
    
    process(clk25)
    begin
	     if rstn = '0' then
            -- Reset to idle state
            last_char <= x"20";
            led_cmd <= "0000";
            fire_cmd <= '0';
            flood_cmd <= '0';
        elsif rising_edge(clk25) then
            -- Write to RAM
            --if we = '1' then
                ram(w_addr) <= w_data;
                
                -- Command detection on Enter key
                if w_data = x"0D" then  -- Enter pressed
                    case last_char is
                        when x"41" | x"61" =>  -- 'A' or 'a'
                            led_cmd <= "1000";
                        when x"42" | x"62" =>  -- 'B' or 'b'
                            led_cmd <= "0100";
                        when x"43" | x"63" =>  -- 'C' or 'c'
                            led_cmd <= "0010";
                        when x"44" | x"64" =>  -- 'D' or 'd'
                            led_cmd <= "0001";
                        
                        -- VGA Image Commands
                        when x"46" =>  -- 'F' (uppercase) - FIRE
                            fire_cmd <= '1';
                            flood_cmd <= '0';
                        when x"66" =>  -- 'f' (lowercase) - FLOOD
                            fire_cmd <= '0';
                            flood_cmd <= '1';
                        
                        when others =>
                            null;  -- Keep current state
                    end case;
                else
                    -- Store character for next command
                    last_char <= w_data;
                end if;
            
            -- Read from RAM
            r_data <= ram(r_addr);
        end if;
    end process;


    
end rtl;
