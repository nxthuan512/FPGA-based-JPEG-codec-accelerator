// *****************************************************************
// QZ_FIFO 128x8
// *****************************************************************
module ic_qz_fifo (
	clock,
	data,
	rdreq,
	sclr,
	wrreq,
	empty,
	full,
	q);

	input	 		clock;
	input	[127:0] data;
	input	  		rdreq;
	input	  		sclr;
	input	  		wrreq;
	output	  		empty;
	output	  		full;
	output	[127:0] q;

	wire  sub_wire0;
	wire [127:0] sub_wire1;
	wire  sub_wire2;
	wire  empty = sub_wire0;
	wire [127:0] q = sub_wire1[127:0];
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
		scfifo_component.lpm_numwords = 32,
		scfifo_component.lpm_showahead = "OFF",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 128,
		scfifo_component.lpm_widthu = 5,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";


endmodule
