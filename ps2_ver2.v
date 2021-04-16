`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:41:09 01/03/2020 
// Design Name: 
// Module Name:    ps2_ver2 
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
module ps2_ver2(
	input wire clk,
	input wire rst,
	input wire ps2_clk,
	input wire ps2_data,
	output wire ready,
	output wire [9:0] data_out
    );

	reg [2:0] ps2_clk_sync;
	wire negedge_ps2_clk;

	always @(posedge clk or posedge rst) begin
		if(rst)
			ps2_clk_sync <= 3'b0;
		else
			ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
	end

	assign negedge_ps2_clk = !ps2_clk_sync[1] & ps2_clk_sync[2];
	reg [3:0] num;
	always @(posedge clk or posedge rst) begin
		if(rst)
			num <= 4'b0;
		else if(num == 4'd11)
			num <= 4'b0;
		else if(negedge_ps2_clk)
			num <= num + 1'b1;
	end

	reg negedge_ps2_clk_shift;
	always @(posedge clk) begin
		negedge_ps2_clk_shift <= negedge_ps2_clk;
	end

	reg [7:0] temp_data;
	always @(posedge clk or posedge rst) begin
		if(rst)
			temp_data <= 8'd0;
		else if(negedge_ps2_clk_shift) begin
			case(num)
				4'd2: temp_data[0] <= ps2_data;
				4'd3: temp_data[1] <= ps2_data;
				4'd4: temp_data[2] <= ps2_data;
				4'd5: temp_data[3] <= ps2_data;
				4'd6: temp_data[4] <= ps2_data;
				4'd7: temp_data[5] <= ps2_data;
				4'd8: temp_data[6] <= ps2_data;
				4'd9: temp_data[7] <= ps2_data;
				default: temp_data <= temp_data;
			endcase
		end else
			temp_data <= temp_data;
	end

	reg data_break, data_done, data_expand;
	reg [9:0] data;
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			data_break <= 1'b0;
			data <= 10'b0;
			data_done <= 1'b0;
			data_expand <= 1'b0;
		end else if(num == 4'd11) begin
			if(temp_data == 8'he0)
				data_expand <= 1'b1;
			else if(temp_data == 8'hf0)
				data_break <= 1'b1;
			else begin
				data <= {data_expand, data_break, temp_data};
				data_done <= 1'b1;
				data_expand <= 1'b0;
				data_break <= 1'b0;
			end
		end else begin
			data <= data;
			data_done <= 1'b0;
			data_expand <= data_expand;
			data_break <= data_break;
		end
	end

	assign data_out = data;
	assign ready = data_done;

endmodule
