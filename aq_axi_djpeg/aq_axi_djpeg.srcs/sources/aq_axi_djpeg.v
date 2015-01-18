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
`timescale 1ps / 1ps

module aq_axi_djpeg
#(
  parameter     C_BASEADRS  = 32'h4001_0000,
  parameter     C_ADRSWIDTH = 8
  )
(
  input         RST_N,
  input         CLK,

  // --------------------------------------------------
  // AXI4 Lite Interface
  // --------------------------------------------------
  input           S_AXI_ACLK,
    
  // Write Address Channel
  input [31:0]  S_AXI_AWADDR,
  input [3:0]   S_AXI_AWCACHE,
  input [2:0]   S_AXI_AWPROT,
  input         S_AXI_AWVALID,
  output        S_AXI_AWREADY, 
        
  // Write Data Channel
  input [31:0]  S_AXI_WDATA,
  input [3:0]   S_AXI_WSTRB,
  input         S_AXI_WVALID,
  output        S_AXI_WREADY,
        
  // Write Response Channel
  output        S_AXI_BVALID,
  input         S_AXI_BREADY,
  output [1:0]  S_AXI_BRESP,

  // Read Address Channel
  input [31:0]  S_AXI_ARADDR,
  input [3:0]   S_AXI_ARCACHE,
  input [2:0]   S_AXI_ARPROT,
  input         S_AXI_ARVALID,
  output        S_AXI_ARREADY,

  // Read Data Channel
  output [31:0] S_AXI_RDATA,
  output [1:0]  S_AXI_RRESP,
  output        S_AXI_RVALID,
  input         S_AXI_RREADY,


  // JPEG Data In
  input [31:0]  DATA_IN,
  input         EMPTY,
  output        READ,


// Bitmap Data Out
  output [31:0] DATA_OUT,
  output        WRITE,
  input         FULL,

  output [31:0] DEBUG
);

  wire           local_cs;
  wire           local_rnw;
  wire           local_ack;
  wire [31:0]    local_addr;
  wire [3:0]     local_be;
  wire [31:0]    local_wdata;
  wire [31:0]    local_rdata;

wire        Empty, Read;
wire [31:0] Data;

wire JpegDecodeIdle;
wire [15:0] OutWidth, OutHeight, OutPixelX, OutPixelY;
wire [7:0] OutR, OutG, OutB;

  aq_axi_lite_slave
    #(
      .C_BASEADRS(C_BASEADRS),
      .C_ADRSWIDTH(C_ADRSWIDTH)
    )
  u_aq_axi_lite_slave 
    (
      .ARESETN(RST_N),
      .ACLK(S_AXI_ACLK),
      
      .S_AXI_AWADDR(S_AXI_AWADDR),
      .S_AXI_AWCACHE(S_AXI_AWCACHE),
      .S_AXI_AWPROT(S_AXI_AWPROT),
      .S_AXI_AWVALID(S_AXI_AWVALID),
      .S_AXI_AWREADY(S_AXI_AWREADY),
      
      .S_AXI_WDATA(S_AXI_WDATA),
      .S_AXI_WSTRB(S_AXI_WSTRB),
      .S_AXI_WVALID(S_AXI_WVALID),
      .S_AXI_WREADY(S_AXI_WREADY),
      
      .S_AXI_BVALID(S_AXI_BVALID),
      .S_AXI_BREADY(S_AXI_BREADY),
      .S_AXI_BRESP(S_AXI_BRESP),
      
      .S_AXI_ARADDR(S_AXI_ARADDR),
      .S_AXI_ARCACHE(S_AXI_ARCACHE),
      .S_AXI_ARPROT(S_AXI_ARPROT),
      .S_AXI_ARVALID(S_AXI_ARVALID),
      .S_AXI_ARREADY(S_AXI_ARREADY),
      
      .S_AXI_RDATA(S_AXI_RDATA),
      .S_AXI_RRESP(S_AXI_RRESP),
      .S_AXI_RVALID(S_AXI_RVALID),
      .S_AXI_RREADY(S_AXI_RREADY),
      
      .LOCAL_CS(local_cs),
      .LOCAL_RNW(local_rnw),
      .LOCAL_ACK(local_ack),
      .LOCAL_ADDR(local_addr),
      .LOCAL_BE(local_be),
      .LOCAL_WDATA(local_wdata),
      .LOCAL_RDATA(local_rdata),
      
      .DEBUG(debug_slave)
    );

wire JpegDecodeRst;
   
aq_djpeg u_aq_djpeg(
  .rst            ( ~JpegDecodeRst  ),
  .clk            ( CLK             ),

  // From FIFO
  .DataIn         ( DATA_IN[31:0]   ),
  .DataInEnable   ( ~EMPTY          ),
  .DataInRead     ( READ            ),

  .JpegDecodeIdle ( JpegDecodeIdle  ),

  .OutEnable      ( WRITE           ),
  .OutWidth       ( OutWidth[15:0]  ),
  .OutHeight      ( OutHeight[15:0] ),
  .OutPixelX      ( OutPixelX[15:0] ),
  .OutPixelY      ( OutPixelY[15:0] ),
  .OutR           ( OutR[7:0]       ),
  .OutG           ( OutG[7:0]       ),
  .OutB           ( OutB[7:0]       )
);

assign DATA_OUT[31:0] = {8'd0, OutR[7:0], OutG[7:0], OutB[7:0]};
//assign DATA_OUT[31:0] = {OutPixelY[15:0], OutPixelX[15:0]};

  aq_axi_djpeg_ctl u_aq_axi_djpeg_ctl
    (
      .RST_N(RST_N),
      .CLK(S_AXI_ACLK),
      
      .LOCAL_CS(local_cs),
      .LOCAL_RNW(local_rnw),
      .LOCAL_ACK(local_ack),
      .LOCAL_ADDR(local_addr),
      .LOCAL_BE(local_be),
      .LOCAL_WDATA(local_wdata),
      .LOCAL_RDATA(local_rdata),

      .LOGIC_RST(JpegDecodeRst),
      .LOGIC_IDLE(JpegDecodeIdle),
      
      .WIDTH(OutWidth[15:0]),
      .HEIGHT(OutHeight[15:0]),
      .PIXELX(OutPixelX[15:0]),
      .PIXELY(OutPixelY[15:0]),
      
      .DEBUG()
    );
    
    assign DEBUG = {24'd0, 2'b00, S_AXI_RREADY, S_AXI_RVALID, local_ack, local_rnw, local_cs, RST_N};

endmodule
