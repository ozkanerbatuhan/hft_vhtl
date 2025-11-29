----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:47:07 11/28/2025 
-- Design Name: 
-- Module Name:    top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port (
        i_clk_50mhz   : in  STD_LOGIC;
        i_reset_n     : in  STD_LOGIC;
        MII_RX_CLK    : in  STD_LOGIC;
        MII_RXD       : in  STD_LOGIC_VECTOR (3 downto 0);
        MII_RX_DV     : in  STD_LOGIC;
        MII_RX_ER     : in  STD_LOGIC;
        MII_TX_CLK    : in  STD_LOGIC;
        MII_TXD       : out STD_LOGIC_VECTOR (3 downto 0);
        MII_TX_EN     : out STD_LOGIC;
        MII_TX_ER     : out STD_LOGIC;
        MDC           : out STD_LOGIC;
        MDIO          : inout STD_LOGIC;
        o_phy_reset_n : out STD_LOGIC;
    );
end top;

architecture Behavioral of top is

    component ethernet_top is
        Port (
            i_clk_50mhz   : in  STD_LOGIC;
            i_reset_n     : in  STD_LOGIC;
            MII_RX_CLK    : in  STD_LOGIC;
            MII_RXD       : in  STD_LOGIC_VECTOR (3 downto 0);
            MII_RX_DV     : in  STD_LOGIC;
            MII_RX_ER     : in  STD_LOGIC;
            MII_TX_CLK    : in  STD_LOGIC;
            MII_TXD       : out STD_LOGIC_VECTOR (3 downto 0);
            MII_TX_EN     : out STD_LOGIC;
            MII_TX_ER     : out STD_LOGIC;
            MDC           : out STD_LOGIC;
            MDIO          : inout STD_LOGIC;
            o_phy_reset_n : out STD_LOGIC;
        );
    end component;
    component packet_builder_with_timer is
        Generic (
            TIMER_WIDTH : integer := 32;  -- Zaman sayacı genişliği
            FIFO_DEPTH  : integer := 16   -- Kaç adet işlem üst üste gelebilir? (Pipeline derinliği)
        );
        Port (
            i_clk          : in  STD_LOGIC;
            i_reset_n      : in  STD_LOGIC;
            
            -- GİRİŞ: ANN'e veri girdiği an tetiklenecek
            i_start_trigger: in  STD_LOGIC;  -- "Veri geldi" sinyali (Parser'dan)
            
            -- GİRİŞ: ANN sonucu hazır olduğunda tetiklenecek
            i_ann_result   : in  STD_LOGIC;  -- ANN'in 1 veya 0 sonucu
            i_ann_done     : in  STD_LOGIC;  -- "Sonuç hazır" sinyali (ANN'den)
            
            -- ÇIKIŞ: Ethernet'e gönderilecek paketlenmiş veri
            o_tx_data      : out STD_LOGIC_VECTOR(31 downto 0); -- 32-bit veri çıkışı
            o_tx_valid     : out STD_LOGIC   -- "Paket hazır, gönder" sinyali
        );
    end component;
    component hft_network is
        Port (
            clock   : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            hft_in  : in  STD_LOGIC_VECTOR(1 downto 0);
            hft_out : out STD_LOGIC
        );
    end component;
    component led_driver is
        Port (
            i_rx_clock    : in  STD_LOGIC;
            i_rx_reset    : in  STD_LOGIC;
            i_rx_frame    : in  STD_LOGIC;
            o_led         : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- Internal signal for LED output from ethernet_top
    signal ethernet_led : STD_LOGIC_VECTOR(7 downto 0);
    -- Internal signal for XOR output
    signal xor_output : STD_LOGIC;

begin

    ethernet_top_inst : ethernet_top
        Port map (
            i_clk_50mhz => i_clk_50mhz,
            i_reset_n => i_reset_n,

            MII_RX_CLK => MII_RX_CLK,
            MII_RXD => MII_RXD,
            MII_RX_DV => MII_RX_DV,
            MII_RX_ER => MII_RX_ER,
            MII_TX_CLK => MII_TX_CLK,
            MII_TXD => MII_TXD,
            MII_TX_EN => MII_TX_EN,
            MII_TX_ER => MII_TX_ER,
            MDC => MDC,
            MDIO => MDIO,
            o_phy_reset_n => o_phy_reset_n,
        );
    
    packet_builder_with_timer_inst : packet_builder_with_timer
        Port map (
            i_clk => i_clk_50mhz,
            i_reset_n => i_reset_n,
            i_start_trigger => '0',
            i_ann_result => xor_output,
            i_ann_done => '0',
            o_tx_data => open,
            o_tx_valid => open
        );
        led_driver_inst : component led_driver
            port map (
                i_rx_clock => to_std_logic(s_rx_clock),
                i_rx_reset => to_std_logic(s_rx_reset),
                i_rx_frame => to_std_logic(s_rx_frame),
                o_led      => LED
            );
    -- HFT Network instance using first 2 bits of SW
    hft_network_inst : hft_network
        Port map (
            clock => i_clk_50mhz,
            reset => i_reset_n,
            hft_in => "00",
            hft_out => "0"
        );        

end Behavioral;