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
`timescale 1 ns / 1ps

module aq_hdmi_enc(
  input         RST_N,  // reset
  input         PCLK,   // pixel clock
  input         PCLK2,  // pixel clock x2
  input [31:0]  DIN,
  input         HSYNC,  // HSYNC data
  input         VSYNC,  // VSYNC data
  input         DE,     // data enable
  output [3:0]  TMDS,
  output [3:0]  TMDSB
);
  wire rstin;
  assign rstin = ~RST_N;

  wire [7:0] blue_din, green_din, red_din;
  
  assign red_din[7:0]   = DIN[23:16];
  assign green_din[7:0] = DIN[15:8];
  assign blue_din[7:0]  = DIN[7:0];
    
  wire 	[9:0]	red ;
  wire 	[9:0]	green ;
  wire 	[9:0]	blue ;

  aq_tdmi_enc encb (
    .clkin	(PCLK),
    .rstin	(rstin),
    .din		(blue_din),
    .c0			(HSYNC),
    .c1			(VSYNC),
    .de			(DE),
    .dout		(blue)
  );

  aq_tdmi_enc encg (
    .clkin	(PCLK),
    .rstin	(rstin),
    .din		(green_din),
    .c0			(HSYNC),
    .c1     (VSYNC),
    .de			(DE),
    .dout		(green)
  );
    
  aq_tdmi_enc encr (
    .clkin	(PCLK),
    .rstin	(rstin),
    .din		(red_din),
    .c0			(HSYNC),
    .c1     (VSYNC),
    .de			(DE),
    .dout		(red)
  );

  wire [2:0] tmdsint;

  // Clock
  wire tmdsclk;
  aq_serdes_n_to_1 clkout (
    .iob_data_out (tmdsclk),
    .ioclk        (PCLK2),
    .gclk         (PCLK),
    .reset        (rstin),
    .datain       (10'b1111100000)
  );

  OBUFDS TMDS3 (.I(tmdsclk), .O(TMDS[3]), .OB(TMDSB[3]));

  // Forward TMDS Data: 3 channels
  aq_serdes_n_to_1 oserdes0 (
    .ioclk(PCLK2),
    .reset(rstin),
    .gclk(PCLK),
    .datain(blue),
    .iob_data_out(tmdsint[0])
  );
  aq_serdes_n_to_1 oserdes1 (
    .ioclk(PCLK2),
    .reset(rstin),
    .gclk(PCLK),
    .datain(green),
    .iob_data_out(tmdsint[1])
  );
  aq_serdes_n_to_1 oserdes2 (
    .ioclk(PCLK2),
    .reset(rstin),
    .gclk(PCLK),
    .datain(red),
    .iob_data_out(tmdsint[2])
  );

  OBUFDS TMDS0 (.I(tmdsint[0]), .O(TMDS[0]), .OB(TMDSB[0]));
  OBUFDS TMDS1 (.I(tmdsint[1]), .O(TMDS[1]), .OB(TMDSB[1]));
  OBUFDS TMDS2 (.I(tmdsint[2]), .O(TMDS[2]), .OB(TMDSB[2]));
endmodule
