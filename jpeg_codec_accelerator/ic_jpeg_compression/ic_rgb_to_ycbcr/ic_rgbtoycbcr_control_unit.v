// ================================================================
// MODULE CONTROL UNIT
// ================================================================
module ic_rgbtoycbcr_control_unit (
				// ---------- Global Signals ---------
				clk,
				reset_n,
				
				// ----------- Inputs ------------
				CU_inputready,
				CU_readdata,
				
				// FlipFlop
				ffY_full,
				ffY_empty,
				R2Y_ff_almost_full, 
				R2Y_ff_almost_empty,
				
				// ----------- Outputs -------------
				R2Y_outputready,
				
				// FlipFlop
				ffY_writerequest,
				ffY_readrequest,
				ffCr_writerequest,
				ffCr_readrequest,
				ffCb_writerequest,
				ffCb_readrequest,
				
				ffY_data,
				ffCr_data,
				ffCb_data,
				
				// MUX 3to1
				MUX_select,
				R2Y_waitrequest
			);
					
// -------------- InOut Declarations --------------
input			clk,
				reset_n,			
				CU_inputready,
				ffY_full, 
				ffY_empty,
				R2Y_ff_almost_full, 
				R2Y_ff_almost_empty;
						
input	[23:0]	CU_readdata;
						
output			R2Y_outputready,
				R2Y_waitrequest,
				ffY_writerequest,
				ffY_readrequest,
				ffCr_writerequest,
				ffCr_readrequest,
				ffCb_writerequest,
				ffCb_readrequest;
				
output	[2:0]	MUX_select;
output	[63:0]	ffY_data,
				ffCr_data,
				ffCb_data;						

// -------------- Wire Declarations ----------------
wire 	[31:0] 	p1_YR, 	p1_YG, 	p1_YB,
				p1_CbR, p1_CbG, p1_CbB,
				p1_CrR, p1_CrG, p1_CrB,
				p1_Y, 	p1_Cr, 	p1_Cb;

// -------------- Reg Declarations ----------------
reg			    s1_CU_inputready,
				s2_CU_inputready,
				s3_CU_inputready;
reg				waitrequest,
				R2Y_waitrequest,
				downsampling_422,
				ffCr_readrequest,
				ffCb_readrequest,
				R2Y_outputready;
reg  	[1:0]	state;
reg		[2:0]	count1, 
				count2, 
				count3,
				MUX_select;

reg		[7:0]	R, G, B;				
reg		[7:0] 	Y [0:7];	
reg		[7:0] 	Cr [0:7];
reg		[7:0] 	Cb [0:7];

reg		[31:0]	YR, YG, YB,
				CbR, CbG, CbB,
				CrR, CrG, CrB;

always @ (posedge clk)
begin
	if (~reset_n)
		R2Y_waitrequest <= 1'b0;
	else if (R2Y_ff_almost_full)
		R2Y_waitrequest <= 1'b1;
	else if (R2Y_ff_almost_empty)
		R2Y_waitrequest <= 1'b0;
end
// ++++++++++++++++++++++++++++++++++++++++++++++++
// Combinational Circuit
// ++++++++++++++++++++++++++++++++++++++++++++++++
assign p1_YR = (R << 14) + (R << 11) + (R << 10) + (R << 7) + (R << 3) + (R << 1) + R;
assign p1_YG = (G << 15) + (G << 12) + (G << 10) + (G << 9) + (G << 6) + (G << 2) + (G << 1);
assign p1_YB = (B << 13) - (B << 10) + (B << 8) + (B << 5) + (B << 4) - (B << 1);

assign p1_CbR = -((R << 13) + (R << 11) + (R << 10) - (R << 8) + (R << 5) + (R << 4) + (R << 1));
assign p1_CbG = -((G << 14) + (G << 13) - (G << 11) - (G << 10) + (G << 8) - (G << 6) + (G << 3) + (G << 2));
assign p1_CbB = B << 15;

assign p1_CrR = R << 15;
assign p1_CrG = -((G << 14) + (G << 13) + (G << 11) + (G << 9) + (G << 8) + (G << 5) + (G << 4) - (G << 1));
assign p1_CrB = -((B << 12) + (B << 10) + (B << 7) + (B << 6) + (B << 4));

