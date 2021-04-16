map <= {60'b0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010,
		60'b0010_0001_1110_0001_0110_0010_0011_0000_0001_0111_0001_0010_1011_0110_0010,
		60'b0010_0100_0010_0011_0101_0010_0001_0001_0001_0010_1011_0010_0101_1011_0010,
		60'b0010_0101_0010_0100_1101_0010_0010_0010_0010_0010_1011_0010_0010_0111_0010,
		60'b0010_0111_0010_0010_0110_0011_0010_0001_0101_1011_0001_1011_0100_0001_0010,
		60'b0010_0001_0001_0010_0010_0011_0010_1100_0010_0010_0010_0010_0010_1011_0010,
		60'b0010_0010_1011_0100_0010_0001_0111_1101_0100_0010_1011_1011_0101_0100_0010,
		60'b0010_1011_1100_1011_0010_0010_0010_0101_0110_0010_1011_0111_0010_0010_0010,
		60'b0010_1100_1101_1100_0010_1100_0101_1100_1100_0010_1100_0001_1100_0001_0010,
		60'b0010_1101_1110_1101_0010_1101_0110_0100_1101_0111_0001_1100_0100_0110_0010,
		60'b0010_0010_0111_0010_0010_0010_0010_0111_0010_0010_0010_0010_0010_0111_0010,
		60'b0010_0001_1110_0001_0010_0001_0111_0001_1101_0110_0010_0011_0001_1100_0010,
		60'b0010_1110_1110_1110_0010_0100_0010_0010_0010_1101_0010_0011_0001_0001_0010,
		60'b0010_0110_1111_0110_0010_0100_0100_0101_0001_1101_0010_1010_1001_1000_0010,
		60'b0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010_0010};
enemys[0] <= 21'b000101000_010000_000011;
enemys[1] <= 21'b000110100_010100_001100;
enemys[2] <= 21'b000011000_011111_001000;
enemys[3] <= 21'b001100110_011100_111000;
enemys[4] <= 21'b100000000_111111_111111;
hero <= 35'b0001100100_0001100_0001100_0100_0000000;
curX <= 4'b1101;
curY <= 4'b0111;
{isBattle, isShop} <= 2'b0;
{step1, step2} <= 2'b0;