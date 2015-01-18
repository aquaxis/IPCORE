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
module aq_axi_fifo_ctl(
  input         RST_N,
  input         CLK,

  input         LOCAL_CS,
  input         LOCAL_RNW,
  output        LOCAL_ACK,
  input [31:0]  LOCAL_ADDR,
  input [3:0]   LOCAL_BE,
  input [31:0]  LOCAL_WDATA,
  output [31:0] LOCAL_RDATA,

  input         CMD_CLK, 
  
  output        WR_START,
  output [31:0] WR_ADRS,
  output [31:0] WR_COUNT,
  input         WR_READY,
  input         WR_FIFO_EMPTY,
  input         WR_FIFO_AEMPTY,
  input         WR_FIFO_FULL,
  input         WR_FIFO_AFULL,

  output        RD_START,
  output [31:0] RD_ADRS,
  output [31:0] RD_COUNT,
  input         RD_READY,
  input         RD_FIFO_EMPTY,
  input         RD_FIFO_AEMPTY,
  input         RD_FIFO_FULL,
  input         RD_FIFO_AFULL,

  input [31:0]  MASTER_STATUS,
  input [31:0]  FIFO_STATUS0,
  input [31:0]  FIFO_STATUS1,
  input [31:0]  FIFO_STATUS2,
  input [31:0]  FIFO_STATUS3,

  output        FIFO_RST,

  output [31:0] DEBUG 
);

  localparam A_WR_START      = 8'h00;
  localparam A_WR_ADRS       = 8'h04;
  localparam A_WR_COUNT      = 8'h08;
  localparam A_RD_START      = 8'h0C;
  localparam A_RD_ADRS       = 8'h10;
  localparam A_RD_COUNT      = 8'h14;
  localparam A_MASTER_STATUS = 8'h18;
  localparam A_TESTDATA      = 8'h1C;
  localparam A_FIFORST       = 8'h20;
  localparam A_DEBUG         = 8'h24;
  localparam A_FIFO_STATUS0  = 8'h28;
  localparam A_FIFO_STATUS1  = 8'h2C;
  localparam A_FIFO_STATUS2  = 8'h30;
  localparam A_FIFO_STATUS3  = 8'h34;

  wire        wr_ena, rd_ena, wr_ack;
  reg         rd_ack;
   
  reg         reg_wrreq_clk;
  reg [1:0]   req_wrack_clk;
  reg [2:0]   reg_wrreq_cmd_clk;

  reg         reg_rdreq_clk;
  reg [1:0]   req_rdack_clk;
  reg [2:0]   reg_rdreq_cmd_clk;

  reg [31:0]  reg_wr_adrs, reg_rd_adrs;
  reg [31:0]  reg_wr_count, reg_rd_count;
  reg [31:0]  reg_testdata;

  reg [31:0]  reg_rdata;

  reg         reg_fifo_rst;

  reg [7:0]   reg_rdreq_count;

  assign wr_ena = (LOCAL_CS & ~LOCAL_RNW)?1'b1:1'b0;
  assign rd_ena = (LOCAL_CS &  LOCAL_RNW)?1'b1:1'b0;
  assign wr_ack = wr_ena;

  // Write Register
  always @(posedge CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_wr_adrs[31:0] <= 32'd0;
      reg_wr_count[31:0] <= 32'd0;
      reg_rd_adrs[31:0] <= 32'd0;
      reg_rd_count[31:0] <= 32'd0;
      reg_fifo_rst <= 1'b0;
    end else begin
      if(wr_ena) begin
        case(LOCAL_ADDR[7:0] & 8'hFC)
          A_WR_START: begin
          end
          A_WR_ADRS: begin
            reg_wr_adrs[31:0] <= LOCAL_WDATA[31:0];
          end
          A_WR_COUNT: begin
            reg_wr_count[31:0] <= LOCAL_WDATA[31:0];
          end
          A_RD_START: begin
          end
            A_RD_ADRS: begin
            reg_rd_adrs[31:0] <= LOCAL_WDATA[31:0];
          end
          A_RD_COUNT: begin
            reg_rd_count[31:0] <= LOCAL_WDATA[31:0];
          end
          A_MASTER_STATUS: begin
          end
          A_TESTDATA: begin
            reg_testdata[31:0] <= LOCAL_WDATA[31:0];
          end
          A_FIFORST: begin
            reg_fifo_rst <= LOCAL_WDATA[0];
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
          A_WR_START: begin
            reg_rdata[31:0] <= {12'd0, WR_FIFO_AEMPTY, WR_FIFO_EMPTY, WR_FIFO_AFULL, WR_FIFO_FULL, 7'd0, WR_READY, 7'd0, reg_wrreq_clk};
          end
          A_WR_ADRS: begin
            reg_rdata[31:0] <= reg_wr_adrs[31:0];
          end
          A_WR_COUNT: begin
            reg_rdata[31:0] <= reg_wr_count[31:0];
          end
          A_RD_START: begin
            reg_rdata[31:0] <= {12'd0, RD_FIFO_AEMPTY, RD_FIFO_EMPTY, RD_FIFO_AFULL, RD_FIFO_FULL, 7'd0, RD_READY, 7'd0, reg_rdreq_clk};
          end
          A_RD_ADRS: begin
            reg_rdata[31:0] <= reg_rd_adrs[31:0];
          end
          A_RD_COUNT: begin
            reg_rdata[31:0] <= reg_rd_count[31:0];
          end
          A_MASTER_STATUS: begin
            reg_rdata[31:0] <= MASTER_STATUS;
          end
          A_TESTDATA: begin
            reg_rdata[31:0] <= reg_testdata[31:0];
          end
          A_FIFORST: begin
            reg_rdata[31:0] <= {31'd0, reg_fifo_rst};
          end
          A_DEBUG: begin
            reg_rdata[31:0] <= {24'd0, reg_rdreq_count};
          end
          A_FIFO_STATUS0: begin
            reg_rdata[31:0] <= FIFO_STATUS0;
          end
          A_FIFO_STATUS1: begin
            reg_rdata[31:0] <= FIFO_STATUS1;
          end
          A_FIFO_STATUS2: begin
            reg_rdata[31:0] <= FIFO_STATUS2;
          end
          A_FIFO_STATUS3: begin
            reg_rdata[31:0] <= FIFO_STATUS3;
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

  // Request Sending(1shot)
  always @(posedge CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_wrreq_clk <= 1'b0;
      req_wrack_clk[1:0] <= 2'd0;
    end else begin
      if(req_wrack_clk[1]) begin
        reg_wrreq_clk <= 1'b0;
      end else if((wr_ena && (LOCAL_ADDR[7:0] == A_WR_START[7:0])) &&
                  (WR_READY)) begin
        reg_wrreq_clk <= 1'b1;
      end
      req_wrack_clk[1:0] <= {req_wrack_clk[0], reg_wrreq_cmd_clk[2]};
    end
  end

  always @(posedge CMD_CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_wrreq_cmd_clk[2:0] <= 3'd0;
    end else begin
      reg_wrreq_cmd_clk[2:0] <= {reg_wrreq_cmd_clk[1:0], reg_wrreq_clk};
    end
  end

  always @(posedge CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_rdreq_clk <= 1'b0;
      req_rdack_clk[1:0] <= 2'd0;
      reg_rdreq_count[7:0] <= 8'd0;
    end else begin
      if(req_rdack_clk[1]) begin
        reg_rdreq_clk <= 1'b0;
      end else if((wr_ena && (LOCAL_ADDR[7:0] == A_RD_START[7:0])) &&
                  (RD_READY)) begin
        reg_rdreq_clk <= 1'b1;
        reg_rdreq_count[7:0] <= reg_rdreq_count[7:0] + 8'd1;
      end
      req_rdack_clk[1:0] <= {req_rdack_clk[0], reg_rdreq_cmd_clk[2]};
    end
  end

  always @(posedge CMD_CLK or negedge RST_N) begin
    if(!RST_N) begin
      reg_rdreq_cmd_clk[2:0] <= 3'd0;
    end else begin
      reg_rdreq_cmd_clk[2:0] <= {reg_rdreq_cmd_clk[1:0], reg_rdreq_clk};
    end
  end

  assign WR_START       = (reg_wrreq_cmd_clk[2:1] == 2'b01)?1'b1:1'b0;
  assign WR_ADRS[31:0]  = reg_wr_adrs[31:0];
  assign WR_COUNT[31:0] = reg_wr_count[31:0];
  assign RD_START       = (reg_rdreq_cmd_clk[2:1] == 2'b01)?1'b1:1'b0;
  assign RD_ADRS[31:0]  = reg_rd_adrs[31:0];
  assign RD_COUNT[31:0] = reg_rd_count[31:0];

  assign FIFO_RST       = reg_fifo_rst;

  assign DEBUG[31:0]    = {24'd0, rd_ack, rd_ena, LOCAL_RNW, LOCAL_CS};

endmodule

