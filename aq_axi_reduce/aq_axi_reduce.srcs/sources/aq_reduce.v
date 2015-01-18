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
module aq_reduce(
	input RST_N,
	input CLK,

	input [10:0] ORG_X,
	input [10:0] ORG_Y,
	input [10:0] CNV_X,
	input [10:0] CNV_Y,

	input DIN_WE,
	input DIN_START_X,
	input DIN_START_Y,
	input [7:0] DIN_A,
	input [7:0] DIN_R,
	input [7:0] DIN_G,
	input [7:0] DIN_B,

	output DOUT_OE,
	output DOUT_START_X,
	output DOUT_START_Y,
	output [7:0] DOUT_A,
	output [7:0] DOUT_R,
	output [7:0] DOUT_G,
	output [7:0] DOUT_B 
);

// 1st Buffer
// バッファリング
reg [10:0]	buf_org_x, buf_org_y, buf_cnv_x, buf_cnv_y;
reg			buf_din_we, buf_din_start_x, buf_din_start_y;
reg [7:0]	buf_din_a, buf_din_r, buf_din_g, buf_din_b;
always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		buf_org_x[10:0]	<= 11'd0;
		buf_org_y[10:0]	<= 11'd0;
		buf_cnv_x[10:0]	<= 11'd0;
		buf_cnv_y[10:0]	<= 11'd0;
		buf_din_we		<= 1'b0;
		buf_din_start_x	<= 1'b0;
		buf_din_start_y	<= 1'b0;
		buf_din_a[7:0]	<= 8'd0;
		buf_din_r[7:0]	<= 8'd0;
		buf_din_g[7:0]	<= 8'd0;
		buf_din_b[7:0]	<= 8'd0;
	end else begin
		buf_org_x[10:0]	<= ORG_X;
		buf_org_y[10:0]	<= ORG_Y;
		buf_cnv_x[10:0]	<= CNV_X;
		buf_cnv_y[10:0]	<= CNV_Y;
		buf_din_we		<= DIN_WE;
		buf_din_start_x	<= DIN_START_X;
		buf_din_start_y	<= DIN_START_Y;
		buf_din_a[7:0]	<= DIN_A;
		buf_din_r[7:0]	<= DIN_R;
		buf_din_g[7:0]	<= DIN_G;
		buf_din_b[7:0]	<= DIN_B;
	end
end

// Enable信号のシフトレジスタ
// ビットはステージの番号と一致する
/*
always @( posedge CLK or negedge RST_N ) begin
if (!RST_N) begin
st_ena
end else begin
st_ena[31:0] <= { st_ena[30:0], DIN_WE };
end
end
*/

// Stage 1
// 縮小割合の計算
// X
wire		x_valid, y_valid;
wire [10:0]	x_ma, x_mb, y_ma, y_mb;
reg [2:0]	st1_st;
reg [7:0]	st1_da, st1_dr, st1_dg, st1_db;
aq_calc_size u_aq_calc_size_x(
	.RST_N	( RST_N				),
	.CLK	( CLK				),
	.ENA	( buf_din_we		),
	.START	( buf_din_start_x	),
	.ORG	( buf_org_x			),
	.CNV	( buf_cnv_x			),
	.VALID	( x_valid			),
	.MA		( x_ma				),
	.MB		( x_mb				)
);
// Y
aq_calc_size u_aq_calc_size_y(
	.RST_N	( RST_N				),
	.CLK	( CLK				),
	.ENA	( buf_din_we & buf_din_start_x		),
	.START	( buf_din_start_x & buf_din_start_y	),
	.ORG	( buf_org_y			),
	.CNV	( buf_cnv_y			),
	.VALID	( y_valid			),
	.MA		( y_ma				),
	.MB		( y_mb				)
);
always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		st1_st	<= 3'd0;
		st1_da	<= 8'd0;
		st1_dr	<= 8'd0;
		st1_dg	<= 8'd0;
		st1_db	<= 8'd0;
	end else begin
		st1_st	<= { buf_din_start_y, buf_din_start_x, buf_din_we };
		st1_da	<= buf_din_a;
		st1_dr	<= buf_din_r;
		st1_dg	<= buf_din_g;
		st1_db	<= buf_din_b;
	end
