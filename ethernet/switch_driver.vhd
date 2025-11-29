----------------------------------------------------------------------------------
-- Switch Driver Component
-- TX Frame Generator: Sends Ethernet frames with switch value
-- Frame Structure: Dest MAC (6) + Src MAC (6) + EtherType (2) + Payload (1 byte)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ethernet_mac;
use ethernet_mac.ethernet_types.all;

entity switch_driver is
    Generic (
        G_MAC_ADDRESS  : std_logic_vector(47 downto 0) := x"000A35123456"
    );
    Port (
        -- Clock and Reset
        i_tx_clock     : in  STD_LOGIC;
        i_tx_reset     : in  STD_LOGIC;
        
        -- Switch Input (value to send)
        i_switch       : in  STD_LOGIC_VECTOR(3 downto 0);
        
        -- TX Interface (to Ethernet MAC)
        o_tx_enable    : out STD_LOGIC;
        o_tx_data      : out STD_LOGIC_VECTOR(7 downto 0);
        i_tx_byte_sent : in  STD_LOGIC;
        i_tx_busy      : in  STD_LOGIC
    );
end switch_driver;

architecture Behavioral of switch_driver is
    
    -- TX State Machine
    type t_tx_state is (IDLE, WAIT_TIMER, SEND_DEST_MAC, SEND_SRC_MAC, 
                        SEND_ETHERTYPE, SEND_PAYLOAD, DONE);
    signal s_tx_state      : t_tx_state := IDLE;
    signal s_tx_counter    : integer range 0 to 50000000 := 0;
    signal s_tx_byte_index : integer range 0 to 14 := 0;
    
    -- Frame Constants
    constant C_BROADCAST_MAC : std_logic_vector(47 downto 0) := x"FFFFFFFFFFFF";
    constant C_ETHERTYPE     : std_logic_vector(15 downto 0) := x"88B5";
    
begin
    
    ----------------------------------------------------------------------------------
    -- TX State Machine Process
    -- Sends Ethernet frame with switch value every 500ms
    ----------------------------------------------------------------------------------
    process(i_tx_clock)
        variable v_payload : std_logic_vector(7 downto 0);
    begin
        if rising_edge(i_tx_clock) then
            if i_tx_reset = '1' then
                o_tx_enable <= '0';
                o_tx_data <= (others => '0');
                s_tx_state <= IDLE;
                s_tx_counter <= 0;
                s_tx_byte_index <= 0;
            else
                -- Prepare payload (switch value padded to 8 bits)
                v_payload := "0000" & i_switch;
                
                case s_tx_state is
                    when IDLE =>
                        o_tx_enable <= '0';
                        s_tx_state <= WAIT_TIMER;
                        s_tx_counter <= 0;
                    
                    when WAIT_TIMER =>
                        -- Wait 500ms (25M cycles @ 50MHz) before sending next frame
                        if s_tx_counter < 25000000 then
                            s_tx_counter <= s_tx_counter + 1;
                        else
                            s_tx_counter <= 0;
                            s_tx_byte_index <= 0;
                            s_tx_state <= SEND_DEST_MAC;
                        end if;
                    
                    when SEND_DEST_MAC =>
                        -- Send 6 bytes of Destination MAC (Broadcast: FF:FF:FF:FF:FF:FF)
                        o_tx_enable <= '1';
                        o_tx_data <= C_BROADCAST_MAC((5 - s_tx_byte_index) * 8 + 7 downto 
                                                     (5 - s_tx_byte_index) * 8);
                        
                        if i_tx_byte_sent = '1' then
                            if s_tx_byte_index < 5 then
                                s_tx_byte_index <= s_tx_byte_index + 1;
                            else
                                s_tx_byte_index <= 0;
                                s_tx_state <= SEND_SRC_MAC;
                            end if;
                        end if;
                    
                    when SEND_SRC_MAC =>
                        -- Send 6 bytes of Source MAC (our MAC address)
                        o_tx_enable <= '1';
                        o_tx_data <= G_MAC_ADDRESS((5 - s_tx_byte_index) * 8 + 7 downto 
                                                   (5 - s_tx_byte_index) * 8);
                        
                        if i_tx_byte_sent = '1' then
                            if s_tx_byte_index < 5 then
                                s_tx_byte_index <= s_tx_byte_index + 1;
                            else
                                s_tx_byte_index <= 0;
                                s_tx_state <= SEND_ETHERTYPE;
                            end if;
                        end if;
                    
                    when SEND_ETHERTYPE =>
                        -- Send 2 bytes of EtherType (0x88B5)
                        o_tx_enable <= '1';
                        if s_tx_byte_index = 0 then
                            o_tx_data <= C_ETHERTYPE(15 downto 8);  -- MSB first
                        else
                            o_tx_data <= C_ETHERTYPE(7 downto 0);   -- LSB
                        end if;
                        
                        if i_tx_byte_sent = '1' then
                            if s_tx_byte_index < 1 then
                                s_tx_byte_index <= s_tx_byte_index + 1;
                            else
                                s_tx_byte_index <= 0;
                                s_tx_state <= SEND_PAYLOAD;
                            end if;
                        end if;
                    
                    when SEND_PAYLOAD =>
                        -- Send 1 byte of payload (switch value)
                        o_tx_enable <= '1';
                        o_tx_data <= v_payload;
                        
                        if i_tx_byte_sent = '1' then
                            s_tx_state <= DONE;
                        end if;
                    
                    when DONE =>
                        -- Frame sent, disable TX and go back to IDLE
                        o_tx_enable <= '0';
                        s_tx_state <= IDLE;
                    
                    when others =>
                        s_tx_state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;

