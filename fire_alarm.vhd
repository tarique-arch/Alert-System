library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fire_alarm is
    port (
        CLOCK_50 : in  std_logic;                      -- 50 MHz board clock
        reset_n  : in  std_logic;
        SW       : in  std_logic_vector(3 downto 0);
        LED      : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of fire_alarm is

    constant CLK_1HZ_DIV   : integer := 5_000_000;

    signal clk_1hz, clk_2hz, clk_3hz, clk_4hz      : std_logic := '0';    
    signal tick            : std_logic := '0';     --Animation tick (speed depends on mode)

    signal poss             : integer range 0 to 9 := 0;
    signal direction       : std_logic := '1';     -- '1' = right, '0' = left
	 
	 signal counter_4hz     : integer range 0 to CLK_1HZ_DIV-1 := 0;
    signal counter_1hz     : integer range 0 to CLK_1HZ_DIV-1 := 0;
	 signal counter_2hz     : integer range 0 to CLK_1HZ_DIV-1 := 0;
	 signal counter_3hz     : integer range 0 to CLK_1HZ_DIV-1 := 0;
    signal mode_counter    : integer range 0 to 31 := 0;   --For variable speed
	 
	 signal clk_1hz_prev, clk_2hz_prev, clk_3hz_prev, clk_4hz_prev : std_logic;
  	 signal clk_1hz_tick, clk_2hz_tick, clk_3hz_tick, clk_4hz_tick : std_logic;

begin
	 -- Detect rising edges
	clk_1hz_tick <= clk_1hz and not clk_1hz_prev;
	clk_2hz_tick <= clk_2hz and not clk_2hz_prev;
	clk_3hz_tick <= clk_3hz and not clk_3hz_prev;
	clk_4hz_tick <= clk_4hz and not clk_4hz_prev;
	
	-- Assign tick based on current mode
    with SW select tick <=
        clk_4hz_tick when "1000",
        clk_1hz_tick     when "0100",
        clk_2hz_tick     when "0010",
        clk_3hz_tick     when "0001",
        '0'              when others;

    process(CLOCK_50, reset_n)
    begin
        if reset_n = '0' then
            counter_1hz <= 0;
            counter_2hz <= 0;
            counter_3hz <= 0;
            counter_4hz <= 0;
            clk_1hz     <= '0';
            clk_2hz     <= '0';
            clk_3hz     <= '0';
            clk_4hz <= '0';
            clk_1hz_prev <= '0';
            clk_2hz_prev <= '0';
            clk_3hz_prev <= '0';
            clk_4hz_prev <= '0';
        elsif rising_edge(CLOCK_50) then
			   clk_1hz_prev <= clk_1hz;
            clk_2hz_prev <= clk_2hz;
            clk_3hz_prev <= clk_3hz;
            clk_4hz_prev <= clk_4hz;
			  
            if counter_1hz = CLK_1HZ_DIV/3 - 1 then
                counter_1hz <= 0;
                clk_1hz     <= not clk_1hz;  
				else
					counter_1hz <= counter_1hz + 1;
					end if; 
				if counter_2hz = CLK_1HZ_DIV/2 - 1 then
                counter_2hz <= 0;
                clk_2hz     <= not clk_2hz;
				else
					counter_2hz <= counter_2hz + 1;
					 end if;
			   if counter_3hz = CLK_1HZ_DIV/6 - 1 then
                counter_3hz <= 0;
                clk_3hz     <= not clk_3hz;
				else
					counter_3hz <= counter_3hz + 1;
					 end if;
			   if counter_4hz = CLK_1HZ_DIV/8 - 1 then
                counter_4hz <= 0;
                clk_4hz     <= not clk_4hz;
				else 
					counter_4hz <= counter_4hz + 1;
					end if;	 
            
        end if;
    end process;



    -- Animation engine (runs only on 'tick')
    process(CLOCK_50, reset_n)
    begin
        if reset_n = '0' then
            poss       <= 0;
            direction <= '1';
        elsif rising_edge(CLOCK_50) then
            if tick = '1' then

                case SW is
                    when "1000" =>  -- EXPLOSION: cycles 0→9→0
    if poss = 9 then 
        poss <= 0;
    else 
        poss <= poss + 1; 
    end if;

                    when "0100" =>  -- Knight Rider scanner
                        if direction = '1' then
                            if poss = 9 then direction <= '0'; poss <= 8;
                            else poss <= poss + 1; end if;
                        else
                            if poss = 0 then direction <= '1';
                            else poss <= poss - 1; end if;
                        end if;

                    when "0010" =>  -- Smooth 3-LED wave
                        if direction = '1' then
                            if poss >= 7 then direction <= '0';
                            else poss <= poss + 1; end if;
                        else
                            if poss <= 2 then direction <= '1';
                            else poss <= poss - 1; end if;
                        end if;

                    when "0001" =>  -- SPARKLE: cycles 0→9→0
    if poss = 9 then 
        poss <= 0;
    else 
        poss <= poss + 1; 
    end if;

                    when others =>
                        poss <= 0;
                        direction <= '1';
                end case;
            end if;
        end if;
    end process;

    -- LED pattern output


        -- LED pattern output - CRAZY ANIMATIONS
process(poss, SW)
begin
    LED <= (others => '0');

    case SW is
        when "1000" =>  -- EXPLOSION: Expand from center then collapse
            case poss is
                when 0 => LED <= "0000110000";  -- Center 2 LEDs
                when 1 => LED <= "0001111000";  -- Expand
                when 2 => LED <= "0011111100";  -- Expand more
                when 3 => LED <= "0111111110";  -- Almost full
                when 4 => LED <= "1111111111";  -- FULL BLAST
                when 5 => LED <= "0111111110";  -- Collapse
                when 6 => LED <= "0011111100";  
                when 7 => LED <= "0001111000";
                when 8 => LED <= "0000110000";
                when 9 => LED <= "0000000000";  -- Dark
                when others => LED <= "0000000000";
            end case;

        when "0100" =>  -- ALTERNATING CHASE: Odd/Even LEDs alternate
            if direction = '1' then
                LED <= "1010101010";  -- Odd LEDs
            else
                LED <= "0101010101";  -- Even LEDs
            end if;

        when "0010" =>  -- SNAKE: Single bright LED with fading tail
            LED(poss) <= '1';  -- Head (brightest)
            if poss > 0 then LED(poss-1) <= '1'; end if;  -- Tail segment 1
            if poss > 1 then LED(poss-2) <= '1'; end if;  -- Tail segment 2
            if poss > 2 then LED(poss-3) <= '1'; end if;  -- Tail segment 3
            if poss > 3 then LED(poss-4) <= '1'; end if;  -- Tail segment 4
            if poss > 4 then LED(poss-5) <= '1'; end if;  -- Long tail!

        when "0001" =>  -- RANDOM SPARKLE: Different pattern each position
            case poss is
                when 0 => LED <= "1000000001";
                when 1 => LED <= "0100000010";
                when 2 => LED <= "0010000100";
                when 3 => LED <= "0001001000";
                when 4 => LED <= "0000110000";
                when 5 => LED <= "0001001000";
                when 6 => LED <= "0010000100";
                when 7 => LED <= "0100000010";
                when 8 => LED <= "1000000001";
                when 9 => LED <= "0000000000";
                when others => LED <= "0000000000";
            end case;

        when others =>
            LED <= "1000000001";  -- Corners when idle
    end case;
end process;

end rtl;
