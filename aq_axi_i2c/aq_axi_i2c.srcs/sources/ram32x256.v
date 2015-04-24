/*
 * Copyright (C)2014-2015 AQUAXIS TECHNOLOGY.
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
module ram32x256(
	input			A_CLK,
	input [3:0]		A_WE,
	input [7:0]		A_ADRS,
	input [31:0]	A_DIN,
//	output [31:0]	A_DOUT,

	input			B_CLK,
//	input [3:0]		B_WE,
	input [7:0]		B_ADRS,
//	input [31:0]	B_DIN,
	output [31:0]	B_DOUT
);

reg [7:0]	dataa	[0:255];
reg [7:0]	datab	[0:255];
reg [7:0]	datac	[0:255];
reg [7:0]	datad	[0:255];
reg [31:0]	outdataa, outdatab;

always @(posedge A_CLK) begin
	if(A_WE[0]) begin
		dataa[A_ADRS] <= A_DIN[7:0];
	end
	if(A_WE[1]) begin
		datab[A_ADRS] <= A_DIN[15:8];
	end
	if(A_WE[2]) begin
		datac[A_ADRS] <= A_DIN[23:16];
	end
	if(A_WE[3]) begin
		datad[A_ADRS] <= A_DIN[31:24];
	end
//	outdataa[31:0]	<= {datad[A_ADRS], datac[A_ADRS], datab[A_ADRS], dataa[A_ADRS]};
end

always @(posedge B_CLK) begin
/*
	if(B_WE[0]) begin
		dataa[B_ADRS] <= B_DIN[7:0];
	end
	if(B_WE[1]) begin
		datab[B_ADRS] <= B_DIN[15:8];
	end
	if(B_WE[2]) begin
		datac[B_ADRS] <= B_DIN[23:16];
	end
	if(B_WE[3]) begin
		datad[B_ADRS] <= B_DIN[31:24];
	end
*/
	outdatab[31:0]	<= {datad[B_ADRS], datac[B_ADRS], datab[B_ADRS], dataa[B_ADRS]};
end

//assign A_DOUT[31:0]	= outdataa[31:0];
assign B_DOUT[31:0]	= outdatab[31:0];

endmodule
