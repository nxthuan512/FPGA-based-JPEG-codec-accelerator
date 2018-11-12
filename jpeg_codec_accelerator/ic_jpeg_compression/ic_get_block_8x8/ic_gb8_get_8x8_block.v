// ============================================================
// GET 8x8x3 BLOCK 
// ============================================================	
module ic_gb8_get_8x8_block (
			clk,
			reset_n,
			// Inputs
			enable,
			IC_X_image,
			IC_X_image_x3,
			// Outputs
			buffer_address			
	);

// ------------------ InOut Declarations --------------------
input			clk,
				reset_n,
				enable;
input	[15:0]	IC_X_image,
				IC_X_image_x3;
output	[12:0]	buffer_address;
// ------------------- Reg Declarations ---------------------
reg		[2:0]	CountValue,		// dem so 32-bit value tren 1 line cua 1 block = 6
				CountRowInBlock;
reg		[7:0]	CountBlockInRow;
reg		[12:0]	FirstAddrInBlock,
				AddrRowInBlock;
		
// ------------------- Wire Declarations --------------------
wire	[4:0]	length;
wire	[9:0]	MaxCountBlockInRow;

// ------------------------------------------------------------
assign MaxCountBlockInRow = IC_X_image[12:3];
assign length = 5'd6;

assign buffer_address = AddrRowInBlock + {10'h0, CountValue};

// ------------------------------------------------------------
always @ (posedge clk)
begin
	if (~reset_n || ~enable)
	begin
		{CountValue, CountRowInBlock}  <= {2{3'h0}};
		{FirstAddrInBlock, AddrRowInBlock} <= {2{13'h0}};
		CountBlockInRow <= 8'h0;
	end
	
	else if (enable)
	begin			     		
		// end of block
		if (CountRowInBlock == 3'h7 && CountValue == 3'h5)
		begin
			CountValue <= 3'h0;				
			CountRowInBlock <= 3'h0;
			// end of buffer	
			if (CountBlockInRow == MaxCountBlockInRow - 1'b1)
			begin
			   	{FirstAddrInBlock, AddrRowInBlock} <= {2{13'h0}};
				CountBlockInRow <= 8'h0; 
			end
			
			else
			begin
				FirstAddrInBlock<= FirstAddrInBlock + length;
				AddrRowInBlock 	<= FirstAddrInBlock + length;
				CountBlockInRow <= CountBlockInRow + 1'b1;
			end
		end  // if (CountRowInBlock == 3'h7)
		
		else
		begin
			CountValue <= CountValue + 1'b1;
			if (CountValue == 3'h5)
			begin
      			AddrRowInBlock  <= AddrRowInBlock + IC_X_image_x3[14:2];
      			// count row = 7 -> end a block
				CountRowInBlock <= (CountRowInBlock == 3'h7) ? 3'h0 : (CountRowInBlock + 1'b1);
				CountValue <= 3'h0;
			end
		end   
			
	end // if (enable)
end
endmodule 
