library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity spi_slave is
  generic(
    d_width : integer := 120);     --data width in bits
  port(
    sclk         : in     std_logic;  --spi clk from master
    ss_n         : in     std_logic;  --active low slave select
    mosi         : in     std_logic;  --master out, slave in
    rx_req       : in     std_logic;  --data request
    rdy         : out std_logic;  --receive ready bit
    rx_cmd       : out    std_logic_vector(7 downto 0) := (others => '0');  --receive command register output to logic
    rx_data      : out    std_logic_vector(d_width-1 downto 0) := (others => '0');  --receive data register output to logic
    busy         : out    std_logic := '0'  --busy signal to logic ('1' during transaction)
    ); 
end spi_slave;

architecture logic of spi_slave is
  signal bit_cnt :  integer range  0 to d_width+7;  
  signal rx_cmd_buf  : std_logic_vector(7 downto 0) := (others => '0');  --receiver command buffer
  signal rx_buf  : std_logic_vector(d_width-1 downto 0) := (others => '0');  --receiver buffer
  signal rdy_sig : std_logic := '0';
  
begin
  busy <= not ss_n;  --high during transactions

  rdy <= rdy_sig;
  
  -- bit counter
  process(ss_n, sclk)
  begin
    if(ss_n = '1') then                       
	   bit_cnt <= 0; 
    else                                                         
      if(falling_edge(sclk)) then                                
        bit_cnt <= bit_cnt + 1; 
      end if;
    end if;
  end process;

  -- set ready register to 1 when data ready, and clear when data request made
  process(ss_n, bit_cnt, rx_req, sclk)
  begin
    if((ss_n = '1' and (rx_req = '1'))) then
      rdy_sig <= '0';  
    elsif rising_edge(sclk) then
	     if(bit_cnt = (d_width+7)) then
          rdy_sig <= '1';   
		  end if;
    end if;
   end process;   
    
  -- receive registers
  process(sclk)
  begin
   if rising_edge(sclk) then        
	  if(bit_cnt > 7) then
		 rx_buf(d_width-1-(bit_cnt-8)) <= mosi;
	  else 
		 rx_cmd_buf(7-bit_cnt) <= mosi;
	  end if;
	end if;
  end process;
  
  rx_cmd <= rx_cmd_buf;
  rx_data <= rx_buf;

end logic;
