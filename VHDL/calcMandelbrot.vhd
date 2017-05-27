
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity calcMandelbrot is
    Port ( clk : in  STD_LOGIC;
	        -- Inputs
	        iter : in unsigned(7 downto 0);
	        zr : in  signed (34 downto 0); -- fixdt(1,35,33), range: (-2,2)
           zi : in  signed (34 downto 0); -- fixdt(1,35,33), range: (-2,2)
			  cr : in  signed (34 downto 0); -- fixdt(1,35,33), range: (-2,2)
           ci : in  signed (34 downto 0); -- fixdt(1,35,33), range: (-2,2)
			  x  : in unsigned (9 downto 0); 
			  y  : in unsigned (9 downto 0);
			  overflowed : in std_logic;
			  valid_input : in std_logic;
			  
			  --Outputs
			  iter_n : out unsigned(7 downto 0);
			  zr_n : out  signed (34 downto 0); -- fixdt(1,35,33), range: (-2,2)
           zi_n : out  signed (34 downto 0); -- fixdt(1,35,33), range: (-2,2)
			  cr_n : out  signed (34 downto 0); -- fixdt(1,35,33), range: (-2,2)
           ci_n : out  signed (34 downto 0); -- fixdt(1,35,33), range: (-2,2)
			  x_n  : out unsigned (9 downto 0); 
			  y_n  : out unsigned (9 downto 0);
			  overflowed_n : out std_logic;	
			  valid_output : out std_logic);
			  
end calcMandelbrot;

architecture Behavioral of calcMandelbrot is

   COMPONENT tapped_delay
   Generic (depth : natural;
            width : natural;
            tap   : natural);
   PORT(
      clk     : IN  std_logic;
      n_in    : IN  std_logic_vector(width-1 downto 0);
      tap_out : OUT std_logic_vector(width-1 downto 0);
      n_out   : OUT std_logic_vector(width-1 downto 0)
      );
   END COMPONENT;

   COMPONENT untapped_delay
   Generic (depth : natural;
            width : natural);
   PORT(
      clk     : IN  std_logic;
      n_in    : IN  std_logic_vector(width-1 downto 0);
      n_out   : OUT std_logic_vector(width-1 downto 0)
      );
   END COMPONENT;
	
signal zr2, zi2, zrzi, zrzi_delayed : std_logic_vector (37 downto 0);  -- fixdt(1,38,34), range: (-8,8)
--signal zmag_slv, z2_diff_slv : std_logic_vector (37 downto 0);  -- fixdt(1,38,34), range: (-8,8)
signal zmag, z2_diff : signed (37 downto 0);  -- fixdt(1,38,34), range: (-8,8)
signal zr_f, zi_f, abs_zr_f, abs_zi_f : signed (38 downto 0); -- fixdt(1,39,34), range: (-16,16)

signal cr_delayed, cr_tapped, ci_delayed, ci_tapped : std_logic_vector(34 downto 0); 

signal overflowed_check1, overflowed_check2, overflowed_result : std_logic := '0';
signal overflowed_v, overflowed_delayed : std_logic_vector (0 downto 0) := (others => '0');
signal valid_input_v, valid_input_delayed : std_logic_vector (0 downto 0) := (others => '0');

signal x_delayed, y_delayed : std_logic_vector (9 downto 0);

signal iter_delayed : std_logic_vector (7 downto 0);
signal zmag_delayed : std_logic_vector (37 downto 0);

--constant N_pipeline : integer := 11;
constant N_pipeline : integer := 10;

begin
-------- Pipeline 1 through 7 -------------
  mult_zr2 : entity work.mult35 --- Multiply zr2 = zr*zr
  port map (
	  clk => clk,
	  a => std_logic_vector(zr),
	  b => std_logic_vector(zr),
	  p => zr2);
	  
  mult_zi2 : entity work.mult35 --- Multiply zi2 = zi*zi
  port map (
	  clk => clk,
	  a => std_logic_vector(zi),
	  b => std_logic_vector(zi),
	  p => zi2);

  mult_zrzi : entity work.mult35 -- Multiply zrzi = zr*zi
  port map (
	  clk => clk,
	  a => std_logic_vector(zr),
	  b => std_logic_vector(zi),
	  p => zrzi);

  ---------- Pipeline 8 ------------

