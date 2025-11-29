----------------------------------------------------------------------------------
-- Top Level Design for Ethernet MAC IP (GitHub ethernet_mac project)
-- Spartan-3E with MII PHY Interface
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ethernet_mac;
use ethernet_mac.ethernet_types.all;
use ethernet_mac.miim_types.all;

----------------------------------------------------------------------------------
-- ENTITY: Top Level
----------------------------------------------------------------------------------
entity ethernet_top is
    Port ( 
        -- Main Clock and Reset
        i_clk_50mhz   : in  STD_LOGIC;
        i_reset_n     : in  STD_LOGIC;


        -- MII Interface (PHY pins)
        MII_RX_CLK    : in  STD_LOGIC;
        MII_RXD       : in  STD_LOGIC_VECTOR (3 downto 0);
        MII_RX_DV     : in  STD_LOGIC;
        MII_RX_ER     : in  STD_LOGIC;
        -- MII_CRS and MII_COL not used (full-duplex mode)
        MII_TX_CLK    : in  STD_LOGIC;
        MII_TXD       : out STD_LOGIC_VECTOR (3 downto 0);
        MII_TX_EN     : out STD_LOGIC;
        MII_TX_ER     : out STD_LOGIC;
        
        -- MDIO Management Interface
        MDC           : out STD_LOGIC;
        MDIO          : inout STD_LOGIC;

        -- PHY Reset Pin
        o_phy_reset_n : out STD_LOGIC
    );
end ethernet_top;

