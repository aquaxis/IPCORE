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
`timescale 1ps / 1ps

module tb_aq_djpeg;
	reg rst;
	reg clk;

	reg [31:0] JPEG_MEM [0:1*1024*1024-1];

	integer	DATA_COUNT;

	parameter clkP = 10000; // 100MHz
	parameter clkH = clkP /2;
	parameter clkL = clkP - clkH;

	wire [31:0] JPEG_DATA;
	reg		 DATA_ENABLE;
	wire		READ_ENABLE;
	wire		JPEG_IDLE;

	wire		OutEnable;
	wire [15:0] OutWidth;
	wire [15:0] OutHeight;
	wire [15:0] OutPixelX;
	wire [15:0] OutPixelY;
	wire [7:0]	OutR;
	wire [7:0]	OutG;
	wire [7:0]	OutB;

	integer	 count;
	reg [23:0]	rgb_mem [0:1920*1080-1];

	initial begin
		count = 0;
		while(1) begin
		 @(posedge clk);
		 count = count +1;
		end
	end

	aq_djpeg u_aq_djpeg
	 (
		.rst(rst),
		.clk(clk),

		.DataIn			(JPEG_DATA),
		.DataInEnable		(DATA_ENABLE),
		.DataInRead		(READ_ENABLE),
		.JpegDecodeIdle	(JPEG_IDLE),

		.OutEnable		( OutEnable ),
		.OutWidth		( OutWidth	),
		.OutHeight		( OutHeight ),
		.OutPixelX		( OutPixelX ),
		.OutPixelY		( OutPixelY ),
		.OutR			( OutR		),
		.OutG			( OutG		),
		.OutB			( OutB		)
		);


	// Clock
	always begin
		#clkH clk = 0;
		#clkL clk = 1;
	end

	initial begin
		rst = 1'b0;
		repeat (300) @(posedge clk);
		rst = 1'b1;
	end

	// Read JPEG File
	initial begin
		$readmemh("/mnt/disk1/Public/FPGA_Magazine_No.6/DJPEG_IP/test.mem",JPEG_MEM);
	end

	// Initial
	initial begin
		DATA_COUNT	<= 0;
		DATA_ENABLE <= 1'b0;
		wait (rst == 1'b1);
		@(posedge clk);
		$display(" Start Clock: %d",count);
		@(posedge clk);
		@(posedge clk);
		DATA_ENABLE <= 1'b1;
		forever begin
		 if(READ_ENABLE == 1'b1) begin
			DATA_COUNT	<= DATA_COUNT +1;
		 end
		 @(posedge clk);
		end
	end // initial begin

	assign JPEG_DATA = JPEG_MEM[DATA_COUNT];

	integer i;

	initial begin
		@(posedge u_aq_djpeg.ImageEnable);

		$display("------------------------------");
		$display("Image Run");
		$display("------------------------------");
		$display(" X: %4d",i,u_aq_djpeg.OutWidth);
		$display(" Y: %4d",i,u_aq_djpeg.OutHeight);
		$display(" Component: %4d",i,u_aq_djpeg.JpegComp);
		$display(" BlockWidth: %4d",i,u_aq_djpeg.JpegBlockWidth);
		$display("------------------------------");
		$display(" DQT Y Table");
		for(i=0;i<64;i=i+1) begin
		 $display(" %2d: %2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_dqt.DQT_Y[i]);
		end

		$display("------------------------------");
		$display(" DQT Cb/Cr Table");
		for(i=0;i<64;i=i+1) begin
		 $display(" %2d: %2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_dqt.DQT_C[i]);
		end
		$display("------------------------------");

		$display("------------------------------");
		$display(" huffman Y-DC Code/Number");
		for(i=0;i<16;i=i+1) begin
		 $display(" %2d: %2x,%2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanTable0r[i],u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanNumber0r[i]);
		end
		$display("------------------------------");

		$display("------------------------------");
		$display(" huffman Y-DC Table");
		for(i=0;i<16;i=i+1) begin
		 $display(" %2d: %2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_dht.DHT_Ydc[i]);
		end
		$display("------------------------------");

		$display("------------------------------");
		$display(" huffman Y-AC Code/Number");
		for(i=0;i<16;i=i+1) begin
		 $display(" %2d: %2x,%2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanTable1r[i],u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanNumber1r[i]);
		end
		$display("------------------------------");

		$display("------------------------------");
		$display(" huffman Y-AC Table");
		for(i=0;i<162;i=i+1) begin
		 $display(" %2d: %2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_dht.DHT_Yac[i]);
		end
		$display("------------------------------");

		$display("------------------------------");
		$display(" huffman C-DC Table");
		for(i=0;i<16;i=i+1) begin
		 $display(" %2d: %2x,%2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanTable2r[i],u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanNumber2r[i]);
		end
		$display("------------------------------");

		$display("------------------------------");
		$display(" huffman C-DC Table");
		for(i=0;i<16;i=i+1) begin
		 $display(" %2d: %2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_dht.DHT_Cdc[i]);
		end
		$display("------------------------------");

		$display("------------------------------");
		$display(" huffman C-AC Table");
		for(i=0;i<16;i=i+1) begin
		 $display(" %2d: %2x,%2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanTable3r[i],u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanNumber3r[i]);
		end
		$display("------------------------------");

		$display("------------------------------");
		$display(" huffman C-AC Table");
		for(i=0;i<162;i=i+1) begin
		 $display(" %2d: %2x",i,u_aq_djpeg.u_jpeg_huffman.u_jpeg_dht.DHT_Cac[i]);
		end
		$display("------------------------------");
	end
/*
	integer Phase8Count;
	initial begin
		Phase8Count <= 0;
		while(1) begin
		 @(posedge clk);
		 if((u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.Process == 4'h8) && !(u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.ProcessCount < 63)) begin
			Phase8Count <= Phase8Count + 1;
			$display(" Process Phase8: %d", Phase8Count);
		end
		end
	end
*/
	integer DataOutEnable;
	initial begin
		DataOutEnable <= 0;
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.DataOutEnable == 1'b1) begin
			DataOutEnable <= DataOutEnable + 1;
			$display(" DataOutEnable: %d", DataOutEnable);
		end
		end
	end

	integer ConvertEnable;
	initial begin
		ConvertEnable <= 0;
		while(1) begin
		 @(posedge clk);
		 if((u_aq_djpeg.u_jpeg_ycbcr.ConvertRead == 1'b1 == 1'b1) && (u_aq_djpeg.u_jpeg_ycbcr.ConvertAddress == 8'd255)) begin
			ConvertEnable <= ConvertEnable + 1;
			$display(" ConvertEnable: %d", ConvertEnable);
		end
		end
	end


/*
	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.Process == 4'h2)
			$display(" Color: %d,%d",u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.ProcessColor,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.ProcessCount);
		end
	end

	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.Process == 4'h4)
			for(i=0;i<16;i=i+1) begin
				$display(" Data Code: %8x,%8x",u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanTable[i],u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.HuffmanNumber[i]);
			end
		end
	end
*/

/*
	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.Process == 4'h6)
			$display(" Wait for RAM");
		end
	end
*/
/*
	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.Process == 4'h4)
			$display(" Data Code: %8x",u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.ProcessData);
		end
	end
*/
/*
	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.Process == 4'hB)
			$display(" Data Code: %d,%d,%4x,%4x,%4x,%4x,%2x,%4x,%4x,%4x,%8x",
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.CodeNumber,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.ProcessCount,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.DhtNumber,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.DhtZero,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.DataNumber,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.TableCode,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.NumberCode,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.DqtData,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.OutCode,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.OutData,
					u_aq_djpeg.u_jpeg_huffman.u_jpeg_hm_decode.ProcessData);
		end
	end



	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_huffman.HmDecEnable == 1'b1)
				$display(" HmDec Code: %d,%4x",
						u_aq_djpeg.u_jpeg_huffman.HmDecCount,
						u_aq_djpeg.u_jpeg_huffman.HmDecData);
		end
	end
*/

/*
	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_huffman.HmOutEnable == 1'b1)
			for(i=0;i<64;i=i+1) begin
				$display(" Data Code: %d,%4x",i,
						u_aq_djpeg.u_jpeg_huffman.u_jpeg_ziguzagu.RegData[i]);
			end
		end
	end
*/

/*
	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_idct.u_jpeg_idctx.Phase4Enable.O == 1'b1)
		 //if(u_aq_djpeg.u_jpeg_idct.u_jpeg_idctx.Phase4Enable == 1'b1)
			$display(" Dct Data[X]: %d:%d,%016x,%016x",u_aq_djpeg.u_jpeg_idct.u_jpeg_idctx.Phase4Page,u_aq_djpeg.u_jpeg_idct.u_jpeg_idctx.Phase4Count,u_aq_djpeg.u_jpeg_idct.u_jpeg_idctx.Phase4R0r,u_aq_djpeg.u_jpeg_idct.u_jpeg_idctx.Phase4R1r);
		end
	end
*/
/*
	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_idct.DctXEnable == 1'b1)
			$display(" Dct Data[X]: %d:%d,%4x,%4x",u_aq_djpeg.u_jpeg_idct.DctXPage,u_aq_djpeg.u_jpeg_idct.DctXCount,u_aq_djpeg.u_jpeg_idct.DctXData0r,u_aq_djpeg.u_jpeg_idct.DctXData1r);
		end
	end
*/

/*
	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Enable == 1'b1)
			$display(" Dct Data[Y2]: %d,%8x,%8x,%8x,%8x,%8x,%8x,%8x,%8x",u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Count,u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[0],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[1],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[2],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[3],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[4],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[5],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[6],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[7]);
		end
	end

	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase5Enable == 1'b1)
			$display(" Dct Data[Y5]: %d,%8x,%8x,%8x,%8x,%8x,%8x,%8x,%8x,%8x,%8x",u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase5Count,u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase5R0w,u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase5R1w,u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[0],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[1],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[2],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[3],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[4],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[5],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[6],u_aq_djpeg.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[7]);
		end
	end



	initial begin
		while(1) begin
		 @(posedge clk);
		 if(u_aq_djpeg.DctEnable == 1'b1)
			$display(" Dct Data[Y]: %d,%4x,%4x",u_aq_djpeg.DctCount,u_aq_djpeg.Dct0Data,u_aq_djpeg.Dct1Data);
		end
	end
*/

	integer address;
	integer fp;

	// ??????????????????????????????
	initial begin
		while(1) begin
		 if(u_aq_djpeg.OutEnable == 1'b1) begin
			address = u_aq_djpeg.OutWidth * u_aq_djpeg.OutPixelY + u_aq_djpeg.OutPixelX;
			$display(" RGB[%4d,%4d][%4d,%4d]: %2x,%2x,%2x",OutPixelX,OutPixelY,OutWidth,OutHeight,OutR,OutG,OutB);
			rgb_mem[address] = {OutR,OutG,OutB};
		 end
		 @(posedge clk);
		end
	end


	initial begin
		wait(!JPEG_IDLE);
		wait(JPEG_IDLE);

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		$display(" End Clock %d",count);
		fp = $fopen("sim.dat");
		$fwrite(fp,"%0d\n",OutWidth);
		$fwrite(fp,"%0d\n",OutHeight);

		for(i=0;i<OutWidth*OutHeight;i=i+1) begin
		 $fwrite(fp,"%06x\n",rgb_mem[i]);
		end
		$fclose(fp);

//		$coverage_save("sim.cov");
		$finish();
		//$stop();
	end

endmodule
