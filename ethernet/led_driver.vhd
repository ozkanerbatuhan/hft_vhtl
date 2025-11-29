----------------------------------------------------------------------------------
-- LED Driver Component
-- RX Activity Detection and LED Display
-- LED<7>   : RX Activity indicator (stays ON for 1 second after frame received)
-- LED<6:4> : Reserved (constant '0')
-- LED<3:0> : Switch feedback display
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_driver is
    Port (
        -- Clock and Reset
        i_rx_clock    : in  STD_LOGIC;
        i_rx_reset    : in  STD_LOGIC;
        
        -- RX Interface (from Ethernet MAC)
        i_rx_frame    : in  STD_LOGIC;
        
        -- Switch Input (for feedback display)
        i_switch      : in  STD_LOGIC_VECTOR(3 downto 0);
        
        -- LED Output
        o_led         : out STD_LOGIC_VECTOR(7 downto 0)
    );
end led_driver;

architecture Behavioral of led_driver is
    
    -- RX Activity Detection
    signal s_rx_activity : std_logic := '0';
    signal s_rx_timeout  : integer range 0 to 50000000 := 0;
    
begin
    
    ----------------------------------------------------------------------------------
    -- RX Activity Detection Process
    -- LED<7> turns ON when a frame is received, stays ON for 1 second
    ----------------------------------------------------------------------------------
    process(i_rx_clock)
    begin
        if rising_edge(i_rx_clock) then
            if i_rx_reset = '1' then
                s_rx_activity <= '0';
                s_rx_timeout <= 0;
            else
                -- Detect frame reception
                if i_rx_frame = '1' then
                    -- Frame is being received, turn ON LED<7>
                    s_rx_activity <= '1';
                    s_rx_timeout <= 50000000;  -- Keep LED on for 1 second (50M cycles @ 50MHz)
                elsif s_rx_timeout > 0 then
                    -- Countdown timer: keep LED on for 1 second after frame ends
                    s_rx_timeout <= s_rx_timeout - 1;
                else
                    -- Timeout expired, turn OFF LED<7>
                    s_rx_activity <= '0';
                end if;
            end if;
        end if;
    end process;
    
    ----------------------------------------------------------------------------------
    -- LED Output Assignment
    ----------------------------------------------------------------------------------
    o_led(7)          <= s_rx_activity;  -- RX Activity
    o_led(6 downto 4) <= "000";          -- Reserved
    o_led(3 downto 0) <= i_switch;       -- Switch feedback

end Behavioral;

