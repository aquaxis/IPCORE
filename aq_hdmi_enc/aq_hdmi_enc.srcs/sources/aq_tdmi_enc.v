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
`timescale 1 ps / 1ps

module aq_tdmi_enc(
  input            clkin,
  input            rstin,
  input      [7:0] din,
  input            c0,
  input            c1,
  input            de,
  output reg [9:0] dout
);

  reg [3:0] n1d;
  reg [7:0] din_q;

  always @ (posedge clkin) begin
    n1d <= din[0] + din[1] + din[2] + din[3] + din[4] + din[5] + din[6] + din[7];

    din_q <= din;
  end

  wire decision1;

  assign decision1 = (n1d > 4'h4) | ((n1d == 4'h4) & (din_q[0] == 1'b0));
  wire [8:0] q_m;
  assign q_m[0] = din_q[0];
  assign q_m[1] = (decision1) ? (q_m[0] ^~ din_q[1]) : (q_m[0] ^ din_q[1]);
  assign q_m[2] = (decision1) ? (q_m[1] ^~ din_q[2]) : (q_m[1] ^ din_q[2]);
  assign q_m[3] = (decision1) ? (q_m[2] ^~ din_q[3]) : (q_m[2] ^ din_q[3]);
  assign q_m[4] = (decision1) ? (q_m[3] ^~ din_q[4]) : (q_m[3] ^ din_q[4]);
  assign q_m[5] = (decision1) ? (q_m[4] ^~ din_q[5]) : (q_m[4] ^ din_q[5]);
  assign q_m[6] = (decision1) ? (q_m[5] ^~ din_q[6]) : (q_m[5] ^ din_q[6]);
  assign q_m[7] = (decision1) ? (q_m[6] ^~ din_q[7]) : (q_m[6] ^ din_q[7]);
  assign q_m[8] = (decision1) ? 1'b0 : 1'b1;

  reg [3:0] n1q_m, n0q_m;
  always @ (posedge clkin) begin
    n1q_m  <= q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
    n0q_m  <= 4'h8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);
  end

  parameter CTRLTOKEN0 = 10'b1101010100;
  parameter CTRLTOKEN1 = 10'b0010101011;
  parameter CTRLTOKEN2 = 10'b0101010100;
  parameter CTRLTOKEN3 = 10'b1010101011;

  reg [4:0] cnt;
  wire decision2, decision3;

  assign decision2 = (cnt == 5'h0) | (n1q_m == n0q_m);
  assign decision3 = (~cnt[4] & (n1q_m > n0q_m)) | (cnt[4] & (n0q_m > n1q_m));

  reg       de_q, de_reg;
  reg       c0_q, c1_q;
  reg       c0_reg, c1_reg;
  reg [8:0] q_m_reg;

  always @ (posedge clkin) begin
    de_q    <=de;
    de_reg  <=de_q;
    
    c0_q    <=c0;
    c0_reg  <=c0_q;
    c1_q    <=c1;
    c1_reg  <=c1_q;

    q_m_reg <=q_m;
  end

  always @ (posedge clkin or posedge rstin) begin
    if(rstin) begin
      dout <= 10'h0;
      cnt <= 5'h0;
    end else begin
      if (de_reg) begin
        if(decision2) begin
          dout[9]   <=~q_m_reg[8]; 
          dout[8]   <=q_m_reg[8]; 
          dout[7:0] <=(q_m_reg[8]) ? q_m_reg[7:0] : ~q_m_reg[7:0];

          cnt <=(~q_m_reg[8]) ? (cnt + n0q_m - n1q_m) : (cnt + n1q_m - n0q_m);
        end else begin
          if(decision3) begin
            dout[9]   <=1'b1;
            dout[8]   <=q_m_reg[8];
            dout[7:0] <=~q_m_reg[7:0];

            cnt <=cnt + {q_m_reg[8], 1'b0} + (n0q_m - n1q_m);
          end else begin
            dout[9]   <=1'b0;
            dout[8]   <=q_m_reg[8];
            dout[7:0] <=q_m_reg[7:0];

            cnt <=cnt - {~q_m_reg[8], 1'b0} + (n1q_m - n0q_m);
          end
        end
      end else begin
        case ({c1_reg, c0_reg})
          2'b00:   dout <=CTRLTOKEN0;
          2'b01:   dout <=CTRLTOKEN1;
          2'b10:   dout <=CTRLTOKEN2;
          default: dout <=CTRLTOKEN3;
        endcase

        cnt <=5'h0;
      end
    end
  end
  
endmodule
