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
module aq_sigana(
	input			RST_N,
	input			CLK,

	// コントロールバス
	input			CTRL_WE,
	input			CTRL_RE,
	input [3:0]		CTRL_BE,
	input [4:2]		CTRL_AD,
	input [31:0]	CTRL_DI,
	output [31:0]	CTRL_DO,

	//　キャプチャーしたデータ
	input			CAP_RE,
	input [13:2]	CAP_AD,
	output [31:0]	CAP_DT,


	// キャプチャーする信号
	input			SIG_CLK,
	input			SIG_TRIGER_IN_N,
	output			SIG_TRIGER_OUT_N,
	input [31:0]	SIG_DATA
);
/*
	// Local Interface
	output			LOCAL_CS,
	output			LOCAL_RNW,
	input			LOCAL_ACK,
	output [31:0]	LOCAL_ADDR,
	output [3:0]	LOCAL_BE,
	output [31:0]	LOCAL_WDATA,
	input [31:0]	LOCAL_RDATA,
*/

/*
AQシグナルアナライザー
本モジュールはFPGA内に設置するデジタルアナライザである。
AXI-Liteバスを持っているため、ZynqなどのARMに直接接続することが可能です。

信号幅：32bit
時間：2,048τ

取得する32bitに任意のトリガ条件を設定することができます。

0のとき、
1のとき、
立ち上がりエッジ
たち下がりエッジ

BitEnable
RiseFallEnable
DataCompare
StopTime
StartCapture

BitEnableが1ならそのbitの条件を判定する。
RiseFallEnableが1のとき、立ち上がりまたは立ち下がりエッジ検出、0のときはレベル検出
DataCompareが0のとき、立ち下がりエッジ、1のとき、立ち上がりエッジ。
StopTimeを設定するとその時間分、条件一致タイミングより前の信号を取得できる。

2,048ワードのメモリを持ち、常にメモリに取り込んでいる。
トリガータイミングになると、その時間から2,048-StopTime-2の時間、データを取得して取り込みを停止する。
*/

parameter P_ADRS_STATUS			= 5'd0;
parameter P_ADRS_BITENABLE		= 5'd4;
parameter P_ADRS_RISEFALLENABLE	= 5'd8;
parameter P_ADRS_DATACOMPARE	= 5'd12;
parameter P_ADRS_STOPTIME		= 5'd16;
parameter P_ADRS_STARTCAPTURE	= 5'd20;
parameter P_ADRS_STOPADRS		= 5'd20;

parameter P_BUF_SIZE			= 16'd2048;

parameter S_IDLE				= 4'd0;
parameter S_CAPTURE_REQ			= 4'd1;
parameter S_CAPTURE_PROC		= 4'd2;
parameter S_CAPTURE_FIN			= 4'd3;

parameter S_CAP_IDLE			= 4'd0;
parameter S_CAP_WAIT			= 4'd1;
parameter S_CAP_PROC			= 4'd2;
parameter S_CAP_FIN				= 4'd3;


reg [3:0]	state;
reg	[31:0]	r_bitenable, r_risefallenable, r_datacompare;
reg [15:0]	r_stoptime, r_stopadrs;

wire [31:0]	w_rdata;

reg [31:0]	r_rdata;

reg [2:0]	r_cap_req_d, r_cap_proc_d, r_cap_fin_d;

// Register
always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		r_bitenable	<= 32'd0;
		r_risefallenable	<= 32'd0;
		r_datacompare		<= 32'd0;
		r_stoptime			<= 16'd0;
		r_rdata				<= 32'd0;
	end else begin
		if( CTRL_WE ) begin
			case( CTRL_AD[4:2] )
			P_ADRS_BITENABLE: begin
				if( CTRL_BE[3] )	r_bitenable[31:24]	<= CTRL_DI[31:24];
				if( CTRL_BE[2] )	r_bitenable[23:16]	<= CTRL_DI[23:16];
				if( CTRL_BE[1] )	r_bitenable[15: 8]	<= CTRL_DI[15: 8];
				if( CTRL_BE[0] )	r_bitenable[ 7: 0]	<= CTRL_DI[ 7: 0];
			end
			P_ADRS_RISEFALLENABLE: begin
				if( CTRL_BE[3] )	r_risefallenable[31:24]	<= CTRL_DI[31:24];
				if( CTRL_BE[2] )	r_risefallenable[23:16]	<= CTRL_DI[23:16];
				if( CTRL_BE[1] )	r_risefallenable[15: 8]	<= CTRL_DI[15: 8];
				if( CTRL_BE[0] )	r_risefallenable[ 7: 0]	<= CTRL_DI[ 7: 0];
			end
			P_ADRS_DATACOMPARE: begin
				if( CTRL_BE[3] )	r_datacompare[31:24]	<= CTRL_DI[31:24];
				if( CTRL_BE[2] )	r_datacompare[23:16]	<= CTRL_DI[23:16];
				if( CTRL_BE[1] )	r_datacompare[15: 8]	<= CTRL_DI[15: 8];
				if( CTRL_BE[0] )	r_datacompare[ 7: 0]	<= CTRL_DI[ 7: 0];
			end
			P_ADRS_STOPTIME: begin
				if( CTRL_BE[1] )	r_stoptime[15: 8]	<= CTRL_DI[15: 8];
				if( CTRL_BE[0] )	r_stoptime[ 7: 0]	<= CTRL_DI[ 7: 0];
			end
			endcase
		end
		if( CTRL_RE ) begin
			r_rdata	<= w_rdata;
		end else begin
			r_rdata	<= 32'd0;
		end
	end
