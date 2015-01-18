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
module aq_zybo_vga(
  input RST_N,
  input CLK,

  input [31:0] DIN,
  input ACTIVE,
  input HIN,
  input VIN,
  
  output HSYNC,
  output VSYNC,
  output [4:0] DOUT_R,
  output [5:0] DOUT_G,
  output [4:0] DOUT_B
);

  reg HSYNC;
  reg VSYNC;
  reg [4:0] DOUT_R;
  reg [5:0] DOUT_G;
  reg [4:0] DOUT_B;

always @(posedge CLK or negedge RST_N) begin
  if(!RST_N) begin
    HSYNC       <= 1'b0;
    VSYNC       <= 1'b0;
    DOUT_R[4:0] <= 5'd0;
    DOUT_G[5:0] <= 6'd0;
    DOUT_B[4:0] <= 5'd0;
  end else begin
    HSYNC       <= HIN;
    VSYNC       <= VIN;
    DOUT_R[4:0] <= (ACTIVE)?DIN[23:19]:5'd0;
    DOUT_G[5:0] <= (ACTIVE)?DIN[15:10]:6'd0;
    DOUT_B[4:0] <= (ACTIVE)?DIN[ 7: 3]:5'd0;
  end
end

endmodule
