// ============================================================
// CONTROL UNIT
// ============================================================
module ic_gb8_control_unit (
			clk,
			reset_n,
			// Inputs
			GB8_inputready,
			IC_X_image,
			
			// Outputs
			GB8_outputready,
			MUX1_select,
			MUX2_select,
			buffer0_wren,
			buffer0_address,
			buffer1_wren,
			buffer1_address			
	);

// -------------------- InOut Declarations --------------------	
input			clk,
				reset_n,
				GB8_inputready;
input	[15:0]	IC_X_image;
output			GB8_outputready,
				MUX1_select,
				MUX2_select,
				buffer0_wren,
				buffer1_wren;
output	[12:0]	buffer0_address,
				buffer1_address;
				
// -------------------- Reg Declarations --------------------		
reg				MUX1_select,
				buffer0_rdreq,
				buffer1_rdreq,
				GB8_outputready;
reg		[12:0]	count0,
				count1;

// -------------------- Wire Declarations --------------------		
wire			buffer0_full,
				buffer0_almostfull,
				buffer0_empty,
				buffer1_full,
				buffer1_empty,
				buffer1_almostfull,
				local_enable0,
				local_enable1;
wire	[12:0]	buffer_address,
				buffer0_address,
				buffer1_address;
wire	[15:0]	IC_X_image_x3,
				IC_X_image_x6;			

// -----------------------------------------------------------
// MAIN PROCESS
// -----------------------------------------------------------
// IC_X_image: chua bao gom R, G, B
// IC_X_image: 8 dong IC_X_image bao gom R, G, B = IC_X_image * 3 * 8
// Moi lan doc vao 32 bit -> IC_X_image * 3 * 8/4
assign IC_X_image_x3 = (IC_X_image << 1'b1) + IC_X_image;
assign IC_X_image_x6 = {IC_X_image_x3[14:0], 1'b0};

assign buffer0_wren = MUX1_select && GB8_inputready;	// MUX1_select = 1
assign buffer1_wren = ~MUX1_select && GB8_inputready;	// MUX1_select = 0

assign buffer0_full = (count0 == IC_X_image_x6[12:0]);
assign buffer1_full = (count1 == IC_X_image_x6[12:0]);

assign buffer0_almostfull = (count0 == (IC_X_image_x6[12:0] - 1'b1));
assign buffer1_almostfull = (count1 == (IC_X_image_x6[12:0] - 1'b1));

assign buffer0_empty = ~(|count0);
assign buffer1_empty = ~(|count1);

assign buffer0_address = (buffer0_rdreq) ? buffer_address : count0;
assign buffer1_address = (buffer1_rdreq) ? buffer_address : count1;

assign MUX2_select = buffer0_rdreq;

assign local_enable0 = buffer0_rdreq && ~buffer0_empty;
assign local_enable1 = buffer1_rdreq && ~buffer1_empty;

// ----------------- MUX1 --------------------
always @ (posedge clk)
begin
	if (~reset_n)
		MUX1_select <= 1'b0;
	else if (GB8_inputready)
	begin
		if (buffer1_almostfull)
			MUX1_select <= 1'b1;
		else if (buffer0_almostfull)
			MUX1_select <= 1'b0;
	end
end

// ------------ readrequest --------------------
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		{buffer0_rdreq, buffer1_rdreq} <= {2{1'b0}};
		GB8_outputready <= 1'b0;
	end
	
	else
	begin
		buffer0_rdreq <= (buffer0_wren && buffer0_almostfull) ? 1'b1 : buffer0_empty ? 1'b0 : buffer0_rdreq;
		buffer1_rdreq <= (buffer1_wren && buffer1_almostfull) ? 1'b1 : buffer1_empty ? 1'b0 : buffer1_rdreq;
		GB8_outputready <= local_enable0 || local_enable1;
	end
end

// ------------ count0, count1 -----------------
always @ (posedge clk)
begin
	if (~reset_n)
		{count0, count1} <= {2{13'h0}};		
	
	else
	begin
		count0 <= (buffer0_wren) ? (count0 + 1'b1) : (local_enable0) ? (count0 - 1'b1) : count0;
		count1 <= (buffer1_wren) ? (count1 + 1'b1) : (local_enable1) ? (count1 - 1'b1) : count1;		
	end
end

ic_gb8_get_8x8_block GET_8x8_BLOCK (
			.clk			(clk),
			.reset_n		(reset_n),
			// Inputs
			.enable			(local_enable0 || local_enable1),
			.IC_X_image		(IC_X_image),
			.IC_X_image_x3	(IC_X_image_x3),
			// Outputs
			.buffer_address	(buffer_address)			
	);
		
endmodule
