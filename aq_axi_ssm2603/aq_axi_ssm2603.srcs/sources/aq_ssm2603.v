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
module aq_ssm2603(
  input         RST_N,
  input         CLK,

  input         LOCAL_CS,
  input         LOCAL_RNW,
  output        LOCAL_ACK,
  input [31:0]  LOCAL_ADDR,
  input [3:0]   LOCAL_BE,
  input [31:0]  LOCAL_WDATA,
  output [31:0] LOCAL_RDATA,

  output        MUTEN,

  input         MCLK,

  output		BCLK,
  output		PBLRC,
  output		PBDAT,
  output		RECLRC,
  input			RECDAT,

  input			FIFO_RD_EMPTY,
  output		FIFO_RD_ENA,
  input [31:0]	FIFO_RD_DATA,
  output		FIFO_WR_ENA,
  output [31:0]	FIFO_WR_DATA
);

  localparam A_MODE      = 8'h00;
  localparam A_CLK       = 8'h04;

  wire        wr_ena, rd_ena, wr_ack;
  reg         rd_ack;
  reg [31:0]	reg_rdata;

	reg			reg_ena, reg_mode16;
	reg [7:0]	reg_clk_max, reg_clk_half;

  assign wr_ena = (LOCAL_CS & ~LOCAL_RNW)?1'b1:1'b0;
  assign rd_ena = (LOCAL_CS &  LOCAL_RNW)?1'b1:1'b0;
  assign wr_ack = wr_ena;

  // Write Register
  always @(posedge CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_ena	<= 1'b0;
      reg_mode16	<= 1'b0;
      reg_clk_half[7:0]	<= 8'd0;
      reg_clk_max[7:0]	<= 8'd0;
    end else begin
      if(wr_ena) begin
        case(LOCAL_ADDR[7:0] & 8'hFC)
          A_MODE: begin
			reg_ena				<= LOCAL_WDATA[0];
			reg_mode16			<= LOCAL_WDATA[8];
          end
          A_CLK: begin
			reg_clk_max[3:0]	<= LOCAL_WDATA[3:0];
			reg_clk_half[3:0]	<= LOCAL_WDATA[11:8];
          end
          default: begin
          end
        endcase
      end
    end
  end

  assign MUTEN  = reg_ena;

  // Read Register
  always @(posedge CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_rdata[31:0] <= 32'd0;
      rd_ack <= 1'b0;
    end else begin
      rd_ack <= rd_ena;
      if(rd_ena) begin
        case(LOCAL_ADDR[7:0] & 8'hFC)
          A_MODE: begin
            reg_rdata[31:0] <= {16'd0, 7'd0, reg_mode16, 7'd0, reg_ena};
          end
          A_CLK: begin
            reg_rdata[31:0] <= {16'd0, 4'd0, reg_clk_half[3:0], 4'd0, reg_clk_max[3:0]};
          end
          default: begin
            reg_rdata[31:0] <= 32'd0;
          end
        endcase
      end else begin
        reg_rdata[31:0] <= 32'd0;
      end
    end
  end

  assign LOCAL_ACK         = (wr_ack | rd_ack);
  assign LOCAL_RDATA[31:0] = reg_rdata[31:0];

	reg			r_clk;
	reg [3:0]	clk_count;
	reg [4:0]	bit_count;
	reg [31:0]	pdata, rdata;
	reg			lr;

	// BCLK
	always @(posedge MCLK or negedge RST_N) begin
		if(!RST_N) begin
			r_clk			<= 1'b1;
			clk_count[3:0]	<= 0;
			bit_count		<= 0;
			pdata			<= 0;
			lr				<= 1'b1;
		end else begin
			if(reg_ena) begin
				if((clk_count[3:0] == reg_clk_half[3:0]) || (clk_count[3:0] == reg_clk_max[3:0])) begin
					r_clk			<= ~r_clk;
				end
				if(clk_count[3:0] == reg_clk_max[3:0]) begin
					clk_count[3:0]	<= 0;
					if(((bit_count == 15) && (reg_mode16 == 1)) || (bit_count == 31)) begin
						lr	<= ~lr;
					end
					if(bit_count == 31) begin
						bit_count	<= 0;
						if(!FIFO_RD_EMPTY) begin
							pdata	<= FIFO_RD_DATA;
						end else begin
							pdata	<= 0;
						end
					end else begin
						bit_count	<= bit_count +1;
					end
				end else begin
					clk_count[3:0]	<= clk_count[3:0] + 16'd1;
				end
			end else begin
				r_clk			<= 1'b1;
				clk_count[3:0]	<= 0;
				bit_count		<= 0;
				pdata			<= 0;
				lr				<= 1'b1;
			end
		end
	end

wire [31:0]	pdata_w;
assign pdata_w[31] = pdata[0];
assign pdata_w[30] = pdata[1];
assign pdata_w[29] = pdata[2];
assign pdata_w[28] = pdata[3];
assign pdata_w[27] = pdata[4];
assign pdata_w[26] = pdata[5];
assign pdata_w[25] = pdata[6];
assign pdata_w[24] = pdata[7];
assign pdata_w[23] = pdata[8];
assign pdata_w[22] = pdata[9];
assign pdata_w[21] = pdata[10];
assign pdata_w[20] = pdata[11];
assign pdata_w[19] = pdata[12];
assign pdata_w[18] = pdata[13];
assign pdata_w[17] = pdata[14];
assign pdata_w[16] = pdata[15];
assign pdata_w[15] = pdata[16];
assign pdata_w[14] = pdata[17];
assign pdata_w[13] = pdata[18];
assign pdata_w[12] = pdata[19];
assign pdata_w[11] = pdata[20];
assign pdata_w[10] = pdata[21];
assign pdata_w[9]  = pdata[22];
assign pdata_w[8]  = pdata[23];
assign pdata_w[7]  = pdata[24];
assign pdata_w[6]  = pdata[25];
assign pdata_w[5]  = pdata[26];
assign pdata_w[4]  = pdata[27];
assign pdata_w[3]  = pdata[28];
assign pdata_w[2]  = pdata[29];
assign pdata_w[1]  = pdata[30];
assign pdata_w[0]  = pdata[31];

	assign BCLK			= ~r_clk;

	assign FIFO_RD_ENA	= (reg_ena && (clk_count == reg_clk_max[3:0]) && (bit_count == 31))?1'b1:1'b0;
	assign PBLRC		= lr;
	assign PBDAT		= pdata_w[bit_count];

	// Rec Data
	always @(posedge MCLK or negedge RST_N) begin
		if(!RST_N) begin
			rdata	<= 0;
		end else begin
			if(reg_ena) begin
				if(clk_count == 0) begin
					if(bit_count == 0) begin
//						rdata	<= {RECDAT, 31'd0};
						rdata	<= {31'd0, RECDAT};
					end else begin
//						rdata	<= {RECDAT, rdata[31:1]};
						rdata	<= {rdata[30:0], RECDAT};
					end
				end
			end else begin
				rdata	<= 0;
			end
		end
	end

	assign RECLRC	= lr;

	assign FIFO_WR_DATA	= rdata;
	assign FIFO_WR_ENA	= (reg_ena && (clk_count == 0) && (bit_count == 0))?1'b1:1'b0;
endmodule
