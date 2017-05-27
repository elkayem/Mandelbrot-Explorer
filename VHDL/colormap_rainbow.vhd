
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity colormap_rainbow is
   port(
      clk: in std_logic;
      addr: in std_logic_vector(7 downto 0);
      data: out std_logic_vector(11 downto 0)
   );
end colormap_rainbow;

architecture arch of colormap_rainbow is
   constant ADDR_WIDTH: integer:=8;
   constant DATA_WIDTH: integer:=12;
   type rom_type is array (0 to 2**ADDR_WIDTH-1)
        of std_logic_vector(DATA_WIDTH-1 downto 0);
   -- ROM definition
   constant colormap: rom_type:=(  -- 2^4-by-12
      x"000",  -- addr 00
		x"000",  -- addr 00
		x"100",  -- addr 00
		x"200",  -- addr 00
		x"300",  -- addr 00
		x"400",  -- addr 00
		x"500",  -- addr 00
		x"600",  -- addr 00
		x"700",  -- addr 00
		x"800",  -- addr 00
		x"900",  -- addr 00
		x"A00",  -- addr 00
		x"B00",  -- addr 00
		x"C00",  -- addr 00
		x"D00",  -- addr 00
		x"E00",  -- addr 00
		x"F00",  -- addr 00
      x"F00",  -- addr 01
      x"F00",  -- addr 03
      x"F10",  -- addr 05
      x"F10",  -- addr 07
      x"F20",  -- addr 09
      x"F20",  -- addr 11
      x"F30",  -- addr 13
      x"F30",  -- addr 15
      x"F40",  -- addr 17
      x"F40",  -- addr 19
      x"F50",  -- addr 21
      x"F50",  -- addr 23
      x"F60",  -- addr 25
      x"F60",  -- addr 27
      x"F70",  -- addr 29
      x"F70",  -- addr 31
      x"F80",  -- addr 33
      x"F80",  -- addr 35
      x"F90",  -- addr 37
      x"F90",  -- addr 39
      x"FA0",  -- addr 41
      x"FA0",  -- addr 43
      x"FB0",  -- addr 45
      x"FB0",  -- addr 47
      x"FC0",  -- addr 49
      x"FC0",  -- addr 51
      x"FD0",  -- addr 53
      x"FD0",  -- addr 55
      x"FE0",  -- addr 57
      x"FE0",  -- addr 59
      x"FF0",  -- addr 61
      x"FF0",  -- addr 62
      x"FF0",  -- addr 65
      x"FF0",  -- addr 66
      x"FF0",  -- addr 67
      x"EF0",  -- addr 69
      x"EF0",  -- addr 70
      x"EF0",  -- addr 71
      x"DF0",  -- addr 73
      x"DF0",  -- addr 74
      x"DF0",  -- addr 75
      x"CF0",  -- addr 77
      x"CF0",  -- addr 78
      x"CF0",  -- addr 79
      x"BF0",  -- addr 81
      x"BF0",  -- addr 82
      x"BF0",  -- addr 83
      x"AF0",  -- addr 85
      x"AF0",  -- addr 86
      x"AF0",  -- addr 87
      x"9F0",  -- addr 89
      x"9F0",  -- addr 90
      x"9F0",  -- addr 91
      x"8F0",  -- addr 93
      x"8F0",  -- addr 94
      x"8F0",  -- addr 95
      x"7F0",  -- addr 97
      x"7F0",  -- addr 98
		x"7F0",  -- addr 99
      x"6F0",  -- addr 101
      x"6F0",  -- addr 102
      x"6F0",  -- addr 103
      x"5F0",  -- addr 105
      x"5F0",  -- addr 106
      x"5F0",  -- addr 107
      x"4F0",  -- addr 109
      x"4F0",  -- addr 110
      x"4F0",  -- addr 111
      x"3F0",  -- addr 113
      x"3F0",  -- addr 114
		x"3F0",  -- addr 115
      x"2F0",  -- addr 117
      x"2F0",  -- addr 118
      x"2F0",  -- addr 119
      x"1F0",  -- addr 121
      x"1F0",  -- addr 122
      x"1F0",  -- addr 123
      x"0F0",  -- addr 125
      x"0F0",  -- addr 126
      x"0F0",  -- addr 127
      x"0F0",  -- addr 02
      x"0F0",  -- addr 03
      x"0F1",  -- addr 05
      x"0F1",  -- addr 06
      x"0F1",  -- addr 07
      x"0F2",  -- addr 09
      x"0F2",  -- addr 10
      x"0F2",  -- addr 11
      x"0F3",  -- addr 13
      x"0F3",  -- addr 14
      x"0F3",  -- addr 15
      x"0F4",  -- addr 17
      x"0F4",  -- addr 18
      x"0F4",  -- addr 19
      x"0F5",  -- addr 21
      x"0F5",  -- addr 22
      x"0F5",  -- addr 23
      x"0F6",  -- addr 25
      x"0F6",  -- addr 26
      x"0F6",  -- addr 27
      x"0F7",  -- addr 29
      x"0F7",  -- addr 30
      x"0F7",  -- addr 31
      x"0F8",  -- addr 33
      x"0F8",  -- addr 34
      x"0F8",  -- addr 35
      x"0F9",  -- addr 37
      x"0F9",  -- addr 38
      x"0F9",  -- addr 39
      x"0FA",  -- addr 41
      x"0FA",  -- addr 42
      x"0FA",  -- addr 43
      x"0FB",  -- addr 45
      x"0FB",  -- addr 46
      x"0FB",  -- addr 47
      x"0FC",  -- addr 49
      x"0FC",  -- addr 50
      x"0FC",  -- addr 51
      x"0FD",  -- addr 53
      x"0FD",  -- addr 54
      x"0FD",  -- addr 55
      x"0FE",  -- addr 57
      x"0FE",  -- addr 58
      x"0FE",  -- addr 59
      x"0FF",  -- addr 61
      x"0FF",  -- addr 62
      x"0FF",  -- addr 63
      x"0FF",  -- addr 66
      x"0FF",  -- addr 67
      x"0EF",  -- addr 69
      x"0EF",  -- addr 70
      x"0EF",  -- addr 71
      x"0DF",  -- addr 73
      x"0DF",  -- addr 74
      x"0DF",  -- addr 75
      x"0CF",  -- addr 77
      x"0CF",  -- addr 78
      x"0CF",  -- addr 79
      x"0BF",  -- addr 81
      x"0BF",  -- addr 82
      x"0BF",  -- addr 83
      x"0AF",  -- addr 85
      x"0AF",  -- addr 86
      x"0AF",  -- addr 87
      x"09F",  -- addr 89
      x"09F",  -- addr 90
      x"09F",  -- addr 91
      x"08F",  -- addr 93
      x"08F",  -- addr 94
      x"08F",  -- addr 95
      x"07F",  -- addr 97
      x"07F",  -- addr 98
		x"07F",  -- addr 99
      x"06F",  -- addr 101
      x"06F",  -- addr 102
      x"06F",  -- addr 103
      x"05F",  -- addr 105
      x"05F",  -- addr 106
      x"05F",  -- addr 107
      x"04F",  -- addr 109
      x"04F",  -- addr 110
      x"04F",  -- addr 111
      x"03F",  -- addr 113
      x"03F",  -- addr 114
		x"03F",  -- addr 115
      x"02F",  -- addr 117
      x"02F",  -- addr 118
      x"02F",  -- addr 119
      x"01F",  -- addr 121
      x"01F",  -- addr 122
      x"01F",  -- addr 123
      x"00F",  -- addr 125
      x"00F",  -- addr 126
      x"00F",  -- addr 127
      x"00F",  -- addr 01
      x"00F",  -- addr 02
      x"00F",  -- addr 03
      x"10F",  -- addr 05
      x"10F",  -- addr 06
      x"10F",  -- addr 07
      x"20F",  -- addr 09
      x"20F",  -- addr 10
      x"20F",  -- addr 11
      x"30F",  -- addr 13
      x"30F",  -- addr 14
      x"30F",  -- addr 15
      x"40F",  -- addr 17
      x"40F",  -- addr 18
      x"40F",  -- addr 19
      x"50F",  -- addr 21
      x"50F",  -- addr 22
      x"50F",  -- addr 23
      x"60F",  -- addr 25
      x"60F",  -- addr 26
      x"60F",  -- addr 27
      x"70F",  -- addr 29
      x"70F",  -- addr 30
      x"70F",  -- addr 31
      x"80F",  -- addr 33
      x"80F",  -- addr 34
      x"80F",  -- addr 35
      x"90F",  -- addr 37
      x"90F",  -- addr 38
      x"90F",  -- addr 39
      x"A0F",  -- addr 41
      x"A0F",  -- addr 42
      x"A0F",  -- addr 43
      x"B0F",  -- addr 45
      x"B0F",  -- addr 46
      x"B0F",  -- addr 47
      x"C0F",  -- addr 49
      x"C0F",  -- addr 50
      x"C0F",  -- addr 51
      x"D0F",  -- addr 53
      x"D0F",  -- addr 54
      x"D0F",  -- addr 55
      x"E0F",  -- addr 57
      x"E0F",  -- addr 58
      x"E0F",  -- addr 59
      x"F0F",  -- addr 61
      x"F0F",  -- addr 62
      x"F0F",  -- addr 63
      x"F0F",  -- addr 66
      x"F0F",  -- addr 67
      x"F0F",  -- addr 69
      x"F0E",  -- addr 70
      x"F0E",  -- addr 71
      x"F0D",  -- addr 73
      x"F0D",  -- addr 74
      x"F0D",  -- addr 75
      x"F0C",  -- addr 77
      x"F0C",  -- addr 78
      x"F0C",  -- addr 79
      x"F0B",  -- addr 81
      x"F0B",  -- addr 82
      x"F0B",  -- addr 83
      x"F0A",  -- addr 85
      x"F0A",  -- addr 86
      x"F0A"  -- addr 87
   );
   signal addr_reg: std_logic_vector(ADDR_WIDTH-1 downto 0);
begin
   -- addr register to infer block RAM
   process (clk)
   begin
      if (clk'event and clk = '1') then
        addr_reg <= addr;
      end if;
   end process;
   data <= colormap(to_integer(unsigned(addr_reg)));
end arch;