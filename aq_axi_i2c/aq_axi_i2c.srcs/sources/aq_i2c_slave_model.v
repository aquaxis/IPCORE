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

module aq_i2c_slave_model (sck, sda);

	// parameters
	parameter I2C_ADR = 7'b100_0111;

	// input && outpus
	input		sck;
	inout		sda;

	// Variable declaration
	wire		debug = 1'b1;

	reg [7:0]	mem [3:0];		// initiate memory
	reg [7:0]	mem_adr;		// memory address
	reg [7:0]	mem_do;		// memory data output

	reg			sta, d_sta;
	reg			sto, d_sto;

	reg [7:0]	sr;				// 8bit shift register
	reg			rw;				// read/write direction

	wire		my_adr;		// my address called ??
	wire		i2c_reset;		// i2c-statemachine reset
	reg [2:0]	bit_cnt;		// 3bit downcounter
	wire		acc_done;		// 8bits transfered
	reg			ld;				// load downcounter

	reg			sda_o;			// sda-drive level
	wire		sda_dly;		// delayed version of sda

	// statemachine declaration
	parameter idle			= 3'b000;
	parameter slave_ack		= 3'b001;
	parameter get_mem_adr	= 3'b010;
	parameter gma_ack			= 3'b011;
	parameter data			= 3'b100;
	parameter data_ack		= 3'b101;

	reg [2:0]	state; // synopsys enum_state

	// module body
	initial begin
		sda_o = 1'b1;
		state = idle;
	end

	// generate shift register
	always @(posedge sck) begin
		sr <= #1 {sr[6:0],sda};
	end

	//detect my_address
	assign my_adr = (sr[7:1] == I2C_ADR);

	// FIXME: This should not be a generic assign, but rather
	// qualified on address transfer phase and probably reset by stop

	//generate bit-counter
	always @(posedge sck) begin
		if(ld) begin
			bit_cnt <= #1 3'b111;
		end else begin
			bit_cnt <= #1 bit_cnt - 3'h1;
		end
	end

	//generate access done signal
	assign acc_done = !(|bit_cnt);

	// generate delayed version of sda
	// this model assumes a hold time for sda after the falling edge of sck.
	// According to the Phillips i2c spec, there s/b a 0 ns hold time for sda
	// with regards to sck. If the data changes coincident with the clock, the
	// acknowledge is missed
	// Fix by Michael Sosnoski
	assign #1 sda_dly = sda;

	//detect start condition
	always @(negedge sda) begin
		if(sck) begin
			sta		<= #1 1'b1;
			d_sta	<= #1 1'b0;
			sto		<= #1 1'b0;
			if(debug) begin
				$display("DEBUG i2c_slave; start condition detected at %t", $time);
			end
		end else begin
			sta <= #1 1'b0;
		end
	end

	always @(posedge sck) begin
		d_sta <= #1 sta;
	end

	// detect stop condition
	always @(posedge sda) begin
		if(sck) begin
			sta <= #1 1'b0;
			sto <= #1 1'b1;
			if(debug) begin
				$display("DEBUG i2c_slave; stop condition detected at %t", $time);
			end
		end else begin
			sto <= #1 1'b0;
		end
	end

	//generate i2c_reset signal
	assign i2c_reset = sta || sto;

	// generate statemachine
	always @(negedge sck or posedge sto) begin
	if (sto || (sta && !d_sta) )
		begin
			state <= #1 idle; // reset statemachine
			sda_o <= #1 1'b1;
			ld	<= #1 1'b1;
		end else begin
			// initial settings
			sda_o <= #1 1'b1;
			ld	<= #1 1'b0;

			case(state) // synopsys full_case parallel_case
				idle: // idle state
					if (acc_done && my_adr) begin
						state <= #1 slave_ack;
						rw <= #1 sr[0];
						sda_o <= #1 1'b0; // generate i2c_ack

						#2;
						if(debug && rw) begin
							$display("DEBUG i2c_slave; command byte received (read) at %t", $time);
						end
						if(debug && !rw) begin
							$display("DEBUG i2c_slave; command byte received (write) at %t", $time);
						end

						if(rw) begin
							mem_do <= #1 mem[mem_adr];
							if(debug) begin
								#2 $display("DEBUG i2c_slave; data block read %x from address %x (1)", mem_do, mem_adr);
								#2 $display("DEBUG i2c_slave; memcheck [0]=%x, [1]=%x, [2]=%x", mem[4'h0], mem[4'h1], mem[4'h2]);
							end
						end
					end
				slave_ack: begin
					if(rw) begin
						state <= #1 data;
						sda_o <= #1 mem_do[7];
					end else begin
						state <= #1 get_mem_adr;
					end
					ld	<= #1 1'b1;
				end
				get_mem_adr:	// wait for memory address
					if(acc_done) begin
						state		<= #1 gma_ack;
						mem_adr	<= #1 sr;				// store memory address
						sda_o		<= #1 !(sr <= 15);	// generate i2c_ack, for valid address
						if(debug) begin
							#1 $display("DEBUG i2c_slave; address received. adr=%x, ack=%b", sr, sda_o);
						end
					end
				gma_ack: begin
					state <= #1 data;
					ld	<= #1 1'b1;
				end
				data: begin// receive or drive data
					if(rw) begin
						sda_o <= #1 mem_do[7];
					end
					if(acc_done) begin
						state <= #1 data_ack;
						mem_adr <= #2 mem_adr + 8'h1;
						sda_o <= #1 (rw && (mem_adr <= 15) ); // send ack on write, receive ack on read

						if(rw) begin
							#3 mem_do <= mem[mem_adr];
							if(debug) begin
								#5 $display("DEBUG i2c_slave; data block read %x from address %x (2)", mem_do, mem_adr);
							end
						end
						if(!rw) begin
							mem[ mem_adr[3:0] ] <= #1 sr; // store data in memory
							if(debug) begin
								#2 $display("DEBUG i2c_slave; data block write %x to address %x", sr, mem_adr);
							end
						end
					end
				end
				data_ack:
				begin
					ld <= #1 1'b1;

					if(rw) begin
						if(sr[0]) begin // read operation && master send NACK
							state <= #1 idle;
							sda_o <= #1 1'b1;
						end else begin
							state <= #1 data;
							sda_o <= #1 mem_do[7];
						end
					end else begin
						state <= #1 data;
						sda_o <= #1 1'b1;
					end
				end
			endcase
		end
	end

	// read data from memory
	always @(posedge sck) begin
		if(!acc_done && rw) begin
			mem_do <= #1 {mem_do[6:0], 1'b1}; // insert 1'b1 for host ack generation
		end
	end

	// generate tri-states
	assign sda = sda_o ? 1'bz : 1'b0;

	// Timing checks
	wire tst_sto = sto;
	wire tst_sta = sta;

	specify specparam
		normal_sck_low	= 4700,
		normal_sck_high	= 4000,
		normal_tsu_sta	= 4700,
		normal_thd_sta	= 4000,
		normal_tsu_sto	= 4000,
		normal_tbuf		= 4700,

		fast_sck_low		= 1300,
		fast_sck_high		=600,
		fast_tsu_sta		= 1300,
		fast_thd_sta		=600,
		fast_tsu_sto		=600,
		fast_tbuf			= 1300;
/*
		$width(negedge sck, normal_sck_low);// sck low time
		$width(posedge sck, normal_sck_high); // sck high time

		$setup(posedge sck, negedge sda &&& sck, normal_tsu_sta); // setup start
		$setup(negedge sda &&& sck, negedge sck, normal_thd_sta); // hold start
		$setup(posedge sck, posedge sda &&& sck, normal_tsu_sto); // setup stop

		$setup(posedge tst_sta, posedge tst_sto, normal_tbuf); // stop to start time
*/
		$width(negedge sck, fast_sck_low);// sck low time
		$width(posedge sck, fast_sck_high); // sck high time

		$setup(posedge sck, negedge sda &&& sck, fast_tsu_sta); // setup start
		$setup(negedge sda &&& sck, negedge sck, fast_thd_sta); // hold start
		$setup(posedge sck, posedge sda &&& sck, fast_tsu_sto); // setup stop

		$setup(posedge tst_sta, posedge tst_sto, fast_tbuf); // stop to start time
	endspecify

endmodule

