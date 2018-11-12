`include "./ic_bd_bindct_1d1.v"
`include "./ic_bd_bindct_1d2.v"
`include "./ic_bd_control_unit.v"
`include "./ic_bd_mux1.v"
`include "./ic_bd_mux2.v"
`include "./ic_bd_transpose_matrix.v"

module ic_bindct_processor (
							// Inputs
							clk,
							reset_n,
							BD_inputready,
							BD_readdata,
							
							// Outputs
							BD_outputready,							
							BD_writedata
					);

// ------------------ In/Out Declarations ----------------------
input 			clk,
				reset_n,
				BD_inputready;
input	[63:0]	BD_readdata;

output			BD_outputready;
output	[127:0]	BD_writedata;

// ------------------ Wire Declarations ----------------------
wire			BD1_outputready,
				BD2_inputready,
				TM1_full,
				TM1_empty,
				TM1_writerequest,
				TM1_readrequest,
				TM2_full,
				TM2_empty,
				TM2_writerequest,
				TM2_readrequest,
				MUX1_select, 
				MUX2_select;

wire	[95:0] 	bd1_r,  bd2_w,
				bd1_r1, bd2_w1,
				bd1_r2,	bd2_w2;
				
// ==================================================================
// SIMULATION ONLY
// ==================================================================
/*
test_BinDCT_proc TEST_BD_PROC (
		  .clk				(clk),
		  .outputready		(BD_outputready),
		  .writedata		(BD_writedata)
		);		
*/
// ============================================================
// CONTROL UNIT
// ============================================================
ic_bd_control_unit CU (
				.clk				(clk),
				.reset_n			(reset_n),
				// Inputs
				.BD1_outputready	(BD1_outputready),
				.TM1_full			(TM1_full),
				.TM1_empty			(TM1_empty),
				.TM2_full			(TM2_full),
				.TM2_empty			(TM2_empty),
				
				// Outputs
				.BD2_inputready		(BD2_inputready),
				.TM1_writerequest	(TM1_writerequest),
				.TM1_readrequest	(TM1_readrequest),
				.TM2_writerequest	(TM2_writerequest),
				.TM2_readrequest	(TM2_readrequest),
				
				.MUX1_select		(MUX1_select), 
				.MUX2_select		(MUX2_select)
				);
				
// ============================================================
// BinDCT Coprocessor
// ============================================================
ic_bd_bindct_1d1 BD_1D1 (
					.clk			(clk),
					.reset_n		(reset_n),
					.inputready		(BD_inputready),
					.outputready	(BD1_outputready),
					.x				(BD_readdata),
					.y				(bd1_r)
				);

ic_bd_bindct_1d2 BD_1D2 (
					.clk			(clk),
					.reset_n		(reset_n),
					.inputready		(BD2_inputready),
					.outputready	(BD_outputready),
					.x				(bd2_w),	
					.y				(BD_writedata)
				);

// ============================================================
// Transpose Matrix
// ============================================================						
ic_bd_transpose_matrix TM1 (
					.clk			(clk),
					.reset_n		(reset_n),
					.writerequest	(TM1_writerequest),
					.readrequest	(TM1_readrequest),
					.empty			(TM1_empty),
					.full			(TM1_full),
					.x				(bd1_r1),
					.y				(bd2_w1)
				);				

ic_bd_transpose_matrix TM2 (
					.clk			(clk),
					.reset_n		(reset_n),
					.writerequest	(TM2_writerequest),
					.readrequest	(TM2_readrequest),
					.empty			(TM2_empty),
					.full			(TM2_full),
					.x				(bd1_r2),
					.y				(bd2_w2)
				);
// ============================================================
// MUX
// ============================================================	
ic_bd_mux1 MUX1 (
					.select			(MUX1_select),
					.z				(bd1_r),
					.x				(bd1_r1),
					.y				(bd1_r2)
		);	

