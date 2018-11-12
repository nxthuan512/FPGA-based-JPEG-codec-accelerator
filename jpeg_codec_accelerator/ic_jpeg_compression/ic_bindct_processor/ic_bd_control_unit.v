// ============================================================
// CONTROL UNIT
// ============================================================
module ic_bd_control_unit (
						clk,
						reset_n,
						// Inputs
						BD1_outputready,
						TM1_full,
						TM1_empty,
						TM2_full,
						TM2_empty,
						
						// Outputs
						BD2_inputready,
						TM1_writerequest,
						TM1_readrequest,
						TM2_writerequest,
						TM2_readrequest,
						
						MUX1_select, 
						MUX2_select
				);

// ----------------- InOut Declarations ------------------
input			clk,
				reset_n,
				
				BD1_outputready,
				TM1_full,
				TM1_empty,
				TM2_full,
				TM2_empty;
						
output			BD2_inputready,
				TM1_writerequest,
				TM1_readrequest,
				TM2_writerequest,
				TM2_readrequest,
					
				MUX1_select, 
				MUX2_select;

// ----------------- Reg Declarations ------------------	
wire			p1_TM1_readrequest,
				p1_TM2_readrequest;
				
reg		       	BD2_inputready,
				TM1_readrequest,
				TM2_readrequest,
				s1_count_r3;	
reg		[3:0]	count_r,
				count_w;
				
// =====================================================
// Combinational Circuit
// =====================================================
assign TM1_writerequest = BD1_outputready && MUX1_select;  
assign TM2_writerequest = BD1_outputready && ~MUX1_select;

assign MUX1_select = ~reset_n ? 1'b0 : ~count_w[3];
assign MUX2_select = ~reset_n ? 1'b0 : ~s1_count_r3;

// =====================================================
// Main process
// =====================================================	
always @ (posedge clk)
begin
	if (~reset_n)
		s1_count_r3 <= 1'b0;
	else 
		s1_count_r3 <= count_r[3];
end

// --------------- counter ------------------
always @ (posedge clk)
begin
	if (~reset_n)
		{count_r, count_w} <= {2{4'h0}};
	
	else 
	begin
		if (BD1_outputready)
			count_w <= count_w + 1'b1;
		if (TM1_readrequest || TM2_readrequest)
			count_r <= count_r + 1'b1;
	end
end

// ------------- readrequest --------------
assign p1_TM2_readrequest = (count_r >= 4'd7) && (count_r <= 4'd14);
assign p1_TM1_readrequest = (count_r == 4'd15) || (count_r < 4'd7);

always @ (posedge clk)
begin
	if (~reset_n)
		{TM1_readrequest, TM2_readrequest} <= {2{1'b0}};	
	
	else if (&count_w[2:0] && BD1_outputready)
	begin
		TM1_readrequest <= p1_TM1_readrequest;
		TM2_readrequest <= p1_TM2_readrequest;
	end
	
	else if (&count_r[2:0])
		{TM1_readrequest, TM2_readrequest} <= {2{1'b0}};	
end

// -------- inputready, readrequest ------------
always @ (posedge clk)
begin
	if (~reset_n)
		BD2_inputready <= 1'b0;		
	else     
		BD2_inputready <= TM1_readrequest | TM2_readrequest;
end

endmodule 
