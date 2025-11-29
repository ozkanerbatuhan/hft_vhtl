-- This file is part of the ethernet_mac project.
--
-- For the full copyright and license information, please read the
-- LICENSE.md file that was distributed with this source code.

-- Simple generic IO architecture for MII/GMII
-- Suitable for Spartan-3E and other FPGAs without special IO primitives

library ieee;
use ieee.std_logic_1164.all;

library ethernet_mac;
use ethernet_mac.ethernet_types.all;
entity mii_gmii_io is
	port(
		-- 125 MHz clock input (exact requirements can vary by implementation)
		-- Spartan 6: clock should be unbuffered
		clock_125_i     : in  std_ulogic;

		-- RX and TX clocks
		clock_tx_o      : out std_ulogic;
		clock_rx_o      : out std_ulogic;

		-- Speed selection for clock switch
		speed_select_i  : in  t_ethernet_speed;

		-- Signals connected directly to external ports
		-- MII
		mii_tx_clk_i    : in  std_ulogic;
		mii_tx_en_o     : out std_ulogic;
		mii_txd_o       : out t_ethernet_data;
		mii_rx_clk_i    : in  std_ulogic;
		mii_rx_er_i     : in  std_ulogic;
		mii_rx_dv_i     : in  std_ulogic;
		mii_rxd_i       : in  t_ethernet_data;

		-- GMII
		gmii_gtx_clk_o  : out std_ulogic;

		-- Signals connected to the mii_gmii module
		int_mii_tx_en_i : in  std_ulogic;
		int_mii_txd_i   : in  t_ethernet_data;
		int_mii_rx_er_o : out std_ulogic;
		int_mii_rx_dv_o : out std_ulogic;
		int_mii_rxd_o   : out t_ethernet_data
	);
end entity;
architecture simple of mii_gmii_io is
begin
	-- Clock selection based on speed
	-- For 10/100 Mbps MII mode, use external PHY clocks
	-- For 1000 Mbps GMII mode, use internal 125 MHz clock
	
	process(speed_select_i, mii_tx_clk_i, mii_rx_clk_i, clock_125_i)
	begin
		case speed_select_i is
			when SPEED_1000MBPS =>
				-- Gigabit mode: use internal 125 MHz clock
				clock_tx_o <= clock_125_i;
				clock_rx_o <= mii_rx_clk_i;
				
			when SPEED_100MBPS | SPEED_10MBPS =>
				-- 10/100 Mbps mode: use PHY-provided clocks
				clock_tx_o <= mii_tx_clk_i;
				clock_rx_o <= mii_rx_clk_i;
				
			when others =>
				-- Unspecified: default to MII mode
				clock_tx_o <= mii_tx_clk_i;
				clock_rx_o <= mii_rx_clk_i;
		end case;
	end process;
	
	-- GMII GTX clock output (only used in gigabit mode)
	gmii_gtx_clk_o <= clock_125_i when speed_select_i = SPEED_1000MBPS else '0';
	
	-- Direct pass-through for MII TX signals
	mii_tx_en_o <= int_mii_tx_en_i;
	mii_txd_o   <= int_mii_txd_i;
	
	-- Direct pass-through for MII RX signals
	int_mii_rx_er_o <= mii_rx_er_i;
	int_mii_rx_dv_o <= mii_rx_dv_i;
	int_mii_rxd_o   <= mii_rxd_i;
	
end architecture;

