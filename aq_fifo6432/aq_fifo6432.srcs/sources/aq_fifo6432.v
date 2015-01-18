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
module aq_fifo6432(
  input RST,

  input WR_CLK,
  input WR_IN_EMPTY,
  output WR_IN_RE,
  input [63:0] WR_IN_DATA,
  input WR_OUT_RE,
  output [31:0] WR_OUT_DO,
  output WR_OUT_EMPTY,
  
  input RD_CLK,
  input RD_OUT_FULL,
  output RD_OUT_WE,
  output [63:0] RD_OUT_DATA,
  input RD_IN_WE,
  input [31:0] RD_IN_DI,
  output RD_IN_FULL,

  output [31:0] DEBUG
);

reg [31:0] wr_buf;
reg wr_state, wr_ena;

// FIFO 64bit -> 32bit
always @(posedge WR_CLK or posedge RST) begin
  if(RST) begin
    wr_buf[31:0] <= 32'd0;
    wr_state <= 1'b0;
    wr_ena <= 1'b0;
  end else begin
    if(!wr_state) begin
      if(!WR_IN_EMPTY) begin
        wr_buf[31:0] <= WR_IN_DATA[63:32];
        wr_ena <= 1'b1;
        if(WR_OUT_RE) begin
          wr_state <= 1'b1;
        end
      end
    end else begin
      if(WR_OUT_RE) begin
        wr_state <= 1'b0;
        wr_ena <= 1'b0;
      end
    end
  end
end

assign WR_OUT_EMPTY = ((!wr_state & !WR_IN_EMPTY) | (wr_state & wr_ena))?1'b0:1'b1;
assign WR_OUT_DO[31:0] = (!wr_state)?WR_IN_DATA[31:0]:wr_buf[31:0];
assign WR_IN_RE = wr_state & WR_OUT_RE;

reg [31:0] rd_buf;
reg rd_ena;

// fifo 32bit -> 64bit
always @(posedge RD_CLK or posedge RST) begin
  if(RST) begin
    rd_buf[31:0] <= 32'd0;
    rd_ena <= 1'b0;
  end else begin
    if(RD_IN_WE & !RD_OUT_FULL) begin
      if(!rd_ena) begin
        rd_buf[31:0] <= RD_IN_DI[31:0];
        rd_ena <= 1'b1;
      end else begin
        rd_ena <= 1'b0;
      end
    end
  end
end

assign RD_OUT_DATA[63:0] = {RD_IN_DI[31:0], rd_buf[31:0]};
assign RD_OUT_WE = RD_IN_WE & rd_ena;
assign RD_IN_FULL = RD_OUT_FULL;

endmodule
