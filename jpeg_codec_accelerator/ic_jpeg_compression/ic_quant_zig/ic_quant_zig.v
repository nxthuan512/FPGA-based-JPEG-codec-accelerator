`include "./ic_qz_fifo.v"
`include "./ic_qz_mult.v"
`include "./ic_qz_control_unit.v"

// *******************************************************************
// Do BinDCT processor cho output dang cot nen trong module nay
// ta lay BinDCT x Quant theo cot roi lay 
// zigzag theo cot, thu tu nhu sau
//    0   2   3   9   10  20  21  35
//    1   4   8   11  19  22  34  36
//    5   7   12  18  23  33  37  48
//    6   13  17  24  32  38  47  49
//    14  16  25  31  39  46  50  57
//    15  26  41  44  52  55  59  62
//    27  29  41  44  52  55  59  62
//    28  42  43  53  54  60  61  63
// Input: BinDCT 128bit (16bits x 8words)
// Output: 104bit (13bits x 8words) 
// Qua trinh dua ra Y0 -> Y1 -> Cr1 -> Cb1 -> ...
// *******************************************************************
module ic_quant_zig (
                      clk,
                      reset_n,
                      // Inputs
                      QZ_inputready,
                      QZ_readdata,
                      // Outputs
                      QZ_outputready,
                      QZ_writedata
				);

// ------------- Input Output Declarations -------------
input   		clk,
				reset_n,
				QZ_inputready;
input	[127:0]	QZ_readdata;
output			QZ_outputready;
output	[103:0]	QZ_writedata;

// ------------- Wire Declarations -------------
wire      		ff_empty,
				ff_full,
				ff_rdreq;
wire	[127:0]	ff_q;

// ======================================================
// SIMULATION ONLY
// ======================================================
/*
test_quantYCrCb TEST_QZ (
				.clk        (clk),
				.inputready (QZ_inputready),
				.readdata   (QZ_readdata),
				.outputready(QZ_outputready),                  
				.writedata  (QZ_writedata)            
);  
*/
// ======================================================
// Main process
// ======================================================
ic_qz_control_unit QZ_CONTROL_UNIT
			(
				.clk    	(clk),
				.reset_n  	(reset_n),
				// Inputs
				.ff_empty 	(ff_empty),
				.ff_full  	(ff_full),
				.x        	(ff_q),
				// Outputs
				.ff_rdreq 	(ff_rdreq),
				.outputready(QZ_outputready),
				.y        	(QZ_writedata)
			);
		
ic_qz_fifo QZ_FIFO (
			.clock			(clk),
				.data			(QZ_readdata),
				.rdreq			(ff_rdreq),
				.sclr			(~reset_n),
				.wrreq			(QZ_inputready),
				.empty			(ff_empty),
				.full			(ff_full),
				.q				(ff_q)
			);
endmodule 

// =============================================================
// SIMULATION ONLY
// =============================================================
/*
module test_quantYCrCb (
                  clk,
                  inputready,
                  readdata,
                  outputready,                  
                  writedata               
              );
input     		clk,
				inputready,
				outputready;
input [127:0]  	readdata;
input [103:0] 	writedata;
reg       		s1_outputready;
             
integer f1, f2, f3;
integer count, count1, tmp, e;
integer t0, t1, t2, t3, t4, t5, t6, t7;
integer v0, v1, v2, v3, v4, v5, v6, v7;

initial 
begin
  $display($time, " << Check results >>");
  f1 = $fopen("modelsim_output_QuantZig.dat", "w");
  f2 = $fopen("modelsim_input_QuanZig.dat", "w");
  f3 = $fopen("golden_input_huffman.dat", "r");
  e = 1;
  count = 0;
  count1 = 0;
end

always @ (posedge clk)
begin
  if (outputready)
  begin
    count = count + 1;
    t0 = (writedata[12:0] > 4095) 	? (writedata[12:0] - 8192) : writedata[12:0];    
    t1 = (writedata[25:13] > 4095) 	? (writedata[25:13] - 8192) : writedata[25:13];
    t2 = (writedata[38:26] > 4095) 	? (writedata[38:26] - 8192) : writedata[38:26];
    t3 = (writedata[51:39]> 4095) 	? (writedata[51:39] - 8192) : writedata[51:39];
    t4 = (writedata[64:52] > 4095) 	? (writedata[64:52] - 8192) : writedata[64:52];
    t5 = (writedata[77:65] > 4095) 	? (writedata[77:65] - 8192) : writedata[77:65];
    t6 = (writedata[90:78] > 4095) ? (writedata[90:78] - 8192) : writedata[90:78];
    t7 = (writedata[103:91] > 4095)? (writedata[103:91] - 8192) : writedata[103:91];
    
    $fwrite (f1, "%3d %3d %3d %3d %3d %3d %3d %3d\n", t0, t1, t2, t3, t4, t5, t6, t7);    
    if (count == 8)
    begin
      $fwrite (f1, "\n");
      count = 0;     
    end     

    tmp = $fscanf(f3, "%d %d %d %d %d %d %d %d", v0, v1, v2, v3, v4, v5, v6, v7);
		if 	 (((v0 - t0) > e) || ((v0 - t0) < -e) || ((v1 - t1) > e) || ((v1 - t1) < -e) ||
		      ((v2 - t2) > e) || ((v2 - t2) < -e) || ((v3 - t3) > e) || ((v3 - t3) < -e) ||
		      ((v4 - t4) > e) || ((v4 - t4) < -e) || ((v5 - t5) > e) || ((v5 - t5) < -e) ||
		      ((v6 - t6) > e) || ((v6 - t6) < -e) || ((v7 - t7) > e) || ((v7 - t7) < -e))  
		begin
			   $display($time, " << Have Errors >>\n");
  			   $display($time, "%3d %3d %3d %3d %3d %3d %3d %3d\n", t0, t1, t2, t3, t4, t5, t6, t7);
			   $display($time, "%3d %3d %3d %3d %3d %3d %3d %3d\n\n\n", v0, v1, v2, v3, v4, v5, v6, v7);
			   $stop;
		end    // if
  end
end    

always @ (posedge clk)
begin
  if (inputready)
  begin
    count1 = count1 + 1;
    t0 = (readdata[15:0] > 32767) 	? (readdata[15:0] - 65536) : readdata[15:0];    
    t1 = (readdata[31:16] > 32767) 	? (readdata[31:16] - 65536) : readdata[31:16];
    t2 = (readdata[47:32] > 32767) 	? (readdata[47:32] - 65536) : readdata[47:32];
    t3 = (readdata[63:48]> 32767) 	? (readdata[63:48] - 65536) : readdata[63:48];
    t4 = (readdata[79:64] > 32767) 	? (readdata[79:64] - 65536) : readdata[79:64];
    t5 = (readdata[95:80] > 32767) 	? (readdata[95:80] - 65536) : readdata[95:80];
    t6 = (readdata[111:96] > 32767) ? (readdata[111:96] - 65536) : readdata[111:96];
    t7 = (readdata[127:112] > 32767)? (readdata[127:112] - 65536) : readdata[127:112];
    
    $fwrite (f2, "%3d %3d %3d %3d %3d %3d %3d %3d\n", t0, t1, t2, t3, t4, t5, t6, t7);    
    if (count1 == 8)
    begin
      $fwrite (f2, "\n");
      count1 = 0;     
    end 
  end
end         
endmodule
*/
