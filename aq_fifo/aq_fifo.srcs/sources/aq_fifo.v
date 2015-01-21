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

module aq_fifo
#(
	parameter FIFO_DEPTH	= 8,
	parameter FIFO_WIDTH	= 32
)
(
	input							RST_N,

	input							FIFO_WR_CLK,
	input							FIFO_WR_ENA,
	input [FIFO_WIDTH -1:0]		FIFO_WR_DATA,
	input							FIFO_WR_LAST,
	output 						FIFO_WR_FULL,
	output 						FIFO_WR_ALM_FULL,
	input [FIFO_DEPTH -1:0]		FIFO_WR_ALM_COUNT,

	input 							FIFO_RD_CLK,
	input 							FIFO_RD_ENA,
	output [FIFO_WIDTH -1:0]	FIFO_RD_DATA,
	output 						FIFO_RD_EMPTY,
	output 						FIFO_RD_ALM_EMPTY,
	input [FIFO_DEPTH -1:0]		FIFO_RD_ALM_COUNT
);
	reg [FIFO_DEPTH -1:0]	wr_adrs, wr_rd_count_d1r, wr_rd_count;
	reg 						wr_full, wr_alm_full;

	reg [FIFO_DEPTH -1:0]	rd_adrs, rd_wr_count_d1r, rd_wr_count;
	reg 						rd_empty, rd_alm_empty;

	wire 						wr_ena;
	reg 						wr_ena_req;
	reg [FIFO_DEPTH -1:0]	wr_adrs_req;
	wire 						rd_wr_ena, rd_wr_ena_ack;
	reg 						rd_wr_ena_d1r, rd_wr_ena_d2r, rd_wr_ena_d3r;
	reg							rd_wr_full_d1r, rd_wr_full;
	
	wire						rd_ena;
	reg 						rd_ena_req;
	reg [FIFO_DEPTH -1:0]	rd_adrs_req;
	wire 						wr_rd_ena, wr_rd_ena_ack;
	reg 						wr_rd_ena_d1r, wr_rd_ena_d2r, wr_rd_ena_d3r;
	reg							wr_rd_empty_d1r, wr_rd_empty;

	wire						reserve_ena;
	reg							reserve_empty, reserve_read;
	wire						reserve_alm_empty;
	reg [FIFO_WIDTH -1:0]	reserve_data;

	wire [FIFO_WIDTH -1:0]	rd_fifo;
	
	assign wr_ena = (!wr_full)?(FIFO_WR_ENA):1'b0;

	/////////////////////////////////////////////////////////////////////
	// Write Block

	// Write Address
	always @(posedge FIFO_WR_CLK or negedge RST_N) begin
		if(!RST_N) begin
			wr_adrs				<= 0;
		end else begin
			if(wr_ena) wr_adrs	<= wr_adrs + 1;
		end
	end

	wire [FIFO_DEPTH -1:0] wr_adrs_s1, wr_adrs_s2;
	assign wr_adrs_s1 = wr_rd_count;
	assign wr_adrs_s2 = wr_rd_count -1;

	// make a full and almost full signal
	always @(posedge FIFO_WR_CLK or negedge RST_N) begin
		if(!RST_N) begin
			wr_full			<= 1'b0;
			wr_alm_full		<= 1'b0;
		end else begin
			if(wr_ena & (wr_adrs == wr_adrs_s1)) begin
				wr_full		<= 1'b1;
			end else if(wr_rd_ena & !(wr_adrs == wr_adrs_s1)) begin
				wr_full		<= 1'b0;
			end
			if(wr_ena & ((wr_adrs == wr_adrs_s1) | (wr_adrs == wr_adrs_s2))) begin
				wr_alm_full	<= 1'b1;
			end else if(wr_rd_ena & !((wr_adrs == wr_adrs_s1) | (wr_adrs == wr_adrs_s2))) begin
				wr_alm_full	<= 1'b0;
			end
		end
	end
	// Read Control signal from Read Block
	always @(posedge FIFO_WR_CLK or negedge RST_N) begin
		if(!RST_N) begin
			wr_rd_count_d1r	<= {FIFO_DEPTH{1'b1}};
			wr_rd_count		<= {FIFO_DEPTH{1'b1}};
		end else begin
			wr_rd_ena_d1r		<= rd_ena_req;
			wr_rd_ena_d2r		<= wr_rd_ena_d1r;
			wr_rd_ena_d3r		<= wr_rd_ena_d2r;
			if(wr_rd_ena) begin
				wr_rd_count	<= rd_adrs_req;
				wr_rd_empty	<= rd_empty;
			end
		end
	end
	assign wr_rd_ena		= wr_rd_ena_d2r & ~wr_rd_ena_d3r;
	assign wr_rd_ena_ack	= wr_rd_ena_d2r & wr_rd_ena_d3r;

	wire [FIFO_DEPTH -1:0] wr_adrs_req_s1; 
	assign wr_adrs_req_s1 = wr_adrs -1;

	// Send a write enable signal for Read Block
	always @(posedge FIFO_WR_CLK or negedge RST_N) begin
		if(!RST_N) begin
			wr_ena_req		<= 1'b0;
			wr_adrs_req		<= 0;
		end else begin
			if(wr_ena & FIFO_WR_LAST & ~rd_wr_ena_ack) begin
				wr_ena_req	<= 1'b1;
				wr_adrs_req	<= wr_adrs;
			end else if(rd_wr_ena_ack) begin
				wr_ena_req	<= 1'b0;
			end
		end
	end	

	/////////////////////////////////////////////////////////////////////
	// Read Block

	// Read Address
	always @(posedge FIFO_RD_CLK or negedge RST_N) begin
		if(!RST_N) begin
			rd_adrs		<= 0;
		end else begin
			if(!rd_empty_d & rd_ena) begin
				rd_adrs	<= rd_adrs + 1;
			end
		end
	end
	
	wire [FIFO_DEPTH -1:0] rd_adrs_s1, rd_adrs_s2;
	assign rd_adrs_s1 = rd_wr_count;
	assign rd_adrs_s2 = rd_wr_count -1;

	// make a empty and almost empty signal
	reg rd_empty_d;
	always @(posedge FIFO_RD_CLK or negedge RST_N) begin
		if(!RST_N) begin
			rd_empty		<= 1'b1;
			rd_empty_d	<= 1'b1;
			rd_alm_empty	<= 1'b1;
		end else begin
			if(rd_ena & (rd_adrs == rd_adrs_s1)) begin
				rd_empty_d	<= 1'b1;
			end else if(rd_wr_ena & !(rd_adrs == rd_adrs_s1)) begin
				rd_empty_d	<= 1'b0;
			end
			rd_empty <= rd_empty_d;
			if(rd_ena & ((rd_adrs == rd_adrs_s1) | (rd_adrs == rd_adrs_s2))) begin
				rd_alm_empty	<= 1'b1;
			end else if(rd_wr_ena & !((rd_adrs == rd_adrs_s1) | (rd_adrs == rd_adrs_s2))) begin
				rd_alm_empty	<= 1'b0;
			end
		end
	end
	
	// Write Control signal from Write Block
	always @(posedge FIFO_RD_CLK or negedge RST_N) begin
		if(!RST_N) begin
			rd_wr_ena_d1r		<= 1'b0;
			rd_wr_ena_d2r		<= 1'b0;
			rd_wr_ena_d3r		<= 1'b0;
			rd_wr_count_d1r	<= {FIFO_DEPTH{1'b1}};
			rd_wr_count		<= {FIFO_DEPTH{1'b1}};
		end else begin
			rd_wr_ena_d1r		<= wr_ena_req;
			rd_wr_ena_d2r		<= rd_wr_ena_d1r;
			rd_wr_ena_d3r		<= rd_wr_ena_d2r;
			if(rd_wr_ena) begin
				rd_wr_count	<= wr_adrs_req;
				rd_wr_full	<= wr_full;
			end
		end
	end

	// Write enable signal from write block
	assign rd_wr_ena		= ~rd_wr_ena_d3r & rd_wr_ena_d2r;
	assign rd_wr_ena_ack	= rd_wr_ena_d3r & rd_wr_ena_d2r;
	
	wire [FIFO_DEPTH -1:0] rd_adrs_req_s1; 
	assign rd_adrs_req_s1 = rd_adrs -1;
	
	// Send a read enable signal for Write Block
	always @(posedge FIFO_RD_CLK or negedge RST_N) begin
		if(!RST_N) begin
			rd_ena_req	<= 1'b0;
			rd_adrs_req	<= 0;
		end else begin
			if(~rd_ena_req & (rd_adrs_req != rd_adrs_req_s1) & ~wr_rd_ena_ack) begin
				rd_ena_req	<= 1'b1;
				rd_adrs_req	<= rd_adrs_req_s1;
			end else if(wr_rd_ena_ack) begin
				rd_ena_req	<= 1'b0;
			end
		end
	end

	/////////////////////////////////////////////////////////////////////
	// Reserve Block
	assign reserve_ena = reserve_empty_d & ~rd_empty & ~FIFO_RD_ENA;
	assign rd_ena = reserve_ena | FIFO_RD_ENA;
	reg reserve_rdena;
	reg reserve_empty_d;
	always @(posedge FIFO_RD_CLK or negedge RST_N) begin
		if(!RST_N) begin
			reserve_data			<= {FIFO_WIDTH{1'b0}};
			reserve_empty			<= 1'b1;
			reserve_rdena			<= 1'b0;
			reserve_empty_d		<= 1'b1;
		end else begin
			if(rd_ena) begin
				reserve_data		<= rd_fifo;
			end
			if(reserve_ena) begin
				reserve_empty_d	<= 1'b0;
			end else if(FIFO_RD_ENA) begin
				reserve_empty_d	<= 1'b1;
			end
			if(FIFO_RD_ENA) begin
				reserve_empty		<= 1'b1;
			end else begin
				reserve_empty		<= reserve_empty_d;
			end
			reserve_rdena			<= FIFO_RD_ENA;
		end
	end

	assign reserve_alm_empty = (rd_empty & ~reserve_empty);
	/////////////////////////////////////////////////////////////////////
	// output signals
	assign FIFO_WR_FULL			= wr_full;
	assign FIFO_WR_ALM_FULL		= wr_alm_full;
	assign FIFO_RD_EMPTY			= (FIFO_RD_ENA)?rd_empty:reserve_empty;
	assign FIFO_RD_ALM_EMPTY	= (FIFO_RD_ENA)?rd_alm_empty:reserve_alm_empty;
	assign FIFO_RD_DATA			= (reserve_empty)?rd_fifo:reserve_data;
	
	/////////////////////////////////////////////////////////////////////
	// RAM
	fifo_ram #(FIFO_DEPTH,FIFO_WIDTH) u_fifo_ram(
		.WR_CLK  ( FIFO_WR_CLK  ),
		.WR_ENA  ( wr_ena  ),
		.WR_ADRS ( wr_adrs ),
		.WR_DATA ( FIFO_WR_DATA ),

		.RD_CLK  ( FIFO_RD_CLK  ),
		.RD_ADRS ( rd_adrs ),
		.RD_DATA ( rd_fifo )
		);
	
endmodule

module fifo_ram
#(
	parameter DEPTH	= 12,
	parameter WIDTH	= 32
)
(
	input					WR_CLK,
	input					WR_ENA,
	input [DEPTH -1:0] 	WR_ADRS,
	input [WIDTH -1:0]	WR_DATA,

	input 					RD_CLK,
	input [DEPTH -1:0] 	RD_ADRS,
	output [WIDTH -1:0]	RD_DATA
);
	reg [WIDTH -1:0]		ram [0:(2**DEPTH) -1];
	reg [WIDTH -1:0]		rd_reg;
	
	always @(posedge WR_CLK) begin
		if(WR_ENA) ram[WR_ADRS] <= WR_DATA;
	end

	always @(posedge RD_CLK) begin
		rd_reg <= ram[RD_ADRS];
	end
	
	assign RD_DATA = rd_reg;
endmodule
