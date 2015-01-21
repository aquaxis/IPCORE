/*
 * Copyright (C)2007-2015 AQUAXIS TECHNOLOGY.
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

module tb_aq_fifo;

	parameter	WR_TIME	= 10000;
	parameter	RD_TIME	= 2000;
//	parameter	WR_TIME	= 4000;
//	parameter	RD_TIME	= 10000;

	wire			wr_ena;
	wire [7:0]	wr_data;
	wire			wr_last;
	wire			rd_ena;

	reg				RST_N;
	reg				WR_CLK;
	reg				WR_ENA;
	reg	[7:0]		WR_DATA;
	reg				WR_LAST;
	wire			WR_FULL;
	wire			WR_ALM_FULL;
	reg	[3:0]		WR_ALM_COUNT;

	reg				RD_CLK;
	reg				RD_ENA;
	wire [7:0]	RD_DATA;
	wire			RD_EMPTY;
	wire			RD_ALM_EMPTY;
	reg [3:0]		RD_ALM_COUNT;

	integer		WriteEnd, ReadEnd;

	assign #10 wr_ena	= WR_ENA;
	assign #10 wr_data	= WR_DATA;
	assign #10 wr_last	= WR_LAST;
	assign #10 rd_ena	= RD_ENA;

	aq_fifo #(4,8) u_fifo(
		.RST_N					( RST_N			),

		.FIFO_WR_CLK			( WR_CLK			),
		.FIFO_WR_ENA			( wr_ena			),
		.FIFO_WR_DATA			( wr_data			),
		.FIFO_WR_LAST			( wr_last			),
		.FIFO_WR_FULL			( WR_FULL			),
		.FIFO_WR_ALM_FULL	( WR_ALM_FULL		),
		.FIFO_WR_ALM_COUNT	( WR_ALM_COUNT	),

		.FIFO_RD_CLK			( RD_CLK			),
		.FIFO_RD_ENA			( rd_ena			),
		.FIFO_RD_DATA			( RD_DATA			),
		.FIFO_RD_EMPTY		( RD_EMPTY		),
		.FIFO_RD_ALM_EMPTY	( RD_ALM_EMPTY	),
		.FIFO_RD_ALM_COUNT	( RD_ALM_COUNT	)
		);

	// Clock & Reset signal
	initial begin
		WR_CLK = 1'b0;
		RD_CLK = 1'b0;
	end

	always begin
		#(WR_TIME/2)	WR_CLK <= ~WR_CLK;
	end

	always begin
		#(RD_TIME/2)	RD_CLK <= ~RD_CLK;
	end

	initial begin
		RST_N = 1'b0;
		repeat (4) @(posedge WR_CLK); #2;
		RST_N = 1'b1;
	end

	// Write Task
	task WRITE;
		input [7:0]	data;
		input			last;
		begin
			WR_ENA		= 1'b1;
			WR_DATA	= data;
			WR_LAST	= last;
			@(posedge WR_CLK);
			WR_ENA		= 1'b0;
		end
	endtask

	// Read Task
	task READ;
		begin
			if(~RD_EMPTY) begin
				RD_ENA	= 1'b1;
				@(posedge RD_CLK);
			end
			if(RD_EMPTY) begin
				RD_ENA	= 1'b0;
				@(posedge RD_CLK);
			end
		end
	endtask

	always begin
		#100;
		READ();
	end
	
	// Init
	initial begin
		WR_ENA			= 1'b0;
		WR_DATA		= 8'h00;
		WR_LAST		= 1'b0;
		WR_ALM_COUNT	= 4'd1;
		RD_ENA			= 1'b0;
		RD_ALM_COUNT	= 4'd1;
	end

	integer i;
	integer c;
	integer f;

	// Write Sequence
	initial begin
		WriteEnd = 0;
		c = 0;
		f = 0;
		i = 0;
		wait(RST_N == 1);
		
		@(posedge WR_CLK);
		
		while(i<256) begin
			#100;
			if(!WR_FULL) begin
				if(c == 15) begin
					c = 0;
					f = 1;
				end else begin
					c = c + 1;
					f = 0;
				end
				WRITE(i, f);
				i = i + 1;
			end
		end
		
		repeat (1000) @(posedge WR_CLK);
		WriteEnd = 1;
		$finish();
	end

	integer s;

	// Read Sequence
	initial begin
		s = 0;
	end

	initial begin
		while(1) begin
			@(posedge RD_CLK);
			if(RD_ENA) begin
				if(RD_DATA != s) $display("Error: %02X != %02X", s, RD_DATA);
				s=s+1;
			end
		end
	end
	
	initial begin
		wait(WriteEnd == 1);
		wait(ReadEnd == 1);
		//$finish;
	end
	
endmodule
