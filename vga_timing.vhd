library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_timing is
    
    PORT(clk_25mhz    : in  std_logic;  
        reset_n      : in  std_logic;  
        hsync        : out std_logic;
        vsync        : out std_logic;
        display_en   : out std_logic;   
        pixel_x      : out unsigned(9 downto 0);  
        pixel_y      : out unsigned(9 downto 0)   
    );
end entity;

architecture rtl of vga_timing is

    -- Horizontal timing constants
    constant H_VISIBLE  : integer := 640;-- visble region start from 0 pixel 
    constant H_FRONT    : integer := 16;
    constant H_SYNC     : integer := 96;
    constant H_BACK     : integer := 48;
    constant H_TOTAL    : integer := H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    -- Vertical timing constants
    constant V_VISIBLE  : integer := 480;
    constant V_FRONT    : integer := 10;
    constant V_SYNC     : integer := 2;
    constant V_BACK     : integer := 33;
    constant V_TOTAL    : integer := V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

   
    signal h_count : integer range 0 to H_TOTAL-1 := 0;
    signal v_count : integer range 0 to V_TOTAL-1 := 0;

begin

    
    process (clk_25mhz, reset_n)
    begin
        if reset_n = '0' then
            h_count <= 0;
            v_count <= 0;
        elsif rising_edge(clk_25mhz) then
            if h_count = H_TOTAL - 1 then
                h_count <= 0;
                if v_count = V_TOTAL - 1 then
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;
    -- HSYNC VSYNC ARE ACTIVE LOW 

    hsync <= '0' when (h_count >= (H_VISIBLE + H_FRONT) and
                       h_count <  (H_VISIBLE + H_FRONT + H_SYNC))
             else '1';

    vsync <= '0' when (v_count >= (V_VISIBLE + V_FRONT) and
                       v_count <  (V_VISIBLE + V_FRONT + V_SYNC))
             else '1';

    
    -- DISPLAY_EN MEAN WHEN VISIBLE
    
    display_en <= '1' when (h_count < H_VISIBLE and v_count < V_VISIBLE)
                  else '0';

  
    --  pixel coordinates
  
    pixel_x <= to_unsigned(h_count, pixel_x'length);
    pixel_y <= to_unsigned(v_count, pixel_y'length);

end architecture;
