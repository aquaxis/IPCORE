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

// 400kHz = 2.5us
//  2.5 x 1000 x 2 / Xns(Freq)
module aq_i2c_master  #(
	parameter		MAX_COUNT = 16'd10000	// for 100MHz
)
(
	input			rst_n,
	input			clk,

	input [3:0]	cmd_wr,
	input [31:0]	cmd_din,
	output [31:0]	cmd_dout,

	output [31:0]	sts_dout,

	input [9:0]	adrs,
	input [3:0]	wena,
	input [31:0]	wdata,
	output [31:0]	rdata,

	output			osda,
	input			isda,
	output			osck
);
	// Command
	// [31]    Command(0:Write, 1:Read)
	// [24:16] Read length
	// [ 8: 0] Write length
	//
	// Status
	// [31]		Busy
	// [30]		Idle
	// [29]		0:Write, 1:Read
	// [28]		Error
	// [24:16]		Read Count
	// [ 8: 0]		Write Count

	reg			r_osda;
	reg			r_osck;

	reg [15:0]	clk_count;
	reg [2:0]	state;
	reg [2:0]	reg_count;
	wire		clk_point;
	reg			busy;
	reg 		err;
	reg			cmd;
	reg [7:0]	getdata, putdata;

	reg [8:0]	ramb_adrs;

	reg [8:0]	rmax, rcount, wmax, wcount;

	wire		w_start_h, w_start_c;
	wire		w_sclk, w_sclk_p;
	wire		w_stop_h, w_stop_c;

	assign w_start_h	= (clk_count[15:0] >= (MAX_COUNT / 3))?1'b0:1'b1;
	assign w_start_c	= (clk_count[15:0] >= (MAX_COUNT - (MAX_COUNT / 3)))?1'b0:1'b1;
	assign w_sclk		= ((clk_count[15:0] >= (MAX_COUNT / 3)) && (clk_count[15:0] <= (MAX_COUNT - (MAX_COUNT / 3))))?1'b1:1'b0;
	assign w_sclk_p	= ((clk_count[15:0] == (MAX_COUNT / 2)))?1'b1:1'b0;
	assign w_stop_h	= (clk_count[15:0] <= (MAX_COUNT - (MAX_COUNT / 3)))?1'b0:1'b1;
	assign w_stop_c	= (clk_count[15:0] <= (MAX_COUNT / 3))?1'b0:1'b1;

	assign clk_point = (clk_count[15:0] == MAX_COUNT)?1'b1:1'b0;

	localparam S_IDLE		= 3'd0;
	localparam S_PRESTART		= 3'd7;
	localparam S_START		= 3'd1;
	localparam S_WDATA		= 3'd2;
	localparam S_SACK		= 3'd3;
	localparam S_RDATA		= 3'd4;
	localparam S_MACK		= 3'd5;
	localparam S_STOP		= 3'd6;

