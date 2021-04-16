`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:01:54 12/24/2019 
// Design Name: 
// Module Name:    vga 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`define BATTLE_START_COL 176
`define BATTLE_START_ROW 32
`define BATTLE_WIDTH 128
`define BATTLE_HEIGHT 224
`define BATTLE_FRAME_WIDTH 2
`define SHOP_START_COL 284
`define SHOP_START_ROW 124
`define SHOP_WIDTH 233
`define SHOP_HEIGHT 233
`define SHOP_CURSOR_START_ROW 79
`define SHOP_CURSOR_START_COL 20
`define SHOP_CURSOR_WIDTH 20
`define SHOP_CURSOR_HEIGHT 34

module vga(
	input wire clk_100mhz,
	input wire rst,
	input wire [899:0] Map,
	input wire [34:0] hero,
	input wire isBattle,
	input wire [23:0] curEnemy,
	input wire isShop,
	input wire [1:0] shopCursor,
	
	output wire [3:0] vga_b,
	output wire [3:0] vga_g,
	output wire [3:0] vga_r,
	output wire vga_hs, vga_vs
	);
	
	reg [1:0] clkdiv;
	always @(posedge clk_100mhz) clkdiv <= clkdiv + 1;
	wire clk_25mhz = clkdiv[1];
	
	wire [8:0] row_addr;
	wire [9:0] col_addr;
	
	reg [11:0] rgb;
	reg [3:0]  map[0:14][0:14];
	
	
	
	//database
	//0000hero, 0001road, 0010wall, 0011key, 0100attack, 0101defend, 0110hp, 0111door
	//1000shopl, 1001shopm, 1010shopr, 1011slim, 1100skeleton, 1101wizard, 1110guard, 1111boss
	//dataStatue
	//0000_road, 0001_hero, 0010_health, 0011_attack, 0100_defend, 0101_coins, 0110_key, 0111_number
	integer i, j;
	always begin
		for(i = 0; i < 15; i = i + 1)
			for(j = 0; j < 15; j = j + 1)
				map[i][j] <= {Map[(i * 15 + j) * 4 + 3], Map[(i * 15 + j) * 4 + 2], Map[(i * 15 + j) * 4 + 1], Map[(i * 15 + j) * 4]};
	end
	
	//input wire [32:0] hero; 			//[34:25]hp, [24:18]attack, [17:11]defend, [10:7]key, [6:0]coins
	wire [3:0] health[3:0], can_health;
	wire [3:0] attack[3:0], can_attack;
	wire [3:0] defend[3:0], can_defend;
	wire [3:0] key[3:0], can_key;
	wire [3:0] coins[3:0], can_coins;
	
	//input wire [20:0] curEnemy;		//[20:12]hp, [11:6]attack, [5:0]defend
	wire [3:0] enemy_health[3:0], can_enemy_health;
	wire [3:0] enemy_attack[3:0], can_enemy_attack;
	wire [3:0] enemy_defend[3:0], can_enemy_defend;
	
	number health_num(.base({3'b0, hero[34:25]}),
					  .num0(health[0]),
					  .num1(health[1]),
					  .num2(health[2]),
					  .num3(health[3]),
					  .can_num(can_health)
					  ),
		   attack_num(.base({7'b0, hero[24:18]}),
					  .num0(attack[0]),
					  .num1(attack[1]),
					  .num2(attack[2]),
					  .num3(attack[3]),
					  .can_num(can_attack)
					  ),
		   defend_num(.base({7'b0, hero[17:11]}),
					  .num0(defend[0]),
					  .num1(defend[1]),
					  .num2(defend[2]),
					  .num3(defend[3]),
					  .can_num(can_defend)
					  ),
		   key_num(   .base({9'b0, hero[10:7]}),
					  .num0(key[0]),
					  .num1(key[1]),
					  .num2(key[2]),
					  .num3(key[3]),
					  .can_num(can_key)
					  ),
		   coins_num( .base({6'b0, hero[6:0]}),
					  .num0(coins[0]),
					  .num1(coins[1]),
					  .num2(coins[2]),
					  .num3(coins[3]),
					  .can_num(can_coins)
					  ),
		   enemy_health_num(.base({4'b0, curEnemy[20:12]}),
							.num0(enemy_health[0]),
							.num1(enemy_health[1]),
							.num2(enemy_health[2]),
							.num3(enemy_health[3]),
							.can_num(can_enemy_health)
							),
		   enemy_attack_num(.base({7'b0, curEnemy[11:6]}),
							.num0(enemy_attack[0]),
							.num1(enemy_attack[1]),
							.num2(enemy_attack[2]),
							.num3(enemy_attack[3]),
							.can_num(can_enemy_attack)
							),
		   enemy_defend_num(.base({7'b0, curEnemy[5:0]}),
							.num0(enemy_defend[0]),
							.num1(enemy_defend[1]),
							.num2(enemy_defend[2]),
							.num3(enemy_defend[3]),
							.can_num(can_enemy_defend)
							);
	
	
	wire [11:0] dataBaseRGB;
	wire [13:0] dataBaseAddress = col_addr >= 10'd160
		? map[row_addr / 32][(col_addr - 160) / 32] * 32 * 32 + row_addr % 32 * 32 + (col_addr - 160) % 32
		: 14'b0;
	dataBase dataBase(
		.a(dataBaseAddress), // input [13 : 0] a
		.spo(dataBaseRGB) // output [11 : 0] spo
		);


	reg [3:0]  statueMap[0:14][0:4];	//0000_road, 0001_hero, 0010_health, 0011_attack, 0100_defend, 0101_coins, 0110_key, 0111_number
	wire [11:0] dataStatueRGB;
	reg [13:0] dataStatueAddress;
	always begin
		if(col_addr >= 10'd160)
			dataStatueAddress <= 14'b0;
		else if(statueMap[row_addr / 32][col_addr / 32] < 4'b0111)
			dataStatueAddress <= statueMap[row_addr / 32][col_addr / 32] * 32 * 32 + row_addr % 32 * 32 + col_addr % 32;
		else
			case(row_addr / 32)
				4'b0011:dataStatueAddress <= row_addr % 32 * 16 + col_addr % 16 + (col_addr >= 10'd80 && col_addr < 10'd144 && can_health[10'd3 - (col_addr - 10'd80) / 10'd16] ? 7168 + health[3 - (col_addr - 10'd80) / 10'd16] * 512 : 0);
				4'b0101:dataStatueAddress <= row_addr % 32 * 16 + col_addr % 16 + (col_addr >= 10'd80 && col_addr < 10'd144 && can_attack[10'd3 - (col_addr - 10'd80) / 10'd16] ? 7168 + attack[3 - (col_addr - 10'd80) / 10'd16] * 512 : 0);
				4'b0111:dataStatueAddress <= row_addr % 32 * 16 + col_addr % 16 + (col_addr >= 10'd80 && col_addr < 10'd144 && can_defend[10'd3 - (col_addr - 10'd80) / 10'd16] ? 7168 + defend[3 - (col_addr - 10'd80) / 10'd16] * 512 : 0);
				4'b1001:dataStatueAddress <= row_addr % 32 * 16 + col_addr % 16 + (col_addr >= 10'd80 && col_addr < 10'd144 &&  can_coins[10'd3 - (col_addr - 10'd80) / 10'd16] ? 7168 +  coins[3 - (col_addr - 10'd80) / 10'd16] * 512 : 0);
				4'b1011:dataStatueAddress <= row_addr % 32 * 16 + col_addr % 16 + (col_addr >= 10'd80 && col_addr < 10'd144 &&    can_key[10'd3 - (col_addr - 10'd80) / 10'd16] ? 7168 +    key[3 - (col_addr - 10'd80) / 10'd16] * 512 : 0);
				default:dataStatueAddress <= 0;
			endcase
	end
	dataStatue dataStatue(
	.a(dataStatueAddress), // input [13 : 0] a
	.spo(dataStatueRGB) // output [11 : 0] spo
	);
	
	
	wire [11:0] dataShopRGB;
	reg [15:0] dataShopAddress;
	always begin
		if(isShop && col_addr >= `SHOP_START_COL && col_addr < `SHOP_START_COL + `SHOP_WIDTH &&
					 row_addr >= `SHOP_START_ROW && row_addr < `SHOP_START_ROW + `SHOP_HEIGHT) begin
					 
			if(col_addr - `SHOP_START_COL >= `SHOP_CURSOR_START_COL &&
			   col_addr - `SHOP_START_COL < `SHOP_CURSOR_START_COL + `SHOP_CURSOR_WIDTH &&
			   row_addr - `SHOP_START_ROW >= `SHOP_CURSOR_START_ROW &&
			   row_addr - `SHOP_START_ROW < `SHOP_CURSOR_START_ROW + `SHOP_CURSOR_HEIGHT * 4 &&
			   (row_addr - `SHOP_START_ROW - `SHOP_CURSOR_START_ROW) / `SHOP_CURSOR_HEIGHT == shopCursor[1:0])
			   
			   dataShopAddress <= `SHOP_WIDTH * `SHOP_HEIGHT +
								  (row_addr - `SHOP_START_ROW - `SHOP_CURSOR_START_ROW) % `SHOP_CURSOR_HEIGHT * `SHOP_CURSOR_WIDTH +
								   col_addr - `SHOP_START_COL - `SHOP_CURSOR_START_COL;
			else
				dataShopAddress <= (row_addr - `SHOP_START_ROW) * `SHOP_WIDTH + col_addr - `SHOP_START_COL;
		end else
			dataShopAddress <= 0;
	end
	dataShop dataShop(
		.a(dataShopAddress), // input [15 : 0] a
		.spo(dataShopRGB) // output [11 : 0] spo
	);


	reg [2:0] battleMap[0:6][0:3];	//000_road, 001_enemy, 010_v, 011_s, 100_health, 101_attack, 110_defend, 111_digit
	wire [11:0] dataBattleRGB;
	reg [14:0] dataBattleAddress;
	always begin
		if(col_addr >= `BATTLE_START_COL &&
		   col_addr < `BATTLE_START_COL + `BATTLE_WIDTH &&
		   row_addr >= `BATTLE_START_ROW &&
		   row_addr < `BATTLE_START_ROW + `BATTLE_HEIGHT) begin
			if(battleMap[(row_addr - `BATTLE_START_ROW) / 32][(col_addr - `BATTLE_START_COL) / 32] == 3'b000)
				dataBattleAddress <= (row_addr - `BATTLE_START_ROW) % 32 * 32 + (col_addr - `BATTLE_START_COL) % 32 + 1;
				
			else if(battleMap[(row_addr - `BATTLE_START_ROW) / 32][(col_addr - `BATTLE_START_COL) / 32] == 3'b001)
				dataBattleAddress <= (row_addr - `BATTLE_START_ROW) % 32 * 32 + (col_addr - `BATTLE_START_COL) % 32 +
									 (curEnemy[23:21] + 6) * 1024 + 1;
									 
			else if(battleMap[(row_addr - `BATTLE_START_ROW) / 32][(col_addr - `BATTLE_START_COL) / 32] < 3'b111)
				dataBattleAddress <= (row_addr - `BATTLE_START_ROW) % 32 * 32 + (col_addr - `BATTLE_START_COL) % 32 +
									 (1 + battleMap[(row_addr - `BATTLE_START_ROW) / 32][(col_addr - `BATTLE_START_COL) / 32] - 3'b010) * 1024 + 1;
			
			else
				case((row_addr - `BATTLE_START_ROW) / 32)
					3'b010:dataBattleAddress <= (row_addr - `BATTLE_START_ROW) % 32 * 16 + (col_addr - `BATTLE_START_COL) % 16 +
												(can_enemy_health[10'd3 - (col_addr - `BATTLE_START_COL) / 16] ?
												11264 + enemy_health[10'd3 - (col_addr - `BATTLE_START_COL) / 16] * 512 : 0) + 1;
					3'b100:dataBattleAddress <= (row_addr - `BATTLE_START_ROW) % 32 * 16 + (col_addr - `BATTLE_START_COL) % 16 +
												(can_enemy_attack[10'd3 - (col_addr - `BATTLE_START_COL) / 16] ?
												11264 + enemy_attack[10'd3 - (col_addr - `BATTLE_START_COL) / 16] * 512 : 0) + 1;
					3'b110:dataBattleAddress <= (row_addr - `BATTLE_START_ROW) % 32 * 16 + (col_addr - `BATTLE_START_COL) % 16 +
												(can_enemy_defend[10'd3 - (col_addr - `BATTLE_START_COL) / 16] ?
												11264 + enemy_defend[10'd3 - (col_addr - `BATTLE_START_COL) / 16] * 512 : 0) + 1;
					default:dataBattleAddress <= 0;
				endcase
		end else
			dataBattleAddress <= 0;
	end
	dataBattle dataBattle(
		.a(dataBattleAddress), // input [14 : 0] a
		.spo(dataBattleRGB) // output [11 : 0] spo
	);
	
	
	always begin
		if(isBattle && col_addr >= `BATTLE_START_COL - `BATTLE_FRAME_WIDTH &&
		   col_addr < `BATTLE_START_COL + `BATTLE_WIDTH + `BATTLE_FRAME_WIDTH &&
		   row_addr >= `BATTLE_START_ROW - `BATTLE_FRAME_WIDTH &&
		   row_addr < `BATTLE_START_ROW + `BATTLE_HEIGHT + `BATTLE_FRAME_WIDTH)
			rgb[11:0] <= dataBattleRGB[11:0];
		else if(col_addr >= 10'd160) begin
			if(isShop && col_addr >= `SHOP_START_COL && col_addr < `SHOP_START_COL + `SHOP_WIDTH && row_addr >= `SHOP_START_ROW && row_addr < `SHOP_START_ROW + `SHOP_HEIGHT)
				rgb[11:0] <= dataShopRGB[11:0];
			else
				rgb[11:0] <= dataBaseRGB[11:0];
		end else
			rgb[11:0] <= dataStatueRGB[11:0];
	end
	
	vgac vgac(.vga_clk(clk_25mhz),
		 .rst(rst),
		 .d_in(rgb),
		 .row_addr(row_addr),
		 .col_addr(col_addr),
		 .r(vga_r),
		 .g(vga_g),
		 .b(vga_b),
		 .hs(vga_hs),
		 .vs(vga_vs));
	
	initial begin
		//battleMap
		battleMap[0][0] <= 3'b010;
		battleMap[0][1] <= 3'b011;
		battleMap[0][2] <= 3'b000;
		battleMap[0][3] <= 3'b001;
		battleMap[1][0] <= 3'b000;
		battleMap[1][1] <= 3'b000;
		battleMap[1][2] <= 3'b000;
		battleMap[1][3] <= 3'b000;
		battleMap[2][0] <= 3'b111;
		battleMap[2][1] <= 3'b111;
		battleMap[2][2] <= 3'b000;
		battleMap[2][3] <= 3'b100;
		battleMap[3][0] <= 3'b000;
		battleMap[3][1] <= 3'b000;
		battleMap[3][2] <= 3'b000;
		battleMap[3][3] <= 3'b000;
		battleMap[4][0] <= 3'b111;
		battleMap[4][1] <= 3'b111;
		battleMap[4][2] <= 3'b000;
		battleMap[4][3] <= 3'b101;
		battleMap[5][0] <= 3'b000;
		battleMap[5][1] <= 3'b000;
		battleMap[5][2] <= 3'b000;
		battleMap[5][3] <= 3'b000;
		battleMap[6][0] <= 3'b111;
		battleMap[6][1] <= 3'b111;
		battleMap[6][2] <= 3'b000;
		battleMap[6][3] <= 3'b110;
		//statueMap
		statueMap[0][0] <= 4'b0000;
		statueMap[0][1] <= 4'b0000;
		statueMap[0][2] <= 4'b0000;
		statueMap[0][3] <= 4'b0000;
		statueMap[0][4] <= 4'b0000;
		statueMap[1][0] <= 4'b0000;
		statueMap[1][1] <= 4'b0001;
		statueMap[1][2] <= 4'b0000;
		statueMap[1][3] <= 4'b0000;
		statueMap[1][4] <= 4'b0000;
		statueMap[2][0] <= 4'b0000;
		statueMap[2][1] <= 4'b0000;
		statueMap[2][2] <= 4'b0000;
		statueMap[2][3] <= 4'b0000;
		statueMap[2][4] <= 4'b0000;
		statueMap[3][0] <= 4'b0000;
		statueMap[3][1] <= 4'b0010;
		statueMap[3][2] <= 4'b0111;
		statueMap[3][3] <= 4'b0111;
		statueMap[3][4] <= 4'b0111;
		statueMap[4][0] <= 4'b0000;
		statueMap[4][1] <= 4'b0000;
		statueMap[4][2] <= 4'b0000;
		statueMap[4][3] <= 4'b0000;
		statueMap[4][4] <= 4'b0000;
		statueMap[5][0] <= 4'b0000;
		statueMap[5][1] <= 4'b0011;
		statueMap[5][2] <= 4'b0111;
		statueMap[5][3] <= 4'b0111;
		statueMap[5][4] <= 4'b0111;
		statueMap[6][0] <= 4'b0000;
		statueMap[6][1] <= 4'b0000;
		statueMap[6][2] <= 4'b0000;
		statueMap[6][3] <= 4'b0000;
		statueMap[6][4] <= 4'b0000;
		statueMap[7][0] <= 4'b0000;
		statueMap[7][1] <= 4'b0100;
		statueMap[7][2] <= 4'b0111;
		statueMap[7][3] <= 4'b0111;
		statueMap[7][4] <= 4'b0111;
		statueMap[8][0] <= 4'b0000;
		statueMap[8][1] <= 4'b0000;
		statueMap[8][2] <= 4'b0000;
		statueMap[8][3] <= 4'b0000;
		statueMap[8][4] <= 4'b0000;
		statueMap[9][0] <= 4'b0000;
		statueMap[9][1] <= 4'b0101;
		statueMap[9][2] <= 4'b0111;
		statueMap[9][3] <= 4'b0111;
		statueMap[9][4] <= 4'b0111;
		statueMap[10][0] <= 4'b0000;
		statueMap[10][1] <= 4'b0000;
		statueMap[10][2] <= 4'b0000;
		statueMap[10][3] <= 4'b0000;
		statueMap[10][4] <= 4'b0000;
		statueMap[11][0] <= 4'b0000;
		statueMap[11][1] <= 4'b0110;
		statueMap[11][2] <= 4'b0111;
		statueMap[11][3] <= 4'b0111;
		statueMap[11][4] <= 4'b0111;
		statueMap[12][0] <= 4'b0000;
		statueMap[12][1] <= 4'b0000;
		statueMap[12][2] <= 4'b0000;
		statueMap[12][3] <= 4'b0000;
		statueMap[12][4] <= 4'b0000;
		statueMap[13][0] <= 4'b0000;
		statueMap[13][1] <= 4'b0000;
		statueMap[13][2] <= 4'b0000;
		statueMap[13][3] <= 4'b0000;
		statueMap[13][4] <= 4'b0000;
		statueMap[14][0] <= 4'b0000;
		statueMap[14][1] <= 4'b0000;
		statueMap[14][2] <= 4'b0000;
		statueMap[14][3] <= 4'b0000;
		statueMap[14][4] <= 4'b0000;
	end
	
endmodule
