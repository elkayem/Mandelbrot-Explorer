library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity VgaSram is
    Port ( clk_200 : in  STD_LOGIC;
           fifo_empty : in  STD_LOGIC;
			  fifo_rd_en : out STD_LOGIC;
           fifo_x_out : in  STD_LOGIC_VECTOR (9 downto 0);
           fifo_y_out : in  STD_LOGIC_VECTOR (9 downto 0);
			  cursorX : in unsigned(10 downto 0);
			  cursorY : in unsigned(9 downto 0);
			  current_colormap : in unsigned (7 downto 0);
           fifo_data_out : in  STD_LOGIC_VECTOR (7 downto 0);
           ad : out  STD_LOGIC_VECTOR (18 downto 0);
           dio : inout  STD_LOGIC_VECTOR (7 downto 0);
			  we_n : out  STD_LOGIC;
           oe_n : out  STD_LOGIC;
           ce_n : out  STD_LOGIC;
           vga_hsync : out  STD_LOGIC;
           vga_vsync : out  STD_LOGIC;
           vga_red : out  STD_LOGIC_VECTOR (3 downto 0);
           vga_green : out  STD_LOGIC_VECTOR (3 downto 0);
           vga_blue : out  STD_LOGIC_VECTOR (3 downto 0));
			  
end VgaSram;

architecture Behavioral of VgaSram is


   -- SVGA 800 by 600
	constant HD: integer := 800; -- Horizontal display area
	constant HF: integer := 40; -- Front porch
	constant HB: integer := 88; -- Back porch
	constant HR: integer := 128; -- Retrace (sync pulse)
	constant VD: integer := 600; -- Vertical display area
	constant VF: integer := 1; -- Front porch
	constant VB: integer := 23; -- Back porch
	constant VR: integer := 4; -- Retrace (sync pulse)
	
	-- sync counters
	signal v_count_reg, v_count_next: unsigned(9 downto 0) := (others => '0');
	signal h_count_reg, h_count_next: unsigned(10 downto 0) := (others => '0');
	
	-- output buffer
	signal v_sync_reg, h_sync_reg: std_logic;
	signal v_sync_next, h_sync_next: std_logic;
	
	-- status signal
	signal h_end, v_end: std_logic;
	
   type state_type is (id0, id1, id2, rd0,rd1,rd2,wr0,wr1,wr2,vga1,vga2);
	type rw_state is (reading,writing);
	signal state_reg: state_type := rd0; 
	signal state_next: state_type := rd0;
	signal rw_state_reg: rw_state := reading; 
	signal rw_state_next: rw_state := reading;
	
   signal data_f2s_reg, data_f2s_next : STD_LOGIC_VECTOR (7 downto 0);
   signal data_s2f_reg, data_s2f_next : STD_LOGIC_VECTOR (7 downto 0);
   signal addr_reg, addr_next : STD_LOGIC_VECTOR (18 downto 0);
	signal addr_calc : STD_LOGIC_VECTOR (18 downto 0);
   signal we_buf, oe_buf, tri_buf : STD_LOGIC;
   signal we_reg, oe_reg, tri_reg : STD_LOGIC;
	
   signal fifo_rd_en_reg, fifo_rd_en_next : std_logic;
	signal fifo_x_out_reg, fifo_y_out_reg : std_logic_vector(9 downto 0);
	signal fifo_x_out_next, fifo_y_out_next : std_logic_vector(9 downto 0);
	signal fifo_data_out_reg,fifo_data_out_next : std_logic_vector(7 downto 0);

   signal rgb, rgb_reg : std_logic_vector (11 downto 0);
	
	signal rgb_rainbow, rgb_caramel, rgb_anet, rgb_roygold, rgb_polar : std_logic_vector (11 downto 0);
   signal rgb_wild, rgb_tropic, rgb_stargate, rgb_rosewht : std_logic_vector (11 downto 0);
   signal rgb_rose1, rgb_flowers3, rgb_candy, rgb_candy1 : std_logic_vector (11 downto 0);
		
