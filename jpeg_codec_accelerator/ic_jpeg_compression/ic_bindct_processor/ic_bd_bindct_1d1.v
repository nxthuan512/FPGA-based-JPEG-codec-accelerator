// ============================================================
// BinDCT Coprocessor
// ============================================================
module ic_bd_bindct_1d1 (
					clk,
					reset_n,
					inputready,
					outputready,
					x,
					y
				);
			
// ------------ Input and Output Declaration --------------			
input 			clk, 
				reset_n,
				inputready;
input	[63:0] 	x;

output			outputready;
output	[95:0] 	y;

// ------------ Reg Decleration ----------------------------
reg  	[11:0] tmp00, tmp01, tmp02, tmp03, tmp04, tmp05, tmp06, tmp07;
reg  	[11:0] tmp20, tmp21, tmp22, tmp23, tmp24, tmp25, tmp26, tmp27;		
reg		[11:0] tmp30, tmp31, tmp32, tmp33, tmp34, tmp35, tmp36, tmp37;

reg				s1_inputready,
				s2_inputready,
				outputready;

// ------------ Wire Decleration ----------------------------
wire	[7:0] 	x0, x1, x2, x3, x4, x5, x6, x7;
wire	[11:0] tmp15, tmp16;

             
// =============================================================
// Combinational Circuit
// =============================================================
assign {x7, x6, x5, x4, x3, x2, x1, x0} = x;

assign y[11:0]  = tmp30;
assign y[23:12] = tmp37;
assign y[35:24] = tmp33;
assign y[47:36] = tmp36;
assign y[59:48] = tmp31;
assign y[71:60] = tmp35;
assign y[83:72] = tmp32;
assign y[95:84] = tmp34;  

// ------------- state 1 ------------------
	// 5/8 = 1/2 + 1/8
	// 49/64 = 1/2 + 1/4 + 1/64
assign	tmp15 = (~reset_n) ? 12'h0 : 
               {tmp06[11], tmp06[11:1]} + {{3{tmp06[11]}}, tmp06[11:3]} - 
           			 {tmp05[11], tmp05[11:1]} - {{2{tmp05[11]}}, tmp05[11:2]} - 
           			 {{6{tmp05[11]}}, tmp05[11:6]}; 
	// 3/8 = 1/4 + 1/8
assign	tmp16 = (~reset_n) ? 12'h0 : 
               tmp06 + {{2{tmp05[11]}}, tmp05[11:2]} + {{3{tmp05[11]}}, tmp05[11:3]};
	  
// =============================================================
// Main Process
// Solve those problems
//   + Shift right a negative number -> the MSB is always 0
//   + Bit numbers in addition and subtraction
// =============================================================
// ------------------ Output Ready -------------------
always @ (posedge clk)
	if (~reset_n)
		{s1_inputready, s2_inputready, outputready} <= 3'h0;
	else
	begin
		s1_inputready	<= inputready;
		s2_inputready	<= s1_inputready;
		outputready		<= s2_inputready;
	end

// -------------- BinDCT Processor -------------------
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		{tmp00, tmp01, tmp02, tmp03, tmp04, tmp05, tmp06, tmp07} <= {8{11'h0}};
		{tmp20, tmp21, tmp22, tmp23, tmp24, tmp25, tmp26, tmp27} <= {8{11'h0}};
		{tmp30, tmp31, tmp32, tmp33, tmp34, tmp35, tmp36, tmp37} <= {8{11'h0}};
	end
		
	else 
	begin
		if (inputready)
		begin
			// -------------- state 0 --------------
			tmp00 <= {{4{x0[7]}}, x0} + {{4{x7[7]}}, x7};
			tmp07 <= {{4{x0[7]}}, x0} - {{4{x7[7]}}, x7};
			tmp01 <= {{4{x1[7]}}, x1} + {{4{x6[7]}}, x6};
			tmp06 <= {{4{x1[7]}}, x1} - {{4{x6[7]}}, x6};
			tmp02 <= {{4{x2[7]}}, x2} + {{4{x5[7]}}, x5};
			tmp05 <= {{4{x2[7]}}, x2} - {{4{x5[7]}}, x5};
			tmp03 <= {{4{x3[7]}}, x3} + {{4{x4[7]}}, x4};
			tmp04 <= {{4{x3[7]}}, x3} - {{4{x4[7]}}, x4};
		end
		
		// ------------- state 2 -----------------
		tmp20 <= tmp00 + tmp03;
		tmp21 <= tmp01 + tmp02;
		tmp22 <= tmp01 - tmp02;
		tmp23 <= tmp00 - tmp03;
		tmp24 <= tmp04 + tmp15;
		tmp25 <= tmp04 - tmp15;
		tmp26 <= tmp07 - tmp16;
		tmp27 <= tmp07 + tmp16;
				
		// ------------- state 3 -----------------
		tmp30 <= tmp20 + tmp21;
		// 1/2
		tmp31 <= {tmp20[11], tmp20[11:1]} - {tmp21[11], tmp21[11:1]};
		// 3/8 = 1/4 + 1/8
		tmp32 <= tmp22 - {{2{tmp23[11]}}, tmp23[11:2]} - {{3{tmp23[11]}}, tmp23[11:3]};
		// 3/8= 1/4 + 1/8
		// 55/64 = 1 - 1/8 - 1/64
		tmp33 <= {{2{tmp22[11]}}, tmp22[11:2]} + {{3{tmp22[11]}}, tmp22[11:3]} +
		tmp23 - {{3{tmp23[11]}}, tmp23[11:3]} - {{6{tmp23[11]}}, tmp23[11:6]};
		// 1/8
		tmp34 <= tmp24 - {{3{tmp27[11]}}, tmp27[11:3]};
		// 7/8 = 1 - 1/8
		tmp35 <= tmp25 + tmp26 - {{3{tmp26[11]}}, tmp26[11:3]};
		// 9/16 = 1/2 + 1/16
		// 1/2
		tmp36 <= {tmp26[11], tmp26[11:1]} + {{4{tmp26[11]}}, tmp26[11:4]} - 
				 {tmp25[11], tmp25[11:1]};
		tmp37 <= tmp27;		
	end
		
end

endmodule 
