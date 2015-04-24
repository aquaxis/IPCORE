/*
 */
`timescale 1ps / 1ps
module tb_aq_axi_ssm2603;

localparam CLK100M	= 10000;
localparam CLK12M	= 81380; // 12.288MHz

reg	ARESETN, ACLK;

// Write Address Channel
wire [31:0]  S_AXI_AWADDR;
wire [3:0]   S_AXI_AWCACHE;
wire [2:0]   S_AXI_AWPROT;
wire         S_AXI_AWVALID;
wire        S_AXI_AWREADY; 
        
// Write Data Channel
wire [31:0]  S_AXI_WDATA;
wire [3:0]   S_AXI_WSTRB;
wire         S_AXI_WVALID;
wire        S_AXI_WREADY;
        
// Write Response Channel
wire        S_AXI_BVALID;
wire        S_AXI_BREADY;
wire [1:0]  S_AXI_BRESP;

// Read Address Channe
wire [31:0]  S_AXI_ARADDR;
wire [3:0]   S_AXI_ARCACHE;
wire [2:0]   S_AXI_ARPROT;
wire         S_AXI_ARVALID;
wire        S_AXI_ARREADY;

// Read Data Channel
wire [31:0] S_AXI_RDATA;
wire [1:0]  S_AXI_RRESP;
wire        S_AXI_RVALID;
wire         S_AXI_RREADY;

reg		MCLK;
wire	BCLK, PBLRC, PBDAT;
wire	RECLRC;
wire	RECDAT;

reg			FIFO_RD_EMPTY;
wire		FIFO_RD_ENA;
reg [31:0]	FIFO_RD_DATA;
wire		FIFO_WR_ENA;
wire [31:0]	FIFO_WR_DATA;

// Clock
always begin
	#(CLK100M/2) ACLK = ~ACLK;
end
always begin
	#(CLK12M/2) MCLK = ~MCLK;
end

initial begin
	ARESETN = 1'b0;
	ACLK	  = 1'b0;
	MCLK	= 1'b0;
	repeat (5) @(posedge MCLK);
	ARESETN = 1'b1;

	repeat (10) @(posedge MCLK);

	repeat (2000) @(posedge MCLK);

	$finish();
end

aq_axi_ssm2603 u_aq_axi_ssm2603(
	// Reset, Clock
	.ARESETN(ARESETN),
	.ACLK(ACLK),
    
	// Write Address Channel
	.S_AXI_AWADDR(S_AXI_AWADDR),
	.S_AXI_AWPROT(S_AXI_AWPROT),
	.S_AXI_AWVALID(S_AXI_AWVALID),
	.S_AXI_AWREADY(S_AXI_AWREADY), 
        
    // Write Data Channel
	.S_AXI_WDATA(S_AXI_WDATA),
	.S_AXI_WSTRB(S_AXI_WSTRB),
	.S_AXI_WVALID(S_AXI_WVALID),
	.S_AXI_WREADY(S_AXI_WREADY),
        
    // Write Response Channel
	.S_AXI_BVALID(S_AXI_BVALID),
	.S_AXI_BREADY(S_AXI_BREADY),
	.S_AXI_BRESP(S_AXI_BRESP),

    // Read Address Channel
	.S_AXI_ARADDR(S_AXI_ARADDR),
	.S_AXI_ARPROT(S_AXI_ARPROT),
	.S_AXI_ARVALID(S_AXI_ARVALID),
	.S_AXI_ARREADY(S_AXI_ARREADY),

    // Read Data Channel
	.S_AXI_RDATA(S_AXI_RDATA),
	.S_AXI_RRESP(S_AXI_RRESP),
	.S_AXI_RVALID(S_AXI_RVALID),
	.S_AXI_RREADY(S_AXI_RREADY),

    // SSM2603
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

assign RECDAT = PBDAT;

/*
 * AXI Lite Slave
 */
aq_axi_lite_master_model bfm(
	.ARESETN(ARESETN),
	.ACLK(ACLK),
    
    // Write Address Channel
	.S_AXI_AWADDR(S_AXI_AWADDR),
//  .S_AXI_AWCACHE(S_AXI_AWCACHE),
	.S_AXI_AWPROT(S_AXI_AWPROT),
	.S_AXI_AWVALID(S_AXI_AWVALID),
	.S_AXI_AWREADY(S_AXI_AWREADY), 
        
    // Write Data Channel
	.S_AXI_WDATA(S_AXI_WDATA),
	.S_AXI_WSTRB(S_AXI_WSTRB),
	.S_AXI_WVALID(S_AXI_WVALID),
	.S_AXI_WREADY(S_AXI_WREADY),
        
    // Write Response Channel
	.S_AXI_BVALID(S_AXI_BVALID),
	.S_AXI_BREADY(S_AXI_BREADY),
	.S_AXI_BRESP(S_AXI_BRESP),

    // Read Address Channel
	.S_AXI_ARADDR(S_AXI_ARADDR),
//  .S_AXI_ARCACHE(S_AXI_ARCACHE),
	.S_AXI_ARPROT(S_AXI_ARPROT),
	.S_AXI_ARVALID(S_AXI_ARVALID),
	.S_AXI_ARREADY(S_AXI_ARREADY),

    // Read Data Channel
	.S_AXI_RDATA(S_AXI_RDATA),
	.S_AXI_RRESP(S_AXI_RRESP),
	.S_AXI_RVALID(S_AXI_RVALID),
	.S_AXI_RREADY(S_AXI_RREADY)
);

initial begin
	wait(!ARESETN);
	@(negedge ACLK);
	@(negedge ACLK);

//	bfm.wrdata(32'h0000_0004, 32'h0000_0001);   // half=0,max=1
//    bfm.wrdata(32'h0000_0000, 32'h0000_0001);  // 32bit, enable

	bfm.wrdata(32'h0000_0004, 32'h0000_0307);   // half=1, max=1
    bfm.wrdata(32'h0000_0000, 32'h0000_0101);  // 16bit, enable
end

initial begin
	FIFO_RD_EMPTY	= 1'b0;
	FIFO_RD_DATA	= 32'h12345678;
end

endmodule
