library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sigmoid_functions.all;

entity xor_network is
    Port (
        clock   : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        input   : in  STD_LOGIC_VECTOR(1 downto 0);
        output  : out STD_LOGIC
    );
end xor_network;

architecture Behavioral of xor_network is

    constant FRACT_BITS : integer := 16;

    -- Type definitions for a 2-2-1 network
    type vector_2 is array (0 to 1) of fix_t;
    type matrix_2x2 is array (0 to 1) of vector_2;

    -- XOR weights and biases in Q17.16 format
    constant W1 : matrix_2x2 := (
        (to_fixed(-3.96692011, 16, 33), to_fixed(-5.53735380, 16, 33)),
        (to_fixed(-3.96875941, 16, 33), to_fixed(-5.55102009, 16, 33))
    );

    constant b1 : vector_2 := (
        to_fixed(5.85884108, 16, 33),
        to_fixed(2.08195529, 16, 33)
    );

    constant W2 : vector_2 := (
        to_fixed(7.50238447, 16, 33),
        to_fixed(-7.88582327, 16, 33)
    );

    constant b2 : fix_t := to_fixed(-3.42964665, 16, 33);

    -- Constants for input conversion and output threshold
    constant VAL_1 : fix_t := to_fixed(1.0, 16, 33);
    constant VAL_0 : fix_t := (others => '0');
    constant THRESHOLD : fix_t := to_fixed(0.5, 16, 33);

    signal hidden_activations : vector_2 := (others => (others => '0'));
    signal output_activation  : fix_t := (others => '0');

begin

    process(clock, reset)
        variable input_fixed      : vector_2;
        variable hidden_preact    : vector_2;
        variable output_preact    : fix_t;
        variable product          : SIGNED(65 downto 0);
        variable product_shifted  : fix_t;
    begin
        if reset = '1' then
            hidden_activations <= (others => (others => '0'));
            output_activation  <= (others => '0');
            output <= '0';
        elsif rising_edge(clock) then

            -- Convert std_logic inputs to fixed-point
            for i in 0 to 1 loop
                if input(i) = '1' then
                    input_fixed(i) := VAL_1;
                else
                    input_fixed(i) := VAL_0;
                end if;
            end loop;

            -- Hidden layer calculation
            for i in 0 to 1 loop
                hidden_preact(i) := b1(i);
                for j in 0 to 1 loop
                    product := W1(i)(j) * input_fixed(j);
                    product_shifted := resize(shift_right(product, FRACT_BITS), 33);
                    hidden_preact(i) := hidden_preact(i) + product_shifted;
                end loop;
                hidden_activations(i) <= sigmoid(hidden_preact(i));
            end loop;

            -- Output layer calculation
            output_preact := b2;
            for i in 0 to 1 loop
                product := W2(i) * hidden_activations(i);
                product_shifted := resize(shift_right(product, FRACT_BITS), 33);
                output_preact := output_preact + product_shifted;
            end loop;
            output_activation <= sigmoid(output_preact);

            -- Threshold for final output
            if output_activation > THRESHOLD then
                output <= '1';
            else
                output <= '0';
            end if;

        end if;
    end process;

end Behavioral;
