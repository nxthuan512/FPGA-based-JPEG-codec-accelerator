// *******************************************************************
// HUFFMAN CONTROL UNIT
// *******************************************************************
module ic_hc_control_unit (
				clk,
				reset_n,
				// Inputs
				IC_NumberOfBlock,
				ff0_empty,
				ff0_full,
				ff1_empty,
				ff1_full,
				ff0_almost_empty,
				ff0_almost_full,
				PTS_outputready,
				ack_pre_IC_EndOfImage,
				ff1_q,
				// Outputs
				IC_EndOfImage,
				pre_IC_EndOfImage,
				ff0_rdreq,
				ff1_rdreq,
				PTS_enable,
				DC_enable,
				AC_enable,
				EOB_enable,
				DIFF_enable,
				MUX_select,
				ff0_wait_request
			);

// ----------------------- In Out -------------------------
input			clk,
				reset_n,
				ff0_empty,
				ff0_full,				
				ff1_empty,
				ff1_full,
				ff0_almost_empty,
				ff0_almost_full,				
				PTS_outputready,
				ack_pre_IC_EndOfImage;
input	[5:0]	ff1_q;
input	[19:0]	IC_NumberOfBlock;

output			ff0_rdreq,
				ff1_rdreq,
				PTS_enable,
				DC_enable,
				AC_enable,
				EOB_enable,
				IC_EndOfImage,
				pre_IC_EndOfImage,
				ff0_wait_request;
output [1:0]	MUX_select;
output [2:0]  	DIFF_enable;

// MUX_select = 00: DCY
//              01: ACY
//              10: DCCb
//              11: ACCb              
				
// ----------------------- Reg -------------------------	
reg				PTS_enable,
				s1_PTS_enable,
				IC_EndOfImage,
				pre_IC_EndOfImage,
				ff0_wait_request;
reg  	[1:0] 	select_YCb,
				MUX_select;
reg		[2:0]	state;
reg		[5:0]	count;
reg  	[19:0] 	block_count;

// ----------------------- Wire -------------------------			
wire	[5:0] 	EOB;				

assign EOB = ff1_q;
assign ff0_rdreq = ~|state && ~ff0_empty;
assign ff1_rdreq = ~|state && ~ff0_empty && (~|count);

assign DC_enable = (~|count) && PTS_outputready;
assign AC_enable = (|count) && PTS_outputready;
assign EOB_enable = (state == 3'h3);

// -------------- DIFF enable ------------------
// chon Y, Cb, Cr =  001  010 100
// selecy_YCb     = 00 01 10  11
assign DIFF_enable = (~select_YCb[1]) ? {2'h0, (~|count) && PTS_enable && ~s1_PTS_enable} : 
                     (~select_YCb[0]) ? {1'b0, (~|count) && PTS_enable && ~s1_PTS_enable, 1'b0} :
                     (select_YCb[0]) ? {(~|count) && PTS_enable && ~s1_PTS_enable, 2'h0} : DIFF_enable;
always @ (posedge clk)
	s1_PTS_enable <= PTS_enable;

always @ (posedge clk)
begin
	if (~reset_n)
		ff0_wait_request <= 1'b0;
	else if (ff0_almost_full) 
		ff0_wait_request <= 1'b1;
	else if (ff0_almost_empty)
		ff0_wait_request <= 1'b0;		
end

// ------------------ MUX ------------------------
// 00: DCY  01: ACY  10: DCCb  11: ACCb
always @ (posedge clk)
	if (~reset_n)
		MUX_select <= 2'h0;
	else
		MUX_select <= DC_enable ? {1'b0, select_YCb[1]} : 
					 (AC_enable || EOB_enable) ? {1'b1, select_YCb[1]} : MUX_select;
                  
// --------------- select Y or Cb --------------------
// select[1]: Cb, ~select[1]: Y
always @ (posedge clk)
	if (~reset_n)
	begin
		select_YCb <= 2'h0;
		block_count <= 20'h0;
	end
	else if (EOB_enable)
	begin
		select_YCb <= select_YCb + 1'b1;
		block_count <= block_count + 1'b1;
	end

// --------------- bat End of Image --------------------
always @ (posedge clk)  
	if (~reset_n)
		pre_IC_EndOfImage <= 1'b0;
	else if ((block_count == IC_NumberOfBlock) && ff0_empty && ff1_empty)
		pre_IC_EndOfImage <= 1'b1;

always @ (posedge clk)  
	if (~reset_n)
		IC_EndOfImage <= 1'b0;
	else if ((block_count == IC_NumberOfBlock) && ack_pre_IC_EndOfImage)
		IC_EndOfImage <= 1'b1;
		
// -------- counter quan li EOB, AC, DC -----------------
always @ (posedge clk)
	if (~reset_n || EOB_enable)
		count <= 6'h0;
	else if (PTS_outputready)
		count <= count + 1'b1;

// --------- Yeu cau FIFO0, FIFO1 va kiem tra ------------
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		PTS_enable <= 1'b0;
		state <= 3'h0;
	end
	// neu da check eob xong -> ff1 ko rong
	else
	begin
		case (state)
			3'h0: begin
				state <= {2'b00, ~ff0_empty};		
				PTS_enable <= ~ff0_empty;
			end
			
			3'h1: if (PTS_outputready)
			begin
				// neu EOB = 0: xuat DC_enable roi EOB_enable
				if (count == EOB)
				begin
					PTS_enable <= 1'b0;
					state <= 3'h2;
				end
				
				else if (count == 6'd7 || count == 6'd15 || count == 6'd23 || count == 6'd31 || count == 6'd39 || count == 6'd47 || count == 6'd55)
				begin
					PTS_enable <= 1'b0;
					state <= 3'h0;
				end
				
				else if (count == 6'd63)
				begin
					PTS_enable <= 1'b0;
					state <= 3'h0;
				end
			end
			
			3'h2: state <= 3'h3;
			// turn on EOB
			3'h3: state <= 3'h0;
		endcase
	end
end

endmodule 
