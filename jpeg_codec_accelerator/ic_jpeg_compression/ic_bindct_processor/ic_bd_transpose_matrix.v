// ============================================================
// Transpose Matrix
// ============================================================
module ic_bd_transpose_matrix (
							clk,
							reset_n,
							writerequest,
							readrequest,
							empty,
							full,
							x,
							y
						);
					
// ------------ Input and Output Declaration --------------			
input 			clk,
				reset_n,
				writerequest,
				readrequest;
input	[95:0]	x;

output			empty,
				full;
output	[95:0]	y;
				
// ------------ Reg Declaration --------------
reg		[3:0]	address;
reg		[95:0]	y;
reg		[11:0] 	ram_y [0:63];

// =========================================================
// Combinational Circuit
// =========================================================
assign empty = ~|address;
assign full = address[3];

// =========================================================
// Main process
// =========================================================
// ------------ address TM ---------------
always @ (posedge clk)
	if (~reset_n)
		address <= 4'h0;
	else if (writerequest & ~full)
		address <= address + 1'b1;
	else if (readrequest & ~empty)
		address <= address - 1'b1;		

// --------- readrequest - writerequest --------		
always @ (posedge clk)
begin
	if (writerequest)
		case (address)
			3'b000: {ram_y[0], ram_y[8],  ram_y[16], ram_y[24], ram_y[32], ram_y[40], ram_y[48], ram_y[56]} <= x;			
			3'b001: {ram_y[1], ram_y[9],  ram_y[17], ram_y[25], ram_y[33], ram_y[41], ram_y[49], ram_y[57]} <= x;				
			3'b010: {ram_y[2], ram_y[10], ram_y[18], ram_y[26], ram_y[34], ram_y[42], ram_y[50], ram_y[58]} <= x;			
			3'b011: {ram_y[3], ram_y[11], ram_y[19], ram_y[27], ram_y[35], ram_y[43], ram_y[51], ram_y[59]} <= x;			
			3'b100: {ram_y[4], ram_y[12], ram_y[20], ram_y[28], ram_y[36], ram_y[44], ram_y[52], ram_y[60]} <= x;			
			3'b101: {ram_y[5], ram_y[13], ram_y[21], ram_y[29], ram_y[37], ram_y[45], ram_y[53], ram_y[61]} <= x;			
			3'b110: {ram_y[6], ram_y[14], ram_y[22], ram_y[30], ram_y[38], ram_y[46], ram_y[54], ram_y[62]} <= x;			
			3'b111: {ram_y[7], ram_y[15], ram_y[23], ram_y[31], ram_y[39], ram_y[47], ram_y[55], ram_y[63]} <= x;
		endcase
		
	if (readrequest) // xet tu 8 -> 1
		case (address)
			3'b001: y <= {ram_y[0],  ram_y[1],  ram_y[2],  ram_y[3],  ram_y[4],  ram_y[5],  ram_y[6],  ram_y[7]};			
			3'b010: y <= {ram_y[8],  ram_y[9],  ram_y[10], ram_y[11], ram_y[12], ram_y[13], ram_y[14], ram_y[15]};			
			3'b011: y <= {ram_y[16], ram_y[17], ram_y[18], ram_y[19], ram_y[20], ram_y[21], ram_y[22], ram_y[23]};						
			3'b100: y <= {ram_y[24], ram_y[25], ram_y[26], ram_y[27], ram_y[28], ram_y[29], ram_y[30], ram_y[31]};									
			3'b101: y <= {ram_y[32], ram_y[33], ram_y[34], ram_y[35], ram_y[36], ram_y[37], ram_y[38], ram_y[39]};									
			3'b110: y <= {ram_y[40], ram_y[41], ram_y[42], ram_y[43], ram_y[44], ram_y[45], ram_y[46], ram_y[47]};									
			3'b111: y <= {ram_y[48], ram_y[49], ram_y[50], ram_y[51], ram_y[52], ram_y[53], ram_y[54], ram_y[55]};
			4'b1000: y <= {ram_y[56], ram_y[57], ram_y[58], ram_y[59], ram_y[60], ram_y[61], ram_y[62], ram_y[63]};												
		endcase
end
endmodule