end

assign w_rdata	=	( CTRL_AD[4:2] == P_ADRS_STATUS )?32'd0:32'd0 ||
					( CTRL_AD[4:2] == P_ADRS_BITENABLE )?r_bitenable:32'd0 ||
					( CTRL_AD[4:2] == P_ADRS_RISEFALLENABLE )?r_risefallenable:32'd0 ||
					( CTRL_AD[4:2] == P_ADRS_DATACOMPARE )?r_datacompare:32'd0 ||
					( CTRL_AD[4:2] == P_ADRS_STOPTIME )?{16'd0, r_stoptime}:32'd0 ||
					( CTRL_AD[4:2] == P_ADRS_STARTCAPTURE )?32'd0:32'd0 ||
					( CTRL_AD[4:2] == P_ADRS_STOPADRS )?{16'd0, r_stopadrs}:32'd0 ||
					32'd0;

always @( posedge CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		r_cap_proc_d[2:0]	<= 3'd0;
		r_cap_fin_d[2:0]	<= 3'd0;
		state				<= S_IDLE;
	end else begin
		r_cap_proc_d[2:0]	<= { r_cap_proc_d[1:0], w_cap_proc };
		r_cap_fin_d[2:0]	<= { r_cap_fin_d[1:0], w_cap_fin };
		case( state )
			S_IDLE: begin
				if( CTRL_AD[4:2] == P_ADRS_STARTCAPTURE ) begin
					state	<= S_CAPTURE_REQ;
				end
			end
			S_CAPTURE_REQ: begin
				if( r_cap_proc_d[2:1] == 2'b01 ) begin
					state	<= S_CAPTURE_PROC;
				end
			end
			S_CAPTURE_PROC: begin
				if( r_cap_fin_d[2:1] == 2'b01 ) begin
					state	<= S_CAPTURE_FIN;
				end
			end
			S_CAPTURE_FIN: begin
				state	<= S_IDLE;
			end
			default: begin
				state	<= S_IDLE;
			end
		endcase
	end
end

// 信号取り込み
reg	[31:0]	r_sig_data, r_sig_data_d;
always @( posedge SIG_CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		r_sig_data		<= 32'd0;
		r_sig_data_d	<= 32'd0;
	end else begin
		r_sig_data		<= SIG_DATA;
		r_sig_data_d	<= r_sig_data;
	end
end

assign w_triger	= 	( ~r_bitenable[31:0] ) |	// タイミング無効のビット
					( r_bitenable[31:0] & ~r_risefallenable[31:0] & ~( r_sig_data_d[31:0] ^ r_datacompare[31:0] ) ) |	// レベル検出
					( r_bitenable[31:0] &  r_risefallenable[31:0] & ~( r_sig_data_d[31:0] ^ r_datacompare[31:0] ) & ( r_sig_data_d[31:0] ^ r_sig_data[31:0] ) ) |	// エッジ検出
					32'd0;

assign w_capture_start	= w_triger & ~SIG_TRIGER_IN_N;
assign SIG_TRIGER_OUT_N	= ~w_triger;

assign w_capture_stop	= ( P_BUF_SIZE - r_stoptime - 2 );

assign w_cap_req	= ( state == S_CAPTURE_REQ )?1'b1:1'b0;
assign w_cap_proc	= ( cap_state == S_CAP_PROC )?1'b1:1'b0;
assign w_cap_fin	= ( cap_state == S_CAPTURE_REQ )?1'b1:1'b0;

reg [3:0]	cap_state;
reg [15:0]	wadrs;
reg [15:0]	r_captime;
always @( posedge SIG_CLK or negedge RST_N ) begin
	if( !RST_N ) begin
		cap_state			<= S_CAP_IDLE;
		wadrs				<= 'd0;
		r_cap_req_d[2:0]	<= 3'd0;
		r_captime			<= 16'd0;
		r_stopadrs			<= 'd0;
	end else begin
		wadrs	<= wadrs + 'd1;
		
		r_cap_req_d[2:0]	<= { r_cap_req_d[1:0], w_cap_req };
		case( cap_state )
			S_CAP_IDLE: begin
				if( r_cap_req_d[2:1] == 2'b01 ) begin
					cap_state	<= S_CAP_PROC;
				end
				r_captime	<= 16'd0;
			end
			S_CAP_WAIT: begin
				if( w_capture_start ) begin
					cap_state	<= S_CAP_PROC;
				end
			end
			S_CAP_PROC: begin
				if( r_captime >= w_capture_stop ) begin
					cap_state	<= S_CAP_FIN;
					r_stopadrs	<= wadrs;
				end
				r_captime	<= r_captime + 'd1;
			end
			S_CAP_FIN: begin
				if( state == S_IDLE ) begin
					cap_state	<= S_CAP_IDLE;
				end
			end
			default: begin
				cap_state	<= S_CAP_IDLE;
			end
		endcase
	end
end

// キャプチャーRAM
reg [31:0]	array [0:P_BUF_SIZE - 1];

assign w_cap_we = ( ( cap_state == S_CAP_WAIT ) && ( cap_state == S_CAP_WAIT) )?1'b1:1'b0;
always @( posedge SIG_CLK ) begin
	if( w_cap_we ) begin
		array[wadrs]	<= r_sig_data_d[31:0];
	end
end

always @( posedge CLK ) begin
	r_rdata[31:0]	<= array[CAP_AD];
end

assign CAP_DT[31:0]	= r_rdata[31:0];

endmodule
