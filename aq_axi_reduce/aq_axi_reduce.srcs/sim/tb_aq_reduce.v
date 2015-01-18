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
module tb_aq_reduce;

	// Inputs
	reg RST_N;
	reg CLK;
	reg [10:0] ORG_X;
	reg [10:0] ORG_Y;
	reg [10:0] CNV_X;
	reg [10:0] CNV_Y;
	reg DIN_WE;
	reg DIN_START_X;
	reg DIN_START_Y;
	reg [7:0] DIN_A;
	reg [7:0] DIN_R;
	reg [7:0] DIN_G;
	reg [7:0] DIN_B;

	// Outputs
	wire DOUT_OE;
	wire DOUT_START_X;
	wire DOUT_START_Y;
	wire [7:0] DOUT_A;
	wire [7:0] DOUT_R;
	wire [7:0] DOUT_G;
	wire [7:0] DOUT_B;

	parameter TIME10N = 10;

	// Instantiate the Unit Under Test (UUT)
	aq_reduce uut (
		.RST_N(RST_N), 
		.CLK(CLK), 
		.ORG_X(ORG_X), 
		.ORG_Y(ORG_Y), 
		.CNV_X(CNV_X), 
		.CNV_Y(CNV_Y), 
		.DIN_WE(DIN_WE), 
		.DIN_START_X(DIN_START_X), 
		.DIN_START_Y(DIN_START_Y), 
		.DIN_A(DIN_A), 
		.DIN_R(DIN_R), 
		.DIN_G(DIN_G), 
		.DIN_B(DIN_B), 
		.DOUT_OE(DOUT_OE), 
		.DOUT_START_X(DOUT_START_X), 
		.DOUT_START_Y(DOUT_START_Y), 
		.DOUT_A(DOUT_A), 
		.DOUT_R(DOUT_R), 
		.DOUT_G(DOUT_G), 
		.DOUT_B(DOUT_B)
	);

	always begin
		#(TIME10N/2) CLK = ~CLK;
	end

	initial begin
		// Initialize Inputs
		RST_N = 0;
		CLK = 0;
		ORG_X = 0;
		ORG_Y = 0;
		CNV_X = 0;
		CNV_Y = 0;
		DIN_WE = 0;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 0;
		DIN_R = 0;
		DIN_G = 0;
		DIN_B = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		RST_N = 1;
		// Add stimulus here

		@(posedge CLK);

		ORG_X = 4;
		ORG_Y = 4;
		CNV_X = 3;
		CNV_Y = 3;

		// 0,0
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 1;
		DIN_START_Y = 1;
		DIN_A = 'hF0;
		DIN_R = 'hE0;
		DIN_G = 'hD0;
		DIN_B = 'hC0;

		// 1,0
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 1;
		DIN_A = 'hE0;
		DIN_R = 'hD0;
		DIN_G = 'hC0;
		DIN_B = 'hB0;

		// 2,0
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 1;
		DIN_A = 'hD0;
		DIN_R = 'hC0;
		DIN_G = 'hB0;
		DIN_B = 'hA0;

		// 3,0
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 1;
		DIN_A = 'hC0;
		DIN_R = 'hB0;
		DIN_G = 'hA0;
		DIN_B = 'h90;

		// 0,1
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 1;
		DIN_START_Y = 0;
		DIN_A = 'hB0;
		DIN_R = 'hA0;
		DIN_G = 'h90;
		DIN_B = 'h80;

		// 1,1
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'hA0;
		DIN_R = 'h90;
		DIN_G = 'h80;
		DIN_B = 'h70;

		// 2,1
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'h90;
		DIN_R = 'h80;
		DIN_G = 'h70;
		DIN_B = 'h60;

		// 3,1
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'h80;
		DIN_R = 'h70;
		DIN_G = 'h60;
		DIN_B = 'h50;

		// 0,0
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 1;
		DIN_START_Y = 0;
		DIN_A = 'hF0;
		DIN_R = 'hE0;
		DIN_G = 'hD0;
		DIN_B = 'hC0;

		// 1,0
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'hE0;
		DIN_R = 'hD0;
		DIN_G = 'hC0;
		DIN_B = 'hB0;

		// 2,0
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'hD0;
		DIN_R = 'hC0;
		DIN_G = 'hB0;
		DIN_B = 'hA0;

		// 3,0
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'hC0;
		DIN_R = 'hB0;
		DIN_G = 'hA0;
		DIN_B = 'h90;

		// 0,1
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 1;
		DIN_START_Y = 0;
		DIN_A = 'hB0;
		DIN_R = 'hA0;
		DIN_G = 'h90;
		DIN_B = 'h80;

		// 1,1
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'hA0;
		DIN_R = 'h90;
		DIN_G = 'h80;
		DIN_B = 'h70;

		// 2,1
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'h90;
		DIN_R = 'h80;
		DIN_G = 'h70;
		DIN_B = 'h60;

		// 3,1
		@(posedge CLK);
		DIN_WE = 1;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 'h80;
		DIN_R = 'h70;
		DIN_G = 'h60;
		DIN_B = 'h50;

		// fin
		@(posedge CLK);
		DIN_WE = 0;
		DIN_START_X = 0;
		DIN_START_Y = 0;
		DIN_A = 0;
		DIN_R = 0;
		DIN_G = 0;
		DIN_B = 0;

		@(posedge CLK);

		repeat (40) @(posedge CLK);
		
		$finish();
	end
      
endmodule

