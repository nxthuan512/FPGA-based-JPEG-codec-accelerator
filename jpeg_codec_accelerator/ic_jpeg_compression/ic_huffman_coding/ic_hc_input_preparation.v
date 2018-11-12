module ic_hc_input_preparation (
				clk,
				reset_n,
				// Inputs
				HC_inputready,
				HC_readdata,
				ff0_rdreq,
				ff1_rdreq,
				// Outputs
				ff0_empty,
				ff0_full,
				ff0_almost_empty,
				ff0_almost_full,
				ff0_q,
				ff1_empty,
				ff1_full,
				ff1_q
			);
			
// ----------------------------------------------------
input			clk,
				reset_n,
				HC_inputready,
				ff0_rdreq,
				ff1_rdreq;
input	[103:0]	HC_readdata;
output			ff0_empty,
				ff0_full,
				ff0_almost_empty,
				ff0_almost_full,
				ff1_empty,
				ff1_full;				
output	[5:0]	ff1_q;
output	[103:0]	ff0_q;

// ----------------------------------------------------
wire			MUX0_select,
				MUX1_select,
				EOB_outputready,
				ff0_wren,
				ff2_full,
				ff2_empty,
				ff2_rdreq,
				ff3_full,
				ff3_empty,
				ff3_rdreq,
				ff2_wren,
				ff3_wren;
wire	[5:0]	EOB_q;
wire	[103:0]	ff0_data,
				ff2_data,
				ff3_data,
				ff2_q,
				ff3_q;

// ----------------------------------------------------
HC_IP_control_unit HC_IP_CONTROL_UNIT (
				.clk				(clk),
				.reset_n			(reset_n),
				// Inputs 
				.MUX0_select		(MUX0_select),
				.MUX1_select		(MUX1_select),
				.ff2_full			(ff2_full),
				.ff2_empty			(ff2_empty),
				.ff3_full			(ff3_full),
				.ff3_empty			(ff3_empty),
				.EOB_q				(EOB_q),
				.HC_inputready		(HC_inputready),
				// Outputs
				.ff2_rdreq			(ff2_rdreq),
				.ff3_rdreq			(ff3_rdreq),
				.ff2_wren			(ff2_wren),
				.ff3_wren			(ff3_wren),
				.ff0_wren			(ff0_wren)
			);
			
// 1
HC_check_EOB HC_CHECK_EOB (
				.clk				(clk),
				.reset_n			(reset_n),
				.inputready			(HC_inputready),
				.readdata			(HC_readdata),
				.outputready		(EOB_outputready),
				.writedata			(EOB_q)
			);				
// 1
HC_mux_1to2 HC_MUX_1TO2 (
				.select				(MUX0_select),
				.a					(HC_readdata),
				.a1					(ff2_data),		// select = 1
				.a0					(ff3_data)		// select = 0
			);
// 2			
HC_ff_8x104 HC_FIFO_2 (
				.clock				(clk),
				.data				(ff2_data),
				.rdreq				(ff2_rdreq),
				.sclr				(~reset_n),
				.wrreq				(ff2_wren),
				.empty				(ff2_empty),
				.full				(ff2_full),
				.q					(ff2_q)
			);
// 2
HC_ff_8x104 HC_FIFO_3 (
				.clock				(clk),
				.data				(ff3_data),
				.rdreq				(ff3_rdreq),
				.sclr				(~reset_n),
				.wrreq				(ff3_wren),
				.empty				(ff3_empty),
				.full				(ff3_full),
				.q					(ff3_q)
			);
// 3			
HC_mux_2to1 HC_MUX_2TO1 (
				.select				(MUX1_select),
				.a1					(ff2_q),		// select = 1
				.a0					(ff3_q),		// select = 0
				.a					(ff0_data)
			);
// 4
HC_ff0 HC_FIFO_0(
				.clock				(clk),
				.data				(ff0_data),
				.rdreq				(ff0_rdreq),
				.sclr				(~reset_n),
				.wrreq				(ff0_wren),
				.empty				(ff0_empty),
				.almost_empty		(ff0_almost_empty),
				.almost_full		(ff0_almost_full),
				.full				(ff0_full),	
				.q					(ff0_q)
			);
// 4
HC_ff1 HC_EOB_FIFO (
				.clock				(clk),
				.data				(EOB_q),
				.rdreq				(ff1_rdreq),
				.sclr				(~reset_n),
				.wrreq				(EOB_outputready),
				.empty				(ff1_empty),
				.full				(ff1_full),
				.q					(ff1_q)
			);		
endmodule 

// *******************************************************************
// HC Input Preparation Control Unit
// *******************************************************************
module HC_IP_control_unit(
				clk,
				reset_n,
				// Inputs 
				ff2_full,
				ff2_empty,
				ff3_full,
				ff3_empty,
				EOB_q,
				HC_inputready,
				// Outputs
				MUX0_select,
				MUX1_select,
				ff2_rdreq,
				ff3_rdreq,
				ff2_wren,
				ff3_wren,
				ff0_wren				
			);
