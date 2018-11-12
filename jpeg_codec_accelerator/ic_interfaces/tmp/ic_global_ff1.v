module ic_global_ff1 (
	clock,
	data,
	rdreq,
	sclr,
	wrreq,
	empty,
	full,
	q);

	input	  clock;
	input	[31:0]  data;
	input	  rdreq;
	input	  sclr;
	input	  wrreq;
	output	  empty;
	output	  full;
	output	[31:0]  q;

	wire  sub_wire0;
	wire [31:0] sub_wire1;
	wire  sub_wire2;
	wire  empty = sub_wire0;
	wire [31:0] q = sub_wire1[31:0];
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
		scfifo_component.lpm_numwords = 16,
		scfifo_component.lpm_showahead = "OFF",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 32,
		scfifo_component.lpm_widthu = 4,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";
endmodule