end

// Stage 2 -> 4
// X方向の拡大
wire [18:0]	st4_da, st4_dr, st4_dg, st4_db, st4_da_b, st4_dr_b, st4_dg_b, st4_db_b;
reg [4:0]	st2_st, st3_st, st4_st;
reg [10:0]	st2_y_ma, st3_y_ma, st4_y_ma;
reg [10:0]	st2_y_mb, st3_y_mb, st4_y_mb;
aq_mul11x8 u_aq_mul11x8_xaa(.RST_N( RST_N	), .CLK( CLK ), .DINA( x_ma ), .DINB( st1_da ), .DOUT( st4_da ));
aq_mul11x8 u_aq_mul11x8_xar(.RST_N( RST_N	), .CLK( CLK ), .DINA( x_ma ), .DINB( st1_dr ), .DOUT( st4_dr ));
aq_mul11x8 u_aq_mul11x8_xag(.RST_N( RST_N	), .CLK( CLK ), .DINA( x_ma ), .DINB( st1_dg ), .DOUT( st4_dg ));
aq_mul11x8 u_aq_mul11x8_xab(.RST_N( RST_N	), .CLK( CLK ), .DINA( x_ma ), .DINB( st1_db ), .DOUT( st4_db ));
aq_mul11x8 u_aq_mul11x8_xba(.RST_N( RST_N	), .CLK( CLK ), .DINA( x_mb ), .DINB( st1_da ), .DOUT( st4_da_b ));
aq_mul11x8 u_aq_mul11x8_xbr(.RST_N( RST_N	), .CLK( CLK ), .DINA( x_mb ), .DINB( st1_dr ), .DOUT( st4_dr_b ));
aq_mul11x8 u_aq_mul11x8_xbg(.RST_N( RST_N	), .CLK( CLK ), .DINA( x_mb ), .DINB( st1_dg ), .DOUT( st4_dg_b ));
aq_mul11x8 u_aq_mul11x8_xbb(.RST_N( RST_N	), .CLK( CLK ), .DINA( x_mb ), .DINB( st1_db ), .DOUT( st4_db_b ));
always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		st2_st	<= 5'd0;
		st3_st	<= 5'd0;
		st4_st	<= 5'd0;
		st2_y_ma	<= 11'd0;
		st3_y_ma	<= 11'd0;
		st4_y_ma	<= 11'd0;
		st2_y_mb	<= 11'd0;
		st3_y_mb	<= 11'd0;
		st4_y_mb	<= 11'd0;
	end else begin
		st2_st		<= { y_valid, x_valid, st1_st };
		st3_st		<= st2_st;
		st4_st		<= st3_st;
		st2_y_ma	<= y_ma;
		st3_y_ma	<= st2_y_ma;
		st4_y_ma	<= st3_y_ma;
		st2_y_mb	<= y_mb;
		st3_y_mb	<= st2_y_mb;
		st4_y_mb	<= st3_y_mb;
	end
end

