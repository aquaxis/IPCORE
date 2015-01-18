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
`timescale 1ns / 1ps
module tb_aq_fifo;

reg         RST;

reg         WRCLK;
reg         WREN;
reg [63:0]  DI;
wire        FULL;
wire        AFULL;
wire [7:0]  WRCOUNT;

reg         RDCLK;
reg         RDEN;
wire [63:0] DO;
wire        EMPTY;
wire        AEMPTY;
wire [7:0]  RDCOUNT;

  aq_fifo u_aq_rfifo
    (
      .RST(RST),
      
      .WRCLK(WRCLK),
      .WREN(WREN),
      .DI(DI),
      .FULL(FULL),
      .AFULL(AFULL),
      .WRCOUNT(WRCOUNT),
      
      .RDCLK(RDCLK),
      .RDEN(RDEN), 
      .DO(DO),
      .EMPTY(EMPTY),
      .AEMPTY(AEMPTY),
      .RDCOUNT(RDCOUNT)
    );

// Clock
initial begin
WRCLK <= 1'b0;
RDCLK <= 1'b0;
end

parameter CLK100N = 10;

always begin
  #(CLK100N/2) WRCLK <= ~WRCLK;
end
always begin
  #(CLK100N/2) RDCLK <= ~RDCLK;
end

// Reset
initial begin
  RST <= 1'b0;
  #(1000);
  RST <= 1'b1;
  #(1000);
  RST <= 1'b0;
end

// Signal
integer wrcount, rdcount;

always @(negedge WRCLK or posedge RST) begin
  if(RST) begin
    wrcount <= 0;
    WREN <= 1'b0;
    DI <= 64'd0;
  end else begin
    wrcount <= wrcount +1;
    if((wrcount >= 100) && (wrcount < 1024+100-256)) begin
      WREN <= 1'b1;
      DI <= DI + 64'd1;
    end else begin
      WREN <= 1'b0;
      DI <= 64'd0;
    end
  end
end

always @(negedge RDCLK or posedge RST) begin
  if(RST) begin
    rdcount <= 0;
    RDEN <= 1'b0;
  end else begin
  end
end

endmodule
