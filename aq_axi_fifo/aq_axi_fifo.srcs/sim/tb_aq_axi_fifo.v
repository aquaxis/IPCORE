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
module tb_aq_axi_fifo;

  // Reset, Clock
  reg           ARESETN;
  reg           ACLK;

    reg           S_AXI_ACLK;
    
    // Write Address Channel
    reg [31:0]  S_AXI_AWADDR;
    reg [3:0]   S_AXI_AWCACHE;
    reg [2:0]   S_AXI_AWPROT;
    reg         S_AXI_AWVALID;
    wire        S_AXI_AWREADY; 
        
    // Write Data Channel
    reg [31:0]  S_AXI_WDATA;
    reg [3:0]   S_AXI_WSTRB;
    reg         S_AXI_WVALID;
    wire        S_AXI_WREADY;
        
    // Write Response Channel
    wire        S_AXI_BVALID;
    wire        S_AXI_BREADY;
    wire [1:0]  S_AXI_BRESP;

    // Read Address Channe
    reg [31:0]  S_AXI_ARADDR;
    reg [3:0]   S_AXI_ARCACHE;
    reg [2:0]   S_AXI_ARPROT;
    reg         S_AXI_ARVALID;
    wire        S_AXI_ARREADY;

    // Read Data Channel
    wire [31:0] S_AXI_RDATA;
    wire [1:0]  S_AXI_RRESP;
    wire        S_AXI_RVALID;
    reg         S_AXI_RREADY;

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
  wire [63:0]  M_AXI_RDATA;
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

    // FIFO
    wire          FIFO_RST;
    
    reg           FIFO_RD_CLK;
    reg           FIFO_RD_EN;
    wire [63:0]   FIFO_DOUT;
    wire          FIFO_EMPTY;

    reg           FIFO_WR_CLK;
    reg [63:0]    FIFO_DIN;
    reg           FIFO_WR_EN;
    wire          FIFO_FULL;

  wire fifo_we;


  parameter CLK10N = 10;


aq_axi_fifo u_aq_axi_fifo(
  // Reset, Clock
  .ARESETN(ARESETN),

  .S_AXI_ACLK(ACLK),
    
    // Write Address Channel
  .S_AXI_AWADDR(S_AXI_AWADDR),
  .S_AXI_AWCACHE(S_AXI_AWCACHE),
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
  .S_AXI_ARCACHE(S_AXI_ARCACHE),
  .S_AXI_ARPROT(S_AXI_ARPROT),
  .S_AXI_ARVALID(S_AXI_ARVALID),
  .S_AXI_ARREADY(S_AXI_ARREADY),

    // Read Data Channel
  .S_AXI_RDATA(S_AXI_RDATA),
  .S_AXI_RRESP(S_AXI_RRESP),
  .S_AXI_RVALID(S_AXI_RVALID),
  .S_AXI_RREADY(S_AXI_RREADY),


  .M_AXI_ACLK(ACLK),

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
        
  .FIFO_RST(FIFO_RST),
    
  .FIFO_RD_CLK(ACLK),
  .FIFO_RD_EN(fifo_we),
  .FIFO_DOUT(FIFO_DOUT),
  .FIFO_EMPTY(FIFO_EMPTY),

  .FIFO_WR_CLK(ACLK),
  .FIFO_DIN(FIFO_DOUT),
  .FIFO_WR_EN(fifo_we),
  .FIFO_FULL(FIFO_FULL),

  .DEBUG(DEBUG)
);

reg fifo_we_ena;
initial begin
  fifo_we_ena <= 0;
  
  wait(!FIFO_EMPTY);

end

assign fifo_we = (fifo_we_ena)?~FIFO_EMPTY:1'b0;

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

assign S_AXI_BREADY = S_AXI_BVALID;

