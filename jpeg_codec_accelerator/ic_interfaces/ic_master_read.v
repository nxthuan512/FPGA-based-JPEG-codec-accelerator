module ic_master_read (
					// Inputs
					clk,
					reset_n,						
					MR_start,
					MR_readdatavalid,
					MR_waitrequest,
					MR_addressinc,
					ff_full,
					HC_ff0_wait_request,
					R2Y_waitrequest,
					
					MR_address,
					MR_length,
					MR_readdata,
					
					// Outputs
					ff_writerequest,
					MR_read,
					
					MR_readaddress,
					MR_writedata
				);
// ------------------ InOut Declarations --------------------
input			clk,
				reset_n,				
				MR_start,
				MR_readdatavalid,
				MR_waitrequest,
				ff_full,
				HC_ff0_wait_request,
				R2Y_waitrequest;
input 	[2:0] 	MR_addressinc;
input	[31:0]	MR_address,
				MR_readdata,
				MR_length;
	
output			ff_writerequest,
				MR_read;
output	[31:0]	MR_readaddress,
				MR_writedata;

// ------------------ Reg Declarations --------------------
reg				MR_read,
				ff_writerequest;
reg		[31:0]	MR_readaddress,
				MR_lastreadaddress,
				MR_writedata;
				
// ========================================================
// CALL FOR SIMULATION
// ========================================================
/*
print_MR_block8x8x3_to_file MR_PBTF(
                        .clk  		(clk),
                        .start   	(MR_start),
                        .data_valid (MR_readdatavalid),
                        .data       (MR_readdata)
                      );
*/
// ========================================================
// Main Process
// ========================================================
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		MR_writedata <= 32'h0;
		ff_writerequest <= 1'b0;
	end
	
	else
	begin
		MR_writedata <= MR_readdatavalid ? MR_readdata : MR_writedata;
		ff_writerequest <= MR_readdatavalid;
	end
end

always @ (posedge clk)
begin
	if (~reset_n)
	begin
		MR_read				<= 1'b0;
		MR_readaddress 		<= 32'h0;	
		MR_lastreadaddress 	<= 32'h1;
	end
	
	else if (MR_start)
	begin
		MR_read <= ~ff_full;
		MR_readaddress 		<= MR_address;				
		MR_lastreadaddress 	<= MR_address + MR_length - MR_addressinc;
	end	
	
	else if ((MR_readaddress == MR_lastreadaddress) & ~MR_waitrequest)
	begin				
		MR_read	<= 1'b0;
		MR_readaddress <= 32'h0;
		MR_lastreadaddress 	<= 32'h1;			
	end
			
	else if (~MR_waitrequest && (MR_lastreadaddress != (MR_readaddress + 1'b1)))
	begin
		if (~(HC_ff0_wait_request | R2Y_waitrequest))
		begin
			MR_readaddress <= MR_readaddress + MR_addressinc;		
			MR_read <= ~ff_full;
		end
		else
			MR_read <= 1'b0;	
	end		
		
end
  
endmodule
