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

module aq_djpeg_ycbcr(
	input			rst,
	input			clk,

	input			ProcessInit,
	input [2:0]	JpegComp,

	input			DataInEnable,
	input [2:0]	DataInPage,
	input [1:0]	DataInCount,
	output			DataInIdle,
	input [8:0]	Data0In,
	input [8:0]	Data1In,
	input [11:0]	DataInBlockWidth,
	output			DataInFull,

	output			OutEnable,
	output [15:0]	OutPixelX,
	output [15:0]	OutPixelY,
	output [7:0]	OutR,
	output [7:0]	OutG,
	output [7:0]	OutB
);
	reg [2:0]		DataInColor;
	reg [11:0]		DataInBlockX;
	reg [11:0]		DataInBlockY;

	wire			ConvertEnable;
	wire			ConvertRead;
	wire			ConvertBank;
	wire [7:0]		ConvertAddress;
	wire [8:0]		DataY;
	wire [8:0]		DataCb;
	wire [8:0]		DataCr;
	wire [11:0]		ConvertBlockX;
	wire [11:0]		ConvertBlockY;

	always @(posedge clk or negedge rst) begin
		if(!rst) begin
			DataInColor	<= 3'd0;
		end else begin
			if(ProcessInit) begin
				DataInColor <= 3'd0;
			end else if((DataInEnable == 1'b1) && (DataInPage == 3'd7) && (DataInCount == 2'd3)) begin
				// コンポーネント数が3ならYCbCrで411
				// コンポーネント数が1ならグレースケールで400
				if(	((JpegComp == 3) && (DataInColor == 3'd5)) || 
					((JpegComp == 1) && (DataInColor == 3'd3))) begin
//				if(DataInColor == 3'd5) begin 
					DataInColor <= 3'd0;
				end else begin
					DataInColor <= DataInColor + 3'd1;
				end
			end
		end
	end

	//------------------------------------------------------------------------
	// YCbCr Memory
	//------------------------------------------------------------------------
	aq_djpeg_ycbcr_mem u_jpeg_ycbcr_mem(
		.rst				( rst				),
		.clk				( clk				),

		.DataInit			( ProcessInit		),
		.JpegComp			( JpegComp			),

		.DataInEnable		( DataInEnable	),
		.DataInColor		( DataInColor		),
		.DataInPage		( DataInPage		),
		.DataInCount		( DataInCount		),
		.Data0In			( Data0In			),
		.Data1In			( Data1In			),
		.DataInFull		( DataInFull		),

		.DataOutEnable	( ConvertEnable	),
		.DataOutAddress	( ConvertAddress	),
		.DataOutRead		( ConvertRead		),
		.DataOutY			( DataY			),
		.DataOutCb			( DataCb			),
		.DataOutCr			( DataCr			)
	);
	//------------------------------------------------------------------------
	// YCbCr to RGB
	//------------------------------------------------------------------------
	always @(posedge clk or negedge rst) begin
		if(!rst) begin
			DataInBlockX <= 12'd0;
			DataInBlockY <= 12'd0;
		end else begin
			if(ProcessInit) begin
				DataInBlockX <= 12'd0;
				DataInBlockY <= 12'd0;
			end else if((ConvertRead == 1'b1) && (ConvertAddress == 8'd255)) begin
//				if(JpegComp == 3)  begin
					if(DataInBlockWidth == DataInBlockX +1) begin
						DataInBlockX <= 12'd0;
						DataInBlockY <= DataInBlockY + 12'd1;
					end else begin
						DataInBlockX <= DataInBlockX + 12'd1;
					end
//				end else begin
//					if(DataInBlockWidth == DataInBlockX +3) begin
//						DataInBlockX <= 12'd0;
//						DataInBlockY <= DataInBlockY + 12'd1;
//					end else begin
//						DataInBlockX <= DataInBlockX + 12'd1;
//					end
//				end
			end
		end
	end
	
	wire [8:0]	tDataCb,tDataCr;
	assign tDataCb = (JpegComp == 1)?9'd0:DataCb;
	assign tDataCr = (JpegComp == 1)?9'd0:DataCr;

	aq_djpeg_ycbcr2rgb u_jpeg_yccr2rgb(
		.rst		( rst				),
		.clk		( clk				),

		.InEnable	( ConvertEnable	),
		.InRead	( ConvertRead		),
		.InBlockX	( DataInBlockX	),
		.InBlockY	( DataInBlockY	),
		.InComp	( JpegComp			),
		.InAddress	( ConvertAddress	),
		.InY		( DataY			),
		.InCb		( tDataCb			),
		.InCr		( tDataCr			),

		.OutEnable	( OutEnable		),
		.OutPixelX	( OutPixelX		),
		.OutPixelY	( OutPixelY		),
		.OutR		( OutR				),
		.OutG		( OutG				),
		.OutB		( OutB				)
	);
endmodule
