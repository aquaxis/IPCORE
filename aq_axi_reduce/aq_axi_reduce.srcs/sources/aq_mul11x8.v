/*
 * Copyright (C)2006-2015 AQUAXIS TECHNOLOGY.
 *  Don't remove this header. 
 * When you use this source, there is a need to inherit this header.
 *
 * License
 *  For no commercial -
 *   License:     The Open Software License 3.0
 *   License URI: http://www.opensource.org/licenses/OSL-3.0
 *
 *  For commmercial -
 *   License:     AQUAXIS License 1.0
 *   License URI: http://www.aquaxis.com/licenses
 *
 * For further information please contact.
 *	URI:    http://www.aquaxis.com/
 *	E-Mail: info(at)aquaxis.com
 */
module aq_mul11x8(
	input			RST_N,
	input			CLK,
	input [10:0]	DINA,
	input [7:0]		DINB,
	output [18:0]	DOUT
);

reg [12:0] x0r, x1r, x2r, x3r;
reg [14:0] y0r, y1r;
reg [18:0] z0r;

always @(negedge RST_N or posedge CLK) begin
	if(!RST_N) begin
		x0r <= 13'd0;
		x1r <= 13'd0;
		x2r <= 13'd0;
		x3r <= 13'd0;
		y0r <= 15'd0;
		y1r <= 15'd0;
		z0r <= 19'd0;
	end else begin
		// 1st
		x0r <= ((({2'b 00,DINA[10:0] }) & {DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] ,DINB[0] })) + ((({1'b 0,DINA[10:0] ,1'b 0}) & {DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] ,DINB[1] }));
		x1r <= ((({2'b 00,DINA[10:0] }) & {DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] ,DINB[2] })) + ((({1'b 0,DINA[10:0] ,1'b 0}) & {DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] ,DINB[3] }));
		x2r <= ((({2'b 00,DINA[10:0] }) & {DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] ,DINB[4] })) + ((({1'b 0,DINA[10:0] ,1'b 0}) & {DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] ,DINB[5] }));
		x3r <= ((({2'b 00,DINA[10:0] }) & {DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] ,DINB[6] })) + ((({1'b 0,DINA[10:0] ,1'b 0}) & {DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] ,DINB[7] }));
		// 2nd
		y0r <= ({2'b 00,x0r[12:0] }) + ({x1r[12:0] ,2'b 00});
		y1r <= ({2'b 00,x2r[12:0] }) + ({x3r[12:0] ,2'b 00});
		// 3rd
		z0r <= ({4'b 0000,y0r[14:0] }) + ({y1r[14:0] ,4'b 0000});
	end
end

assign DOUT = z0r;

endmodule
