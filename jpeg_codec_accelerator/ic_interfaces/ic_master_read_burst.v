// Doc tu PSRAM, moi burst 16 phan tu -> oBurst_length = 16
// MASTER_READ ho tro toi da burst 128

module ic_master_read_burst (
							iClk,
							iReset_n,
							// Inputs 
							iStart,
							iRead_data_valid,
							iWait_request,
							iFF_almost_full,
							HC_ff0_wait_request,
							R2Y_waitrequest,
							
							iStart_read_address,
							iLength,
							iRead_data,
							
							// Outputs
							oRead,
							oRead_address,
							oFF_write_request,
							oBurst_length,
							oWrite_data								
						);
							
parameter			BURST_LENGTH 		= 8'd64;
parameter			ADDRESS_INC 		= 4;
localparam			BURST_ADDRESS_INC 	= (BURST_LENGTH * ADDRESS_INC);
// ============================================
// Input/Output Declarations
// ============================================
input				iClk,
					iReset_n;
// Inputs 
input				iStart,
					iRead_data_valid,
					iWait_request,
					iFF_almost_full;
input				HC_ff0_wait_request,
					R2Y_waitrequest;
input	[31:0]		iStart_read_address,
					iLength;
input	[31:0]		iRead_data;

output				oRead;
output				oFF_write_request;
output	[7:0]		oBurst_length;
output	[31:0]		oRead_address;
output	[31:0]		oWrite_data;

// ============================================
// Wire Declarations
// ============================================
wire				read_data_valid;

// ============================================
// Reg Declarations
// ============================================
reg					oRead,
					oFF_write_request;
reg		[1:0]		state;
reg		[7:0]		burst_count;
reg		[31:0]		end_read_address,
					oRead_address,
					oWrite_data;

// ========================================================
// Main Process
// ========================================================
assign oBurst_length   = BURST_LENGTH;
assign read_data_valid = iRead_data_valid && (oRead_address <= end_read_address);

///
always @ (posedge iClk)
begin
	if (~iReset_n)
	begin
		oWrite_data 		<= 32'h0;
		oFF_write_request	<= 1'b0;
	end
	
	else
	begin
		oWrite_data 		<= read_data_valid ? iRead_data : oWrite_data;
		oFF_write_request 	<= read_data_valid;
	end
end

/////
always @ (posedge iClk)
begin
	if (~iReset_n)
	begin
		oRead				<= 1'b0;
		oRead_address 		<= 32'h0;	
		burst_count			<= 8'h0;
		end_read_address 	<= 32'h0;
		state				<= 2'h0;
	end
	
	else 
		case (state)
			// bat dau START
			2'h0: if (iStart)
			begin
				oRead				<= 1'b1;
				oRead_address 		<= iStart_read_address;				
				end_read_address 	<= iStart_read_address + iLength - ADDRESS_INC;
				state				<= 2'h1;
			end	
			
			// neu wait_request ngung xac lap -> co du lieu hop le
			// doi doc du BURST_LENGTH du lieu tu slave gui ve
			2'h1: begin
				if (~iWait_request)
				begin
					oRead				<= 1'b0;
					if (burst_count == BURST_LENGTH)
					begin
						oRead_address	<= oRead_address + BURST_ADDRESS_INC;
						burst_count		<= 8'h0;
						state			<= 2'h2;
					end
				end
				if (iRead_data_valid)
					burst_count		<= burst_count + 1'b1;				
			end
			
			// Kiem tra dk stop, neu chua stop thi nhay len 1, stop thi nhay ve 3
			2'h2: begin
				if (oRead_address > end_read_address)
					state			<= 2'h3;
				else if (~iFF_almost_full && ~(HC_ff0_wait_request || R2Y_waitrequest))
				begin
					oRead				<= 1'b1;
					state				<= 2'h1;
				end
			end
			
			// Done, da doc xong LENGTH phan tu 
			2'h3: begin				
					oRead				<= 1'b0;
					oRead_address 		<= 32'h0;
					end_read_address 	<= 32'h1;		
					state				<= 2'h0;
			end

			default:;			
		endcase
end

endmodule
