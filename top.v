`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:16:36 01/06/2020 
// Design Name: 
// Module Name:    top 
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
module top(
	input wire clk_100mhz,
	input wire rst,
	input wire ps2_clk,
	input wire ps2_data,
	output wire [3:0] vga_b, vga_g, vga_r,
	output wire vga_hs, vga_vs
    );
	
	wire [4:0] operation;
	wire [899:0] map;
	wire [34:0] hero;
	wire [23:0] curEnemy;
	wire isBattle, isShop;
	wire [1:0] shopCursor;
	
	main main(.clk_100mhz(clk_100mhz),
			  .rst(rst),
			  .operation(operation),
			  .map(map),
			  .hero(hero),
			  .curEnemy(curEnemy),
			  .isBattle(isBattle),
			  .isShop(isShop),
			  .shopCursor(shopCursor)
			  );
			  
	keyboard keyboard(.clk_100mhz(clk_100mhz),
					  .rst(rst),
					  .ps2_clk(ps2_clk),
					  .ps2_data(ps2_data),
					  .operation(operation)
					  );
	
	vga vga(
		.clk_100mhz(clk_100mhz),
		.rst(rst),
		.Map(map),
		.hero(hero),
		.isBattle(isBattle),
		.curEnemy(curEnemy),
		.isShop(isShop),
		.shopCursor(shopCursor),
		.vga_b(vga_b),
		.vga_g(vga_g),
		.vga_r(vga_r),
		.vga_hs(vga_hs),
		.vga_vs(vga_vs)
	);


endmodule
