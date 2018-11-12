`include "./ic_rgbtoycbcr_control_unit.v"
`include "./ic_rgbtoycbcr_32to24.v"
`include "./ic_rgbtoycbcr_mux_3to1.v"
`include "./ic_rgbtoycbcr_ff_16x64.v"
`include "./ic_rgbtoycbcr_ff_4x64.v"
`include "./ic_rgbtoycbcr_ff_1920x32.v"

module ic_rgb_to_ycbcr (
						// Inputs
						clk,
						reset_n,
						R2Y_inputready,
						R2Y_readdata,	// {B, G, R}
						
						// Outputs
						R2Y_outputready,		
						R2Y_writedata,
						R2Y_waitrequest
					);
					
// ------------------- InOut Declarations --------------------
input			clk,
				reset_n,
				R2Y_inputready;
input	[31:0]	R2Y_readdata;

output			R2Y_outputready,
				R2Y_waitrequest;
output	[63:0]	R2Y_writedata;

// ------------------- Wire Declarations --------------------
wire			ff0_full, ff0_empty,
				ff0_rdreq,
				ffY_full, ffY_empty,
				ffY_writerequest,  ffY_readrequest,
				ffCr_writerequest, ffCr_readrequest,
				ffCb_writerequest, ffCb_readrequest,
				R2Y_ff_almost_full, R2Y_ff_almost_empty;
wire			CU_inputready;
wire	[2:0]	MUX_select;				
wire	[23:0]	CU_readdata;
wire	[31:0]	ff0_q;
wire	[63:0]	ffY_data,  ffY_q,
				ffCr_data, ffCr_q,
				ffCb_data, ffCb_q;			

// ==================================================================
// SIMULATION ONLY
// ==================================================================
/*
test_YCrCb_result TEST_YCrCb_RESULT (
                  clk,            
                  R2Y_outputready,
                  R2Y_writedata
                );

*/				
// Order -> output block 8x8: Y => Cb => Cr				
// ======================= CONTROL UNIT ======================
ic_rgbtoycbcr_control_unit R2Y_CONTROL_UNIT (
			// ---------- Global Signals ---------
			.clk				(clk),
			.reset_n			(reset_n),
			
			// ----------- Inputs ------------
			.CU_inputready		(CU_inputready),
			.CU_readdata		(CU_readdata),
			
			// FlipFlop
			.ffY_full			(ffY_full),
			.ffY_empty			(ffY_empty),
			.R2Y_ff_almost_empty(R2Y_ff_almost_empty),
			.R2Y_ff_almost_full	(R2Y_ff_almost_full),
			
			// ----------- Outputs -------------
			.R2Y_outputready	(R2Y_outputready),
			
			// FlipFlop
			.ffY_writerequest	(ffY_writerequest),
			.ffY_readrequest	(ffY_readrequest),
			.ffCr_writerequest	(ffCr_writerequest),
			.ffCr_readrequest	(ffCr_readrequest),
			.ffCb_writerequest	(ffCb_writerequest),
			.ffCb_readrequest	(ffCb_readrequest),
			
			.ffY_data			(ffY_data),
			.ffCr_data			(ffCr_data),
			.ffCb_data			(ffCb_data),
			
			// MUX 3to1
			.MUX_select			(MUX_select),
			.R2Y_waitrequest	(R2Y_waitrequest)
		);

// =============== 32bits to 24bits ===================
ic_rgbtoycbcr_32to24 R2Y_32TO24 (
			.clk				(clk),
			.reset_n			(reset_n),
			// Inputs
			.ff0_empty			(ff0_empty),
			.ff0_full			(ff0_full),
			.T32_readdata		(ff0_q),
			// Outputs
			.ff0_rdreq			(ff0_rdreq),
			.T32_outputready	(CU_inputready),
			.T32_writedata		(CU_readdata)				
		);
				
// ======================= FIFOs ======================
ic_rgbtoycbcr_ff_1920x32 FIFO_0 (
			.clock				(clk),
			.data				(R2Y_readdata),
			.rdreq				(ff0_rdreq),
			.sclr				(~reset_n),
			.wrreq				(R2Y_inputready),
			.almost_empty		(R2Y_ff_almost_empty),
			.almost_full		(R2Y_ff_almost_full),
			.empty				(ff0_empty),
			.full				(ff0_full),
			.q					(ff0_q)
		);
		
ic_rgbtoycbcr_ff_4x64 FIFO_Y (
			.clock		(clk),
			.data		(ffY_data),
			.rdreq		(ffY_readrequest),
			.sclr		(~reset_n),
			.wrreq		(ffY_writerequest),
			.empty		(ffY_empty),
			.full		(ffY_full),
			.q			(ffY_q)
		);
		
