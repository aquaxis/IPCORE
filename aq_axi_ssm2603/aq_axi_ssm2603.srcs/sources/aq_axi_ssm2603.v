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
module aq_axi_ssm2603
  (
    input           ARESETN,
    input			ACLK,

    // --------------------------------------------------
    // AXI4 Lite Interface
    // --------------------------------------------------
    // Write Address Channel
    input [15:0]  S_AXI_AWADDR,
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
    input [15:0]  S_AXI_ARADDR,
    input [3:0]   S_AXI_ARCACHE,
    input [2:0]   S_AXI_ARPROT,
    input         S_AXI_ARVALID,
    output        S_AXI_ARREADY,

    // Read Data Channel
    output [31:0] S_AXI_RDATA,
    output [1:0]  S_AXI_RRESP,
    output        S_AXI_RVALID,
    input         S_AXI_RREADY,

    // SSM2603
    output      MUTEN,
    
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

	wire           local_cs;
	wire           local_rnw;
	wire           local_ack;
	wire [31:0]    local_addr;
	wire [3:0]     local_be;
	wire [31:0]    local_wdata;
	wire [31:0]    local_rdata;

	aq_axi_lite_slave u_aq_axi_lite_slave(
		.ARESETN(ARESETN),
		.ACLK(ACLK),
      
		.S_AXI_AWADDR({16'd0, S_AXI_AWADDR}),
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
      
		.S_AXI_ARADDR({16'd0, S_AXI_ARADDR}),
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
		.LOCAL_RDATA(local_rdata)
	);
   
	aq_ssm2603 u_ssm2603(
		.RST_N(ARESETN),
		.CLK(ACLK),
      
		.LOCAL_CS(local_cs),
		.LOCAL_RNW(local_rnw),
		.LOCAL_ACK(local_ack),
		.LOCAL_ADDR(local_addr),
		.LOCAL_BE(local_be),
		.LOCAL_WDATA(local_wdata),
		.LOCAL_RDATA(local_rdata),

        .MUTEN(MUTEN),

		.MCLK(MCLK),
      
		.BCLK(BCLK),
		.PBLRC(PBLRC),
		.PBDAT(PBDAT),
		.RECLRC(RECLRC),
		.RECDAT(RECDAT),
  
		.FIFO_RD_EMPTY(FIFO_RD_EMPTY),
		.FIFO_RD_ENA(FIFO_RD_ENA),
		.FIFO_RD_DATA(FIFO_RD_DATA),
		.FIFO_WR_ENA(FIFO_WR_ENA),
		.FIFO_WR_DATA(FIFO_WR_DATA)
    );

endmodule
 
