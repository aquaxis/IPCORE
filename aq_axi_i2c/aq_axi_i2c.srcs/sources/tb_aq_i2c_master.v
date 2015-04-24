/*
 * Copyright (C)2006-2015 AQUAXIS TECHNOLOGY.
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
module tb_i2c_master;

	// Inputs
	reg rst_n;
	reg clk;
	reg [3:0] cmd_wr;
	reg [31:0] cmd_din;
	reg [9:0] adrs;
	reg [3:0] wena;
	reg [31:0] wdata;
	reg isda;

	// Outputs
	wire [31:0] cmd_dout;
	wire [31:0] rdata;
	wire osda;
	wire osck;
	tri1 sda;

	// Instantiate the Unit Under Test (UUT)
	aq_i2c_master uut (
		.rst_n(rst_n),
		.clk(clk),
		.cmd_wr(cmd_wr),
		.cmd_din(cmd_din),
		.cmd_dout(cmd_dout),
		.adrs(adrs),
		.wena(wena),
		.wdata(wdata),
		.rdata(rdata),
		.osda(osda),
		.isda(sda),
		.osck(osck)
	);

	assign sda = (osda)?1'bZ:1'b0;
	aq_i2c_slave_model u_i2c_slabe_model(
		.sck( osck		),
		.sda( sda		)
	);

	always begin
		#5 clk = ~clk;
	end

	initial begin
		// Initialize Inputs
		rst_n = 0;
		clk = 0;
		// Wait 100 ns for global reset to finish
		#100;

		// Add stimulus here
		rst_n = 1;
	end

	reg [31:0] count;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			count[31:0] <= 32'd0;
		end else begin
			count[31:0] <= count[31:0] + 32'd1;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			cmd_wr <= 0;
			cmd_din <= 0;
			adrs <= 0;
			wena <= 0;
			wdata <= 0;
			isda <= 0;
		end else begin
			case(count[31:0])
				32'd1: begin
					wena <= 4'hF;
					adrs <= 10'h0;
					wdata <= 32'h00610160;
				end
				32'd2: begin
					wena <= 4'hF;
					adrs <= 10'h4;
					wdata <= 32'h99008F66;
				end
				32'd3: begin
					wena <= 4'hF;
					adrs <= 10'h8;
					wdata <= 32'hFFEEDDCC;
				end
				32'd5: begin
					cmd_wr <= 4'hF;
//					cmd_din <= {1'b0, 6'd0, 9'd3, 7'd0, 9'd5};
					cmd_din <= {1'b0, 6'd0, 9'd0, 7'd0, 9'd2};
				end
				32'd1100000: begin
					wena <= 4'hF;
					adrs <= 10'h0;
					wdata <= 32'h00000061;
				end
				32'd1100001: begin
					cmd_wr <= 4'hF;
					cmd_din <= {1'b1, 6'd0, 9'd8, 7'd0, 9'd1};
				end
				32'd1200000: begin
					adrs <= 10'h200;
				end
				32'd4000000: begin
					$finish();
				end
				default: begin
					cmd_wr <= 0;
					cmd_din <= 0;
					adrs <= 0;
					wena <= 0;
					wdata <= 0;
					isda <= 0;
				end
			endcase
		end
	end

endmodule

