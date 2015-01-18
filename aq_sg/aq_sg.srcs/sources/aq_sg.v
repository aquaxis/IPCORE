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
module aq_sg(
  input RST_N,
  input CLK,

  output VSYNC,
  output HSYNC,
  output FSYNC,
  output ACTIVE,

  output [31:0] DEBUG
);

/* 1368x768@60Hz(85.478MHz) */
/*
localparam HSYNC_MAX    = 1792;
localparam HSYNC_ACTIVE = 1368;
localparam HSYNC_START  = 1424;
localparam HSYNC_END    = 1536;
localparam VSYNC_MAX    = 795;
localparam VSYNC_ACTIVE = 768;
localparam VSYNC_START  = 771;
localparam VSYNC_END    = 777;
localparam SYNC_REV     = 1;
*/

/* 1280x1024@60Hz(108MHz) */
/*
localparam HSYNC_MAX    = 1688;
localparam HSYNC_ACTIVE = 1280;
localparam HSYNC_START  = 1328;
localparam HSYNC_END    = 1440;
localparam VSYNC_MAX    = 1066;
localparam VSYNC_ACTIVE = 1024;
localparam VSYNC_START  = 1025;
localparam VSYNC_END    = 1028;
localparam SYNC_REV     = 1;
*/
/* 1024x768@60Hz(65/75MHz) */

localparam HSYNC_MAX    = 1344;   // 65MHz(60Hz)
//localparam HSYNC_MAX    = 1328;   // 75MHz(70Hz)
localparam HSYNC_ACTIVE = 1024;
localparam HSYNC_START  = 1048;
localparam HSYNC_END    = 1184;
localparam VSYNC_MAX    = 806;
localparam VSYNC_ACTIVE = 768;
localparam VSYNC_START  = 771;
localparam VSYNC_END    = 777;
localparam SYNC_REV     = 0;

/* 640x480@60Hz(25.175MHz) */
/*
localparam HSYNC_MAX    = 800;
localparam HSYNC_ACTIVE = 640;
localparam HSYNC_START  = 656;
localparam HSYNC_END    = 752;
localparam VSYNC_MAX    = 525;
localparam VSYNC_ACTIVE = 480;
localparam VSYNC_START  = 490;
localparam VSYNC_END    = 492;
localparam SYNC_REV     = 0;
*/

/* 800x600@60Hz(40MHz) */
/*
localparam HSYNC_MAX    = 1056;
localparam HSYNC_ACTIVE = 800;
localparam HSYNC_START  = 840;
localparam HSYNC_END    = 968;
localparam VSYNC_MAX    = 628;
localparam VSYNC_ACTIVE = 600;
localparam VSYNC_START  = 601;
localparam VSYNC_END    = 605;
localparam SYNC_REV     = 1;
*/

/* 800x600@72Hz(50MHz) */
/*
localparam HSYNC_MAX    = 1040;
localparam HSYNC_ACTIVE = 800;
localparam HSYNC_START  = 856;
localparam HSYNC_END    = 976;
localparam VSYNC_MAX    = 666;
localparam VSYNC_ACTIVE = 600;
localparam VSYNC_START  = 637;
localparam VSYNC_END    = 643;
localparam SYNC_REV     = 1;
*/

reg [10:0] reg_h, reg_v;
reg [10:0] reg_hsync_max, reg_hsync_active, reg_hsync_start, reg_hsync_end;
reg [10:0] reg_vsync_max, reg_vsync_active, reg_vsync_start, reg_vsync_end;
reg reg_hsync, reg_vsync,reg_fsync;
reg reg_active;

always @(posedge CLK or negedge RST_N) begin
  if(!RST_N) begin
    reg_h <= 0;
    reg_v <= 0;
    reg_hsync_max <= 0;
    reg_vsync_max <= 0;
    reg_hsync_active <= 0;
    reg_hsync_start  <= 0;
    reg_hsync_end    <= 0; 
    reg_vsync_active <= 0;
    reg_vsync_start  <= 0;
    reg_vsync_end    <= 0; 
    reg_hsync <= 0;
    reg_vsync <= 0;
    reg_fsync <= 0;
    reg_active <= 0;
  end else begin
    reg_hsync_max <= HSYNC_MAX -1;
    reg_vsync_max <= VSYNC_MAX -1;

    reg_hsync_active <= HSYNC_ACTIVE;
    reg_hsync_start  <= HSYNC_START;
    reg_hsync_end    <= HSYNC_END; 
    reg_vsync_active <= VSYNC_ACTIVE;
    reg_vsync_start  <= VSYNC_START;
    reg_vsync_end    <= VSYNC_END; 

    if(reg_h == reg_hsync_max ) begin
      reg_h <= 0;
      if(reg_v == reg_vsync_max ) begin
        reg_v <= 0;
      end else begin
        reg_v <= reg_v + 1;
      end
    end else begin
      reg_h <= reg_h + 1;
    end

    if((reg_h >= reg_hsync_start) && (reg_h < reg_hsync_end) ) begin
      reg_hsync <= 0;
    end else begin
      reg_hsync <= 1;
    end

    if( ((reg_v == (reg_vsync_start -1)) && (reg_h >= reg_hsync_active)) || 
        ((reg_v >= reg_vsync_start) && (reg_v < (reg_vsync_end -1))) ||
        ((reg_v == (reg_vsync_end -1)) && (reg_h < reg_hsync_active))
        ) begin
      reg_vsync <= 0;
    end else begin
      reg_vsync <= 1;
    end

    if((reg_h < reg_hsync_active) && (reg_v < reg_vsync_active) ) begin
      reg_active <= 1;
    end else begin
      reg_active <= 0;
    end
    
    if((reg_h == reg_hsync_active) && (reg_v == reg_vsync_active)) begin
      reg_fsync <= 1;
    end else begin
      reg_fsync <= 0;
    end
  end
end

assign HSYNC = (SYNC_REV)?~reg_hsync:reg_hsync;
assign VSYNC = (SYNC_REV)?~reg_vsync:reg_vsync;
assign FSYNC = reg_fsync;
assign ACTIVE = reg_active;

endmodule
