`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:13:41 01/02/2020 
// Design Name: 
// Module Name:    keyboard 
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
module keyboard(
	input wire clk_100mhz, rst, ps2_clk, ps2_data,
	output reg [4:0] operation
    );
	
	wire [9:0] data;
	wire ready;
	
	always @(posedge clk_100mhz) begin
		if(ready) begin
			if(data[8] == 1'b1) begin
				if(data[7:0] == 8'h29)			//space
					operation <= 5'b10000;
				else if(data[7:0] == 8'h1c)		//a
					operation <= 5'b01000;
				else if(data[7:0] == 8'h1d)		//w
					operation <= 5'b00100;
				else if(data[7:0] == 8'h1b)		//s
					operation <= 5'b00010;
				else if(data[7:0] == 8'h23)		//d
					operation <= 5'b00001;
				else
					operation <= 5'b0;
			end
		end else
			operation <= 5'b0;
	end
	
	ps2_ver2 ps2_keyboard(.clk(clk_100mhz),
							  .rst(rst),
							  .ps2_clk(ps2_clk),
							  .ps2_data(ps2_data),
							  .ready(ready),
							  .data_out(data)
							  );

endmodule