//	reg [31:0]		ram[0:127];

	// I2C Clock
	// CLK = 100MHz for 400KHz(3.0us)
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			clk_count[15:0]			<= 16'd0;
		end else begin
			if(state == S_IDLE) begin
				clk_count[15:0]		<= 16'd0;
			end else begin
				if(clk_point == 1'b1) begin
					clk_count[15:0]	<= 16'd0;
				end else begin
					clk_count[15:0]	<= clk_count[15:0] + 16'd1;
				end
			end
		end
	end

/*
	reg [31:0] rama_data, ramb_data;

	// Port A
	always @(posedge clk) begin
		if(wena) begin
			ram[wadrs[8:2]] <= wdata[31:0];
		end
		rama_data[31:0] <= ram[radrs[8:2]];
	end

	// Port B
	always @(posedge clk) begin
		if(ramb_ena) begin
			case(ramb_adrs[1:0])
				2'b00: ram[ramb_adrs[8:2]][ 7: 0] <= getdata[7:0];
				2'b01: ram[ramb_adrs[8:2]][15: 8] <= getdata[7:0];
				2'b10: ram[ramb_adrs[8:2]][23:16] <= getdata[7:0];
				2'b11: ram[ramb_adrs[8:2]][31:24] <= getdata[7:0];
			endcase
		end
		ramb_data[31:0] <= ram[ramb_adrs[8:2]];
	end
*/
	wire [3:0]		ramb_we;
	wire			ramb_ena;
	wire			ramb_bank;
	wire [31:0]	ramb_rdata, ramb_wdata;
	assign ramb_ena = ((state == S_MACK) && (w_sclk_p == 1'b1))?1'b1:1'b0;
	assign ramb_bank = (state == S_MACK)?1'b1:1'b0;
	assign ramb_we[0] = ((ramb_ena == 1'b1) && (ramb_adrs[1:0] == 2'b00))?1'b1:1'b0;
	assign ramb_we[1] = ((ramb_ena == 1'b1) && (ramb_adrs[1:0] == 2'b01))?1'b1:1'b0;
	assign ramb_we[2] = ((ramb_ena == 1'b1) && (ramb_adrs[1:0] == 2'b10))?1'b1:1'b0;
	assign ramb_we[3] = ((ramb_ena == 1'b1) && (ramb_adrs[1:0] == 2'b11))?1'b1:1'b0;
	assign ramb_wdata[31:0] = {getdata[7:0], getdata[7:0], getdata[7:0], getdata[7:0]};
/*
	// Xilinx Spartan 6
	RAMB16BWE_S36_S36 u_ram(
		.CLKA	( clk					),
		.ENA	( 1'b1					),
		.ADDRA	( {1'b0, adrs[9:2]}	),	// 9bit
		.WEA	( wena[3:0]			),	// 4bit
		.DIA	( wdata[31:0]			),
		.DIPA	( 4'd0					),	// Parity
		.DOA	( rdata[31:0]			),
		.DOPA	( 						),	// Parity
		.SSRA	( 1'b0					),

		.CLKB	( clk					),
		.ENB	( 1'b1					),
		.ADDRB	( {1'b0, ramb_bank, ramb_adrs[8:2]}	),	// 9bit
		.WEB	( ramb_we[3:0]			),	// 4bit
		.DIB	( ramb_wdata[31:0]	),
		.DIPB	( 4'd0					),
		.DOB	( ramb_rdata[31:0]	),
		.DOPB	( 						),
		.SSRB	( 1'b0					)
	);
*/

	// Xilinx 7 Series
  RAMB36E1
  #(
    .WRITE_WIDTH_A(36),
    .WRITE_WIDTH_B(36),
    .READ_WIDTH_A(36),
    .READ_WIDTH_B(36)
  )
  u_ram(
    .CLKARDCLK(clk),
    .ADDRARDADDR({2'd0, adrs[9:2], 5'd0}),
    .ENARDEN(1'b1),
    .REGCEAREGCE(1'b1),
    .RSTRAMARSTRAM(~rst_n),
    .RSTREGARSTREG(~rst_n),
    .WEA(wena[3:0]),
    .DIADI(wdata[31:0]),
    .DIPADIP(4'd0),
    .DOADO(rdata[31:0]),
    .DOPADOP(),

    .CLKBWRCLK(clk),
    .ADDRBWRADDR({2'd0, ramb_bank, ramb_adrs[8:2], 5'd0}),
    .ENBWREN(1'b1),
    .REGCEB(1'b1),
    .RSTRAMB(~rst_n),
    .RSTREGB(~rst_n),
    .WEBWE(ramb_we[3:0]),
    .DIBDI(ramb_wdata[31:0]),
    .DIPBDIP(4'd0),
    .DOBDO(ramb_rdata[31:0]),
    .DOPBDOP()
  );

/*
ram32x256 u_ram1(
	.A_CLK	(clk),
	.A_WE	(wena[3:0]),
	.A_ADRS	(adrs[9:2]),
	.A_DIN	(wdata),
//	.A_DOUT	(rdata),

	.B_CLK	(clk),
//	.B_WE	(ramb_we[3:0]),
	.B_ADRS	({ramb_bank, ramb_adrs[8:2]}),
//	.B_DIN	(ramb_wdata[31:0]),
	.B_DOUT	(ramb_rdata[31:0])
);

ram32x256 u_ram2(
	.B_CLK	(clk),
//	.B_WE	(wena[3:0]),
	.B_ADRS	(adrs[9:2]),
//	.B_DIN	(wdata),
	.B_DOUT	(rdata),

	.A_CLK	(clk),
	.A_WE	(ramb_we[3:0]),
	.A_ADRS	({ramb_bank, ramb_adrs[8:2]}),
	.A_DIN	(ramb_wdata[31:0])
//	.A_DOUT	(ramb_rdata[31:0])
);
*/

	wire [7:0]	w_rama_data;
	assign w_rama_data[7:0] =	((ramb_adrs[1:0] == 2'h0)?ramb_rdata[ 7: 0]:8'd0) |
									((ramb_adrs[1:0] == 2'h1)?ramb_rdata[15: 8]:8'd0) |
									((ramb_adrs[1:0] == 2'h2)?ramb_rdata[23:16]:8'd0) |
									((ramb_adrs[1:0] == 2'h3)?ramb_rdata[31:24]:8'd0);

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			state				<= S_IDLE;
			reg_count[2:0]	<= 3'd0;
			busy				<= 1'b0;
			cmd					<= 1'b0;
			rmax[8:0]			<= 9'd0;
			wmax[8:0]			<= 9'd0;
			rcount[8:0]		<= 9'd0;
			wcount[8:0]		<= 9'd0;
			ramb_adrs[8:0]	<= 9'd0;
			putdata[7:0]    <= 8'd0;
		end else begin
			case(state)
				S_IDLE: begin
					if(cmd_wr[3] == 1'b1) begin
						state			<= S_PRESTART;
						busy			<= 1'b1;
//						rmax[8:0]		<= cmd_din[24:16];
//						wmax[8:0]		<= cmd_din[8:0];
						rcount[8:0]	<= 9'd0;
						wcount[8:0]	<= 9'd0;
						reg_count[2:0]	<= 3'd0;
						ramb_adrs[8:0]	<= 9'd0;
					end else begin
						busy			<= 1'b0;
					end
					if(cmd_wr[3] == 1'b1) begin
						cmd				<= cmd_din[31];
						rmax[8]		<= cmd_din[24];
					end
					if(cmd_wr[2] == 1'b1) begin
						rmax[7:0]		<= cmd_din[23:16];
					end
					if(cmd_wr[1] == 1'b1) begin
						wmax[8]		<= cmd_din[8];
					end
					if(cmd_wr[0] == 1'b1) begin
						wmax[7:0]		<= cmd_din[7:0];
					end
				end
				S_PRESTART: begin
                    if(clk_point == 1'b1) begin
                        state            <= S_START;
                    end
                end
				S_START: begin
					if(clk_point == 1'b1) begin
						state			<= S_WDATA;
					end
					reg_count[2:0]	<= 3'd0;
					putdata[7:0]		<= w_rama_data[7:0];
				end
				S_WDATA: begin
					if(clk_point == 1'b1) begin
						if(reg_count[2:0] == 3'd7) begin
							state				<= S_SACK;
							ramb_adrs[8:0]	<= ramb_adrs[8:0] + 9'd1;
							wcount[8:0]		<= wcount[8:0] + 9'd1;
						end else begin
							reg_count[2:0]	<= reg_count[2:0] + 3'd1;
							putdata[7:0]		<= {putdata[6:0], 1'b0};
						end
					end
				end
				S_SACK: begin
					if(clk_point == 1'b1) begin
//						if((err == 1'b0) begin
							if((cmd == 1'b1) && (wcount[8:0] == (wmax[8:0] - 9'd1))) begin
								// Sr(Next Start) for Read
								state	<= S_START;
							end else begin
								if(wcount[8:0] == wmax[8:0]) begin
									if(cmd == 1'b1) begin
										// Next for Read
										state				<= S_RDATA;
										ramb_adrs[8:0]	<= 9'd0;
									end else begin
										// Finish for Write
										state				<= S_STOP;
									end
								end else begin
									state	<= S_WDATA;
								end
							end
//						end else begin
//							state	<= S_STOP;
//						end
					end
					putdata[7:0]	<= w_rama_data[7:0];
					reg_count[2:0]	<= 3'd0;
				end
				S_RDATA: begin
					if(clk_point == 1'b1) begin
						if(reg_count[2:0] == 3'd7) begin
							state			<= S_MACK;
							rcount[8:0]	<= rcount[8:0] + 9'd1;
						end else begin
							reg_count[2:0]	<= reg_count[2:0] + 3'd1;
						end
					end
				end
				S_MACK: begin
					if(clk_point == 1'b1) begin
						if(rcount[8:0] == rmax[8:0]) begin
							state	<= S_STOP;
						end else begin
							state	<= S_RDATA;
							ramb_adrs[8:0]	<= ramb_adrs[8:0] + 9'd1;
						end
					end
					reg_count[2:0]	<= 3'd0;
				end
				S_STOP: begin
					if(clk_point == 1'b1) begin
						state	<= S_IDLE;
					end
				end
			endcase
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_osda <= 1'b1;
			r_osck <= 1'b1;
		end else begin
			case(state)
				S_IDLE: begin
					r_osda <= 1'b1;
					r_osck <= 1'b1;
				end
				S_PRESTART: begin
                    r_osda <= 1'b1;
                    r_osck <= 1'b0;
                end
				S_START: begin
					r_osda <= w_start_h;
					r_osck <= w_start_c;
				end
				S_STOP: begin
					r_osda <= w_stop_h;
					r_osck <= w_stop_c;
				end
				S_RDATA: begin
					r_osda <= 1'b1;
					r_osck <= w_sclk;
				end
				S_WDATA: begin
					r_osda <= putdata[7];
					r_osck <= w_sclk;
				end
				S_MACK: begin
					r_osda <= (rcount[8:0] == rmax[8:0])?1'b1:1'b0;
					r_osck <= w_sclk;
				end
				default: begin
					r_osda <= 1'b1;
					r_osck <= w_sclk;
				end
			endcase
		end
	end
	assign osda = r_osda;
	assign osck = r_osck;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			getdata[7:0]	<= 8'd0;
			err				<= 1'b0;
		end else begin
			if(state == S_RDATA) begin
				if(w_sclk_p == 1'b1) begin
					getdata[7:0] <= {getdata[6:0], isda};
				end
			end
			if(state == S_START) begin
				err <= 1'b0;
			end else begin
				if((state == S_SACK) && (w_sclk_p == 1'b1) && (isda == 1'b1)) begin
					err <= 1'b1;
				end
			end
		end
	end

	assign cmd_dout[31:0] = {cmd, 6'd0, rmax[8:0], 7'd0, wmax[8:0]};
	assign sts_dout[31:0] = {busy, ~busy, cmd, err, 3'd0, rcount[8:0], 7'd0, wcount[8:0]};

endmodule
