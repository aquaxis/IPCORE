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
`timescale 1ns / 100ps
module tb_aq_axi_master;

  // Reset, Clock
  reg           ARESETN;
  reg           ACLK;

  // Master Write Address
  wire [0:0]  M_AXI_AWID;
  wire [31:0] M_AXI_AWADDR;
  wire [7:0]  M_AXI_AWLEN;
  wire [2:0]  M_AXI_AWSIZE;
  wire [1:0]  M_AXI_AWBURST;
  wire        M_AXI_AWLOCK;
  wire [3:0]  M_AXI_AWCACHE;
  wire [2:0]  M_AXI_AWPROT;
  wire [3:0]  M_AXI_AWQOS;
  wire [0:0]  M_AXI_AWUSER;
  wire        M_AXI_AWVALID;
  reg         M_AXI_AWREADY;

  // Master Write Data
  wire [63:0] M_AXI_WDATA;
  wire [2:0]  M_AXI_WSTRB;
  wire        M_AXI_WLAST;
  wire [0:0]  M_AXI_WUSER;
  wire        M_AXI_WVALID;
  reg         M_AXI_WREADY;

  // Master Write Response
  reg [0:0]   M_AXI_BID;
  reg [1:0]   M_AXI_BRESP;
  reg [0:0]   M_AXI_BUSER;
  reg         M_AXI_BVALID;
  wire        M_AXI_BREADY;
    
  // Master Read Address
  wire [0:0]  M_AXI_ARID;
  wire [31:0] M_AXI_ARADDR;
  wire [7:0]  M_AXI_ARLEN;
  wire [2:0]  M_AXI_ARSIZE;
  wire [1:0]  M_AXI_ARBURST;
  wire [1:0]  M_AXI_ARLOCK;
  wire [3:0]  M_AXI_ARCACHE;
  wire [2:0]  M_AXI_ARPROT;
  wire [3:0]  M_AXI_ARQOS;
  wire [0:0]  M_AXI_ARUSER;
  wire        M_AXI_ARVALID;
  reg         M_AXI_ARREADY;
    
  // Master Read Data 
  reg [0:0]   M_AXI_RID;
  reg [63:0]  M_AXI_RDATA;
  reg [1:0]   M_AXI_RRESP;
  reg         M_AXI_RLAST;
  reg [0:0]   M_AXI_RUSER;
  reg         M_AXI_RVALID;
  wire        M_AXI_RREADY;
        
  // Local Bus
  reg         WR_START;
  reg [31:0]  WR_ADRS;
  reg [15:0]  WR_LEN;
  wire        WR_READY;
  wire        WR_FIFO_RE;
  reg         WR_FIFO_EMPTY;
  reg [63:0]  WR_FIFO_DATA;

  reg         RD_START;
  reg [31:0]  RD_ADRS;
  reg [15:0]  RD_LEN;
  wire        RD_READY;
  wire        RD_FIFO_WE;
  reg         RD_FIFO_FULL;
  wire [63:0] RD_FIFO_DATA;

  wire [31:0] DEBUG;

  parameter CLK10N = 10;


aq_axi_master u_aq_axi_master(
  // Reset, Clock
  .ARESETN(ARESETN),
  .ACLK(ACLK),

  // Master Write Address
  .M_AXI_AWID(M_AXI_AWID),
  .M_AXI_AWADDR(M_AXI_AWADDR),
  .M_AXI_AWLEN(M_AXI_AWLEN),
  .M_AXI_AWSIZE(M_AXI_AWSIZE),
  .M_AXI_AWBURST(M_AXI_AWBURST),
  .M_AXI_AWLOCK(M_AXI_AWLOCK),
  .M_AXI_AWCACHE(M_AXI_AWCACHE),
  .M_AXI_AWPROT(M_AXI_AWPROT),
  .M_AXI_AWQOS(M_AXI_AWQOS),
  .M_AXI_AWUSER(M_AXI_AWUSER),
  .M_AXI_AWVALID(M_AXI_AWVALID),
  .M_AXI_AWREADY(M_AXI_AWREADY),

  // Master Write Data
  .M_AXI_WDATA(M_AXI_WDATA),
  .M_AXI_WSTRB(M_AXI_WSTRB),
  .M_AXI_WLAST(M_AXI_WLAST),
  .M_AXI_WUSER(M_AXI_WUSER),
  .M_AXI_WVALID(M_AXI_WVALID),
  .M_AXI_WREADY(M_AXI_WREADY),

  // Master Write Response
  .M_AXI_BID(M_AXI_BID),
  .M_AXI_BRESP(M_AXI_BRESP),
  .M_AXI_BUSER(M_AXI_BUSER),
  .M_AXI_BVALID(M_AXI_BVALID),
  .M_AXI_BREADY(M_AXI_BREADY),
    
  // Master Read Address
  .M_AXI_ARID(M_AXI_ARID),
  .M_AXI_ARADDR(M_AXI_ARADDR),
  .M_AXI_ARLEN(M_AXI_ARLEN),
  .M_AXI_ARSIZE(M_AXI_ARSIZE),
  .M_AXI_ARBURST(M_AXI_ARBURST),
  .M_AXI_ARLOCK(M_AXI_ARLOCK),
  .M_AXI_ARCACHE(M_AXI_ARCACHE),
  .M_AXI_ARPROT(M_AXI_ARPROT),
  .M_AXI_ARQOS(M_AXI_ARQOS),
  .M_AXI_ARUSER(M_AXI_ARUSER),
  .M_AXI_ARVALID(M_AXI_ARVALID),
  .M_AXI_ARREADY(M_AXI_ARREADY),
    
  // Master Read Data 
  .M_AXI_RID(M_AXI_RID),
  .M_AXI_RDATA(M_AXI_RDATA),
  .M_AXI_RRESP(M_AXI_RRESP),
  .M_AXI_RLAST(M_AXI_RLAST),
  .M_AXI_RUSER(M_AXI_RUSER),
  .M_AXI_RVALID(M_AXI_RVALID),
  .M_AXI_RREADY(M_AXI_RREADY),
        
  // Local Bus
  .WR_START(WR_START),
  .WR_ADRS(WR_ADRS),
  .WR_LEN(WR_LEN), 
  .WR_READY(WR_READY),
  .WR_FIFO_RE(WR_FIFO_RE),
  .WR_FIFO_EMPTY(WR_FIFO_EMPTY),
  .WR_FIFO_DATA(WR_FIFO_DATA),

  .RD_START(RD_START),
  .RD_ADRS(RD_ADRS),
  .RD_LEN(RD_LEN), 
  .RD_READY(RD_READY),
  .RD_FIFO_WE(RD_FIFO_WE),
  .RD_FIFO_FULL(RD_FIFO_FULL),
  .RD_FIFO_DATA(RD_FIFO_DATA),

  .DEBUG(DEBUG)
);

initial begin
  ACLK <=1'b0;
end

// Clock
always begin
  #(CLK10N/2) ACLK <= ~ACLK;
end

// Reset
initial begin
  ARESETN <= 1'b0;
  #(100);
  ARESETN <= 1'b1;
end

// Read Control
initial begin
  RD_START <= 1'b0;
  RD_ADRS <= 32'd0;
  RD_LEN <= 16'd0;

  wait (ARESETN);

  @(negedge ACLK);
  @(negedge ACLK);
  @(negedge ACLK);

  RD_START <= 1'b0;
  RD_ADRS <= 32'h1C000000;
  RD_LEN <= 16'd8;

  @(negedge ACLK);

  RD_START <= 1'b0;
  RD_ADRS <= 32'd0;
  RD_LEN <= 16'd0;

  @(negedge ACLK);

end

initial begin
  RD_FIFO_FULL <= 1'b0;
end

// Write Control
initial begin
  WR_START <= 1'b0;
  WR_ADRS <= 32'd0;
  WR_LEN <= 16'd0;

  wait (ARESETN);

  @(negedge ACLK);
  @(negedge ACLK);
  @(negedge ACLK);

  WR_START <= 1'b1;
  WR_ADRS <= 32'h1C800000;
  WR_LEN <= 16'd8;

  @(negedge ACLK);

  WR_START <= 1'b0;

  @(negedge ACLK);
  @(negedge ACLK);

  @(negedge ACLK);
  @(negedge ACLK);
  @(negedge ACLK);


end

initial begin
  WR_FIFO_EMPTY <= 1'b0;
  WR_FIFO_DATA  <= 64'h0000_0000_0000_0000;

  wait (ARESETN);

  @(negedge ACLK);
  @(negedge ACLK);
  @(negedge ACLK);

  WR_FIFO_DATA  <= 64'h3333_2222_1111_1010;

  wait(WR_FIFO_RE);

  WR_FIFO_DATA  <= 64'h4444_3333_2222_1111;

  wait(WR_FIFO_RE);

  WR_FIFO_DATA  <= 64'h5555_4444_3333_2222;

  wait(WR_FIFO_RE);

  WR_FIFO_DATA  <= 64'h6666_5555_4444_3333;

end

// AXI Read Control
initial begin

  M_AXI_ARREADY <= 1'b0;

  wait (ARESETN);

  @(negedge ACLK);
  @(negedge ACLK);
  @(negedge ACLK);

  wait(M_AXI_ARVALID);

  @(negedge ACLK);

  M_AXI_ARREADY <= 1'b1;

  @(negedge ACLK);

  M_AXI_ARREADY <= 1'b0;

  @(negedge ACLK);



end

// AXI Write Control
initial begin

  M_AXI_AWREADY <= 1'b0;
  M_AXI_WREADY <= 1'b0;
  M_AXI_BID <= 1'b0;
  M_AXI_BRESP <= 2'b00;
  M_AXI_BUSER <= 1'b0;
  M_AXI_BVALID <= 1'b0;

  wait (ARESETN);

  @(negedge ACLK);
  @(negedge ACLK);
  @(negedge ACLK);

  wait(M_AXI_AWVALID);

  @(negedge ACLK);

  M_AXI_AWREADY <= 1'b1;

  @(negedge ACLK);

  M_AXI_AWREADY <= 1'b0;

  wait(M_AXI_WVALID);

  @(negedge ACLK);

  M_AXI_WREADY <= 1'b1;

  @(negedge ACLK);

  M_AXI_WREADY <= 1'b0;

  @(negedge ACLK);

  M_AXI_BID <= 1'b0;
  M_AXI_BRESP <= 2'b00;
  M_AXI_BUSER <= 1'b0;

  wait(M_AXI_BREADY);

  @(negedge ACLK);

  M_AXI_BVALID <= 1'b1;

  @(negedge ACLK);

  M_AXI_BVALID <= 1'b0;


end

endmodule
