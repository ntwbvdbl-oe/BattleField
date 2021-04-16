`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:01:55 01/07/2020 
// Design Name: 
// Module Name:    number 
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
module number(
	input wire [12:0] base,
	output wire [3:0] num0, num1, num2, num3,
	output reg [3:0] can_num
    );

	assign num0 = base % 10;
	assign num1 = base / 10 % 10;
	assign num2 = base / 100 % 10;
	assign num3 = base / 1000;
	
	always begin
		can_num[3] = num3 ? 1'b1 : 1'b0;
		can_num[2] = num2 || can_num[3] ? 1'b1 : 1'b0;
		can_num[1] = num1 || can_num[2] ? 1'b1 : 1'b0;
		can_num[0] = 1'b1;
	end
	
endmodule
