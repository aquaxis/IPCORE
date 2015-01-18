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
module aq_div19x11(
	input			RST_N,
	input			CLK,
	input [18:0]	DINA,
	input [10:0]	DINB,
	output [7:0]	DOUT
);

reg [19:0] r1r, r2r, r3r, r4r, r5r, r6r, r7r, r8r;
reg [10:0] s1r, s2r, s3r, s4r, s5r, s6r, s7r;

always @(negedge RST_N or posedge CLK) begin
	if(!RST_N) begin
		r1r <= 20'd0;
		r2r <= 20'd0;
		r3r <= 20'd0;
		r4r <= 20'd0;
		r5r <= 20'd0;
		r6r <= 20'd0;
		r7r <= 20'd0;
		r8r <= 20'd0;
		s1r <= 11'd0;
		s2r <= 11'd0;
		s3r <= 11'd0;
		s4r <= 11'd0;
		s5r <= 11'd0;
		s6r <= 11'd0;
		s7r <= 11'd0;
	end else begin
		// 1st
		r1r[19:7]	<= ({1'b 1,DINA[18:7] }) - ({2'b 00,DINB});
		r1r[6:0]	<= DINA[6:0] ;
		s1r 		<= DINB;
		// 2nd
		if((r1r[19] == 1'b 0)) begin
			r2r[18:6]	<= ({1'b 0,r1r[17:6] }) + ({2'b 00,s1r});
		end else begin
			r2r[18:6]	<= ({1'b 1,r1r[17:6] }) - ({2'b 00,s1r});
		end
		r2r[19]		<= r1r[19] ;
		r2r[5:0]	<= r1r[5:0] ;
		s2r 		<= s1r;
		// 3rd
		if((r2r[18] == 1'b 0)) begin
			r3r[17:5]	<= ({1'b 0,r2r[16:5] }) + ({2'b 00,s2r});
		end else begin
			r3r[17:5]	<= ({1'b 1,r2r[16:5] }) - ({2'b 00,s2r});
		end
		r3r[19:18]	<= r2r[19:18] ;
		r3r[4:0]	<= r2r[4:0] ;
		s3r 		<= s2r;
		// 4th
		if((r3r[17] == 1'b 0)) begin
			r4r[16:4]	<= ({1'b 0,r3r[15:4] }) + ({2'b 00,s3r});
		end else begin
			r4r[16:4]	<= ({1'b 1,r3r[15:4] }) - ({2'b 00,s3r});
		end
		r4r[19:17]	<= r3r[19:17] ;
		r4r[3:0]	<= r3r[3:0] ;
		s4r 		<= s3r;
		// 5th
		if((r4r[16] == 1'b 0)) begin
			r5r[15:3]	<= ({1'b 0,r4r[14:3] }) + ({2'b 00,s4r});
		end else begin
			r5r[15:3]	<= ({1'b 1,r4r[14:3] }) - ({2'b 00,s4r});
		end
		r5r[19:16]	<= r4r[19:16] ;
		r5r[2:0]	<= r4r[2:0] ;
		s5r 		<= s4r;
		// 6th
		if((r5r[15] == 1'b 0)) begin
			r6r[14:2]	<= ({1'b 0,r5r[13:2] }) + ({2'b 00,s5r});
		end else begin
			r6r[14:2]	<= ({1'b 1,r5r[13:2] }) - ({2'b 00,s5r});
		end
		r6r[19:15]	<= r5r[19:15] ;
		r6r[1:0]	<= r5r[1:0] ;
		s6r 		<= s5r;
		// 7th
		if((r6r[14] == 1'b 0)) begin
			r7r[13:1]	<= ({1'b 0,r6r[12:1] }) + ({2'b 00,s6r});
		end else begin
			r7r[13:1]	<= ({1'b 1,r6r[12:1] }) - ({2'b 00,s6r});
		end
		r7r[19:14]	<= r6r[19:14] ;
		r7r[0]		<= r6r[0] ;
		s7r 		<= s6r;
		// 8th
		if((r7r[13] == 1'b 0)) begin
			r8r[12:0]	<= ({1'b 0,r7r[11:0] }) + ({2'b 00,s7r});
		end else begin
			r8r[12:0]	<= ({1'b 1,r7r[11:0] }) - ({2'b 00,s7r});
		end
		r8r[19:13]	<= r7r[19:13] ;
    end
end

assign DOUT = r8r[19:12] ;

endmodule
