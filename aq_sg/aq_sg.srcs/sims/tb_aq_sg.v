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
module tb_aq_sg;

reg RST_N1;
reg RST_N2;
reg CLK;

wire VSYNC;
wire HSYNC;
wire FSYNC;
wire ACTIVE;

reg ERROR;

aq_sg u_aq_sg(
  .RST_N(RST_N2),
  .CLK(CLK),

  .VSYNC(VSYNC),
  .HSYNC(HSYNC),
  .FSYNC(FSYNC),
  .ACTIVE(ACTIVE),

  .DEBUG()
);

wire active_video_out, hsync_out, vsync_out;

design_1_wrapper
   u_design_1_wrapper(
    .active_video_out(active_video_out),
    .clk(CLK),
    .hsync_out(hsync_out),
    .resetn(RST_N1),
    .vsync_out(vsync_out)
    );


parameter CLK100M = 10;

initial begin
  RST_N1 <= 1'b0;
  RST_N2 <= 1'b0;
  CLK <= 1'b0;
  #100;

  @(posedge CLK);
  RST_N1 <= 1'b1;
  @(posedge CLK);
  @(posedge CLK);
  @(posedge CLK);
  RST_N2 <= 1'b1;
end

always  begin
  #(CLK100M/2) CLK <= ~CLK;
end

always @(posedge CLK or negedge RST_N2) begin
  if(!RST_N2) begin
    ERROR <= 0;
  end else begin
    ERROR <= (vsync_out ^ VSYNC) | (hsync_out ^ HSYNC);
  end
end

endmodule