// -----------------------------------------			
input			clk,
				reset_n,
				ff2_full,
				ff2_empty,
				ff3_full,
				ff3_empty,
				HC_inputready;
input	[5:0]	EOB_q;
output			MUX0_select,
				MUX1_select,
				ff2_rdreq,
				ff3_rdreq,
				ff2_wren,
				ff3_wren,
				ff0_wren;
				
// -----------------------------------------
wire	[6:0]	count_shl3;		

// -----------------------------------------				
reg				ff2_rdreq,
				ff3_rdreq,
				s1_ff2_rdreq,
				s1_ff3_rdreq,
				ff_select;
reg		[3:0]	count_r, 
				count_w;

// ------------------------------------------				
assign ff2_wren = (~reset_n) ? 1'b0 : (HC_inputready && MUX0_select);
assign ff3_wren = (~reset_n) ? 1'b0 : (HC_inputready && ~MUX0_select);

assign ff0_wren = (s1_ff2_rdreq || s1_ff3_rdreq) && (count_shl3 <= EOB_q);

assign count_shl3 = {count_r[2:0], 3'h0};

assign MUX0_select = ~reset_n ? 1'b0 : ~count_w[3];
assign MUX1_select = ~reset_n ? 1'b0 : ~count_r[3];

// -------------------------------------------
always @ (posedge clk)
begin
	if (~reset_n)
		{ff2_rdreq, ff3_rdreq} <= {2{1'b0}};	
		
	else if (MUX1_select)
	begin
		if (&count_w[2:0] && HC_inputready)
			ff2_rdreq <= 1'b1;			
		else if (count_r[2:0] == 3'h6)
			ff2_rdreq <= 1'b0;
	end
	
	else
	begin
		if (&count_w[2:0] && HC_inputready)
			ff3_rdreq <= 1'b1;			
		else if (count_r[2:0] == 3'h6)
			ff3_rdreq <= 1'b0;
	end
end

// -------------------------------------------
always @ (posedge clk)
	if (~reset_n)
		{s1_ff2_rdreq, s1_ff3_rdreq} <= {2{1'b0}};
	else
		{s1_ff2_rdreq, s1_ff3_rdreq} <= {ff2_rdreq, ff3_rdreq};
		
// --------------- counter ------------------
always @ (posedge clk)
begin
	if (~reset_n)
		{count_r, count_w} <= {2{4'h0}};
	
	else 
	begin
		if (HC_inputready)
			count_w <= count_w + 1'b1;
		if (s1_ff2_rdreq || s1_ff3_rdreq)
			count_r <= count_r + 1'b1;
	end
end

endmodule 
			
// *******************************************************************
// MUX 2 TO 1
// *******************************************************************
module HC_mux_2to1 (
				select,
				a1,		// select = 1
				a0,		// select = 0
				a
			);
			
input			select;
input	[103:0]	a0,
				a1;
output	[103:0]	a;
				
assign a = select ? a1 : a0;

endmodule

// *******************************************************************
// MUX 1 TO 2
// *******************************************************************
module HC_mux_1to2 (
				select,
				a,
				a1,		// select = 1
				a0		// select = 0
			);
			
input			select;
input	[103:0]	a;
output	[103:0]	a1,
				a0;
				
assign a1 = select ? a : 104'h0;
assign a0 = ~select ? a : 104'h0;

endmodule

// *******************************************************************
// Xac dinh EOB khi doc du lieu tu ngoai vao FIFO
// *******************************************************************	
module HC_check_EOB (
				clk,
				reset_n,
				inputready,
				readdata,
				outputready,
				writedata
			);

input			clk,
				reset_n,
				inputready;
input	[103:0]	readdata;	
// ---------------------------------------
// x[i] = 0: gia tri vao bang 0
// x[i] = 1: gia tri vao khac 0
output			outputready;
output	[5:0]	writedata;

wire	[12:0]	x7, x6, x5, x4, x3, x2, x1, x0;
wire 	[5:0]  	count_shl3;

reg				outputready,
				pre_outputready;
reg		[2:0]	count;
reg		[5:0]	EOB;

// Xac dinh gia tri dua vao = 0 hay khac 0
assign x7 = |readdata[103:91];
assign x6 = |readdata[90:78];
assign x5 = |readdata[77:65];
assign x4 = |readdata[64:52];
assign x3 = |readdata[51:39];
assign x2 = |readdata[38:26];
assign x1 = |readdata[25:13];
assign x0 = |readdata[12:0];

assign count_shl3 = (count << 2'h3);
assign writedata = EOB;

// ----------------------
always @ (posedge clk)
  if (~reset_n)
    pre_outputready <= 1'b0;
  else if (inputready && (&count))
    pre_outputready <= 1'b1;
  else
    pre_outputready <= 1'b0;
	
// --- du lieu ngo ra ---
always @ (posedge clk)
	if (~reset_n)
		outputready <= 1'b0;
	else
		outputready <= pre_outputready;

// --- EOB ---
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		count 	<= 3'h0;
		EOB		<= 6'h0;
	end
	else if (inputready)
	begin
		count <= count + 1'b1;
		if (&count && pre_outputready)
			EOB <= 6'h0;			
		else
    		EOB	 <= x7 ? (3'h7 + count_shl3) : 
					x6 ? (3'h6 + count_shl3) :
					x5 ? (3'h5 + count_shl3) : 
					x4 ? (3'h4 + count_shl3) :
					x3 ? (3'h3 + count_shl3) :
					x2 ? (3'h2 + count_shl3) :
					x1 ? (3'h1 + count_shl3) : 
					x0 ? (3'h0 + count_shl3) : EOB;
	end		
end
endmodule 
			
// *******************************************************************
// FIFO 8 x 104
// *******************************************************************
module HC_ff_8x104 (
	clock,
	data,
	rdreq,
	sclr,
	wrreq,
	empty,
	full,
	q);

	input	  clock;
	input	[103:0]  data;
	input	  rdreq;
	input	  sclr;
	input	  wrreq;
	output	  empty;
	output	  full;
	output	[103:0]  q;

	wire  sub_wire0;
	wire [103:0] sub_wire1;
	wire  sub_wire2;
	wire  empty = sub_wire0;
	wire [103:0] q = sub_wire1[103:0];
	wire  full = sub_wire2;

	scfifo	scfifo_component (
				.rdreq (rdreq),
				.sclr (sclr),
				.clock (clock),
				.wrreq (wrreq),
				.data (data),
				.empty (sub_wire0),
				.q (sub_wire1),
				.full (sub_wire2)
				// synopsys translate_off
				,
				.aclr (),
				.almost_empty (),
				.almost_full (),
				.usedw ()
				// synopsys translate_on
				);
	defparam
		scfifo_component.add_ram_output_register = "OFF",
		scfifo_component.intended_device_family = "Stratix III",
		scfifo_component.lpm_numwords = 8,
		scfifo_component.lpm_showahead = "OFF",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 104,
		scfifo_component.lpm_widthu = 3,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";
endmodule

// *******************************************************************
// FIFO 0
// *******************************************************************
module HC_ff0 (
	clock,
	data,
	rdreq,
	sclr,
	wrreq,
	almost_empty,
	almost_full,
	empty,
	full,
	q);

	input	  clock;
	input	[103:0]  data;
	input	  rdreq;
	input	  sclr;
	input	  wrreq;
	output	  almost_empty;
	output	  almost_full;
	output	  empty;
	output	  full;
	output	[103:0]  q;

	wire  sub_wire0;
	wire  sub_wire1;
	wire  sub_wire2;
	wire [103:0] sub_wire3;
	wire  sub_wire4;
	wire  almost_full = sub_wire0;
	wire  empty = sub_wire1;
	wire  almost_empty = sub_wire2;
	wire [103:0] q = sub_wire3[103:0];
	wire  full = sub_wire4;

	scfifo	scfifo_component (
				.rdreq (rdreq),
				.sclr (sclr),
				.clock (clock),
				.wrreq (wrreq),
				.data (data),
				.almost_full (sub_wire0),
				.empty (sub_wire1),
				.almost_empty (sub_wire2),
				.q (sub_wire3),
				.full (sub_wire4)
				// synopsys translate_off
				,
				.aclr (),
				.usedw ()
				// synopsys translate_on
				);
	defparam
		scfifo_component.add_ram_output_register = "OFF",
		scfifo_component.almost_empty_value = 128,
		scfifo_component.almost_full_value = 512,
		scfifo_component.intended_device_family = "Stratix III",
		scfifo_component.lpm_numwords = 768,
		scfifo_component.lpm_showahead = "OFF",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 104,
		scfifo_component.lpm_widthu = 10,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";


endmodule

// *******************************************************************
// FIFO EOB
// *******************************************************************
module HC_ff1 (
	clock,
	data,
	rdreq,
	sclr,
	wrreq,
	empty,
	full,
	q);

	input	  clock;
	input	[5:0]  data;
	input	  rdreq;
	input	  sclr;
	input	  wrreq;
	output	  empty;
	output	  full;
	output	[5:0]  q;

	wire  sub_wire0;
	wire [5:0] sub_wire1;
	wire  sub_wire2;
	wire  empty = sub_wire0;
	wire [5:0] q = sub_wire1[5:0];
	wire  full = sub_wire2;

	scfifo	scfifo_component (
				.rdreq (rdreq),
				.sclr (sclr),
				.clock (clock),
				.wrreq (wrreq),
				.data (data),
				.empty (sub_wire0),
				.q (sub_wire1),
				.full (sub_wire2)
				// synopsys translate_off
				,
				.aclr (),
				.almost_empty (),
				.almost_full (),
				.usedw ()
				// synopsys translate_on
				);
	defparam
		scfifo_component.add_ram_output_register = "OFF",
		scfifo_component.intended_device_family = "Stratix III",
		scfifo_component.lpm_numwords = 512,
		scfifo_component.lpm_showahead = "OFF",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 6,
		scfifo_component.lpm_widthu = 9,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";
endmodule

