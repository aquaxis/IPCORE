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
module aq_axi_djpeg_ctl(
  input         RST_N,
  input         CLK,

  input         LOCAL_CS,
  input         LOCAL_RNW,
  output        LOCAL_ACK,
  input [31:0]  LOCAL_ADDR,
  input [3:0]   LOCAL_BE,
  input [31:0]  LOCAL_WDATA,
  output [31:0] LOCAL_RDATA,
  
  output        LOGIC_RST,
  input         LOGIC_IDLE,
  
  input [15:0]  WIDTH,
  input [15:0]  HEIGHT,
  input [15:0]  PIXELX,
  input [15:0]  PIXELY,

  output [31:0] DEBUG 
);

  localparam A_STATUS    = 8'h00;
  localparam A_SIZE      = 8'h04;
  localparam A_PIXEL     = 8'h08;

  wire        wr_ena, rd_ena, wr_ack;
  reg         rd_ack;

  reg [31:0]  reg_rdata;

  reg         reg_rst;

  assign wr_ena = (LOCAL_CS & ~LOCAL_RNW)?1'b1:1'b0;
  assign rd_ena = (LOCAL_CS &  LOCAL_RNW)?1'b1:1'b0;
  assign wr_ack = wr_ena;

  // Write Register
  always @(posedge CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_rst <= 1'b0;
    end else begin
      if(wr_ena) begin
        case(LOCAL_ADDR[7:0] & 8'hFC)
          A_STATUS: begin
            reg_rst <= LOCAL_WDATA[31];
          end
          A_SIZE: begin
          end
          A_PIXEL: begin
          end
          default: begin
          end
        endcase
      end
    end
  end

  // Read Register
  always @(posedge CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_rdata[31:0] <= 32'd0;
      rd_ack <= 1'b0;
    end else begin
      rd_ack <= rd_ena;
      if(rd_ena) begin
        case(LOCAL_ADDR[7:0] & 8'hFC)
          A_STATUS: begin
            reg_rdata[31:0] <= {reg_rst, 30'd0, LOGIC_IDLE};
          end
          A_SIZE: begin
            reg_rdata[31:0] <= {HEIGHT[15:0], WIDTH[15:0]};
          end
          A_PIXEL: begin
            reg_rdata[31:0] <= {PIXELY[15:0], PIXELX[15:0]};
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
  
  assign LOGIC_RST = reg_rst;

  assign LOCAL_ACK          = rd_ack | wr_ack;
  assign LOCAL_RDATA[31:0]  = reg_rdata[31:0];

  assign DEBUG[31:0] = {32'd0};

endmodule
