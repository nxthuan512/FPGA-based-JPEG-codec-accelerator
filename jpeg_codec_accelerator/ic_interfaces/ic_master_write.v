module ic_master_write (
					// Inputs
					clk,
					reset_n,
					MW_start,												
					ff_empty,
					MW_waitrequest,
					MW_addressinc,
					
					MW_address,
					MW_readdata,
					IC_EndOfImage,
					
					// Output
					MW_done,
					ff_readrequest,
					MW_write,
					
					MW_writeaddress,
					MW_writedata
			);
				
// ------------------ InOut Declarations --------------------
input			clk,
				reset_n,
				MW_start,				
				ff_empty,
				MW_waitrequest,
				IC_EndOfImage;
input 	[2:0] 	MW_addressinc;
input	[31:0]	MW_address,
				MW_readdata;

						
output			MW_done,
				ff_readrequest,
				MW_write;
output	[31:0]	MW_writeaddress,
				MW_writedata;
				
// ------------------ Reg Declarations --------------------					
reg				MW_done,
				MW_write;
reg		[1:0]	state;
reg		[31:0]	MW_writedata,
				MW_writeaddress;
// ------------------ Wire Declarations ------------------
wire 			ff_readrequest;

// ========================================================
// Main FSM
// ========================================================
assign ff_readrequest = (~reset_n) ? 1'b0 : (~ff_empty && ~|state);

always @ (posedge clk)				
begin
	if (~reset_n)
	begin
		state <= 2'h0;
		{MW_write, MW_done} <= 2'b0;
		{MW_writedata, MW_writeaddress} <= {2{32'h0}};
	end
	
	else
	begin
		if (MW_start)
			MW_writeaddress <= MW_address;
			
		else if (~ff_empty || |state)		
			case (state)
				2'h0: state <= 2'h1;
				2'h1: begin
					MW_write <= 1'b1;
					MW_writedata <= MW_readdata;
					state <= 2'h2;
				end
				2'h2: if (~MW_waitrequest)
					begin
						MW_writeaddress <= MW_writeaddress + MW_addressinc;
						MW_write <= 1'b0;
						state <= 2'h0;
					end						
			endcase
		
		else if (IC_EndOfImage)
			MW_done	<= 1'b1;
		else
			MW_done <= 1'b0;
	end
end
endmodule
