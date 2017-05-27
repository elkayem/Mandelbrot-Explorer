library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity tapped_delay is
   Generic (depth : natural;
            width : natural;
            tap   : natural);

    Port ( clk :       in  STD_LOGIC;
           n_in:      in  STD_LOGIC_VECTOR(width-1 downto 0);
           tap_out:   out STD_LOGIC_VECTOR(width-1 downto 0);
           n_out:      out STD_LOGIC_VECTOR(width-1 downto 0)
         );
end tapped_delay;

architecture Behavioral of tapped_delay is
   signal r : STD_LOGIC_VECTOR((depth+1)*width-1 downto 0) := (others => '0');
   signal n : STD_LOGIC_VECTOR((depth+1)*width-1 downto 0);
begin
   n <= r(depth*width-1 downto 0) & n_in;
   n_out   <= r((depth+1)*width-1 downto depth*width);
   tap_out <= r((tap+1)*width-1 downto (tap)*width);
   
   process(clk, n)
   begin
      if clk'event and clk = '1' then
         r <= n;
      end if;
   end process;

end Behavioral;

