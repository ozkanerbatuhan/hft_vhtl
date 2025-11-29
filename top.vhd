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
        SW            : in  STD_LOGIC_VECTOR(3 downto 0);
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
        LED           : out STD_LOGIC_VECTOR(7 downto 0)
    );
end top;

architecture Behavioral of top is

    component ethernet_top is
        Port (
            i_clk_50mhz   : in  STD_LOGIC;
            i_reset_n     : in  STD_LOGIC;
            SW            : in  STD_LOGIC_VECTOR(3 downto 0);
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
            LED           : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component xor_ann is
        Port (
            clock   : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            xor_in  : in  STD_LOGIC_VECTOR(1 downto 0);
            xor_out : out STD_LOGIC
        );
    end component;

    signal clk_50mhz : STD_LOGIC;
    signal reset_n : STD_LOGIC;
    signal SW : STD_LOGIC_VECTOR(3 downto 0);
    signal MII_RX_CLK : STD_LOGIC;
    signal MII_RXD : STD_LOGIC_VECTOR (3 downto 0);
    signal MII_RX_DV : STD_LOGIC;
    signal MII_RX_ER : STD_LOGIC;
    signal MII_TX_CLK : STD_LOGIC;
    signal MII_TXD : STD_LOGIC_VECTOR (3 downto 0);
    signal MII_TX_EN : STD_LOGIC;
    signal MII_TX_ER : STD_LOGIC;
    signal MDC : STD_LOGIC;
    signal MDIO : STD_LOGIC;
    signal o_phy_reset_n : STD_LOGIC;
    signal LED : STD_LOGIC_VECTOR(7 downto 0);

begin

    ethernet_top_inst : ethernet_top
        Port map (
            i_clk_50mhz => clk_50mhz,
            i_reset_n => reset_n,
            SW => SW,
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
            LED => LED
        );

    clk_50mhz <= i_clk_50mhz;
    reset_n <= i_reset_n;
    SW <= i_SW(3 downto 0);
    MII_RX_CLK <= i_MII_RX_CLK;
    MII_RXD <= i_MII_RXD;
    MII_RX_DV <= i_MII_RX_DV;
    MII_RX_ER <= i_MII_RX_ER;
    MII_TX_CLK <= i_MII_TX_CLK;
    MII_TXD <= i_MII_TXD(3 downto 0);
    MII_TX_EN <= i_MII_TX_EN;
    MII_TX_ER <= i_MII_TX_ER;
    MDC <= i_MDC;
    MDIO <= i_MDIO;
    o_phy_reset_n <= i_o_phy_reset_n;
    LED <= i_LED(7 downto 0);

    
    xor_ann_inst : xor_ann
        Port map (
            clock => clk_50mhz,
            reset => reset_n,
            xor_in => SW,
            xor_out => LED(0)
        );
        


end Behavioral;