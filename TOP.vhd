library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP is
    port (
        CLOCK_50  : in  std_logic;
        reset_n   : in  std_logic;
        VGA_R     : out std_logic_vector(2 downto 0);
        VGA_G     : out std_logic_vector(2 downto 0);
        VGA_B     : out std_logic_vector(1 downto 0);
        VGA_HS    : out std_logic;
        VGA_VS    : out std_logic;
        SW1       : in  std_logic;
        SW2       : in  std_logic;
        LED       : out std_logic_vector(9 downto 0);
        UART_RX   : in  std_logic
    );
end entity;

architecture rtl of TOP is

    signal clk_25mhz      : std_logic;
    signal pll_locked     : std_logic;
    signal reset_sync     : std_logic;
    signal hsync, vsync   : std_logic;
    signal display_en     : std_logic;
    signal pixel_x, pixel_y : unsigned(9 downto 0);
    signal pixel_data_1   : std_logic_vector(7 downto 0);
    signal pixel_data_2   : std_logic_vector(7 downto 0);
    signal fb_x           : unsigned(7 downto 0);
    signal fb_y           : unsigned(7 downto 0);
    
    signal uart_data      : std_logic_vector(7 downto 0);
    signal uart_ready     : std_logic;
    signal uart_error     : std_logic;
    
    signal tb_w_addr      : integer range 0 to 2399;
    signal tb_r_addr      : integer range 0 to 2399;
    signal cursor_pos     : integer range 0 to 2399 := 0;
    
    -- Command signals from text buffer
    signal cmd_led_sw     : std_logic_vector(3 downto 0);
    signal cmd_fire       : std_logic;
    signal cmd_flood      : std_logic;
    
    -- Combined VGA control
    signal show_fire      : std_logic;
    signal show_flood     : std_logic;

begin

    -- PLL: 50 MHz → 25 MHz
    pll_inst : entity work.clk
        port map (
            inclk0 => CLOCK_50,
            c0     => clk_25mhz,
            locked => pll_locked
        );

    -- Reset synchronizer
	 
    process (clk_25mhz, reset_n)
    begin
        if reset_n = '0' then
            reset_sync <= '0';
        elsif rising_edge(clk_25mhz) then
            if pll_locked = '1' then
                reset_sync <= '1';
            end if;
        end if;
    end process;


    -- UART Receiver

    uart_rx_inst : entity work.uart_rx
        port map (
            clk           => CLOCK_50,
            rstn           => reset_n,
            rx            => UART_RX,
            data_out      => uart_data,
            data_ready    => uart_ready,
            framing_error => uart_error
        );

    -- UART to Text Buffer Writer
	 
    process(CLOCK_50, reset_n)
    begin
        if reset_n = '0' then
            cursor_pos <= 0;
        elsif rising_edge(CLOCK_50) then
            
            if uart_ready = '1' then
                tb_w_addr <= cursor_pos;
                
                if uart_data = x"0D" then  -- Enter
                    cursor_pos <= ((cursor_pos / 80) + 1) * 80;
                elsif uart_data = x"08" then  -- Backspace
                    if cursor_pos > 0 then
                        cursor_pos <= cursor_pos - 1;
                    end if;
                else  -- Normal character
                    if cursor_pos < 2399 then
                        cursor_pos <= cursor_pos + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Text Buffer with Command Detection
	 
    text_buffer_inst : entity work.text_buffer
        port map (
            clk25     => clk_25mhz,
				rstn      => reset_n,
            w_addr    => tb_w_addr,
            w_data    => uart_data,
            r_addr    => tb_r_addr,
            r_data    => open,
            led_sw    => cmd_led_sw,
            vga_fire  => cmd_fire,
            vga_flood => cmd_flood
        );

    -- LED Pattern Control (fire_alarm)
    
    fire_alert : entity work.fire_alarm
        port map(
            CLOCK_50 => CLOCK_50,
            reset_n  => reset_n,
            SW       => cmd_led_sw,
            LED      => LED
        );

    -- VGA Image Control (Manual switches + UART commands)
	 
    show_fire  <= SW1 or cmd_fire;
    show_flood <= SW2 or cmd_flood;

    vga_timing_inst : entity work.vga_timing
        port map (
            clk_25mhz  => clk_25mhz,
            reset_n    => reset_sync,
            hsync      => hsync,
            vsync      => vsync,
            display_en => display_en,
            pixel_x    => pixel_x,
            pixel_y    => pixel_y
        );

    -- Integer scaling (240×160 → 640×480)
    
    fb_x <= to_unsigned((to_integer(pixel_x) * 240) / 640, 8);
    fb_y <= to_unsigned((to_integer(pixel_y) * 160) / 480, 8);

    -- Image ROM (MIF file)
    rom_inst_1 : entity work.fire
        port map (
            clock   => clk_25mhz,
            address => std_logic_vector(
                           to_unsigned(to_integer(fb_y) * 240 + to_integer(fb_x), 16)
                       ),
            q       => pixel_data_1
        );
     
    rom_inst_2 : entity work.flood
        port map (
            clock   => clk_25mhz,
            address => std_logic_vector(
                           to_unsigned(to_integer(fb_y) * 240 + to_integer(fb_x), 16)
                       ),
            q       => pixel_data_2
        );
          
    process (clk_25mhz)
    begin
        if rising_edge(clk_25mhz) then
            if display_en = '1' and show_fire = '1' then
                VGA_R <= pixel_data_1(7 downto 5);
                VGA_G <= pixel_data_1(4 downto 2);
                VGA_B <= pixel_data_1(1 downto 0);
            elsif display_en = '1' and show_flood = '1' then
                VGA_R <= pixel_data_2(7 downto 5);
                VGA_G <= pixel_data_2(4 downto 2);
                VGA_B <= pixel_data_2(1 downto 0);
            else
                VGA_R <= (others => '0');
                VGA_G <= (others => '0');
                VGA_B <= (others => '0');
            end if;
        end if;
    end process;

    VGA_HS <= hsync;
    VGA_VS <= vsync;

end architecture;
