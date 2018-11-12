// *******************************************************************
// Chuyen tu song song sang noi tiep
// *******************************************************************
module ic_hc_parallel_to_serial (
					clk,
					reset_n,
					// Inputs
					enable,
      				DIFF_enable,
					readdata,
					// Outputs
					outputready,
					writedata					
				);
// ----------------------------------------------				
input			clk,
				reset_n,
				enable;
input 	[2:0]	DIFF_enable;
input	[103:0]	readdata;
output			outputready;
output	[12:0]	writedata;

// ----------------------------------------------
wire			outputready;

reg		[3:0]	state;
reg		[12:0]	previous_DCY,
				previous_DCCb,
				previous_DCCr,
				writedata;

// -----------------------------------------------
// outputready bat khi state la so le
assign outputready = state[0] && enable;

always @ (posedge clk)
begin
	if (~reset_n)
		writedata <= 13'h0;
	else 
	begin
		case (state)
			4'h0: writedata <= 	(DIFF_enable[0]) ? (readdata[12:0] - previous_DCY) : 
								(DIFF_enable[1]) ? (readdata[12:0] - previous_DCCb) : 
								(DIFF_enable[2]) ? (readdata[12:0] - previous_DCCr) : readdata[12:0];	
			4'h2: writedata <= readdata[25:13];			
			4'h4: writedata <= readdata[38:26];			
			4'h6: writedata <= readdata[51:39];
			4'h8: writedata <= readdata[64:52];
			4'ha: writedata <= readdata[77:65];
			4'hc: writedata <= readdata[90:78];
			4'he: writedata <= readdata[103:91];
			default: ;
		endcase
	end
end

// ---------------------------					
always @ (posedge clk)
  if (~reset_n)
  begin 
    previous_DCY <= 13'h0;
    previous_DCCb <= 13'h0;
    previous_DCCr <= 13'h0;
  end
  else if (DIFF_enable[0])
    previous_DCY <= readdata[12:0];
  else if (DIFF_enable[1])
    previous_DCCb <= readdata[12:0]; 
  else if (DIFF_enable[2])
    previous_DCCr <= readdata[12:0];
	
// ---------------------------
always @ (posedge clk)
begin
	if (~reset_n)
		state <= 4'h0;	
	else if (enable)
		state <= state + 1'b1;
	else
		state <= 4'h0;
end

endmodule
