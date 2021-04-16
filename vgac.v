`timescale 1ns / 1ps

module vgac (
    input vga_clk, // 25MHz
	input rst,
    input [11:0] d_in, // rrrr_gggg_bbbb, pixel
    output reg [8:0] row_addr, // pixel ram row address, 480 (512) lines
    output reg [9:0] col_addr, // pixel ram col address, 640 (1024) pixels
    output reg [3:0] r, g, b, // red, green, blue colors, 8-bit for each
    output reg hs, vs // horizontal and vertical synchronization
	);
	reg rdn; // read pixel RAM (active low)

// h_count: vga horizontal counter (0-799 pixels)
    reg [9:0] h_count = 0;
    always @ (posedge vga_clk) begin
        if (rst)
            h_count <= 10'h0;
        else if (h_count == 10'd799)
            h_count <= 10'h0;
        else
            h_count <= h_count + 10'h1;
    end

// v_count: vga vertical counter (0-524 lines)
    reg [9:0] v_count = 0;
    always @ (posedge vga_clk) begin
        if (rst)
            v_count <= 10'h0;
        else if (h_count == 10'd799) begin
            if (v_count == 10'd524)
                v_count <= 10'h0;
            else
                v_count <= v_count + 10'h1;
        end
    end

// signals, will be latched for outputs
    wire [9:0] row = v_count - 10'd35;	// pixel ram row address
    wire [9:0] col = h_count - 10'd143;	// pixel ram col address
    wire h_sync = (h_count > 10'd95);	// 96 -> 799
    wire v_sync = (v_count > 10'd1);	// 2 -> 524
    wire read = (h_count > 10'd142) &&	// 143 -> 782 =
				(h_count < 10'd783) &&	// 640 pixels
				(v_count > 10'd34)  &&	// 35 -> 514 =
				(v_count < 10'd515);	// 480 lines

// vga signals
    always @ (posedge vga_clk) begin
        row_addr <= row[8:0]; // pixel ram row address
        col_addr <= col; // pixel ram col address
        rdn <= ~read; // read pixel (active low)
        hs <= h_sync; // horizontal synch
        vs <= v_sync; // vertical synch
        r <= rdn ? 4'h0 : d_in[11:8]; // 4-bit red
        g <= rdn ? 4'h0 : d_in[7:4]; // 4-bit green
        b <= rdn ? 4'h0 : d_in[3:0]; // 4-bit blue
    end
endmodule