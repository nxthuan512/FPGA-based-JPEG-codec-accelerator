`include "./ic_gb8_buffer.v"
`include "./ic_gb8_control_unit.v"
`include "./ic_gb8_get_8x8_block.v"
`include "./ic_gb8_mux1.v"
`include "./ic_gb8_mux2.v"

module ic_get_block_8x8 (
					clk,
					reset_n,	// ~reset_n && IC_global_enable
					// Inputs
					GB8_inputready,
					GB8_readdata,
					IC_X_image,	// IC_X_image: chua bao gom R, G, B
					// Outputs
					GB8_outputready,
					GB8_writedata
		);

// -------------------- InOut Declarations --------------------		
input			clk,
				reset_n,
				GB8_inputready;
input	[15:0]	IC_X_image;
input	[31:0]	GB8_readdata;
output			GB8_outputready;
output	[31:0]	GB8_writedata;

// -------------------- Wire Declarations --------------------
wire			MUX1_select,
				MUX2_select,
				buffer0_wren,
				buffer1_wren;
wire	[12:0]	buffer0_address,
				buffer1_address;
wire	[31:0]	buffer0_data,
				buffer1_data,
				buffer0_q,
				buffer1_q;

// ============================================================
// SIMULATION ONLY
// ============================================================			
/*
test_block8x8_result TEST_BLOCK8x8 (
                  clk,
                  GB8_outputready,
                  GB8_writedata
              );      
*/
// ============================================================
// CONTROL UNIT
// ============================================================
ic_gb8_control_unit GB8_CONTROL_UNIT (
			.clk			(clk),
			.reset_n		(reset_n),
			// Inputs
			.GB8_inputready	(GB8_inputready),
			.IC_X_image		(IC_X_image),
			
			// Outputs
			.GB8_outputready	(GB8_outputready),
			.MUX1_select	(MUX1_select),
			.MUX2_select	(MUX2_select),
			.buffer0_wren	(buffer0_wren),
			.buffer0_address(buffer0_address),
			.buffer1_wren	(buffer1_wren),
			.buffer1_address(buffer1_address)			
	);
// ============================================================
// MUX
// ============================================================	
ic_gb8_mux1 GB8_MUX1 (
			.select			(MUX1_select),
			.z				(GB8_readdata),
			.x				(buffer0_data),
			.y				(buffer1_data)
		);	

ic_gb8_mux2 GB8_MUX2 (
			.select			(MUX2_select),
			.x				(buffer0_q),
			.y				(buffer1_q),
			.z				(GB8_writedata)
		);
		
// ============================================================
// BUFFER BLOCK 8x8
// ============================================================						
ic_gb8_buffer GB8_BUFFER0 (
			.address	(buffer0_address),
			.clock		(clk),
			.data		(buffer0_data),
			.wren		(buffer0_wren),
			.q			(buffer0_q)
	);	
	
ic_gb8_buffer GB8_BUFFER1 (
			.address	(buffer1_address),
			.clock		(clk),
			.data		(buffer1_data),
			.wren		(buffer1_wren),
			.q			(buffer1_q)
	);	

		
endmodule 
// =====================================================================
// SIMULATION ONLY
// =====================================================================
/*
module test_block8x8_result (
                  clk,
                  GB8_outputready,
                  GB8_writedata
                );
                
input         clk,
              GB8_outputready;
input   [31:0]GB8_writedata;

integer count, temp, e;              
integer f1, f2;
integer t0, t1, t2, t3, t4, t5, t6, t7;
integer v0, v1, v2, v3, v4, v5, v6, v7;

initial 
begin
  $display($time, " << Check Results >>");
  
  $display ("\n Print block8x8x3 to modelsim_MW_output_RGB_block8x8x3.dat\n");
	f1 = $fopen("modelsim_output_block8x8x3.dat", "w");
	f2 = $fopen("golden_input_RGB_block8x8x3.dat", "r");
	
	count = 0;
	e = 1;
end

always @ (posedge clk)
begin
  if (GB8_outputready)
  begin
    count = count + 1;
    
    t0 = GB8_writedata & 32'h000000ff;  
    t1 = (GB8_writedata & 32'h0000ff00) >> 8; 
    t2 = (GB8_writedata & 32'h00ff0000) >> 16;  
    t3 = (GB8_writedata & 32'hff000000) >> 24;
    
    $fwrite(f1,"%5d %5d %5d %5d", t0, t1, t2, t3);
    if (count % 6 == 0) $fwrite (f1, "\n");          
    if (count % 48 == 0) $fwrite (f1, "\n");   
      
    temp = $fscanf(f2,"%d %d %d %d", v0, v1, v2, v3);
    if ((t0 != v0) || (t1 != v1) || (t2 != v2) || (t3 != v3) || (t4 != v4))
    begin
      $display($time, " << Have Errors >>\n");
			$display($time, "%3d %3d %3d %3d\n", t0, t1, t2, t3);
			$display($time, "%3d %3d %3d %3d\n\n\n", v0, v1, v2, v3);
      $stop;
    end
  end
end
                    
endmodule
*/