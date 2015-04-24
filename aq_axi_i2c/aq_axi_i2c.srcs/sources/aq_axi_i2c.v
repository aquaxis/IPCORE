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
module aq_axi_i2c(
    input         ARESETN,

    // --------------------------------------------------
    // AXI4 Lite Interface
    // --------------------------------------------------
    input           S_AXI_ACLK,
    
    // Write Address Channel
    input [15:0]  S_AXI_AWADDR,
    input [3:0]   S_AXI_AWCACHE,  // 4'b0011
    input [2:0]   S_AXI_AWPROT,   // 3'b000
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
    input [15:0]  S_AXI_ARADDR,
    input [3:0]   S_AXI_ARCACHE,  // 4'b0011
    input [2:0]   S_AXI_ARPROT,   // 3'b000
    input         S_AXI_ARVALID,
    output        S_AXI_ARREADY,
    
    // Read Data Channel
    output [31:0] S_AXI_RDATA,
    output [1:0]  S_AXI_RRESP,
    output        S_AXI_RVALID,
    input         S_AXI_RREADY,

    // I2C
    inout           I2C_SDA,
    inout           I2C_SCL    
    );

  wire           local_cs;
  wire           local_rnw;
  wire           local_ack;
  wire [31:0]    local_addr;
  wire [3:0]     local_be;
  wire [31:0]    local_wdata;
  wire [31:0]    local_rdata;
    
  aq_axi_lite_slave u_aq_axi_lite_slave 
    (
      .ARESETN(ARESETN),
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

    wire [3:0] i2c_cmd_wr, i2c_ram_wr;
    wire [31:0] i2c_cmd_dout, i2c_sts_dout, i2c_rdata;
    
    reg local_cs_d;
    always @(posedge S_AXI_ACLK or negedge ARESETN) begin
        if(!ARESETN) begin
            local_cs_d <= 1'b0;
        end else begin
            local_cs_d <= local_cs;
        end
    end
    
    assign local_ack = (local_cs & (~local_rnw)) | local_cs_d;
    assign i2c_cmd_wr[3:0] = (local_cs & (~local_rnw) & (local_addr[15:0] == 16'h0400))?local_be[3:0]:4'd0;
    assign i2c_ram_wr[3:0] = (local_cs & (~local_rnw) & (local_addr[15:10] == 6'd0))?local_be[3:0]:4'd0;

    assign local_rdata[31:0] =  ((local_addr[15:10] == 6'd0)?i2c_rdata[31:0]:32'd0) |
                                ((local_addr[15:0] == 16'h0400)?i2c_cmd_dout[31:0]:32'd0) |
                                ((local_addr[15:0] == 16'h0404)?i2c_sts_dout[31:0]:32'd0) |
                                ((local_addr[15:0] == 16'h0408)?32'hAA55AA55:32'd0);

    wire w_isda, w_osda, w_oscl;

    aq_i2c_master u_aq_i2c_master(
	   .rst_n(ARESETN),
	   .clk(S_AXI_ACLK),

	   .cmd_wr(i2c_cmd_wr[3:0]),
	   .cmd_din(local_wdata[31:0]),
	   .cmd_dout(i2c_cmd_dout[31:0]),

	   .sts_dout(i2c_sts_dout[31:0]),

	   .adrs(local_addr[9:0]),
	   .wena(i2c_ram_wr[3:0]),
	   .wdata(local_wdata[31:0]),
	   .rdata(i2c_rdata[31:0]),

	   .osda(w_osda),
	   .isda(w_isda),
	   .osck(w_oscl)
    );

    assign I2C_SDA = (w_osda)?1'bZ:1'b0;
    assign w_isda = I2C_SDA;
    assign I2C_SCL = (w_oscl)?1'b1:1'b0;
    
endmodule