// Stage 5
reg [4:0]	st5_st;
reg [10:0]	st5_y_ma, st5_y_mb;
reg [18:0]	st5_da, st5_dr, st5_dg, st5_db;
reg [18:0]	st5_da_b, st5_dr_b, st5_dg_b, st5_db_b;
always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		st5_st	<= 5'd0;
		st5_y_ma	<= 11'd0;
		st5_y_mb	<= 11'd0;
		st5_da		<= 19'd0;
		st5_dr		<= 19'd0;
		st5_dg		<= 19'd0;
		st5_db		<= 19'd0;
		st5_da_b	<= 19'd0;
		st5_dr_b	<= 19'd0;
		st5_dg_b	<= 19'd0;
		st5_db_b	<= 19'd0;
	end else begin
		st5_st	<= st4_st;
		st5_y_ma	<= st4_y_ma;
		st5_y_mb	<= st4_y_mb;
		if( st4_st[0] ) begin
			if( st4_st[1] ) begin
				st5_da		<= st4_da;
				st5_da_b	<= st4_da_b;
				st5_dr		<= st4_dr;
				st5_dr_b	<= st4_dr_b;
				st5_dg		<= st4_dg;
				st5_dg_b	<= st4_dg_b;
				st5_db		<= st4_db;
				st5_db_b	<= st4_db_b;
			end else if( st4_st[3] ) begin
				// VALが立っている時は出力データが揃っていることを示す
				st5_da		<= st4_da + st5_da_b;
				st5_da_b	<= st4_da_b;
				st5_dr		<= st4_dr + st5_dr_b;
				st5_dr_b	<= st4_dr_b;
				st5_dg		<= st4_dg + st5_dg_b;
				st5_dg_b	<= st4_dg_b;
				st5_db		<= st4_db + st5_db_b;
				st5_db_b	<= st4_db_b;
			end else begin
				// VALが立っていない時は計算したデータを保持するタイミングである
				st5_da_b	<= st4_da_b + st5_da_b;
				st5_dr_b	<= st4_dr_b + st5_dr_b;
				st5_dg_b	<= st4_dg_b + st5_dg_b;
				st5_db_b	<= st4_db_b + st5_db_b;
			end
		end
	end
end

// Stage 6-13
wire [7:0]	st13_da, st13_dr, st13_dg, st13_db;
reg [4:0]	st6_st, st7_st, st8_st, st9_st, st10_st, st11_st, st12_st, st13_st; 
reg [10:0]	st6_y_ma, st7_y_ma, st8_y_ma, st9_y_ma, st10_y_ma, st11_y_ma, st12_y_ma, st13_y_ma;
reg [10:0]	st6_y_mb, st7_y_mb, st8_y_mb, st9_y_mb, st10_y_mb, st11_y_mb, st12_y_mb, st13_y_mb;
aq_div19x11 u_aq_div19x11_xa (
	.RST_N	( RST_N		),
	.CLK	( CLK		),
	.DINA	( st5_da	),
	.DINB	( buf_org_x	),
	.DOUT	( st13_da	)
);
aq_div19x11 u_aq_div19x11_xr (
	.RST_N	( RST_N		),
	.CLK	( CLK		),
	.DINA	( st5_dr	),
	.DINB	( buf_org_x	),
	.DOUT	( st13_dr	)
);
aq_div19x11 u_aq_div19x11_xg (
	.RST_N	( RST_N		),
	.CLK	( CLK		),
	.DINA	( st5_dg	),
	.DINB	( buf_org_x	),
	.DOUT	( st13_dg	)
);
aq_div19x11 u_aq_div19x11_xb (
	.RST_N	( RST_N		),
	.CLK	( CLK		),
	.DINA	( st5_db	),
	.DINB	( buf_org_x	),
	.DOUT	( st13_db	)
);
always @( posedge CLK or negedge RST_N ) begin
	if ( !RST_N ) begin
		st6_st	<= 5'd0;
		st7_st	<= 5'd0;
		st8_st	<= 5'd0;
		st9_st	<= 5'd0;
		st10_st	<= 5'd0;
		st11_st	<= 5'd0;
		st12_st	<= 5'd0;
		st13_st	<= 5'd0;
		st6_y_ma	<= 11'd0;
		st7_y_ma	<= 11'd0;
		st8_y_ma	<= 11'd0;
		st9_y_ma	<= 11'd0;
		st10_y_ma	<= 11'd0;
		st11_y_ma	<= 11'd0;
		st12_y_ma	<= 11'd0;
		st13_y_ma	<= 11'd0;
		st6_y_mb	<= 11'd0;
		st7_y_mb	<= 11'd0;
		st8_y_mb	<= 11'd0;
		st9_y_mb	<= 11'd0;
		st10_y_mb	<= 11'd0;
		st11_y_mb	<= 11'd0;
		st12_y_mb	<= 11'd0;
		st13_y_mb	<= 11'd0;
	end else begin
		st6_st <=  st5_st;
		st7_st <=  st6_st;
		st8_st <=  st7_st;
		st9_st <=  st8_st;
		st10_st <=  st9_st;
		st11_st <=  st10_st;
		st12_st <=  st11_st;
		st13_st <=  st12_st;
		st6_y_ma <= st5_y_ma;
		st7_y_ma <= st6_y_ma;
		st8_y_ma <= st7_y_ma;
		st9_y_ma <= st8_y_ma;
		st10_y_ma <= st9_y_ma;
		st11_y_ma <= st10_y_ma;
		st12_y_ma <= st11_y_ma;
		st13_y_ma <= st12_y_ma;
		st6_y_mb <= st5_y_mb;
		st7_y_mb <= st6_y_mb;
		st8_y_mb <= st7_y_mb;
		st9_y_mb <= st8_y_mb;
		st10_y_mb <= st9_y_mb;
		st11_y_mb <= st10_y_mb;
		st12_y_mb <= st11_y_mb;
		st13_y_mb <= st12_y_mb;
	end