ic_bd_mux2 MUX2 (
					.select			(MUX2_select),
					.x				(bd2_w1),
					.y				(bd2_w2),
					.z				(bd2_w)
		);

endmodule 

// ==================================================================
// SIMULATION ONLY
// ==================================================================
module test_BinDCT_proc (
						clk,
						outputready,
						writedata
                );
                
input         	 	clk,
					outputready;
input   [127:0] 	writedata;
              
integer f1, f2;
integer count, tmp, e;
integer t0, t1, t2, t3, t4, t5, t6, t7;
integer v0, v1, v2, v3, v4, v5, v6, v7;

initial 
begin
  $display($time, " << Check BINDCT inputs >>");
  f1 = $fopen("modelsim_output_BinDCT_coprocessor.dat", "w");
  f2 = $fopen("golden_input_quant.dat", "r");
  e = 1;
  count = 0;
end

always @ (posedge clk)
begin
  if (outputready)
  begin
    count = count + 1;
    t0 = (writedata[15:0] > 32767) 	? (writedata[15:0] - 65536) : writedata[15:0];    
    t1 = (writedata[31:16] > 32767) ? (writedata[31:16] - 65536) : writedata[31:16];
    t2 = (writedata[47:32] > 32767) ? (writedata[47:32] - 65536) : writedata[47:32];
    t3 = (writedata[63:48]> 32767) 	? (writedata[63:48] - 65536) : writedata[63:48];
    t4 = (writedata[79:64] > 32767) ? (writedata[79:64] - 65536) : writedata[79:64];
    t5 = (writedata[95:80] > 32767) ? (writedata[95:80] - 65536) : writedata[95:80];
    t6 = (writedata[111:96] > 32767) ? (writedata[111:96] - 65536) : writedata[111:96];
    t7 = (writedata[127:112] > 32767)? (writedata[127:112] - 65536) : writedata[127:112];
    
    $fwrite (f1, "%3d %3d %3d %3d %3d %3d %3d %3d\n", t0, t1, t2, t3, t4, t5, t6, t7);
    
    if (count == 8)
    begin
      $fwrite (f1, "\n");
      count = 0;     
    end  
    
    tmp = $fscanf(f2, "%d %d %d %d %d %d %d %d", v0, v1, v2, v3, v4, v5, v6, v7);
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
                    
endmodule 

// ========================================================================
/*
module BD_test_bench ();

reg	     			clk,
					reset_n,
					inputready;
reg 	[63:0]  	readdata;
wire				outputready;
wire	[127:0]		writedata;
             
integer f1;
integer tmp, i, n;
integer X_image, Y_image;
integer t0, t1, t2, t3, t4, t5, t6, t7;

icmd_ic_bindct_processor ICMD_IC_BINDCT_PROCESSOR (
							// Inputs
							.clk			(clk),
							.reset_n		(reset_n),
							.BD_inputready	(inputready),
							.BD_readdata	(readdata),
							
							// Outputs
							.BD_outputready	(outputready),							
							.BD_writedata	(writedata)
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
	f1 = $fopen("golden_input_fbindct.dat", "r");

	inputready = 0;
	X_image = 32;
	Y_image = 24;
	n = X_image * Y_image * 2;
	
	wait(reset_n);
	#200;
	
	for (i = 0; i < n; i = i + 8)
	begin
		tmp = $fscanf(f1, "%d %d %d %d %d %d %d %d", t0, t1, t2, t3, t4, t5, t6, t7);
		readdata[7:0] = t0;
		readdata[15:8] = t1;
		readdata[23:16] = t2;
		readdata[31:24] = t3;
		readdata[39:32] = t4;
		readdata[47:40] = t5;
		readdata[55:48] = t6;
		readdata[63:56] = t7;
		
		@(posedge clk)
		inputready = 1;
		@(posedge clk)
		inputready = 0;
	end
	
	$fclose(f1);
end

endmodule 
*/