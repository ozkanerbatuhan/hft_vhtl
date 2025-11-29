library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sigmoid_functions.all;

entity hft_network is
    Port (
        clock   : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        hft_in  : in  STD_LOGIC_VECTOR(1 downto 0);
        hft_out : out STD_LOGIC
    );
end hft_network;

architecture Behavioral of hft_network is

    -- Component declaration for the HFT network
    component hft_network is
        Port (
            clock   : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            input   : in  STD_LOGIC_VECTOR(1 downto 0);
            output  : out STD_LOGIC
        );
    end component;

begin

    -- Instantiate the HFT Network
    U1_hft_network: hft_network
        Port map (
            clock   => clock,
            reset   => reset,
            input   => hft_in,
            output  => hft_out
        );

end Behavioral;