end

// Stage 14 -> 16
wire [18:0]	st16_da, st16_dr, st16_dg, st16_db;
wire [18:0]	st16_da_b, st16_dr_b, st16_dg_b, st16_db_b;
reg [4:0]	st14_st, st15_st, st16_st;
reg [10:0]	st14_y_ma, st15_y_ma, st16_y_ma;
reg [10:0]	st14_y_mb, st15_y_mb, st16_y_mb;
aq_mul11x8 u_aq_mul11x8_yaa(.RST_N( RST_N	), .CLK( CLK ), .DINA( st13_y_ma ), .DINB( st13_da ), .DOUT( st16_da ));
aq_mul11x8 u_aq_mul11x8_yar(.RST_N( RST_N	), .CLK( CLK ), .DINA( st13_y_ma ), .DINB( st13_dr ), .DOUT( st16_dr ));
aq_mul11x8 u_aq_mul11x8_yag(.RST_N( RST_N	), .CLK( CLK ), .DINA( st13_y_ma ), .DINB( st13_dg ), .DOUT( st16_dg ));
aq_mul11x8 u_aq_mul11x8_yab(.RST_N( RST_N	), .CLK( CLK ), .DINA( st13_y_ma ), .DINB( st13_db ), .DOUT( st16_db ));
aq_mul11x8 u_aq_mul11x8_yba(.RST_N( RST_N	), .CLK( CLK ), .DINA( st13_y_mb ), .DINB( st13_da ), .DOUT( st16_da_b ));
aq_mul11x8 u_aq_mul11x8_ybr(.RST_N( RST_N	), .CLK( CLK ), .DINA( st13_y_mb ), .DINB( st13_dr ), .DOUT( st16_dr_b ));
aq_mul11x8 u_aq_mul11x8_ybg(.RST_N( RST_N	), .CLK( CLK ), .DINA( st13_y_mb ), .DINB( st13_dg ), .DOUT( st16_dg_b ));
aq_mul11x8 u_aq_mul11x8_ybb(.RST_N( RST_N	), .CLK( CLK ), .DINA( st13_y_mb ), .DINB( st13_db ), .DOUT( st16_db_b ));
always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		st14_st	<= 5'd0;
		st15_st	<= 5'd0;
		st16_st	<= 5'd0;
		st14_y_ma	<= 11'd0;
		st15_y_ma	<= 11'd0;
		st16_y_ma	<= 11'd0;
		st14_y_mb	<= 11'd0;
		st15_y_mb	<= 11'd0;
		st16_y_mb	<= 11'd0;
		st17_st	<= 5'd0;
		st17_y_ma	<= 11'd0;
		st17_y_mb	<= 11'd0;
	end else begin
		st14_st <=  st13_st;
		st15_st	<= st14_st;
		st16_st	<= st15_st;
		st14_y_ma <= st13_y_ma;
		st15_y_ma	<= st14_y_ma;
		st16_y_ma	<= st15_y_ma;
		st14_y_mb <= st13_y_mb;
		st15_y_mb	<= st14_y_mb;
		st16_y_mb	<= st15_y_mb;
		st17_st	<= st16_st;
		st17_y_ma	<= st16_y_ma;
		st17_y_mb	<= st16_y_mb;
	end