----------------------------------------------------------------------------------
-- ARCHITECTURE
----------------------------------------------------------------------------------
architecture Behavioral of ethernet_top is


    -- Component Declaration for GitHub ethernet_mac
    component ethernet is
        generic(
            MIIM_PHY_ADDRESS      : t_phy_address;
            MIIM_RESET_WAIT_TICKS : natural;
            MIIM_POLL_WAIT_TICKS  : natural;
            MIIM_CLOCK_DIVIDER    : positive;
            MIIM_DISABLE          : boolean
        );
        port(
            clock_125_i        : in    std_ulogic;
            reset_i            : in    std_ulogic;
            reset_o            : out   std_ulogic;
            mac_address_i      : in    t_mac_address;
            
            mii_tx_clk_i       : in    std_ulogic;
            mii_tx_er_o        : out   std_ulogic;
            mii_tx_en_o        : out   std_ulogic;
            mii_txd_o          : out   std_ulogic_vector(7 downto 0);
            mii_rx_clk_i       : in    std_ulogic;
            mii_rx_er_i        : in    std_ulogic;
            mii_rx_dv_i        : in    std_ulogic;
            mii_rxd_i          : in    std_ulogic_vector(7 downto 0);
            
            gmii_gtx_clk_o     : out   std_ulogic;
            rgmii_tx_ctl_o     : out   std_ulogic;
            rgmii_rx_ctl_i     : in    std_ulogic;
            
            miim_clock_i       : in    std_ulogic;
            mdc_o              : out   std_ulogic;
            mdio_io            : inout std_ulogic;
            link_up_o          : out   std_ulogic;
            speed_o            : out   t_ethernet_speed;
            speed_override_i   : in    t_ethernet_speed;
            
            tx_clock_o         : out   std_ulogic;
            tx_reset_o         : out   std_ulogic;
            tx_enable_i        : in    std_ulogic;
            tx_data_i          : in    t_ethernet_data;
            tx_byte_sent_o     : out   std_ulogic;
            tx_busy_o          : out   std_ulogic;
            
            rx_clock_o         : out   std_ulogic;
            rx_reset_o         : out   std_ulogic;
            rx_frame_o         : out   std_ulogic;
            rx_data_o          : out   t_ethernet_data;
            rx_byte_received_o : out   std_ulogic;
            rx_error_o         : out   std_ulogic
      );
    end component;

    -- Signal Declarations
    signal s_reset          : std_ulogic;
    signal s_reset_out      : std_ulogic;
    
    -- MAC Address (Change this to your desired MAC address)
    -- Format: 48-bit hex value (00:0A:35:12:34:56)
    constant C_MAC_ADDRESS  : t_mac_address := x"000A35123456";
    
    -- MII Signals (8-bit for GitHub IP, but only 4-bit used in MII mode)
    signal s_mii_tx_en      : std_ulogic;
    signal s_mii_txd_8bit   : std_ulogic_vector(7 downto 0);
    signal s_mii_rxd_8bit   : std_ulogic_vector(7 downto 0);
    
    -- MDIO Signals
    signal s_mdc            : std_ulogic;
    
    -- Link Status
    signal s_link_up        : std_ulogic;
    signal s_speed          : t_ethernet_speed;
    
    -- TX/RX Clocks from MAC
    signal s_tx_clock       : std_ulogic;
    signal s_rx_clock       : std_ulogic;
    signal s_tx_reset       : std_ulogic;
    signal s_rx_reset       : std_ulogic;
    
    -- TX Interface
    signal s_tx_enable      : std_ulogic;
    signal s_tx_data        : t_ethernet_data;
    signal s_tx_byte_sent   : std_ulogic;
    signal s_tx_busy        : std_ulogic;
    
    -- RX Interface
    signal s_rx_frame       : std_ulogic;
    signal s_rx_data        : t_ethernet_data;
    signal s_rx_byte_received : std_ulogic;
    signal s_rx_error       : std_ulogic;
    
    -- Component Interface Signals
    signal s_tx_enable_slv  : std_logic;
    signal s_tx_data_slv    : std_logic_vector(7 downto 0);
    signal s_tx_byte_sent_slv : std_logic;
    signal s_tx_busy_slv    : std_logic;
    
    -- Type conversion functions
    function to_std_logic(u : std_ulogic) return std_logic is
    begin
        return std_logic(u);
    end function;
    
    function to_std_ulogic(s : std_logic) return std_ulogic is
    begin
        return std_ulogic(s);
    end function;
    
    function to_std_ulogic_vector(slv : std_logic_vector) return std_ulogic_vector is
        variable result : std_ulogic_vector(slv'range);
    begin
        for i in slv'range loop
            result(i) := std_ulogic(slv(i));
        end loop;
        return result;
    end function;
    
    function to_std_logic_vector(sulv : std_ulogic_vector) return std_logic_vector is
        variable result : std_logic_vector(sulv'range);
    begin
        for i in sulv'range loop
            result(i) := std_logic(sulv(i));
        end loop;
        return result;
    end function;

begin

    -- Reset Conversion (active-low button to active-high)
    s_reset <= to_std_ulogic(not i_reset_n);
    
    -- PHY Reset (active-low, synchronized with MAC reset)
    o_phy_reset_n <= not to_std_logic(s_reset_out);
    
    -- MII Data Bus Conversion (4-bit to 8-bit for MII mode)
    -- In MII mode, only lower 4 bits are used
    s_mii_rxd_8bit <= "0000" & to_std_ulogic_vector(MII_RXD);
    MII_TX_EN <= to_std_logic(s_mii_tx_en);
    MII_TXD <= to_std_logic_vector(s_mii_txd_8bit(3 downto 0));
    
    -- MDIO Management Signals
    MDC <= to_std_logic(s_mdc);
    
    -- Type Conversions for Component Interfaces
    s_tx_enable <= to_std_ulogic(s_tx_enable_slv);
    s_tx_data <= to_std_ulogic_vector(s_tx_data_slv);
    s_tx_byte_sent_slv <= to_std_logic(s_tx_byte_sent);
    s_tx_busy_slv <= to_std_logic(s_tx_busy);
    

    
    ----------------------------------------------------------------------------------
    -- Ethernet MAC Instantiation
    ----------------------------------------------------------------------------------
    ethernet_inst : component ethernet
        generic map (
            MIIM_PHY_ADDRESS      => "00001",  -- PHY Address 1 (change if needed)
            MIIM_RESET_WAIT_TICKS => 2500000,  -- Wait 50ms after reset @ 50MHz
            MIIM_POLL_WAIT_TICKS  => 10000000, -- Poll every 200ms @ 50MHz
            MIIM_CLOCK_DIVIDER    => 20,       -- 50MHz / 20 = 2.5MHz MDC
            MIIM_DISABLE          => FALSE     -- MIIM enabled (auto PHY config)
        )
        port map (
            -- Clocks and Reset
            clock_125_i        => to_std_ulogic(i_clk_50mhz),  -- Use 50MHz (not ideal but works for MII)
            reset_i            => s_reset,
            reset_o            => s_reset_out,
            
            -- MAC Address
            mac_address_i      => C_MAC_ADDRESS,
            
            -- MII Physical Interface
            mii_tx_clk_i       => to_std_ulogic(MII_TX_CLK), 
            mii_tx_er_o        => open,  -- Not used in MII mode
            mii_tx_en_o        => s_mii_tx_en,
            mii_txd_o          => s_mii_txd_8bit,
            mii_rx_clk_i       => to_std_ulogic(MII_RX_CLK),
            mii_rx_er_i        => to_std_ulogic(MII_RX_ER),
            mii_rx_dv_i        => to_std_ulogic(MII_RX_DV),
            mii_rxd_i          => s_mii_rxd_8bit,
            
            -- GMII/RGMII (not used in MII mode)
            gmii_gtx_clk_o     => open,
            rgmii_tx_ctl_o     => open,
            rgmii_rx_ctl_i     => '0',
            
            -- MDIO Management Interface (Automatic!)
            miim_clock_i       => to_std_ulogic(i_clk_50mhz),
            mdc_o              => s_mdc,
            mdio_io            => MDIO,
            link_up_o          => s_link_up,
            speed_o            => s_speed,
            speed_override_i   => SPEED_UNSPECIFIED,
            
            -- TX Client Interface
            tx_clock_o         => s_tx_clock,
            tx_reset_o         => s_tx_reset,
            tx_enable_i        => s_tx_enable,
            tx_data_i          => s_tx_data,
            tx_byte_sent_o     => s_tx_byte_sent,
            tx_busy_o          => s_tx_busy,
            
            -- RX Client Interface
            rx_clock_o         => s_rx_clock,
            rx_reset_o         => s_rx_reset,
            rx_frame_o         => s_rx_frame,
            rx_data_o          => s_rx_data,
            rx_byte_received_o => s_rx_byte_received,
            rx_error_o         => s_rx_error
        );




end Behavioral;