assign p1_Y = ((YR + YG + YB) >> 5'h10) - 8'd128;
assign p1_Cr = (CrR + CrG + CrB) >> 5'h10;
assign p1_Cb = (CbR + CbG + CbB) >> 5'h10;

// -- 4 --
// send data to FIFO				                                     					
assign ffY_data  = {Y[7],  Y[6],  Y[5],  Y[4],  Y[3],  Y[2],  Y[1],  Y[0]};
assign ffCr_data = {Cr[7], Cr[6], Cr[5], Cr[4], Cr[3], Cr[2], Cr[1], Cr[0]};
assign ffCb_data = {Cb[7], Cb[6], Cb[5], Cb[4], Cb[3], Cb[2], Cb[1], Cb[0]};

// -- 5 --
// control signals used to write data into FIFO
assign ffY_writerequest  = s3_CU_inputready && (~|count1);  // count1 = 0
assign ffCr_writerequest = s3_CU_inputready && (~|count1) && downsampling_422;
assign ffCb_writerequest = s3_CU_inputready && (~|count1) && downsampling_422;

// control signals used to read data from FIFO
// when ffY has new data, export it immediately, except having waitrequest
assign ffY_readrequest = ~ffY_empty && ~waitrequest;

// ++++++++++++++++++++++++++++++++++++++++++++++++
// Delay Signals
// ++++++++++++++++++++++++++++++++++++++++++++++++
always @ (posedge clk)
begin
	s1_CU_inputready <= CU_inputready;
	s2_CU_inputready <= s1_CU_inputready;
	s3_CU_inputready <= s2_CU_inputready;
end

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Calculate YCrCb
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		count1 <= 3'h0;				
		{B, G, R} <= {3{8'h0}};
		{YR, YG, YB} <= {3{32'h0}};
   	{CbR, CbG, CbB} <= {3{32'h0}};
   	{CrR, CrG, CrB} <= {3{32'h0}};
	end
	
	// receive 3 pixels, 24 bytes: R G B
	else 
	begin
		// 1. CU_inputready
		// receive new input when CU_inputready is asserted
		if (CU_inputready)			
			{B, G, R} <= CU_readdata;
			
		// 2. s1_CU_inputready
		// Calculate Y, Cr, Cb
		if (s1_CU_inputready)	
		begin
			YR <= p1_YR;
			YG <= p1_YG;
			YB <= p1_YB;

			CbR <= p1_CbR;
			CbG <= p1_CbG;
			CbB <= p1_CbB;

			CrR <= p1_CrR;
			CrG <= p1_CrG;
			CrB <= p1_CrB;
		end	
		
		// 3. s2_CU_inputready
		// count1 - row ; count2 - column of block 8x8x3
		if (s2_CU_inputready)
		begin
			count1 <= count1 + 1'b1;	

			Y[count1]  <= p1_Y[7:0];
			Cr[count1] <= p1_Cr[7:0];
			Cb[count1] <= p1_Cb[7:0];
		end
	end	
end

// +++++++++++++++++++++++++++++++++++++++++++++++++++++
// Allows data from RGB_to_YCrCb transfers to the BinDCT
// +++++++++++++++++++++++++++++++++++++++++++++++++++++
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		// count3 - column of block 8x8 when outputing
		{ffCr_readrequest, ffCb_readrequest} <= {2{1'h0}};
		{count2, count3} 	<= {2{3'h0}};
		MUX_select 			<= 3'h0;
		R2Y_outputready 	<= 1'b0;
		downsampling_422 	<= 1'b0;
		waitrequest 		<= 1'b0;
		state 				<= 2'h0;
	end
		
	else
	begin
		R2Y_outputready <= ffY_readrequest || ffCb_readrequest || ffCr_readrequest;
		case (state)
			2'h0: begin
				MUX_select <= 3'b001;
				waitrequest <= 1'b0;
				
				if (ffY_readrequest)
				begin
					if (count2 == 3'h7)
					begin
						count2 <= 3'h0;
						state <= 2'h1;
					end				
					else
						count2 <= count2 + 1'b1;
				end				
			end
			
			2'h1: begin
				// not allow new input to pass through
				waitrequest <= downsampling_422;				
				ffCb_readrequest <= downsampling_422;	
				downsampling_422 <= ~downsampling_422;
				state <= {downsampling_422, 1'b0};
			end
			// Transfer Cr to the BinDCT
			2'h2: begin
				MUX_select <= 3'b010;
				if (count3 == 3'h7)
				begin
					count3 <= 3'h0;					
					ffCb_readrequest <= 1'b0;
					ffCr_readrequest <= 1'b1;					
					state <= 2'h3;
				end				
				else
					count3 <= count3 + 1'b1;
			end
			
			// Transfer Cb to the BinDCT
			2'h3: begin
				MUX_select <= 3'b100;
				if (count3 == 3'h7)
				begin
					count3 <= 3'h0;					
					ffCr_readrequest <= 1'b0;					
					state <= 2'h0;
				end				
				else
					count3 <= count3 + 1'b1;
			end
		endcase
	end
end

endmodule
