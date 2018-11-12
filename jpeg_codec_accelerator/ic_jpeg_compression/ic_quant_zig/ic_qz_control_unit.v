module ic_qz_control_unit
			(
				clk,
				reset_n,
				// Inputs
				ff_empty,
				ff_full,
				x,
				// Outputs
				ff_rdreq,
				outputready,
				y
			);
					
// ------------ Input and Output Declaration --------------			
input 			clk,
				reset_n,
				ff_empty,
				ff_full;
input	[127:0]	x;

output			ff_rdreq,
				outputready;
output	[103:0]	y;
				
// ------------ Wire Declaration -------------
wire    		tabY_full, 
				tabY_empty,
				tabCr_full, 
				tabCr_empty;
wire	[12:0]	op_b7, op_b6, op_b5, op_b4, op_b3, op_b2, op_b1, op_b0;
wire 	[12:0] 	p1_ram_y7, p1_ram_y6, p1_ram_y5, p1_ram_y4, p1_ram_y3, p1_ram_y2, p1_ram_y1, p1_ram_y0;
wire	[15:0]	op_a7, op_a6, op_a5, op_a4, op_a3, op_a2, op_a1, op_a0;
wire	[28:0]	re_7, re_6, re_5, re_4, re_3, re_2, re_1, re_0;
wire	[103:0]	p1_ram_y;

// ------------ Reg Declaration --------------
reg				tabY_rdreq,
				tabCr_rdreq,
				tabY_wreq,
				tabCr_wreq,
				outputready;
reg     [1:0]	rdreq_state,
				ff_rdreq_state;
reg   	[1:0] 	select_tabYCrCb;
reg		[3:0]   wreq_state;
reg  [2:0]			quantCoefTable_address;
reg		[3:0]	quantTableY_address,
				quantTableCr_address,
				count;
reg 	[12:0] 	ram_y7, ram_y6, ram_y5, ram_y4, ram_y3, ram_y2, ram_y1, ram_y0;
reg		[12:0] 	ram_Y [0:63];
reg		[12:0] 	ram_Cr [0:63];
reg		[103:0]	op_b,
				y;
                 
// ======================================================
// readrequest
// ======================================================

always @ (posedge clk)
begin
	if (~reset_n)
	begin
		outputready <= 1'b0;
		rdreq_state <= 2'h0;
		{tabY_rdreq, tabCr_rdreq} <= 2'h0;
	end
		
	else
	begin
		case (rdreq_state)
			2'h0: begin
				if (tabY_full)
					{rdreq_state, tabY_rdreq} <= 3'b011;
				else if (tabCr_full)
					{rdreq_state, tabCr_rdreq} <= 3'b101;
			end
			
			2'h1: begin
				outputready <= 1'b1;
				if (tabY_empty)
					{outputready, tabY_rdreq, rdreq_state} <= 3'b000;
			end
			
			2'h2: begin
				outputready <= 1'b1;
				if (tabCr_empty)
					{outputready, tabCr_rdreq, rdreq_state} <= 3'b000;
			end
		endcase
	end
end

// ======================================================
// writerequest
// ======================================================
assign {op_a7, op_a6, op_a5, op_a4, op_a3, op_a2, op_a1, op_a0} = x;

// ======================================================
// SIMULATION ONLY
// Do LPM_ALT ton 2 clk nhung trong Modelsim chi ton 1 clk
// nen delay de thuc thi trong mo phong
// ======================================================
assign ff_rdreq = (~ff_empty && ~count[3] && ~|ff_rdreq_state);

// ------------------------------------------
always @ (posedge clk)
begin
  if (~reset_n)
  begin
    count <= 4'h0;
    ff_rdreq_state <= 2'h0;
    select_tabYCrCb <= 2'h0;
  end

  else
  begin
    case (ff_rdreq_state)  
      2'h0: begin
        if (~ff_empty)           
          count <= count + 1'b1;
        if (count[3])   
        begin  
          ff_rdreq_state <= 2'h1;
          
        end
      end
      
      2'h1: begin
        count <= 4'h0;
        if (~tabY_empty) 
          ff_rdreq_state <= 2'h2;
        else 
          ff_rdreq_state <= 2'h3;    
      end
      
      2'h2: begin
        if (tabY_empty) 
        begin
          ff_rdreq_state <= 2'h0;    
          select_tabYCrCb <= select_tabYCrCb + 1'b1;
        end
      end    
      
      2'h3: begin
        if (tabCr_empty)
        begin 
          ff_rdreq_state <= 2'h0;    
          select_tabYCrCb <= select_tabYCrCb + 1'b1;
        end
      end
    endcase
  end
end

// ---------- empty or full -----------------
assign tabY_full = quantTableY_address[3];
assign tabY_empty = ~|quantTableY_address;

