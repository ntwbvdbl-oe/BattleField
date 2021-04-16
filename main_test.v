`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:23:10 01/08/2020
// Design Name:   main
// Module Name:   C:/Users/lenovo/Desktop/logic/BattleField/main_test.v
// Project Name:  BattleField
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: main
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module main_test;

	// Inputs
	reg clk_100mhz;
	reg rst;
	reg [4:0] operation;

	// Outputs
	wire [899:0] map;
	wire [32:0] hero;
	wire [23:0] curEnemy;
	wire isBattle;
	wire isShop;
	wire [1:0] shopCursor;

	// Instantiate the Unit Under Test (UUT)
	main uut (
		.clk_100mhz(clk_100mhz), 
		.rst(rst), 
		.operation(operation), 
		.map(map), 
		.hero(hero), 
		.curEnemy(curEnemy), 
		.isBattle(isBattle), 
		.isShop(isShop), 
		.shopCursor(shopCursor)
	);

	initial begin
		// Initialize Inputs
		clk_100mhz = 0;
		rst = 0;
		operation = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		
		#10;
		operation = 5'b00001;
		#10;
		operation = 5'b00000;
		#100;
		
		#10;
		operation = 5'b01000;
		#10;
		operation = 5'b00000;
		#100;
		
		#10;
		operation = 5'b01000;
		#10;
		operation = 5'b00000;
		#100;
		
		#10;
		operation = 5'b01000;
		#10;
		operation = 5'b00000;
		#100;
		
		#10;
		operation = 5'b01000;
		#10;
		operation = 5'b00000;
		#100;
		
		#10;
		operation = 5'b00100;
		#10;
		operation = 5'b00000;
		#100;
	end
     
	 
	always begin
		clk_100mhz = 0;#10;
		clk_100mhz = 1;#10;
	end
	
endmodule