end

// Stage 17
reg [10:0]	addra, addrb;
reg [4:0]	st17_st;
reg [10:0]	st17_y_ma, st17_y_mb;
reg [18:0]	st17_da, st17_dr, st17_dg, st17_db;
reg [18:0]	st17_da_bi, st17_dr_bi, st17_dg_bi, st17_db_bi;
wire [18:0]	st17_da_b, st17_dr_b, st17_dg_b, st17_db_b;
wire		st17_we;
assign st17_we = st17_st[3] & st17_st[0];
aq_ram19x11 u_aq_ram19x11_ya(
	.CLKA	( CLK			),
	.WEA	( st17_we		),
	.ADDRA	( addra 		),
	.DINA	( st17_da_bi	),
	
	.CLKB	( CLK			),
	.ADDRB	( addrb			),
	.DOUTB	( st17_da_b		)
);
aq_ram19x11 u_aq_ram19x11_yr(
	.CLKA	( CLK			),
	.WEA	( st17_we		),
	.ADDRA	( addra 		),
	.DINA	( st17_dr_bi	),
	
	.CLKB	( CLK			),
	.ADDRB	( addrb			),
	.DOUTB	( st17_dr_b		)
);
aq_ram19x11 u_aq_ram19x11_yg(
	.CLKA	( CLK			),
	.WEA	( st17_we		),
	.ADDRA	( addra 		),
	.DINA	( st17_dg_bi	),
	
	.CLKB	( CLK			),
	.ADDRB	( addrb			),
	.DOUTB	( st17_dg_b		)
);
aq_ram19x11 u_aq_ram19x11_yb(
	.CLKA	( CLK			),
	.WEA	( st17_we		),
	.ADDRA	( addra 		),
	.DINA	( st17_db_bi	),
	
	.CLKB	( CLK			),
	.ADDRB	( addrb			),
	.DOUTB	( st17_db_b		)
);
always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		addrb	<= 11'd0;
	end else begin
		if( st14_st[1] ) begin
			addrb	<= 11'd0;
		end else if( st14_st[3] ) begin
			addrb <= addrb + 11'd1;
		end
	end
end
always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		st17_st	<= 5'd0;
		st17_y_ma	<= 11'd0;
		st17_y_mb	<= 11'd0;
		st17_da		<= 19'd0;
		st17_dr		<= 19'd0;
		st17_dg		<= 19'd0;
		st17_db		<= 19'd0;
		st17_da_bi		<= 19'd0;
		st17_dr_bi		<= 19'd0;
		st17_dg_bi		<= 19'd0;
		st17_db_bi		<= 19'd0;
		addra	<= 11'd0;
	end else begin
		st17_st		<= st16_st;
		st17_y_ma	<= st16_y_ma;
		st17_y_mb	<= st16_y_mb;
		if( st16_st[3] ) begin
			if( st16_st[2] ) begin
				st17_da		<= st16_da;
				st17_da_bi	<= st16_da_b;
				st17_dr		<= st16_dr;
				st17_dr_bi	<= st16_dr_b;
				st17_dg		<= st16_dg;
				st17_dg_bi	<= st16_dg_b;
				st17_db		<= st16_db;
				st17_db_bi	<= st16_db_b;
			end else if( st16_st[4] ) begin
				// VALが立っている時は出力データが揃っていることを示す
				st17_da		<= st16_da + st17_da_b;
				st17_da_bi	<= st16_da_b;
				st17_dr		<= st16_dr + st17_dr_b;
				st17_dr_bi	<= st16_dr_b;
				st17_dg		<= st16_dg + st17_dg_b;
				st17_dg_bi	<= st16_dg_b;
				st17_db		<= st16_db + st17_db_b;
				st17_db_bi	<= st16_db_b;
			end else begin
				// VALが立っていない時は計算したデータを保持するタイミングである
				st17_da_bi	<= st16_da_b + st17_da_b;
				st17_dr_bi	<= st16_dr_b + st17_dr_b;
				st17_dg_bi	<= st16_dg_b + st17_dg_b;
				st17_db_bi	<= st16_db_b + st17_db_b;
			end
		end
		if( st16_st[1] ) begin
			addra	<= 11'd0;
		end else if( st16_st[3] ) begin
			addra <= addra + 11'd1;
		end
	end
