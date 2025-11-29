library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sigmoid_functions.all;

entity xor_ann is
    Port (
        clock   : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        xor_in  : in  STD_LOGIC_VECTOR(1 downto 0);
        xor_out : out STD_LOGIC
    );
end xor_ann;

architecture Behavioral of xor_ann is

    -- Component declaration for the XOR network
    component xor_network is
        Port (
            clock   : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            input   : in  STD_LOGIC_VECTOR(1 downto 0);
            output  : out STD_LOGIC
        );
    end component;

begin

    -- Instantiate the XOR Network
    U1_xor_network: xor_network
    port map (
        clock   => clock,
        reset   => reset,
        input   => xor_in,
        output  => xor_out
    );

end Behavioral;