ic_rgbtoycbcr_ff_16x64 FIFO_Cr (
			.clock		(clk),
			.data		(ffCr_data),
			.rdreq		(ffCr_readrequest),
			.sclr		(~reset_n),
			.wrreq		(ffCr_writerequest),
			.q			(ffCr_q)
		);
	
ic_rgbtoycbcr_ff_16x64 FIFO_Cb (
			.clock		(clk),
			.data		(ffCb_data),
			.rdreq		(ffCb_readrequest),
			.sclr		(~reset_n),
			.wrreq		(ffCb_writerequest),
			.q			(ffCb_q)
		);

// ======================= MUX 3to1 ===================
ic_rgbtoycbcr_mux_3to1 MUX_3TO1 (
			.select		(MUX_select),
			.a0			(ffY_q),
			.a1			(ffCb_q),
			.a2			(ffCr_q),
			.a			(R2Y_writedata)
		);

endmodule

// ==================================================================
// SIMULATION ONLY
// ==================================================================

module test_YCrCb_result (
                  clk,
                  R2Y_outputready,
                  R2Y_writedata
                );
                
input         clk,
              R2Y_outputready;
input   [63:0]R2Y_writedata;

integer count, temp, e;              
integer f1, f2;
integer t0, t1, t2, t3, t4, t5, t6, t7;
integer v0, v1, v2, v3, v4, v5, v6, v7;

initial 
begin
	$display($time, " << Check YCrCb Results >>");
  
	$display ("\n Print block8x8x3 to modelsim_MW_output_RGB_block8x8x3.dat\n");
	f1 = $fopen("modelsim_R2Y_output_YCrCb_block8x8x3.dat", "w");
	f2 = $fopen("golden_input_fbindct.dat", "r");
	
	count = 0;
	e = 1;
end

always @ (posedge clk)
begin
  if (R2Y_outputready)
  begin
    count = count + 1;
    
    t0 = R2Y_writedata & 64'h00000000000000ff;  
    t1 = (R2Y_writedata & 64'h000000000000ff00) >> 8; 
    t2 = (R2Y_writedata & 64'h0000000000ff0000) >> 16;  
    t3 = (R2Y_writedata & 64'h00000000ff000000) >> 24;
    t4 = (R2Y_writedata & 64'h000000ff00000000) >> 32;
    t5 = (R2Y_writedata & 64'h0000ff0000000000) >> 40;
    t6 = (R2Y_writedata & 64'h00ff000000000000) >> 48;
    t7 = (R2Y_writedata & 64'hff00000000000000) >> 56;
    
    if (t0 > 127) t0 = t0 - 256;
    if (t1 > 127) t1 = t1 - 256;
    if (t2 > 127) t2 = t2 - 256;
    if (t3 > 127) t3 = t3 - 256;  
    if (t4 > 127) t4 = t4 - 256;
    if (t5 > 127) t5 = t5 - 256;
    if (t6 > 127) t6 = t6 - 256;
    if (t7 > 127) t7 = t7 - 256;        
    
    $fwrite(f1,"%5d %5d %5d %5d %5d %5d %5d %5d\n", t0, t1, t2, t3, t4, t5, t6, t7);
    if (count % 8 == 0) $fwrite (f1, "\n");          
      
    temp = $fscanf(f2,"%d %d %d %d %d %d %d %d", v0, v1, v2, v3, v4, v5, v6, v7);
    //if ((t0 != v0) || (t1 != v1) || (t2 != v2) || (t3 != v3) || (t4 != v4) || (t5 != v5) || (t6 != v6) || (t7 != v7))
    if 	 (((v0 - t0) > e) || ((v0 - t0) < -e) || ((v1 - t1) > e) || ((v1 - t1) < -e) ||
	       ((v2 - t2) > e) || ((v2 - t2) < -e) || ((v3 - t3) > e) || ((v3 - t3) < -e) ||
		     ((v4 - t4) > e) || ((v4 - t4) < -e) || ((v5 - t5) > e) || ((v5 - t5) < -e) ||
		     ((v6 - t6) > e) || ((v6 - t6) < -e) || ((v7 - t7) > e) || ((v7 - t7) < -e))
    begin
		$display($time, " << Have Errors >>\n");
		$display($time, "%3d %3d %3d %3d %3d %3d %3d %3d\n", t0, t1, t2, t3, t4, t5, t6, t7);
		$display($time, "%3d %3d %3d %3d %3d %3d %3d %3d\n\n\n", v0, v1, v2, v3, v4, v5, v6, v7);
		$stop;
    end
  end
end
                    
endmodule 
