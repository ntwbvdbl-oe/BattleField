`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:33:01 01/07/2020 
// Design Name: 
// Module Name:    main 
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
module main(
	input wire clk_100mhz,
	input wire rst,
	input wire [4:0] operation,
	output reg [899:0] map,
	output reg [34:0] hero,
	output reg [23:0] curEnemy,
	output reg isBattle, isShop,
	output reg [1:0] shopCursor
    );
	
	reg [31:0] clkdiv = 0;
	always @(posedge clk_100mhz or posedge rst)
		if(rst) clkdiv <= 0;
		else clkdiv <= clkdiv + 1'b1;
	//wire [4:0] operation;
	
	//0000hero, 0001road, 0010wall, 0011key, 0100attack, 0101defend, 0110hp, 0111door
	//1000shopl, 1001shopm, 1010shopr, 1011slim, 1100skeleton, 1101wizard, 1110guard, 1111boss
	//reg [34:0] hero;			//[34:25]hp, [24:18]attack, [17:11]defend, [10:7]key, [6:0]coins
	reg [20:0] enemys[0:4];		//[23:21]id, [20:12]hp, [11:6]attack, [5:0]defend

	reg [3:0] curX, curY;
	reg [3:0] nextX, nextY;
	reg [3:0] nextStatue;
	
	reg step1, step2;
	always @(posedge clk_100mhz or posedge rst) begin
		if(rst) begin
			`include "main_init.v"
		end else if(isBattle) begin						//battle
			if(clkdiv[23:0] == 24'b0) begin
				//if(hero[34:25] == 10'b0)				//hero died
				//	gameOver <= 1'b1;
				if(curEnemy[20:12] == 9'b0) begin		//enemy died
					isBattle <= 0;
					curEnemy <= 0;
					hero[6:0] <= hero[6:0] + curEnemy[23:21] + 1;
					{map[(nextX * 15 + nextY) * 4 + 3], map[(nextX * 15 + nextY) * 4 + 2], map[(nextX * 15 + nextY) * 4 + 1], map[(nextX * 15 + nextY) * 4]} <= 4'b0001;
					{nextX, nextY} <= 6'b0;
				end
				hero[34:25] <= hero[34:25] - (hero[34:25] <= (curEnemy[11:6] <= hero[17:11] ? 1'b0 : curEnemy[11:6] - hero[17:11]) ? hero[34:25] : (curEnemy[11:6] <= hero[17:11] ? 1'b0 : curEnemy[11:6] - hero[17:11]));
				curEnemy[20:12] <= curEnemy[20:12] - (curEnemy[20:12] <= (hero[24:18] <= curEnemy[5:0] ? 1'b0 : hero[24:18] - curEnemy[5:0]) ? curEnemy[20:12] : (hero[24:18] <= curEnemy[5:0] ? 1'b0 : hero[24:18] - curEnemy[5:0]));
			end
		end else if(isShop && operation[4:0] != 0) begin		//shop
			if(operation == 5'b10000)		//buy
				case(shopCursor)
					2'b00:if(hero[6:0] >= 4) begin hero[34:25] <= hero[34:25] + 100;hero[6:0] <= hero[6:0] - 4; end	//+100hp
					2'b01:if(hero[6:0] >= 4) begin hero[24:18] <= hero[24:18] + 4;  hero[6:0] <= hero[6:0] - 4; end	//+4attack
					2'b10:if(hero[6:0] >= 4) begin hero[17:11] <= hero[17:11] + 4;  hero[6:0] <= hero[6:0] - 4; end	//+4defend
					2'b11:isShop <= 0;
				endcase
			else		//move
				case(operation)
					5'b00100: shopCursor <= shopCursor - 1'b1;	//up
					5'b00010: shopCursor <= shopCursor + 1'b1;	//down
				endcase
		end else if(operation[3:0] != 0) begin			//step0: calc next position
			step1 <= 1'b1;
			case(operation[3:0])
				4'b1000: begin nextX <= curX;			nextY <= curY - 1'b1; 	end		//a
				4'b0100: begin nextX <= curX - 1'b1;	nextY <= curY; 			end		//w
				4'b0010: begin nextX <= curX + 1'b1;	nextY <= curY; 			end		//s
				4'b0001: begin nextX <= curX;			nextY <= curY + 1'b1; 	end		//d
				default:{nextX, nextY} <= 8'b0;
			endcase
		end else if(step1) begin						//step1: calc next statue
			step1 <= 1'b0;
			step2 <= 1'b1;
			nextStatue <= {map[(nextX * 15 + nextY) * 4 + 3], map[(nextX * 15 + nextY) * 4 + 2], map[(nextX * 15 + nextY) * 4 + 1], map[(nextX * 15 + nextY) * 4]};
		end else if(step2) begin						//step2: process
			step2 <= 1'b0;
			if(nextStatue == 4'b0001 || (nextStatue >= 4'b0011 && nextStatue <= 4'b0111)) begin
				if(nextStatue == 4'b0011)				//key
					hero[10: 7] <= hero[10: 7] + 1'b1;
				else if(nextStatue == 4'b0100)			//attack
					hero[24:18] <= hero[24:18] + 3'd4;
				else if(nextStatue == 4'b0101)			//defend
					hero[17:11] <= hero[17:11] + 3'd4;
				else if(nextStatue == 4'b0110)			//hp
					hero[34:25] <= hero[34:25] + 7'd100;
				else if(nextStatue == 4'b0111 && hero[10:7] > 0)	//door
					hero[10: 7] <= hero[10: 7] - 1'b1;
				if(nextStatue != 4'b0111 || (nextStatue == 4'b0111 && hero[10:7] > 0)) begin
					{map[(curX * 15 + curY) * 4 + 3], map[(curX * 15 + curY) * 4 + 2], map[(curX * 15 + curY) * 4 + 1], map[(curX * 15 + curY) * 4]} <= 4'b0001;
					{map[(nextX * 15 + nextY) * 4 + 3], map[(nextX * 15 + nextY) * 4 + 2], map[(nextX * 15 + nextY) * 4 + 1], map[(nextX * 15 + nextY) * 4]} <= 4'b0000;
					{curX, curY} <= {nextX, nextY};
				end
				{nextX, nextY} <= 6'b0;
			end else if(nextStatue == 4'b1001) begin	//shop
				isShop <= 1'b1;
				shopCursor <= 2'b0;
				{nextX, nextY} <= 6'b0;
			end else if(nextStatue >= 4'b1011 && nextStatue <= 4'b1111) begin	//battle
				isBattle <= 1'b1;
				curEnemy[23:21] <= nextStatue - 4'b1011;
				curEnemy[20:0] <= enemys[nextStatue - 4'b1011];
			end
			nextStatue <= 4'b0;
		end
	end
	
	initial begin
		`include "main_init.v"
	end

endmodule
