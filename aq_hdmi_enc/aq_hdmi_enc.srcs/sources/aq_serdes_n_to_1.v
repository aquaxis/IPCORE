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
`timescale 1ps/1ps

module aq_serdes_n_to_1 (
  input       ioclk,
  input       gclk, 
  input       reset,
  input [9:0] datain,
  output      iob_data_out
);

wire		cascade_di;
wire		cascade_ti;
wire		cascade_do;
wire		cascade_to;

reg toggle;
reg [4:0] datain_d;

reg rst_inst;
always @(posedge gclk or posedge reset) begin
    if(reset) begin
        rst_inst <= 1'b1;
    end else begin
        rst_inst <= 1'b0;
    end
end

OSERDESE2 #(
	.DATA_WIDTH     	(10),
    .TRISTATE_WIDTH     (1),
	.DATA_RATE_OQ      	("DDR"),
	.DATA_RATE_TQ      	("SDR"),
	.SERDES_MODE    	("MASTER")
	)
oserdes_m (
	.RST     		(rst_inst),
	.CLK    		(ioclk),
	.CLKDIV  		(gclk),

    .OQ         (iob_data_out),
    .D8         (datain[7]),
    .D7         (datain[6]),
    .D6         (datain[5]),
    .D5         (datain[4]),
    .D4         (datain[3]),
    .D3         (datain[2]),
    .D2         (datain[1]),
    .D1         (datain[0]),
    .OCE        (1'b1),

	.TQ  			(),
	.T1 			(1'b0),
	.T2 			(1'b0),
	.T3 			(1'b0),
	.T4 			(1'b0),
	.TCE	   		(1'b0),

	.TBYTEIN    		(1'b0),
	.TBYTEOUT    		(),
	.TFB(),
	.SHIFTIN1 		(cascade_di),
    .SHIFTIN2       (cascade_ti),
	.SHIFTOUT1 		(),
	.SHIFTOUT2 		()
    );

OSERDESE2 #(
	.DATA_WIDTH     	(10),
    .TRISTATE_WIDTH     (1),
    .DATA_RATE_OQ          ("DDR"),
    .DATA_RATE_TQ          ("SDR"),
	.SERDES_MODE    	("SLAVE")
	)
oserdes_s (
	.RST     		(rst_inst),
    .CLK            (ioclk),
    .CLKDIV          (gclk),

	.D8(1'b0),
	.D7(1'b0),
	.D6(1'b0),
	.D5(1'b0),
	.D4  			(datain[9]),
	.D3  			(datain[8]),
	.D2(1'b0),
	.D1(1'b0),
    .OCE        (1'b1),
	
	.TQ  			(),
    .T1             (1'b0),
    .T2             (1'b0),
    .T3             (1'b0),
    .T4             (1'b0),
    .TCE               (1'b0),

    .TBYTEIN            (1'b0),
    .TBYTEOUT            (),
    .TFB(),
    .SHIFTIN1         (1'b0),
    .SHIFTIN2         (1'b0),
    .SHIFTOUT1         (cascade_di),
    .SHIFTOUT2         (cascade_ti)
);
endmodule
