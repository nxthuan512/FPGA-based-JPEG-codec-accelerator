module ic_rgbtoycbcr_ff_1920x32 (
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
	input	[31:0]  data;
	input	  rdreq;
	input	  sclr;
	input	  wrreq;
	output	  almost_empty;
	output	  almost_full;
	output	  empty;
	output	  full;
	output	[31:0]  q;

	wire  sub_wire0;
	wire  sub_wire1;
	wire  sub_wire2;
	wire [31:0] sub_wire3;
	wire  sub_wire4;
	wire  almost_full = sub_wire0;
	wire  empty = sub_wire1;
	wire  almost_empty = sub_wire2;
	wire [31:0] q = sub_wire3[31:0];
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
		scfifo_component.almost_empty_value = 92,
		scfifo_component.almost_full_value = 8100,
		scfifo_component.intended_device_family = "Stratix III",
		scfifo_component.lpm_numwords = 8192,
		scfifo_component.lpm_showahead = "OFF",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 32,
		scfifo_component.lpm_widthu = 13,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";

endmodule
