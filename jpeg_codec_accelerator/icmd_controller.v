// ****************************************************************
// Copyright @ by NXT
// Ideas: 
//			DDR2 --> IC_MR --> FF1 --> IC --> FF2 --> IC_MW --> DDR2
//					   	  --> Grayscale --> MD_MR --> Buffer 640x40 --> MD_MW --> MD			
// ****************************************************************
`include "./ic_interfaces/ic_global_ff1.v"
`include "./ic_interfaces/ic_global_ff2.v"
`include "./ic_interfaces/ic_slave_controller.v"
`include "./ic_interfaces/ic_master_read_burst.v"
`include "./ic_interfaces/ic_master_write.v"

`include "./ic_jpeg_compression/ic_jpeg_compression.v"

module icmd_controller (
						// Global signals
						clk,
						reset_n,
						
						// Slave Control Signals
						// Input
						IC_SC_chipselect,
						IC_SC_write,
						IC_SC_read,						
						IC_SC_address,
						IC_SC_writedata,
						
						// Output
						IC_SC_readdata,
						
						// Master Read Signals
						// Input
						IC_MR_readdatavalid,
						IC_MR_waitrequest,
						IC_MR_readdata,
						oBurst_length,
						
						// Output
						IC_MR_read,
						IC_MR_readaddress,						
						
						// Master Write Signals
						// Input
						IC_MW_waitrequest,
						
						// Output
						IC_MW_write,
						IC_MW_writeaddress,
						IC_MW_writedata					
					);

// ----------------- Input Output Declarations ---------------------
// Global Signals
input				clk,
					reset_n;
					
// Slave Control Signals
input				IC_SC_chipselect,
					IC_SC_write,
					IC_SC_read;
input	[2:0]		IC_SC_address;
input	[31:0]		IC_SC_writedata;
output	[31:0]		IC_SC_readdata;

// Master Read Signals
input				IC_MR_readdatavalid,
					IC_MR_waitrequest;
input	[31:0]		IC_MR_readdata;
output				IC_MR_read;
output	[7:0]		oBurst_length;
output	[31:0]		IC_MR_readaddress;


// Master Write Signals
input				IC_MW_waitrequest;	
output				IC_MW_write;				
output	[31:0]		IC_MW_writedata,
					IC_MW_writeaddress;
					
// ----------------- Wire Declarations ---------------------
wire				IC_global_enable,
					IC_MR_start,
					IC_MR_done,
					IC_MW_start,
					IC_MW_done,
					IC_ff1_full,
					IC_ff1_empty,
					IC_ff1_almost_full,
					IC_ff1_writerequest,
					IC_ff2_full,
					IC_ff2_empty,
					IC_ff2_writerequest,
					IC_ff2_readrequest,		
					IC_EndOfImage,
					HC_ff0_wait_request,
					R2Y_waitrequest;
wire 	[2:0] 		IC_address_inc;
wire	[31:0]		IC_MR_length;
wire	[15:0]		IC_X_image;
wire	[19:0]		IC_NumberOfBlock;
wire	[31:0]		IC_MR_writedata,
					IC_MW_readdata,
					IC_MR_address,
					IC_MW_address,
					IC_ff1_q,
					IC_ff2_data,
					IC_ByteCount;									

// ----------------- Reg Declarations ---------------------
reg					IC_ff1_readrequest,
					s1_IC_ff1_readrequest,
					s1_IC_MR_readdatavalid,
					s2_IC_MR_readdatavalid;
					
// ================================================================
// Local Control Unit
// ================================================================
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		{IC_ff1_readrequest, s1_IC_ff1_readrequest} <= 2'h0;
		{s1_IC_MR_readdatavalid, s2_IC_MR_readdatavalid} <= 2'h0;
	end
	else
	begin
		s1_IC_MR_readdatavalid <= IC_MR_readdatavalid;
		s2_IC_MR_readdatavalid <= s1_IC_MR_readdatavalid;
		IC_ff1_readrequest <= s2_IC_MR_readdatavalid;
		s1_IC_ff1_readrequest <= IC_ff1_readrequest;
	end	
end

