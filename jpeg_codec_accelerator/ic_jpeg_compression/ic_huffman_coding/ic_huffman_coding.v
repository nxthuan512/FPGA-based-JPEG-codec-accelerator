`include "./ic_hc_input_preparation.v"
`include "./ic_hc_huffman_coding.v"
`include "./ic_hc_huffman_coding_preparation.v"
`include "./ic_hc_parallel_to_serial.v"
`include "./ic_hc_control_unit.v"
`include "./ic_hc_DCYtab.v"
`include "./ic_hc_DCCbtab.v"
`include "./ic_hc_ACYtab.v"
`include "./ic_hc_ACCbtab.v"

module ic_huffman_coding (
			clk,
			reset_n,			// ~reset_n && IC_global_enable
			// Inputs
			HC_inputready,
			HC_readdata,
			IC_NumberOfBlock,	// so luong block 8x8x3 trong anh 4:2:2
			// Outputs
			IC_EndOfImage,
			IC_ByteCount,
			HC_outputready,
			HC_writedata,
			ff0_wait_request
		);

// --------------- Input Output Declarations -----------------
input			clk,
				reset_n,
				HC_inputready;
input	[19:0]	IC_NumberOfBlock;
input	[103:0]	HC_readdata;
output			IC_EndOfImage,
				HC_outputready,
				ff0_wait_request;
output	[31:0]	HC_writedata,
				IC_ByteCount;

// --------------- Wire Declarations -----------------
wire			// ff0
				ff0_rdreq,
				ff0_empty,
				ff0_full,
				// ff1
				ff1_rdreq,
				ff1_empty,
				ff1_full,
				ff0_almost_empty,
				ff0_almost_full,
				// EOB
				EOB_outputready,
				// PTS
				PTS_enable,
				PTS_outputready,				
				// Pre
				DC_enable,
				AC_enable,
				EOB_enable,
				PRE_outputready;

wire			Diff_eq_0,
				pre_IC_EndOfImage,
				ack_pre_IC_EndOfImage;
wire	[1:0] 	MUX_select;
wire 	[2:0] 	DIFF_enable;
wire	[5:0]	EOB_q,
				ff1_q;
wire	[12:0]	PTS_q,
				PRE_value,
				PRE_RSL;
wire	[103:0]	ff0_q;

// ==================================================================
// ICMD_IC_HUFF_CODING_SIM
// ==================================================================
/*
ICMD_IC_Huffman_coding_sim ICMD_IC_HUFF_CODING_SIM (
                                .clk        (clk),
                                .outputready(HC_outputready),
                                .writedata  (HC_writedata)
                            );
*/                         
// ==================================================================
// Call functions
// ==================================================================

ic_hc_control_unit HC_CONTROL_UNIT (
				.clk				(clk),
				.reset_n			(reset_n),
				// Inputs
				.IC_NumberOfBlock	(IC_NumberOfBlock),
				.ff0_empty			(ff0_empty),
				.ff0_full			(ff0_full),
				.ff0_rdreq			(ff0_rdreq),
				.ff1_empty			(ff1_empty),
				.ff1_full			(ff1_full),
				.ff1_rdreq			(ff1_rdreq),
				.ff0_almost_empty	(ff0_almost_empty),
				.ff0_almost_full	(ff0_almost_full),
				.PTS_outputready	(PTS_outputready),
				.ack_pre_IC_EndOfImage (ack_pre_IC_EndOfImage),
				.ff1_q				(ff1_q),
				// Outputs
				.IC_EndOfImage		(IC_EndOfImage),
				.pre_IC_EndOfImage	(pre_IC_EndOfImage),
				.PTS_enable			(PTS_enable),
				.DC_enable			(DC_enable),
				.AC_enable			(AC_enable),
				.EOB_enable			(EOB_enable),
				.DIFF_enable  		(DIFF_enable),
				.MUX_select   		(MUX_select),
				.ff0_wait_request	(ff0_wait_request)
			);

ic_hc_input_preparation HC_INPUT_PREPARATION (
				.clk				(clk),	
				.reset_n			(reset_n),
				// Inputs
				.HC_inputready		(HC_inputready),
				.HC_readdata		(HC_readdata),
				.ff0_rdreq			(ff0_rdreq),
				.ff1_rdreq			(ff1_rdreq),
				// Outputs
				.ff0_empty			(ff0_empty),
				.ff0_full			(ff0_full),
				.ff0_q				(ff0_q),
				.ff1_empty			(ff1_empty),
				.ff1_full			(ff1_full),
				.ff0_almost_empty	(ff0_almost_empty),
				.ff0_almost_full	(ff0_almost_full),
				.ff1_q				(ff1_q)
			);
			
ic_hc_parallel_to_serial HC_P2S (
				.clk				(clk),
				.reset_n			(reset_n),
				// Inputs
				.enable				(PTS_enable),
				.DIFF_enable  		(DIFF_enable),
				.readdata			(ff0_q),
				// Outputs
				.outputready		(PTS_outputready),
				.writedata			(PTS_q)					
				);
				
ic_hc_huffman_coding_preparation HC_HUFFMAN_CODING_PREPARATION (
				.clk				(clk),
				.reset_n			(reset_n),
				// Inputs
				.DC_enable			(DC_enable),
				.AC_enable			(AC_enable),
				.EOB_enable			(EOB_enable),
				.readdata			(PTS_q),
				// Outputs
				.outputready		(PRE_outputready),
				.writedata_value	(PRE_value),
				.writedata_RSL		(PRE_RSL)
			);

ic_hc_huffman_coding HC_HUFFMAN_CODING (
				.clk				(clk),
				.reset_n			(reset_n),
				// Inputs
				.inputready			(PRE_outputready),
				.pre_IC_EndOfImage	(pre_IC_EndOfImage),
				.MUX_select 		(MUX_select),
				.readdata_value		(PRE_value),
				.readdata_RSL		(PRE_RSL),
				// Outputs
				.outputready		(HC_outputready),
				.ack_pre_IC_EndOfImage(ack_pre_IC_EndOfImage) ,
				.writedata			(HC_writedata),
				.IC_ByteCount		(IC_ByteCount)
			);			
endmodule 

// =====================================================================
// SIMULATION ONLY
// =====================================================================

module ICMD_IC_Huffman_coding_sim (
                                clk,
                                outputready,
                                writedata
                            );

input           clk,
                outputready;
input [31:0]    writedata;
 
integer f1, f2;
integer count, temp, e;
integer v, t;

initial
begin
	$display ("\n Print result to dat file\n");
	f1 = $fopen("modelsim_output_Huffman.dat", "w");
	f2 = $fopen("expected_output_huffman.dat", "r");
	count = 0;
	e = 1;
	t = 0;
	v = 0;
end

always @ (posedge clk)
begin
  if (outputready)
  begin   
    count = count + 1;
   
    $fwrite(f1,"%x\n", writedata);
    t = writedata;
    temp = $fscanf(f2,"%x", v);    
    if 	 (((v - t) > e) || ((t - v) < -e))
    begin
		$display("Have Errors...");
		$display($time, "  %x\n", writedata);
		$display($time, "  %x\n", v);
		$stop;
    end    
  end
end

endmodule
/*
module test_bench();

reg				clk,
				reset_n,
				inputready;
reg		[19:0]	IC_NumberOfBlock;
reg		[103:0]	readdata;
wire			IC_EndOfImage,
				outputready;
wire	[31:0]	writedata,
				IC_ByteCount;

integer f1;
integer X, Y;
integer tmp, i, j;	
integer t0, t1, t2, t3, t4, t5, t6, t7;
			
icmd_ic_huffman_coding ICMD_IC_HUFFMANC_CODING(
				.clk				(clk),
				.reset_n			(reset_n),			// ~reset_n && IC_global_enable
				// Inputs
				.HC_inputready		(inputready),
				.HC_readdata		(readdata),
				.IC_NumberOfBlock	(IC_NumberOfBlock),	// so luong block 8x8x3 trong anh 4:2:2
				// Outputs
				.IC_EndOfImage		(IC_EndOfImage),
				.IC_ByteCount		(IC_ByteCount),
				.HC_outputready		(outputready),
				.HC_writedata		(writedata)
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
	f1 = $fopen("golden_input_huffman.dat", "r"); 
	inputready = 0;	
	
	X = 640;
	Y = 480;
	IC_NumberOfBlock = (X * Y)/ 32;
	wait(reset_n);
	#300;
	
	for (i = 0; i < IC_NumberOfBlock; i = i + 1)
	begin
		for (j = 0; j < 8; j = j + 1)
		begin
			tmp = $fscanf(f1, "%d %d %d %d %d %d %d %d ", t0, t1, t2, t3, t4, t5, t6, t7);
			readdata[12:0] = t0;
			readdata[25:13] = t1;
			readdata[38:26] = t2;
			readdata[51:39] = t3;
			readdata[64:52] = t4;
			readdata[77:65] = t5;
			readdata[90:78] = t6;
			readdata[103:91] = t7;
			
			@ (posedge clk)
			inputready = 1;
			@ (posedge clk)
			inputready = 0;
		end
		
		repeat(17)
			@ (posedge clk);
	end
	$fclose(f1);
end

always @ (posedge clk)
	if (IC_EndOfImage)
		#100 reset_n = 0;
endmodule 
*/