end

// Stage 18-25
wire [7:0]	st25_da, st25_dr, st25_dg, st25_db;
reg [4:0]	st18_st, st19_st, st20_st, st21_st, st22_st, st23_st, st24_st, st25_st;
aq_div19x11 u_aq_div19x11_ya (
	.RST_N	( RST_N		),
	.CLK	( CLK		),
	.DINA	( st17_da	),
	.DINB	( buf_org_y	),
	.DOUT	( st25_da	)
);
aq_div19x11 u_aq_div19x11_yr (
	.RST_N	( RST_N		),
	.CLK	( CLK		),
	.DINA	( st17_dr	),
	.DINB	( buf_org_y	),
	.DOUT	( st25_dr	)
);
aq_div19x11 u_aq_div19x11_yg (
	.RST_N	( RST_N		),
	.CLK	( CLK		),
	.DINA	( st17_dg	),
	.DINB	( buf_org_y	),
	.DOUT	( st25_dg	)
);
aq_div19x11 u_aq_div19x11_yb (
	.RST_N	( RST_N		),
	.CLK	( CLK		),
	.DINA	( st17_db	),
	.DINB	( buf_org_y	),
	.DOUT	( st25_db	)
);
always @( posedge CLK or negedge RST_N ) begin
	if ( !RST_N ) begin
		st18_st <= 5'd0;
		st19_st <= 5'd0;
		st20_st <= 5'd0;
		st21_st <= 5'd0;
		st22_st <= 5'd0;
		st23_st <= 5'd0;
		st24_st <= 5'd0;
		st25_st <= 5'd0;
	end else begin
		st18_st <=  st17_st;
		st19_st <=  st18_st;
		st20_st <=  st19_st;
		st21_st <=  st20_st;
		st22_st <=  st21_st;
		st23_st <=  st22_st;
		st24_st <=  st23_st;
		st25_st <=  st24_st;
	end
end

// Stage 28
reg [4:0]	st26_st;
reg [7:0]	st26_da, st26_dr, st26_dg, st26_db;
always @( posedge CLK or negedge RST_N ) begin
	if ( !RST_N ) begin
		st26_st <= 5'd0;
		st26_da <= 8'd0;
		st26_dr <= 8'd0;
		st26_dg <= 8'd0;
		st26_db <= 8'd0;
	end else begin
		st26_st <=  st25_st;
		st26_da	<=	st25_da;
		st26_dr	<=	st25_dr;
		st26_dg	<=	st25_dg;
		st26_db	<=	st25_db;
	end
end

// Output signals
assign DOUT_OE = ( st26_st[0] )?( st26_st[3] & st26_st[4] ):1'b0;
assign DOUT_START_X = ( st26_st[0] )?st26_st[1]:1'b0;
assign DOUT_START_Y = ( st26_st[0] )?st26_st[2]:1'b0;
assign DOUT_A = st26_da;
assign DOUT_R = st26_dr;
assign DOUT_G = st26_dg;
assign DOUT_B = st26_db;

endmodule
