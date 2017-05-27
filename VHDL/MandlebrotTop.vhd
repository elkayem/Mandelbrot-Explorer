library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MandlebrotTop is
    Port ( 
	  clk : in  STD_LOGIC;
	  -- From SPI
	  sclk : IN std_logic;
	  ss_n : IN std_logic;
	  mosi : IN std_logic;
	  -- To/from chip
	  ad : out  STD_LOGIC_VECTOR (18 downto 0);
	  we_n : out  STD_LOGIC;
	  oe_n : out  STD_LOGIC;
	  dio : inout  STD_LOGIC_VECTOR (7 downto 0);
	  ce_n : out  STD_LOGIC;
	  -- To VGA
	  VGA_HSYNC : out  STD_LOGIC;
	  VGA_VSYNC : out  STD_LOGIC;
	  VGA_RED : out  STD_LOGIC_VECTOR (3 downto 0);
	  VGA_GREEN : out  STD_LOGIC_VECTOR (3 downto 0);
	  VGA_BLUE : out  STD_LOGIC_VECTOR (3 downto 0);
	  -- To Arduino
	  ARD_RESET: out std_logic);
end MandlebrotTop;

architecture Behavioral of MandlebrotTop is
	component clk_manager
	port
	 (-- Clock in ports
	  CLK32           : in     std_logic;
	  -- Clock out ports
	  CLK_200        : out    std_logic;
	  CLK_m        : out    std_logic
	 );
	end component;

   COMPONENT calcMandelbrot
   PORT(
         clk : IN  std_logic;
         iter : IN  unsigned(7 downto 0);
         zr : IN  signed(34 downto 0);
         zi : IN  signed(34 downto 0);
         cr : IN  signed(34 downto 0);
         ci : IN  signed(34 downto 0);
		   x  : in unsigned (9 downto 0); 
			y  : in unsigned (9 downto 0);
			overflowed : in std_logic;
			valid_input : in std_logic;
         iter_n : OUT  unsigned(7 downto 0);
         zr_n : OUT  signed(34 downto 0);
         zi_n : OUT  signed(34 downto 0);
			cr_n : out  signed (34 downto 0);
         ci_n : out  signed (34 downto 0);
			x_n  : out unsigned (9 downto 0); 
			y_n  : out unsigned (9 downto 0);
			overflowed_n : out std_logic;
			valid_output : out std_logic
        );
   END COMPONENT;

	COMPONENT VgaSram
	PORT(
		clk_200 : IN std_logic;
		fifo_empty : IN std_logic;
		fifo_x_out : IN std_logic_vector(9 downto 0);
		fifo_y_out : IN std_logic_vector(9 downto 0);
		fifo_data_out : IN std_logic_vector(7 downto 0);
      cursorX : in unsigned(10 downto 0);
		cursorY : in unsigned(9 downto 0);
      current_colormap : in unsigned (7 downto 0);		
		dio : INOUT std_logic_vector(7 downto 0);      
		fifo_rd_en : OUT std_logic;
		ad : OUT std_logic_vector(18 downto 0);
		we_n : OUT std_logic;
		oe_n : OUT std_logic;
		ce_n : OUT std_logic;
		vga_hsync : OUT std_logic;
		vga_vsync : OUT std_logic;
		vga_red : OUT std_logic_vector(3 downto 0);
		vga_green : OUT std_logic_vector(3 downto 0);
		vga_blue : OUT std_logic_vector(3 downto 0)
		);
	END COMPONENT;
	
   COMPONENT fifo
   PORT (
    --clk : IN STD_LOGIC;
	 wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(27 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
   );
   END COMPONENT;
	
   COMPONENT spi_slave
	PORT(
		sclk : IN std_logic;
		ss_n : IN std_logic;
		mosi : IN std_logic;
		rx_req : IN std_logic;          
		rdy : OUT std_logic;
		rx_cmd : OUT std_logic_vector(7 downto 0);
		rx_data : OUT std_logic_vector(119 downto 0);
		busy : OUT std_logic
		);
	END COMPONENT;

	constant HD: integer := 800; -- Horizontal display area
	constant VD: integer := 600; -- Vertical display area

	type fsm_state is (load_mem_init, load_mem, draw);
	signal mode : fsm_state := load_mem_init;
	
	type spi_state_type is (idle, spi_rx);
	signal spi_state: spi_state_type := idle; 

	signal clk_200, clk_m, clk_tmp : std_logic;
	signal x_in, y_in, x_1, y_1, x_2, y_2 : unsigned(9 downto 0)  := (others => '0');
	signal x_out, y_out : unsigned(9 downto 0);
	signal iter_out : unsigned(7 downto 0);
	signal new_xy_available: std_logic := '0';

	signal cr_in, ci_in : signed(34 downto 0);
	
	signal iter_1, iter_2 : unsigned(7 downto 0);
   signal zr_1, zr_2, zi_1, zi_2, cr_1, cr_2, ci_1, ci_2 :  signed(34 downto 0);
	signal overflowed_1, overflowed_2 : std_logic;
   signal valid_1, valid_2 : std_logic;
	
	signal rd_en, wr_en, fifo_empty : std_logic := '0';
	signal fifo_out : std_logic_vector(27 downto 0);
	signal din : STD_LOGIC_VECTOR(27 DOWNTO 0);
	
   signal spi_busy, spi_rdy : std_logic;
	signal rx_req : std_logic := '0';
	
	signal command: std_logic_vector(7 downto 0) := (others => '0'); 
	signal spi_rx_cmd: std_logic_vector(7 downto 0) := (others => '0');
	
	signal message: std_logic_vector(119 downto 0) := (others => '0'); 
	signal spi_rx_data: std_logic_vector(119 downto 0) := (others => '0');
	
	signal cursorX : unsigned(10 downto 0);
   signal cursorY : unsigned(9 downto 0);

	-- Initial coordinates (-2, -1.17), delta c = 3.2/800
	signal cr0 : signed(34 downto 0)     := "10000000000000000000000000000000000";  -- -2
   signal ci0 : signed(34 downto 0)     := "10110101000000000000000000000000000"; -- -1.2
	signal delta_c : signed(34 downto 0) := "00000000010000000000000000000000000"; -- 0.0039

   signal cr0_next, ci0_next, delta_c_next : signed(34 downto 0);
	
	signal new_cr : std_logic := '0';
	
	signal current_colormap : unsigned(7 downto 0) := (others => '0');
	
	
begin
  ard_reset <= '1'; -- Set arduino reset high, allows AVR chip to run

  clk_mgr: clk_manager
  port map
   (-- Clock in ports
    CLK32 => CLK,
    -- Clock out ports
	 CLK_200 => CLK_200,  -- 200 MHz clock
	 clk_m => clk_tmp); --clk_m);
	clk_m <= clk_200;  -- Fractal calculation also runs at 200 MHz
	
	-- SPI process, receives commands from AVR
   process(clk_200)
	begin
	  if rising_edge(clk_200) then
	    case spi_state is
	      when idle =>
		     if ((spi_busy='0') and (spi_rdy='1')) then
             rx_req <= '1';
             spi_state <= spi_rx;
           else 
             spi_state <= idle;
           end if;

         when spi_rx =>
			  rx_req <= '0';
			  command <= spi_rx_cmd;
           message <= spi_rx_data;
			  spi_state <= idle;
		 end case;
	  end if;
	end process;

   -- Unpack commands from AVR
   process(clk_200, command)
	begin
	  if rising_edge(clk_200) then
	     new_cr <= '0';
		  if (command(1 downto 0) = "01") then -- Command 01: Update cursor position and color map
			 cursorX <= unsigned(message(114 downto 104));  -- Bytes 1 (119-112), Byte 2 (111-104)
			 cursorY <= unsigned(message(97 downto 88)); -- Byte3 (103-96), Byte 4 (95-88)
			 current_colormap <= unsigned(message(87 downto 80)); -- Byte 5 (87-80)
		  elsif (command(1 downto 0) = "10") then -- Command 10: Update coordinates (zoom in/out)
			 cr0_next <= signed(message(114 downto 80));
			 ci0_next <= signed(message(74 downto 40));
			 delta_c_next <= signed(message(34 downto 0));
			 new_cr <= '1'; 
		  end if;
	  end if;
	end process;
	
	-- Mode logic to load new fractal calculation into SRAM
   process(clk_200)
	begin
	  if rising_edge(clk_200) then 
		  case mode is
		  when load_mem_init =>
			 x_in <= (others => '0');
			 y_in <= (others => '0');
			 cr_in <= cr0;
			 ci_in <= ci0;
			 new_xy_available <= '1';
			 mode <= load_mem;
			 
		  when load_mem =>
           if ((overflowed_2 = '1') or (valid_2 = '0')) then -- Ready for next xy
				  new_xy_available <= '1';
				  if (x_in = HD-1) then
					 x_in <= (others => '0');
					 cr_in <= cr0;
					 if (y_in = VD-1) then
						y_in <= (others => '0');
						ci_in <= ci0;
						mode <= draw;
						new_xy_available <= '0';
					 else
						y_in <= y_in + 1;
						ci_in <= ci_in + delta_c;
					 end if;
				  else
					 x_in <= x_in + 1;
					 cr_in <= cr_in + delta_c;
				  end if;
           end if;
			  
		  when draw =>
		
		  end case;
		  
		  if (new_cr = '1') then
		    mode <= load_mem_init;
			 cr0 <= cr0_next;
			 ci0 <= ci0_next;
			 delta_c <= delta_c_next;
		  end if;
		end if;
	end process;     


   Mandelbrot: calcMandelbrot PORT MAP (
          clk => clk_m,
          iter => iter_1,
          zr => zr_1,
          zi => zi_1,
          cr => cr_1,
          ci => ci_1,
			 x => x_1,
			 y => y_1,
			 overflowed => overflowed_1,
			 valid_input => valid_1,
          iter_n => iter_2,
          zr_n => zr_2,
          zi_n => zi_2,
			 cr_n => cr_2,
          ci_n => ci_2,
			 x_n => x_2,
			 y_n => y_2,
			 overflowed_n => overflowed_2,
			 valid_output => valid_2
        );

  loop_mgr : process (clk_m)
    begin
    if rising_edge(clk_m) then
		 if (new_xy_available = '1') and ((overflowed_2 = '1') or (valid_2 = '0')) then --and (out_flag = '0') then  -- Iteration complete or invalid data
			cr_1 <= cr_in;
			ci_1 <= ci_in;
			x_1 <= x_in;
			y_1 <= y_in;
			zr_1 <= (others => '0');
			zi_1 <= (others => '0');
			iter_1 <= (others => '0');
			overflowed_1 <= '0';
			valid_1 <= '1';
			x_out <= x_2;
			y_out <= y_2;
			iter_out <= iter_2;
			wr_en <= '1';

		 else  -- Keep iterating
		   cr_1 <= cr_2;
			ci_1 <= ci_2;
			zr_1 <= zr_2;
			zi_1 <= zi_2;
			iter_1 <= iter_2;
			x_1 <= x_2;
			y_1 <= y_2;
			overflowed_1 <= overflowed_2;
			valid_1 <= valid_2;
			wr_en <= '0';

		 end if;
	  end if;
	end process;

	Inst_VgaSram: VgaSram PORT MAP(
		clk_200 => clk_200,
		fifo_empty => fifo_empty,
		fifo_rd_en => rd_en,
		fifo_x_out => fifo_out(27 downto 18),
		fifo_y_out => fifo_out(17 downto 8),
		fifo_data_out => fifo_out(7 downto 0),
		cursorX => cursorX,
		cursorY => cursorY,
		current_colormap => current_colormap,
		ad => ad,
		dio => dio,
		we_n => we_n,
		oe_n => oe_n,
		ce_n => ce_n,
		vga_hsync => vga_hsync,
		vga_vsync => vga_vsync,
		vga_red => vga_red,
		vga_green => vga_green,
		vga_blue => vga_blue 
	);
	
	din <= std_logic_vector(x_out) & std_logic_vector(y_out) & std_logic_vector(iter_out);
	
	inst_fifo : fifo
   PORT MAP (
	 wr_clk => clk_m,
	 rd_clk => clk_200,
    din => din,
    wr_en => wr_en,
    rd_en => rd_en,
    dout => fifo_out,
    full => open,
    empty => fifo_empty,
    valid => open
   );
  
	Inst_spi_slave: spi_slave PORT MAP(
		sclk => sclk,
		ss_n => ss_n,
		mosi => mosi,
		rx_req => rx_req,
		rdy => spi_rdy,
		rx_cmd => spi_rx_cmd,
		rx_data => spi_rx_data,
		busy => spi_busy
	);

end Behavioral;