begin

	 process(clk_200)
	 begin
	   if rising_edge(clk_200) then
		  state_reg <= state_next;
		  rw_state_reg <= rw_state_next;
		  addr_reg <= addr_next;
		  data_f2s_reg <= data_f2s_next;
		  data_s2f_reg <= data_s2f_next;
		  tri_reg <= tri_buf;
		  we_reg <= we_buf;
		  oe_reg <= oe_buf;
		  v_count_reg <= v_count_next;
		  h_count_reg <= h_count_next;
		  v_sync_reg <= v_sync_next;
		  h_sync_reg <= h_sync_next;
		  rgb_reg <= rgb;
		  fifo_rd_en_reg <= fifo_rd_en_next;
		  fifo_x_out_reg <= fifo_x_out_next;
		  fifo_y_out_reg <= fifo_y_out_next;
		  fifo_data_out_reg <= fifo_data_out_next;
		end if;
	 end process;
	  
	 -- Counter end
	 h_end <= '1' when h_count_reg = (HD+HF+HB+HR-1) else '0';
	 v_end <= '1' when v_count_reg = (VD+VF+VB+VR-1) else '0';         
	 
	 
	 process(state_reg,dio,data_f2s_reg,data_s2f_reg,addr_reg,rw_state_reg,fifo_data_out_reg,
	         h_count_reg,v_count_reg,h_end,v_end,rw_state_reg,addr_calc)
	 begin
	 	addr_next <= addr_reg;
	   data_f2s_next <= data_f2s_reg;
	   data_s2f_next <= data_s2f_reg;
		h_count_next <= h_count_reg;
		v_count_next <= v_count_reg;
		
      -- State Logic --	
      case state_reg is		
        when id0 =>  -- Idle states
  		    state_next <= id1;
		  when id1 =>
  		    state_next <= id2;
		  when id2 =>
		    data_s2f_next <= (others => '0');
  		    state_next <= vga1;
			 
		  when rd0 =>  -- Read states
		    state_next <= rd1;
		  when rd1 => 
		    state_next <= rd2;
		  when rd2 =>  
		    data_s2f_next <= dio;
		    state_next <= vga1;
			 
		  when wr0 =>  -- Write states					
		    state_next <= wr1;
		  when wr1 =>  
		    state_next <= wr2;
		  when wr2 =>  
		  	 data_s2f_next <= (others => '0'); -- Set SRAM to FPGA data to zero, sets pixel output to zero
		    state_next <= vga1;
		  when vga1 =>
		    state_next <= vga2;
			 if h_end='1' then
			   h_count_next <= (others => '0');
				if v_end='1' then
				   v_count_next <= (others => '0');
				else
				   v_count_next <= v_count_reg + 1;
				end if;
			 else
			   h_count_next <= h_count_reg + 1;
			 end if;
			 
		  when vga2 =>
		    addr_next  <=  addr_calc;
			 
		    if rw_state_reg = writing then			   
			    data_f2s_next <= fifo_data_out_reg;
				 state_next <= wr0;
          elsif (v_count_reg < VD) and (h_count_reg < HD) then
            data_f2s_next <= (others => '0');
				state_next <= rd0;
			 else
			   data_f2s_next <= (others => '0');
				state_next <= id0;  
			 end if;
	   end case;
	 end process;
	 
    -- FIFO logic --
	 process(state_reg,fifo_data_out_reg,fifo_x_out_reg,fifo_y_out_reg,fifo_data_out_reg,fifo_empty,
	         fifo_x_out,fifo_y_out,fifo_data_out,rw_state_reg)
	 begin
	 	rw_state_next <= rw_state_reg;
	 	fifo_rd_en_next <= '0';
		fifo_x_out_next <= fifo_x_out_reg;
		fifo_y_out_next <= fifo_y_out_reg;
		fifo_data_out_next <= fifo_data_out_reg;
		if ((state_reg = id0) or (state_reg = rd0) or (state_reg = wr0)) then 
			 if (fifo_empty = '0') then  -- Read FIFO this loop, and next loop switch to writing 
			  fifo_rd_en_next <= '1';
			  rw_state_next <= writing;
			 else
				fifo_rd_en_next <= '0';
				rw_state_next <= reading;
			 end if; 
		elsif ((state_reg = id1) or (state_reg = rd1) or (state_reg = wr1)) then
			 fifo_x_out_next <= fifo_x_out; -- FIFO x,y,data to be latched at beginning of id2, rd2, wr2
			 fifo_y_out_next <= fifo_y_out;
			 fifo_data_out_next <= fifo_data_out;
		end if;
    end process;

 
	 process(state_reg,state_next)
	 begin
	   tri_buf <= '1';
      we_buf <= '1';
	   oe_buf <= '1';
		
		case state_next is
		  when id0 =>
		  when id1 =>
		  when id2 =>
		  when rd0 =>
		    oe_buf <= '0';
        when rd1 =>
          oe_buf <= '0';
        when rd2 => 
          oe_buf <= '0';
        when wr0 =>
          --tri_buf <= '0';
			 --we_buf <= '0';
		  when wr1 =>
          tri_buf <= '0';
          we_buf <= '0';
        when wr2 =>
          tri_buf <= '0';
			 we_buf <= '0';
		  when vga1 =>
		    if state_reg = wr2 then
			   tri_buf <= '0';  -- Hold tri-state low for one more cycle to make sure write completes
			 else
            tri_buf <= '1';			 
			 end if;
		  when vga2 =>
		end case;
	end process;

   -- SRAM address calculation

	process(rw_state_reg,h_count_reg,v_count_reg,fifo_x_out_reg,fifo_y_out_reg)
	begin
		 if rw_state_reg = writing then
			 -- Address = 800 x y_in + x_in
			 addr_calc  <=  std_logic_vector(
											unsigned(fifo_y_out_reg & "000000000") -- y_in * 512
							 + unsigned('0'    & fifo_y_out_reg & "00000000")  -- y_in * 256
							 + unsigned("0000" & fifo_y_out_reg & "00000")     -- y_in *  32
							 + unsigned(fifo_x_out_reg));  
		 elsif (v_count_reg < VD) and (h_count_reg < HD) then 
			addr_calc <= std_logic_vector(
										 unsigned(v_count_reg & "000000000") -- y_in * 512
						  + unsigned('0'    & v_count_reg & "00000000")  -- y_in * 256
						  + unsigned("0000" & v_count_reg & "00000")     -- y_in *  32
						  + unsigned(h_count_reg));  
		 else
			addr_calc <= (others => '0');
		 end if;
   end process;	
	
	h_sync_next <= '0' when (h_count_reg >= (HD+HF))
	                    and (h_count_reg <= (HD+HF+HR-1)) else
						'1';
						
	v_sync_next <= '0' when (v_count_reg >= (VD+VF))
	                    and (v_count_reg <= (VD+VF+VR-1)) else
						'1';					
	
	-- Color Maps
	
	colormap_rainbow : entity work.colormap_rainbow
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_rainbow
	);

	colormap_caramel : entity work.colormap_caramel
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_caramel
	);
	
   colormap_roygold : entity work.colormap_roygold
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_roygold
	);

   colormap_polar : entity work.colormap_polar
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_polar
	);

   colormap_wild : entity work.colormap_wild
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_wild
	);

   colormap_tropic : entity work.colormap_tropic
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_tropic
	);

   colormap_stargate : entity work.colormap_stargate
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_stargate
	);

   colormap_rosewht : entity work.colormap_rosewht
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_rosewht
	);
	
   colormap_rose1 : entity work.colormap_rose1
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_rose1
	);

   colormap_flowers3 : entity work.colormap_flowers3
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_flowers3
	);

   colormap_candy : entity work.colormap_candy
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_candy
	);

   colormap_candy1 : entity work.colormap_candy1
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_candy1
	);
	
   colormap_anet : entity work.colormap_anet
	port map (
	  clk => clk_200,
	  addr => data_s2f_reg(7 downto 0),
	  data => rgb_anet
	);
	
	rgb <= (others => '1')  when ((h_count_reg = cursorX) xor ((v_count_reg = cursorY) and h_count_reg < HD))
	       else rgb_rainbow when current_colormap = 0
			 else rgb_roygold when current_colormap = 1
			 else rgb_polar when current_colormap = 2
 			 else rgb_wild when current_colormap = 3
			 else rgb_tropic when current_colormap = 4
			 else rgb_stargate when current_colormap = 5
			 else rgb_rosewht when current_colormap = 6
			 else rgb_rose1 when current_colormap = 7
			 else rgb_flowers3 when current_colormap = 8
			 else rgb_candy when current_colormap = 9
			 else rgb_candy1 when current_colormap = 10			 
			 else rgb_anet    when current_colormap = 11
			 else rgb_caramel    when current_colormap = 12
			 else rgb_rainbow;
			 
	-- To FIFO
	fifo_rd_en <= fifo_rd_en_reg;
	
   -- To SRAM
   we_n <= we_reg;
   oe_n <= oe_reg;
   ad <= addr_reg;
   ce_n <= '0';
   dio <= data_f2s_reg when tri_reg = '0' else (others=>'Z');	
	
	-- To VGA
	VGA_HSYNC <= h_sync_reg;
	VGA_VSYNC <= v_sync_reg;

   VGA_RED <= rgb_reg(11 downto 8);
	VGA_GREEN <= rgb_reg(7 downto 4);
	VGA_BLUE <= rgb_reg(3 downto 0);

end Behavioral;


