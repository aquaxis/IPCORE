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
`timescale 1ps / 1ps

//----------------------------------------------------------------------------
// JPEG YCbCr -> RGB Conveter
//----------------------------------------------------------------------------
module aq_djpeg_ycbcr2rgb(
	input			clk,
	input			rst,

	input			InEnable,
	output			InRead,
	input [11:0]	InBlockX,
	input [11:0]	InBlockY,
	input [2:0]	InComp,
	output [7:0]	InAddress,
	input [8:0]	InY,
	input [8:0]	InCb,
	input [8:0]	InCr,

	output			OutEnable,
	output [15:0]	OutPixelX,
	output [15:0]	OutPixelY,
	output [7:0]	OutR,
	output [7:0]	OutG,
	output [7:0]	OutB
);
	reg				RunActive;
	reg [7:0]		RunCount;
	reg [11:0]	 	RunBlockX;
	reg [11:0]	 	RunBlockY;
	reg [2:0]		RunComp;

	always @(posedge clk or negedge rst) begin
		if(!rst) begin
			RunActive	<= 1'b0;
			RunCount	<= 8'h00;
			RunBlockX	<= 12'h000;
			RunBlockY	<= 12'h000;
			RunComp	<= 1'b0;
		end else begin
			if(RunActive == 1'b0) begin
				if(InEnable == 1'b1) begin
					RunActive	<= 1'b1;
					RunBlockX	<= InBlockX;
					RunBlockY	<= InBlockY;
					RunComp	<= InComp;
				end
				RunCount	<= 8'h00;
			end else begin
				if(RunCount == 8'd255) begin
					RunActive	<= 1'b0;
					RunCount	<= 8'd0;
				end else begin
					RunCount	<= RunCount +8'd1;
				end
			end
		end
	end

	assign InRead		= RunActive;
	assign InAddress	= RunCount;

	reg			PreEnable;
	reg [15:0]	PreCountX;
	reg [15:0]	PreCountY;
	reg			Phase0Enable;
	reg [15:0]	Phase0CountX;
	reg [15:0]	Phase0CountY;
	reg			Phase1Enable;
	reg [15:0]	Phase1CountX;
	reg [15:0]	Phase1CountY;
	reg			Phase2Enable;
	reg [15:0]	Phase2CountX;
	reg [15:0]	Phase2CountY;
	reg			Phase3Enable;
	reg [15:0]	Phase3CountX;
	reg [15:0]	Phase3CountY;

	reg signed [31:0] rgb00r;
	reg signed [31:0] r00r;
	reg signed [31:0] g00r;
	reg signed [31:0] g01r;
	reg signed [31:0] b00r;
	reg signed [31:0] r10r;
	reg signed [31:0] g10r;
	reg signed [31:0] g11r;
	reg signed [31:0] b10r;
	reg signed [31:0] r20r;
	reg signed [31:0] g20r;
	reg signed [31:0] b20r;

	wire signed [8:0] DataY;
	wire signed [8:0] DataCb;
	wire signed [8:0] DataCr;

	reg signed [8:0]	Phase0Y;
	reg signed [8:0]	Phase0Cb;
	reg signed [8:0]	Phase0Cr;

	wire signed [19:0] C_RR = 20'h59BA5; // R_Cr: 1.402	* 0x4000
	wire signed [19:0] C_GB = 20'h16066; // G_Cb: 0.34414 * 0x4000
	wire signed [19:0] C_GR = 20'h2DB47; // G_Cr: 0.71414 * 0x4000
	wire signed [19:0] C_BB = 20'h71687; // B_Cb: 1.772	* 0x4000

	assign			 DataY	= InY;
	assign			 DataCb = InCb;
	assign			 DataCr = InCr;

	reg signed [8:0]	Phase1Y,Phase1Cb,Phase1Cr;
	reg signed [8:0]	Phase2Y,Phase2Cb,Phase2Cr;

	always @(posedge clk or negedge rst) begin
		if(!rst) begin
			rgb00r <= 0;
			r00r	<= 0;
			g00r	<= 0;
			g01r	<= 0;
			b00r	<= 0;

			r10r	<= 0;
			g10r	<= 0;
			g11r	<= 0;
			b10r	<= 0;

			r20r	<= 0;
			g20r	<= 0;
			b20r	<= 0;

			Phase0Enable <= 1'b0;
			Phase0CountX <= 16'h0000;
			Phase0CountY <= 16'h0000;
			Phase1Enable <= 1'b0;
			Phase1CountX <= 16'h0000;
			Phase1CountY <= 16'h0000;
			Phase2Enable <= 1'b0;
			Phase2CountX <= 16'h0000;
			Phase2CountY <= 16'h0000;
			Phase3Enable <= 1'b0;
			Phase3CountX <= 16'h0000;
			Phase3CountY <= 16'h0000;
		end else begin
			// Pre
			PreEnable <= RunActive;
			if(RunComp == 3) begin
				// コンポーネント数が3のとき、16x16が1ブロック
				PreCountX <= {RunBlockX,RunCount[3:0]};
				PreCountY <= {RunBlockY,RunCount[7:4]};
			end else begin
				// コンポーネント数が1のとき、32x8が1ブロック
				PreCountX <= {RunBlockX[10:0],RunCount[7],RunCount[3:0]};
				PreCountY <= {1'b0,RunBlockY[11:0],RunCount[6:4]};
			end

			// Phase0
			Phase0Enable	<= PreEnable;
			Phase0CountX	<= PreCountX;
			Phase0CountY	<= PreCountY;
			Phase0Y		<= DataY;
			Phase0Cb		<= DataCb;
			Phase0Cr		<= DataCr;

			// Phase1
			Phase1Enable	<= Phase0Enable;
			Phase1CountX	<= Phase0CountX;
			Phase1CountY	<= Phase0CountY;

			rgb00r <= 32'h02000000 + {Phase0Y[8],Phase0Y[8],Phase0Y[8],Phase0Y[8],Phase0Y[8],Phase0Y[8:0],18'h0000};
			r00r	<= Phase0Cr * C_RR;
			g00r	<= Phase0Cb * C_GB;
			g01r	<= Phase0Cr * C_GR;
			b00r	<= Phase0Cb * C_BB;

			Phase1Y	<= Phase0Y;
			Phase1Cb	<= Phase0Cb;
			Phase1Cr	<= Phase0Cr;

			// Phase2
			Phase2Enable	<= Phase1Enable;
			Phase2CountX	<= Phase1CountX;
			Phase2CountY	<= Phase1CountY;

			r10r	<= rgb00r + r00r;
			g10r	<= rgb00r - g00r;
			g11r	<= g01r;
			b10r	<= rgb00r + b00r;

			Phase2Y	<= Phase1Y;
			Phase2Cb	<= Phase1Cb;
			Phase2Cr	<= Phase1Cr;

			// Phase3
			Phase3Enable	<= Phase2Enable;
			Phase3CountX	<= Phase2CountX;
			Phase3CountY	<= Phase2CountY;
			r20r	<= r10r;
			g20r	<= g10r - g11r;
			b20r	<= b10r;
		end
	end

	assign OutEnable	= Phase3Enable;
	assign OutPixelX	= Phase3CountX;
	assign OutPixelY	= Phase3CountY;
	assign OutR		= (r20r[31])?8'h00:(r20r[26])?8'hFF:r20r[25:18];
	assign OutG		= (g20r[31])?8'h00:(g20r[26])?8'hFF:g20r[25:18];
	assign OutB		= (b20r[31])?8'h00:(b20r[26])?8'hFF:b20r[25:18];
endmodule