// ================================================================
// Call Modules
// ================================================================
ic_global_ff1 IC_GLOBAL_FF1	(
				.clock				(clk),
				.data				(IC_MR_writedata),
				.rdreq				(IC_ff1_readrequest),
				.sclr				(~reset_n || ~IC_global_enable),
				.wrreq				(IC_ff1_writerequest),
				.almost_empty		(),
				.almost_full		(IC_ff1_almost_full),
				.empty				(IC_ff1_empty),
				.full				(IC_ff1_full),
				.q					(IC_ff1_q)
			);

ic_global_ff2 IC_GLOBAL_FF2 (
				.clock				(clk),
				.data				(IC_ff2_data),
				.rdreq				(IC_ff2_readrequest),
				.sclr				(~reset_n || ~IC_global_enable),
				.wrreq				(IC_ff2_writerequest),
				.empty				(IC_ff2_empty),
				.full				(IC_ff2_full),
				.q					(IC_MW_readdata)
			);

ic_jpeg_compression IC_JPEG_COMPRESSION (
				.clk				(clk),
				.reset_n			(reset_n && IC_global_enable),
				// Inputs
				.IC_inputready		(s1_IC_ff1_readrequest),
				.IC_readdata		(IC_ff1_q),
				.IC_NumberOfBlock	(IC_NumberOfBlock),
				.IC_X_image			(IC_X_image),
				
				// Outputs
				.IC_EndOfImage		(IC_EndOfImage),
				.IC_outputready		(IC_ff2_writerequest),							
				.IC_writedata		(IC_ff2_data),
				.IC_ByteCount		(IC_ByteCount),
				.HC_ff0_wait_request(HC_ff0_wait_request),
				.R2Y_waitrequest	(R2Y_waitrequest)
			);
			
// ==================================================================
// Interactive with Avalon
// ==================================================================
ic_slave_controller IC_SLAVE_CONTROL (
				// Inputs
				.clk				(clk),
				.reset_n			(reset_n),						
				.SC_chipselect		(IC_SC_chipselect),
				.SC_write			(IC_SC_write),
				.SC_read			(IC_SC_read),
				.MW_done			(IC_MW_done),
				
				.SC_address			(IC_SC_address),						
				.SC_writedata		(IC_SC_writedata),
				
				.IC_ByteCount		(IC_ByteCount),
				
				// Outputs
				.IC_global_enable	(IC_global_enable),
				.MR_start			(IC_MR_start),
				.MW_start			(IC_MW_start),
				.address_inc 		(IC_address_inc),
				
				.SC_readdata		(IC_SC_readdata),
				.src_address		(IC_MR_address),
				.dest_address		(IC_MW_address),
				.image_size			(IC_MR_length),
     			
     			.IC_NumberOfBlock	(IC_NumberOfBlock),
				.IC_X_image			(IC_X_image)
		);
			
ic_master_read_burst IC_MASTER_READ (
				.iClk				(clk),
				.iReset_n			(reset_n),
				// Inputs 
				.iStart				(IC_MR_start),
				.iRead_data_valid	(IC_MR_readdatavalid),
				.iWait_request		(IC_MR_waitrequest),
				.iFF_almost_full	(IC_ff1_almost_full),
				.HC_ff0_wait_request(HC_ff0_wait_request),
				.R2Y_waitrequest	(R2Y_waitrequest),
				
				.iStart_read_address(IC_MR_address),
				.iLength			(IC_MR_length),
				.iRead_data			(IC_MR_readdata),
				
				// Outputs
				.oRead				(IC_MR_read),
				.oRead_address		(IC_MR_readaddress),
				.oFF_write_request	(IC_ff1_writerequest),
				.oBurst_length		(oBurst_length),
				.oWrite_data		(IC_MR_writedata)
			);

			
ic_master_write IC_MASTER_WRITE (
				// Inputs
				.clk				(clk),
				.reset_n			(reset_n),
				.MW_start			(IC_MW_start),												
				.ff_empty			(IC_ff2_empty),
				.MW_waitrequest		(IC_MW_waitrequest),
				.MW_addressinc 		(IC_address_inc),
				
				.MW_address			(IC_MW_address),
				.MW_readdata		(IC_MW_readdata),
				.IC_EndOfImage		(IC_EndOfImage),
				
				// Output
				.MW_done			(IC_MW_done),
				.ff_readrequest		(IC_ff2_readrequest),
				.MW_write			(IC_MW_write),
				.MW_writeaddress	(IC_MW_writeaddress),
				.MW_writedata		(IC_MW_writedata)				
			);

endmodule 