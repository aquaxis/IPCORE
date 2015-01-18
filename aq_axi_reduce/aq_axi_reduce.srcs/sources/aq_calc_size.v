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
module aq_calc_size(
	input			RST_N,
	input			CLK,
	input			ENA,
	input			START,
	input [10:0]	ORG,
	input [10:0]	CNV,
	output			VALID,
	output [10:0]	MA,
	output [10:0]	MB
);

wire [10:0]	next_ma, next_mb;
reg [10:0]	reg_ma, reg_mb;

assign next_ma[10:0] = (START)?11'd0:ORG-reg_mb;
assign next_mb[10:0] = (START)?CNV:CNV-next_ma;

always @(posedge CLK or negedge RST_N) begin
	if(!RST_N) begin
		reg_ma	<= 11'd0;
		reg_mb	<= 11'd0;
	end else begin
		if( ENA ) begin
			reg_ma	<= next_ma;
			reg_mb	<= next_mb;
		end;
	end
end

assign MA		= reg_ma;
assign MB		= reg_mb;
assign VALID	= (reg_ma > 11'd0)?1'b1:1'b0;

endmodule
