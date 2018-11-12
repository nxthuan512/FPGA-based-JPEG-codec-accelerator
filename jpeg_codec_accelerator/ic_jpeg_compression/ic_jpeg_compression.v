`include "./ic_get_block_8x8/ic_get_block_8x8.v"
`include "./ic_rgb_to_ycbcr/ic_rgb_to_ycbcr.v"
`include "./ic_bindct_processor/ic_bindct_processor.v"
`include "./ic_quant_zig/ic_quant_zig.v"
`include "./ic_huffman_coding/ic_huffman_coding.v"

module ic_jpeg_compression (
							clk,
							reset_n,			// ~reset_n && IC_global_enable
							// Inputs
							IC_inputready,
							IC_readdata,
							IC_NumberOfBlock,
							IC_X_image,
							
							// Outputs
							IC_EndOfImage,
							IC_outputready,							
							IC_writedata,
							IC_ByteCount,
							HC_ff0_wait_request,
							R2Y_waitrequest
						);

// ------------------- InOut Declarations ------------------
input			clk,
				reset_n,
				IC_inputready;
input	[15:0]	IC_X_image;
input	[19:0]	IC_NumberOfBlock;
input	[31:0]	IC_readdata;

output			IC_EndOfImage,
				IC_outputready,
				HC_ff0_wait_request,
				R2Y_waitrequest;
output	[31:0]	IC_writedata,
				IC_ByteCount;

// ------------------- Wire Declarations -----------------
wire			GB8_R2Y_dataready,
				R2Y_BD_dataready,
				BD_QZ_dataready,
				QZ_HC_dataready;
wire	[31:0]	GB8_R2Y_data;
wire	[63:0]	R2Y_BD_data;
wire	[127:0]	BD_QZ_data;
wire	[103:0]	QZ_HC_data;

ic_get_block_8x8 GET_BLOCK8x8 (
						// Inputs
						.clk				(clk),
						.reset_n			(reset_n),
						.GB8_inputready		(IC_inputready),
						.GB8_readdata		(IC_readdata),
						.IC_X_image			(IC_X_image),		// X_image: chua bao gom R, G, B
						// Outputs
						.GB8_outputready	(GB8_R2Y_dataready),
						.GB8_writedata		(GB8_R2Y_data)
				);
	
ic_rgb_to_ycbcr RGB_TO_YCBCR (
						// Inputs
						.clk				(clk),
						.reset_n			(reset_n),
						.R2Y_inputready		(GB8_R2Y_dataready),
						.R2Y_readdata		(GB8_R2Y_data),
						
						// Outputs
						.R2Y_outputready	(R2Y_BD_dataready),		
						.R2Y_writedata		(R2Y_BD_data),
						.R2Y_waitrequest 	(R2Y_waitrequest)
					);

ic_bindct_processor BD_PROC (
						// Inputs
						.clk				(clk),
						.reset_n			(reset_n),
						.BD_inputready		(R2Y_BD_dataready),
						.BD_readdata		(R2Y_BD_data),
						
						// Outputs
						.BD_outputready		(BD_QZ_dataready),							
						.BD_writedata		(BD_QZ_data)
					);
											
ic_quant_zig QUANT_ZIG (
                      .clk					(clk),
                      .reset_n				(reset_n),
                      // Inputs
                      .QZ_inputready		(BD_QZ_dataready),
                      .QZ_readdata			(BD_QZ_data),
                      // Outputs
                      .QZ_outputready		(QZ_HC_dataready),
                      .QZ_writedata			(QZ_HC_data)
				);
	
ic_huffman_coding HUFF_CODING (
					.clk					(clk),
					.reset_n				(reset_n),
					// Inputs
					.HC_inputready			(QZ_HC_dataready),
					.HC_readdata			(QZ_HC_data),
					.IC_NumberOfBlock		(IC_NumberOfBlock),	// so luong block 8x8x3 trong anh 4:2:2
					// Outputs
					.IC_EndOfImage			(IC_EndOfImage),
					.IC_ByteCount			(IC_ByteCount),
					.HC_outputready			(IC_outputready),
					.HC_writedata			(IC_writedata),
					.ff0_wait_request		(HC_ff0_wait_request)
		);

endmodule 

// ===============================================================
/*
`timescale 1ns / 1ps
`include "f:/altera/91/quartus/eda/sim_lib/altera_mf.v"
`include "f:/altera/91/quartus/eda/sim_lib/220model.v"
`include "f:/altera/91/quartus/eda/sim_lib/sgate.v"
`include "f:/altera/91/quartus/eda/sim_lib/altera_primitives.v"
`include "f:/altera/91/quartus/eda/sim_lib/stratixiii_atoms.v"

module sim_icmd_ic_controller();

reg				clk,
				reset_n,
				IC_inputready,
				IC_global_enable;
reg		[31:0]	IC_readdata;
reg		[19:0]	IC_NumberOfBlock;
reg   [15:0]  IC_X_image;

wire			IC_EndOfImage,
				IC_outputready;
wire	[31:0]	IC_writedata,
				IC_ByteCount;

integer X_image, Y_image;
integer image_size;
integer f1, f2, f3;
integer i, tmp, t0, t1, v;
integer t10, t11, t12, t13, t14;
				
icmd_ic_controller ICMD_IC_CONTROLLER (
							.clk				(clk),
							.reset_n			(reset_n && IC_global_enable),			// ~reset_n && IC_global_enable
							// Inputs
							.IC_inputready		(IC_inputready),
							.IC_readdata		(IC_readdata),
							.IC_NumberOfBlock	(IC_NumberOfBlock),
							.IC_X_image			(IC_X_image),
							
							// Outputs
							.IC_EndOfImage		(IC_EndOfImage),
							.IC_outputready		(IC_outputready),							
							.IC_writedata		(IC_writedata),
							.IC_ByteCount		(IC_ByteCount)
						);
						
initial
    clk = 1'b0;
always
    #10 clk <= ~clk;
  
initial 
	begin
		reset_n <= 0;
		#200 reset_n <= 1;
	end

initial
	begin
		IC_inputready = 0;
		IC_readdata = 0;
		IC_NumberOfBlock = 0;
		IC_X_image = 0;
		IC_global_enable = 0;
		
		f1 = $fopen("modelsim_MW_output_Huffman.dat", "w");
		f2 = $fopen("expected_output_huffman.dat", "r");
		f3 = $fopen("altmemddr_0_test_fpga.dat", "r");
	   
	  IC_NumberOfBlock = 32'hffff;
		wait (reset_n);
		#300;
		IC_global_enable = 1;
		
		X_image = 32;
	  Y_image = 24;
	
		IC_NumberOfBlock = (X_image * Y_image * 3) / 64;
		IC_X_image = X_image;	
		image_size = (X_image * Y_image * 3) / 4;
		#300;
		
		for (i = 0; i < image_size; i = i + 1)
		begin
			tmp = $fscanf(f3, "%x", v);
			IC_readdata = v;
			@(posedge clk);
			IC_inputready = 1;
			@(posedge clk);
			IC_inputready = 0;
			
			repeat (14)
				@(posedge clk);
		end
	end

always @ (posedge clk)
begin
	if (IC_outputready)
	begin
		t0 = IC_writedata;
		$fwrite(f1, "%x\n", t0);
		
		tmp = $fscanf(f2, "%x", t1);
		t10 = (t1 & 32'hff000000) >> 24;
		t11 = (t1 & 32'h00ff0000) >> 16;
		t12 = (t1 & 32'h0000ff00) >> 8;
		t13 = (t1 & 32'hff0000ff);
		t14 = (t13 << 24) + (t12 << 16) + (t11 << 8) + t10;
		
		if (t0 != t14)
		begin
			$display($time, "  %x   %x\n", t0, t1);
			$stop;
		end
		
	end
end

initial 
begin
	wait (IC_EndOfImage);
	#100;
	$fclose(f1);
	$fclose(f2);
end
endmodule
*/