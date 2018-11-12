// +++++++++++++++++++++++++++++++++++++++++++++++++++++
// 32 bits data to 24 bits RGB
// +++++++++++++++++++++++++++++++++++++++++++++++++++++
module ic_rgbtoycbcr_32to24 (
					clk,
					reset_n,
					// Inputs
					ff0_empty,
					ff0_full,
					T32_readdata,
					// Outputs
					ff0_rdreq,
					T32_outputready,
					T32_writedata				
				);

// ---------- InOut Declarations -------------			
input			clk,
				reset_n,
				ff0_empty,
				ff0_full;
input	[31:0]	T32_readdata;

output			ff0_rdreq,
				T32_outputready;
output	[23:0]	T32_writedata;

// ---------- Reg Declarations -------------
reg				T32_outputready,
				s1_ff0_rdreq, 
				s2_ff0_rdreq,
				s3_ff0_rdreq;
reg		[1:0]	state;
reg		[7:0]	R0, G0, B0, R1, G1, B1;
reg		[23:0]	T32_writedata;

// ===================================================================
assign ff0_rdreq = ~ff0_empty && (state != 2'h2);

always @ (posedge clk)
begin
	if (~reset_n)
		{s1_ff0_rdreq, s2_ff0_rdreq, s3_ff0_rdreq} <= {3{1'b0}};
	else
		{s1_ff0_rdreq, s2_ff0_rdreq, s3_ff0_rdreq} <= {ff0_rdreq, s1_ff0_rdreq, s2_ff0_rdreq};
end

always @ (posedge clk)
begin
	if (~reset_n)
	begin
		state <= 2'h0;	
		T32_outputready <= 1'b0;
		T32_writedata <= 24'h0;
		{R0, G0, B0, R1, G1, B1} <= {6{8'h0}};
	end
		
	else
	begin 
		T32_outputready <= s2_ff0_rdreq || s3_ff0_rdreq;
		T32_writedata <= (state[0]) ? {B0, G0, R0} : {B1, G1, R1};
		
		if (s1_ff0_rdreq || s2_ff0_rdreq)
		begin
			state <= state + 1'b1;
			case (state)
				2'h0: {R1, B0, G0, R0} <= T32_readdata;
				2'h1: {G0, R0, B1, G1} <= T32_readdata;
				2'h2: {B1, G1, R1, B0} <= T32_readdata;
			endcase
		end
	end
end

endmodule 
