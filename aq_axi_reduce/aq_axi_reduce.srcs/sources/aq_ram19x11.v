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
module aq_ram19x11 (
	input			CLKA,
	input			WEA,
	input [10:0]	ADDRA,
	input [18:0]	DINA,
	
	input			CLKB,
	input [10:0]	ADDRB,
	output [18:0]	DOUTB
);

reg [18:0]	array [0:2048];

always @( posedge CLKA ) begin
	if( WEA ) begin
		array[ ADDRA[10:0] ] = DINA[18:0];
	end
end

reg [18:0] data;
always @( posedge CLKB ) begin
	data[18:0]	= array[ ADDRB[10:0] ];
end

assign DOUTB[18:0] = data[18:0];

endmodule
