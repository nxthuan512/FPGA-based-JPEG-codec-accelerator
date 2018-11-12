// *******************************************************************
// HUFFMAN PRECALCULATION
// *******************************************************************
module ic_hc_huffman_coding_preparation (
					clk,
					reset_n,
					// Inputs
					DC_enable,
					AC_enable,
					EOB_enable,
					readdata,
					// Outputs
					outputready,
					writedata_value,
					writedata_RSL
			);

// ----------------- InOut Declarations ---------------
input			clk,
				reset_n,
				DC_enable,
				AC_enable,
				EOB_enable;
input	[12:0]	readdata;
output			outputready;
output	[12:0]	writedata_value,
				writedata_RSL;

// ----------------- Reg Declarations ---------------
reg				outputready;
reg		[5:0]	number_of_zeroes;
reg		[12:0]	writedata_value,
				writedata_RSL;
		
// ----------------- Wire Declarations ---------------
wire			comp0, comp1, comp2, comp3, comp4, comp5, comp6, 
				comp7, comp8, comp9, comp10, comp11;
				// comp12;
wire [3:0]		length;
wire [12:0] 	mask_readdata,
				graycode_readdata;

// **************************************************************
// category: 			0			-> 205
//					  -1  1			-> 1
// 					-3 -2 2 3		-> 2
//		    -7 -6 -5 -4  4  5  6  7 -> 3
// 					..........
//			-32768 .......... 32767	-> 15		
// **************************************************************
// ----------------------- precalculate ----------------------
// Kiem tra xem so nhap vao co bao nhieu bits
assign comp0 =  (readdata == 13'h0);
assign comp1 =  (readdata == 13'h1FFF)  || (readdata == 13'h0001); 	// -1
assign comp2 =  (readdata >= 13'h1FFD)  || (readdata <= 13'h0003); 	// -3
assign comp3 =  (readdata >= 13'h1FF9)  || (readdata <= 13'h0007 ); // -7
assign comp4 =  (readdata >= 13'h1FF1) 	|| (readdata <= 13'h000F);
assign comp5 =  (readdata >= 13'h1FE1) 	|| (readdata <= 13'h001F);
assign comp6 =  (readdata >= 13'h1FC1) 	|| (readdata <= 13'h003F);
assign comp7 =  (readdata >= 13'h1F81)	|| (readdata <= 13'h007F);
assign comp8 =  (readdata >= 13'h1F01)  || (readdata <= 13'h00FF);
assign comp9 =  (readdata >= 13'h1E01)  || (readdata <= 13'h01FF);
assign comp10 = (readdata >= 13'h1C01)	|| (readdata <= 13'h03FF);
assign comp11 = (readdata >= 13'h1801)	|| (readdata <= 13'h07FF);
// assign comp12 = (readdata >= 13'h1001)	|| (readdata <= 13'h0FFF);

// chieu dai cua readdata
assign length = comp0 ? 4'h0 : comp1 ? 4'h1 : comp2  ? 4'h2 : comp3 ? 4'h3 : 
				comp4 ? 4'h4 : comp5 ? 4'h5 : comp6 ? 4'h6 : comp7 ? 4'h7 : 
				comp8 ? 4'h8 : comp9 ? 4'h9 : comp10 ? 4'ha : comp11 ? 4'hb : 4'hc;
// lay gray code				
assign mask_readdata = comp1  ? 13'h0001 : comp2  ? 13'h0003 : comp3 ? 13'h0007 : 
                       comp4  ? 13'h000F : comp5  ? 13'h001F : comp6 ? 13'h003F : 
                       comp7  ? 13'h007F : comp8  ? 13'h00FF : comp9 ? 13'h01FF : 
                       comp10 ? 13'h03FF : comp11 ? 13'h07FF : 13'h0FFF;
assign graycode_readdata = (readdata[12]) ? (~(~readdata + 13'h1)) : readdata;
// ------------------------------------------------------------------------
// Du lieu ngo ra hop le
always @ (posedge clk)
	if (~reset_n)
		outputready <= 1'b0;
	else
		outputready <= DC_enable || EOB_enable || (AC_enable && |readdata);

// Yeu cau du lieu vao
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		number_of_zeroes <= 6'h0;
		writedata_value <= 13'h0;
		writedata_RSL <= 13'h0;		
	end
	// ----------------------------------------
	// DC: writedata_RSL = 11'h0 + length
	// AC: writedata_RSL = M16zeroes + number_of_zeroes + length
	else if (DC_enable)
	begin
		writedata_value <= graycode_readdata & mask_readdata;
		writedata_RSL <= {1'b0, 2'h0, 6'h0, length};	// write run, size, length
		number_of_zeroes <= 6'h0;
	end
	
	else if (AC_enable)		
	begin			
		// neu gap 0 thi bo qua
		if (readdata == 13'h0)	
			number_of_zeroes <= number_of_zeroes + 1'b1;
		// neu gap 1 thi
		else					
		begin
			number_of_zeroes <= 6'h0;	
			writedata_value <= graycode_readdata & mask_readdata;				
			// AC: writedata_RSL = EOB + M16zeroes + number_of_zeroes + length
			//						1		2			6				 4
			if (number_of_zeroes < 6'h10)
				writedata_RSL <= {1'b0, 2'b00, number_of_zeroes, length};
			else if (number_of_zeroes > 6'h2F)
				writedata_RSL <= {1'b0, 2'b11, number_of_zeroes - 6'd48, length};
			else if (number_of_zeroes > 6'h1F)
				writedata_RSL <= {1'b0, 2'b10, number_of_zeroes - 6'd32, length};
			else if (number_of_zeroes > 6'hF)				
				writedata_RSL <= {1'b0, 2'b01, number_of_zeroes - 6'd16, length};						
		end
	end
	
	else if (EOB_enable)
		writedata_RSL <= {1'b1, 2'h0, 6'h0, 4'h0};	
end			
endmodule 
   