// Read Control
initial begin
  S_AXI_AWADDR  <= 32'h4000_0000;
  S_AXI_AWCACHE <= 3'd0;
  S_AXI_AWPROT  <= 2'd0;
  S_AXI_AWVALID   <= 1'b0;
  S_AXI_WDATA  <= 32'h0000_0000;
  S_AXI_WSTRB  <= 4'H0;
  S_AXI_WVALID <= 1'b0;

  wait (ARESETN);

  @(negedge ACLK);
  @(negedge ACLK);

// Read Count
  @(negedge ACLK);

  S_AXI_AWADDR <= 32'h4000_0014;
  S_AXI_AWVALID  <= 1'b1;

  @(negedge ACLK);

  wait(S_AXI_AWREADY);
  S_AXI_AWVALID  <= 1'b0;

  @(negedge ACLK);

  S_AXI_WDATA  <= 32'h0000_2000;
  S_AXI_WSTRB  <= 4'HF;
  S_AXI_WVALID <= 1'b1;

  wait(S_AXI_WREADY);

  @(negedge ACLK);

  S_AXI_WVALID <= 1'b0;

  @(negedge ACLK);
//

// Read Address
  @(negedge ACLK);

  S_AXI_AWADDR <= 32'h4000_0010;
  S_AXI_AWVALID  <= 1'b1;

  @(negedge ACLK);

  wait(S_AXI_AWREADY);
  S_AXI_AWVALID  <= 1'b0;

  @(negedge ACLK);

  S_AXI_WDATA  <= 32'h3322_1100;
  S_AXI_WSTRB  <= 4'HF;
  S_AXI_WVALID <= 1'b1;

  wait(S_AXI_WREADY);

  @(negedge ACLK);

  S_AXI_WVALID <= 1'b0;

  @(negedge ACLK);
//

// Start Read
  @(negedge ACLK);

  S_AXI_AWADDR <= 32'h4000_000C;
  S_AXI_AWVALID  <= 1'b1;

  @(negedge ACLK);

  wait(S_AXI_AWREADY);
  S_AXI_AWVALID  <= 1'b0;

  @(negedge ACLK);

  S_AXI_WDATA  <= 32'h0000_0001;
  S_AXI_WSTRB  <= 4'HF;
  S_AXI_WVALID <= 1'b1;

  wait(S_AXI_WREADY);

  @(negedge ACLK);

  S_AXI_WVALID <= 1'b0;

  @(negedge ACLK);
//


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



// AXI Read Data
assign M_AXI_ARREADY = M_AXI_ARVALID;

reg [31:0] count,rcount;
always @(posedge ACLK or negedge ARESETN) begin
    if(!ARESETN) begin
        count <= 32'd0;
        rcount <= 32'd0;
        M_AXI_RVALID<=1'b0;
    end else begin
      if(M_AXI_RLAST) begin
        axi_rena <= 0;
      end else if(M_AXI_ARVALID) begin
        axi_rena <= 1;
      end

      if(axi_rena) begin
        count <= count + 32'd1;
      end else begin
        count <= 0;
      end

      if(M_AXI_RVALID & M_AXI_RREADY) begin
          rcount <= rcount + 32'd1;
      end
    end
end
assign M_AXI_RDATA  = {rcount,rcount};
assign M_AXI_RLAST  = (axi_rena & (count == 255))?1:0;
assign M_AXI_RVALID = axi_rena;

// AXI Write Control
initial begin

  M_AXI_BID <= 1'b0;
  M_AXI_BRESP <= 2'b00;
  M_AXI_BUSER <= 1'b0;

end

always @(posedge ACLK or negedge ARESETN)begin
  if(!ARESETN) begin
    axiwvalid <= 0;
  end else begin
    if(M_AXI_BREADY) begin
      axiwvalid <= 0;
    end else if (M_AXI_WVALID & M_AXI_WLAST) begin
      axiwvalid <= 1;
    end
  end
end

assign M_AXI_AWREADY = M_AXI_AWVALID;
assign M_AXI_WREADY  = M_AXI_WVALID;
assign M_AXI_BVALID  = axi_wvalid;

endmodule
