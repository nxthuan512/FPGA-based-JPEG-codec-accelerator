module ic_slave_controller (
						// Inputs
						clk,
						reset_n,						
						SC_chipselect,
						SC_write,
						SC_read,
						MW_done,
						
						SC_address,						
						SC_writedata,
						
						IC_ByteCount,
						
						// Outputs
						IC_global_enable,
						MR_start,
						MW_start,
						address_inc,
						
						SC_readdata,
						src_address,
						dest_address,
						image_size,
						
						IC_NumberOfBlock,
						IC_X_image
					);

// ------------------ InOut Declarations --------------------
input			clk,
				reset_n,						
				SC_chipselect,
				SC_write,
				SC_read,
				MW_done;
input	[2:0]	SC_address;						
input 	[31:0]	SC_writedata,
				IC_ByteCount;	// 6

output			IC_global_enable,
				MR_start,
				MW_start;
output 	[2:0]  	address_inc;
output	[31:0]	SC_readdata,
				src_address,
				dest_address,
				image_size;
output	[15:0]	IC_X_image;
output	[19:0]	IC_NumberOfBlock;		
				
// ------------------ Wire Declarations -------------------
wire			GO, 
				WORD, 
				HW, 
				BYTE,
				DONE, 
				BUSY;
				
// ------------------ Reg Declarations --------------------				
// Control Registers
reg		[31:0]	src_address,		// 0
				dest_address,		// 1
				image_dimensions,	// 2 = {X_image, Y_image}
				X_image_mul_Y_image,// 3 = X_image * Y_image
				control,			// 4
				status,				// 5
				MW_lastaddress; //6

reg				MR_start,
				MW_start;				
reg     [1:0] 	state;
reg		[31:0]	SC_readdata,				
				global_timer;		// 7
// ========================================================
// Combination Logic
// ========================================================
assign {GO, WORD, HW, BYTE} = control[3:0];
assign {BUSY, DONE} = status[1:0];
assign address_inc = {WORD, HW, BYTE};

// X_image * Y_image * 3;
assign image_size = {X_image_mul_Y_image[30:0], 1'b0} + X_image_mul_Y_image;

// X_image_mul_Y_image / 32: YCrCb 4:2:2
assign IC_NumberOfBlock = (X_image_mul_Y_image == 32'h0) ? 20'hFFFFF : {X_image_mul_Y_image[24:5]};

// global enable for all of components in IC system
assign IC_global_enable = BUSY;

assign IC_X_image = image_dimensions[31:16];
// ========================================================
// Receive data from Nios
// ========================================================
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		src_address			<= 32'h0;
		dest_address		<= 32'h0;
		image_dimensions 	<= 32'h0;
		X_image_mul_Y_image	<= 32'h0;
		control				<= 32'h0;
		SC_readdata			<= 32'h0;					
	end
	
	else if (DONE)
		control <= 32'h0;
		
	else if (SC_chipselect)
	begin
		if (SC_write & ~BUSY)
			case (SC_address)
				3'h0: src_address 		<= SC_writedata;
				3'h1: dest_address		<= SC_writedata;
				3'h2: image_dimensions  <= SC_writedata;
				3'h3: X_image_mul_Y_image <= SC_writedata;
				3'h4: control 	  		<= SC_writedata;
			endcase
		
		else if (SC_read)
			case (SC_address)
				3'h5: SC_readdata <= status;		
				3'h6: SC_readdata <= MW_lastaddress;
				3'h7: SC_readdata <= global_timer;
			endcase
	end 		
end

// ========================================================
// Check time of process
// ========================================================
always @ (posedge clk)
	if (~reset_n || MW_start)
		global_timer <= 32'h0;
	else if (BUSY)
		global_timer <= global_timer + 1'b1;		

// =========================================================================
// Control MASTER READ and MASTER WRITE
// MASTER WRITE just knows whether FIFO is empty or not to get the data out
// =========================================================================
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		status <= 32'h0;
		{MR_start, MW_start} <= {2{1'b0}};
		MW_lastaddress <= 32'h0;
		state <= 2'h0;
	end
	
	else
		case (state)
			2'h0: begin
				if (GO)
				begin
					status <= 32'h2;
					{MR_start, MW_start} <= {2{1'b1}};				
					MW_lastaddress <= 32'h0;	
					state <= 2'h1;
				end
			end
			
			2'h1: begin
				{MR_start, MW_start} <= {2{1'b0}};
				if (MW_done)
				begin
					MW_lastaddress <= dest_address + IC_ByteCount;
					status <= 32'h1;
					state <= 2'h2;
				end
			end
				
			2'h2: begin
				status <= 32'h0;
				state <= 2'h0;
			end
		endcase
end

endmodule