assign tabCr_full = quantTableCr_address[3];
assign tabCr_empty = ~|quantTableCr_address;

// -------------------------------------------
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		wreq_state <= 4'h0;
		quantCoefTable_address <= 3'h0;
		{tabY_wreq, tabCr_wreq} <= 2'h0;
	end
	
	else
	begin
		wreq_state <= {wreq_state[2:0], ff_rdreq};			
		if (ff_rdreq)
			quantCoefTable_address <= quantCoefTable_address + 1'b1;	
		
		// wreq_state[0]: da co op_a va op_b
		// wreq_state[1]: luu buffer
		// wreq_state[2]: bat writerequest den Cr, Y
		tabY_wreq <= ~select_tabYCrCb[1] && wreq_state[1];
		tabCr_wreq <= select_tabYCrCb[1] && wreq_state[1];
		// wreq_state[3]: co ket qua re
	end
end

// -------------- bang tra he so luong tu --------------------
assign {op_b0, op_b1, op_b2, op_b3, op_b4, op_b5, op_b6, op_b7} = op_b;

always @ (posedge clk)
begin
	op_b <= 
		// Y table
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b0000) ? 104'h1FC1E4CDCE7A83818C7435413A :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b0001) ? 104'h3C9AB693CA8924208BFC3C0163 : 
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b0010) ? 104'h4CE279526877628D0830344169 :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b0011) ? 104'h35B1EE8DB26191ED87F8338189 :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b0100) ? 104'h2A39C009B44271DE0750334194 :              
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b0101) ? 104'h0EF87743F41730AE836419C10A :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b0110) ? 104'h0CD08003A41C50CD03701D011C :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b0111) ? 104'h0B689184D426C122048424413A :
		// CrCb table
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b1000) ? 104'h1C3944C8182420A303001AA0E2 : 
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b1001) ? 104'h28997E8AC025E0EB0454266146 :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b1010) ? 104'h20615805521A90F9849828C15A :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b1011) ? 104'h12109783521D811505182D6181 :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b1100) ? 104'h0A307583E622A14606003541C4 :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b1101) ? 104'h060045424C1460C003881F610A :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b1110) ? 104'h06A84CC28C16B0D503EC22E128 :
		({select_tabYCrCb[1], quantCoefTable_address} == 4'b1111) ? 104'h07105182B41810E2042825013A : op_b;
end

// ======================================================
// Write to RAM
// ======================================================
// -----------------------------------------------------
assign p1_ram_y7 = re_7[28:16] + re_7[28];
assign p1_ram_y6 = re_6[28:16] + re_6[28];
assign p1_ram_y5 = re_5[28:16] + re_5[28];
assign p1_ram_y4 = re_4[28:16] + re_4[28];
assign p1_ram_y3 = re_3[28:16] + re_3[28];
assign p1_ram_y2 = re_2[28:16] + re_2[28];
assign p1_ram_y1 = re_1[28:16] + re_1[28];
assign p1_ram_y0 = re_0[28:16] + re_0[28];

always @ (posedge clk)
begin
	if (~reset_n)
		{ram_y0, ram_y1, ram_y2, ram_y3, ram_y4, ram_y5, ram_y6, ram_y7} <= {8{13'h0}};
	
	else if (wreq_state[1])
	begin
		ram_y0 <= p1_ram_y0;
		ram_y1 <= p1_ram_y1;
		ram_y2 <= p1_ram_y2;
		ram_y3 <= p1_ram_y3;
		ram_y4 <= p1_ram_y4;
		ram_y5 <= p1_ram_y5;
		ram_y6 <= p1_ram_y6;
		ram_y7 <= p1_ram_y7;
	end
end	

// ---------- control writedata & readdata -----------
assign p1_ram_y = {ram_y0, ram_y1, ram_y2, ram_y3, ram_y4, ram_y5, ram_y6, ram_y7};

always @ (posedge clk)
begin
	if (~reset_n)
		{quantTableY_address, quantTableCr_address} <= {2{3'h0}};		
	else 
	begin		
		// ----------- writerequest ---------------			
		if (tabY_wreq)	// state = 0, 1
		begin
			quantTableY_address <= (~tabY_full) ? (quantTableY_address + 1'b1) : quantTableY_address;			
			case (quantTableY_address)
				3'b000: {ram_Y[0], ram_Y[2],  ram_Y[3],  ram_Y[9],  ram_Y[10], ram_Y[20], ram_Y[21], ram_Y[35]}<= p1_ram_y;
				3'b001: {ram_Y[1], ram_Y[4],  ram_Y[8],  ram_Y[11], ram_Y[19], ram_Y[22], ram_Y[34], ram_Y[36]}<= p1_ram_y;
				3'b010: {ram_Y[5], ram_Y[7],  ram_Y[12], ram_Y[18], ram_Y[23], ram_Y[33], ram_Y[37], ram_Y[48]}<= p1_ram_y;						
				3'b011: {ram_Y[6], ram_Y[13], ram_Y[17], ram_Y[24], ram_Y[32], ram_Y[38], ram_Y[47], ram_Y[49]}<= p1_ram_y;				
				3'b100: {ram_Y[14],ram_Y[16], ram_Y[25], ram_Y[31], ram_Y[39], ram_Y[46], ram_Y[50], ram_Y[57]}<= p1_ram_y;
				3'b101: {ram_Y[15],ram_Y[26], ram_Y[30], ram_Y[40], ram_Y[45], ram_Y[51], ram_Y[56], ram_Y[58]}<= p1_ram_y;
				3'b110: {ram_Y[27],ram_Y[29], ram_Y[41], ram_Y[44], ram_Y[52], ram_Y[55], ram_Y[59], ram_Y[62]}<= p1_ram_y;				
				3'b111: {ram_Y[28],ram_Y[42], ram_Y[43], ram_Y[53], ram_Y[54], ram_Y[60], ram_Y[61], ram_Y[63]}<= p1_ram_y;				
			endcase
		end
		else if (tabCr_wreq)	// state = 2, 3
		begin
			quantTableCr_address <= (~tabCr_full) ? (quantTableCr_address + 1'b1) : quantTableCr_address;			
			case (quantTableCr_address)
				3'b000: {ram_Cr[0], ram_Cr[2],  ram_Cr[3],  ram_Cr[9],  ram_Cr[10], ram_Cr[20], ram_Cr[21], ram_Cr[35]}<= p1_ram_y;
				3'b001: {ram_Cr[1], ram_Cr[4],  ram_Cr[8],  ram_Cr[11], ram_Cr[19], ram_Cr[22], ram_Cr[34], ram_Cr[36]}<= p1_ram_y;
				3'b010: {ram_Cr[5], ram_Cr[7],  ram_Cr[12], ram_Cr[18], ram_Cr[23], ram_Cr[33], ram_Cr[37], ram_Cr[48]}<= p1_ram_y;						
				3'b011: {ram_Cr[6], ram_Cr[13], ram_Cr[17], ram_Cr[24], ram_Cr[32], ram_Cr[38], ram_Cr[47], ram_Cr[49]}<= p1_ram_y;				
				3'b100: {ram_Cr[14],ram_Cr[16], ram_Cr[25], ram_Cr[31], ram_Cr[39], ram_Cr[46], ram_Cr[50], ram_Cr[57]}<= p1_ram_y;
				3'b101: {ram_Cr[15],ram_Cr[26], ram_Cr[30], ram_Cr[40], ram_Cr[45], ram_Cr[51], ram_Cr[56], ram_Cr[58]}<= p1_ram_y;
				3'b110: {ram_Cr[27],ram_Cr[29], ram_Cr[41], ram_Cr[44], ram_Cr[52], ram_Cr[55], ram_Cr[59], ram_Cr[62]}<= p1_ram_y;				
				3'b111: {ram_Cr[28],ram_Cr[42], ram_Cr[43], ram_Cr[53], ram_Cr[54], ram_Cr[60], ram_Cr[61], ram_Cr[63]}<= p1_ram_y;				
			endcase
		end
		
		// ----------- readrequest ---------------	
		if (tabY_rdreq) // xet tu 8 -> 1
		begin
			quantTableY_address <= (~tabY_empty) ? (quantTableY_address - 1'b1) : quantTableY_address;
			case (quantTableY_address)
				3'b001:  y <=  {ram_Y[63], ram_Y[62], ram_Y[61], ram_Y[60], ram_Y[59], ram_Y[58], ram_Y[57], ram_Y[56]};				
				3'b010:  y <=  {ram_Y[55], ram_Y[54], ram_Y[53], ram_Y[52], ram_Y[51], ram_Y[50], ram_Y[49], ram_Y[48]};
				3'b011:  y <=  {ram_Y[47], ram_Y[46], ram_Y[45], ram_Y[44], ram_Y[43], ram_Y[42], ram_Y[41], ram_Y[40]};
				3'b100:  y <=  {ram_Y[39], ram_Y[38], ram_Y[37], ram_Y[36], ram_Y[35], ram_Y[34], ram_Y[33], ram_Y[32]};
				3'b101:  y <=  {ram_Y[31], ram_Y[30], ram_Y[29], ram_Y[28], ram_Y[27], ram_Y[26], ram_Y[25], ram_Y[24]};
				3'b110:  y <=  {ram_Y[23], ram_Y[22], ram_Y[21], ram_Y[20], ram_Y[19], ram_Y[18], ram_Y[17], ram_Y[16]};
				3'b111:  y <=  {ram_Y[15], ram_Y[14], ram_Y[13], ram_Y[12], ram_Y[11], ram_Y[10], ram_Y[9],  ram_Y[8]};
				4'b1000: y <=  {ram_Y[7],  ram_Y[6],  ram_Y[5],  ram_Y[4],  ram_Y[3],  ram_Y[2],  ram_Y[1],  ram_Y[0]};				
			endcase
		end
			
		else if (tabCr_rdreq)
		begin
			quantTableCr_address <= (~tabCr_empty) ? (quantTableCr_address - 1'b1) : quantTableCr_address;
			case (quantTableCr_address)
				3'b001:  y <=  {ram_Cr[63], ram_Cr[62], ram_Cr[61], ram_Cr[60], ram_Cr[59], ram_Cr[58], ram_Cr[57], ram_Cr[56]};				
				3'b010:  y <=  {ram_Cr[55], ram_Cr[54], ram_Cr[53], ram_Cr[52], ram_Cr[51], ram_Cr[50], ram_Cr[49], ram_Cr[48]};
				3'b011:  y <=  {ram_Cr[47], ram_Cr[46], ram_Cr[45], ram_Cr[44], ram_Cr[43], ram_Cr[42], ram_Cr[41], ram_Cr[40]};
				3'b100:  y <=  {ram_Cr[39], ram_Cr[38], ram_Cr[37], ram_Cr[36], ram_Cr[35], ram_Cr[34], ram_Cr[33], ram_Cr[32]};
				3'b101:  y <=  {ram_Cr[31], ram_Cr[30], ram_Cr[29], ram_Cr[28], ram_Cr[27], ram_Cr[26], ram_Cr[25], ram_Cr[24]};
				3'b110:  y <=  {ram_Cr[23], ram_Cr[22], ram_Cr[21], ram_Cr[20], ram_Cr[19], ram_Cr[18], ram_Cr[17], ram_Cr[16]};
				3'b111:  y <=  {ram_Cr[15], ram_Cr[14], ram_Cr[13], ram_Cr[12], ram_Cr[11], ram_Cr[10], ram_Cr[9],  ram_Cr[8]};
				4'b1000: y <=  {ram_Cr[7],  ram_Cr[6],  ram_Cr[5],  ram_Cr[4],  ram_Cr[3],  ram_Cr[2],  ram_Cr[1],  ram_Cr[0]};				
			endcase
		end
	end
end

// ----------- call functions --------------
ic_qz_mult QZ_Y_MULT7(
			.aclr		(~reset_n),
			.clken		(wreq_state[0] || wreq_state[1]),
			.clock		(clk),
			.dataa		(op_a7),
			.datab		(op_b7),
			.result		(re_7)
		);
		
ic_qz_mult QZ_Y_MULT6(
			.aclr		(~reset_n),
			.clken		(wreq_state[0] || wreq_state[1]),
			.clock		(clk),
			.dataa		(op_a6),
			.datab		(op_b6),
			.result		(re_6)
		);
		
ic_qz_mult QZ_Y_MULT5(
			.aclr		(~reset_n),
			.clken		(wreq_state[0] || wreq_state[1]),
			.clock		(clk),
			.dataa		(op_a5),
			.datab		(op_b5),
			.result		(re_5)
		);
		
ic_qz_mult QZ_Y_MULT4(
			.aclr		(~reset_n),
			.clken		(wreq_state[0] || wreq_state[1]),
			.clock		(clk),
			.dataa		(op_a4),
			.datab		(op_b4),
			.result		(re_4)
		);
		
ic_qz_mult QZ_Y_MULT3(
			.aclr		(~reset_n),
			.clken		(wreq_state[0] || wreq_state[1]),
			.clock		(clk),
			.dataa		(op_a3),
			.datab		(op_b3),
			.result		(re_3)
		);

ic_qz_mult QZ_Y_MULT2(
			.aclr		(~reset_n),
			.clken		(wreq_state[0] || wreq_state[1]),
			.clock		(clk),
			.dataa		(op_a2),
			.datab		(op_b2),
			.result		(re_2)
		);
		
ic_qz_mult QZ_Y_MULT1(
			.aclr		(~reset_n),
			.clken		(wreq_state[0] || wreq_state[1]),
			.clock		(clk),
			.dataa		(op_a1),
			.datab		(op_b1),
			.result		(re_1)
		);
		
ic_qz_mult QZ_Y_MULT0(
			.aclr		(~reset_n),
			.clken		(wreq_state[0] || wreq_state[1]),
			.clock		(clk),
			.dataa		(op_a0),
			.datab		(op_b0),
			.result		(re_0)
		);
	
endmodule