--  add_zmag : entity work.add38 -- zmag = zr^2 + zi^2
--  PORT MAP (
--    a => zr2,
--    b => zi2,
--    clk => clk,
--    s => zmag_slv
--  );
--  
--  sub_z2diff : entity work.sub38 -- z2_diff = zr^2 - zi^2
--  PORT MAP (
--    a => zr2,
--    b => zi2,
--    clk => clk,
--    s => z2_diff_slv
--  );
--  zmag <= signed(zmag_slv);
--  z2_diff <= signed(z2_diff_slv);
--  
  process(clk)
  begin
    if rising_edge(clk) then
      zmag <= signed(zr2) + signed(zi2); -- zmag = zr^2 + zi^2
	   z2_diff <= signed(zr2) - signed(zi2); -- z2_diff = zr^2 - zi^2
		zrzi_delayed <= zrzi;
	 end if;
  end process;
  
  ----------- Pipeline 9 ------------
  
  process(clk)
  begin
    if rising_edge(clk) then
      zr_f <= resize(signed(z2_diff),zr_f'length) + resize(signed(cr_tapped & '0'),zr_f'length); -- zr_f = z_diff + cr, with bit resizing
      zi_f <= signed(zrzi_delayed & '0')  + resize(signed(ci_tapped & '0'),zr_f'length); -- zi_f = 2*zrzi + ci, with bit resizing
    end if;
  end process;

 
  ----------- Pipeline 10 ------------		
  process(clk)
  begin
    if rising_edge(clk) then  
      abs_zr_f <= abs(zr_f); 
      abs_zi_f <= abs(zi_f);

 		zr_n <= resize(zr_f(38 downto 1),zr_n'length);
		zi_n <= resize(zi_f(38 downto 1),zi_n'length);	
	  end if;
  end process;
  
	 -- Overflow check 1
	 overflowed_check1 <= '1' when (signed(zmag_delayed(37 downto 34)) >= 4) 
			else '0';
					
	 -- Overflow check 2
	 overflowed_check2 <= '0' when ((signed(abs_zr_f(38 downto 34)) < 2) and (signed(abs_zi_f(38 downto 34)) < 2)) 	  
						else '1';
		
	 overflowed_result <=  '1' when ((overflowed_delayed(0) = '1') or (overflowed_check1 = '1')
									 or  (overflowed_check2 = '1') or (iter_delayed = "11111111"))  -- Also "overflow" if we've reached max iterations
						else '0';


	 ---- Outputs ---	
	 overflowed_n <= overflowed_result;
	 iter_n <= unsigned(iter_delayed)  when ((overflowed_delayed(0) = '1') or (overflowed_check1 = '1')) 
						else unsigned(iter_delayed) + 1;	-- Increase iter if magnitude hasn't overflowed yet.  Note overflow_check2 shows 
																	-- mag2 will overflow at next iteration, so allow it to increase here					
		

  
	cr_tapped_delay: tapped_delay generic map (width => 35, depth => N_pipeline, tap => N_pipeline-2) -- cr_tapped required at pipeline 9
	port map(
	  	clk => clk,
		n_in => std_logic_vector(cr),
		n_out => cr_delayed,
		tap_out => cr_tapped
	);
   cr_n <= signed(cr_delayed);
	
   ci_tapped_delay: tapped_delay
	generic map (width => 35, depth => N_pipeline, tap => N_pipeline-2)  -- ci_tapped required at pipeline 10
	port map(
	  	clk => clk,
		n_in => std_logic_vector(ci),
		n_out => ci_delayed,
		tap_out => ci_tapped
	);
   ci_n <= signed(ci_delayed);
	
	x_untapped_delay: untapped_delay
	generic map (width => 10, depth => N_pipeline)
	port map(
	  	clk => clk,
		n_in => std_logic_vector(x),
		n_out => x_delayed
	);
   x_n <= unsigned(x_delayed);
	
	y_untapped_delay: untapped_delay
	generic map (width => 10, depth => N_pipeline)
	port map(
	  	clk => clk,
		n_in => std_logic_vector(y),
		n_out => y_delayed
	);
   y_n <= unsigned(y_delayed);	
	
	overflowed_v(0)   <= overflowed;	
	overflow_untapped_delay: untapped_delay
	generic map (width => 1, depth => N_pipeline)
	port map(
	  	clk => clk,
		n_in => overflowed_v,
		n_out => overflowed_delayed
	);

	valid_input_v(0)   <= valid_input;	
	valid_input_delay: untapped_delay
	generic map (width => 1, depth => N_pipeline)
	port map(
	  	clk => clk,
		n_in => valid_input_v,
		n_out => valid_input_delayed
	);
	valid_output <= valid_input_delayed(0);
	
	iteration_delay: untapped_delay
	generic map (width => 8, depth => N_pipeline)
	port map(
	  	clk => clk,
		n_in => std_logic_vector(iter),
		n_out => iter_delayed
	);
	
	zmag_delay: untapped_delay
	generic map (width => 38, depth => 1)
	port map(
	  	clk => clk,
		n_in => std_logic_vector(zmag),
		n_out => zmag_delayed
	);
	
--	zrzi_delay: untapped_delay
--	generic map (width => 38, depth => 1)
--	port map(
--	  	clk => clk,
--		n_in => std_logic_vector(zrzi),
--		n_out => zrzi_delayed
--	);
	
end Behavioral;

