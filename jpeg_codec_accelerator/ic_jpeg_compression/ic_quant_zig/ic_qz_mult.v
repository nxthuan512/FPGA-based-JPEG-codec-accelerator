module ic_qz_mult (
			aclr,
			clken,
			clock,
			dataa,
			datab,
			result
		);

	input	  aclr;
	input	  clken;
	input	  clock;
	input	[15:0]  dataa;
	input	[12:0]  datab;
	output	[28:0]  result;

	wire [28:0] sub_wire0;
	wire [28:0] result = sub_wire0[28:0];

	lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (datab),
				.clken (clken),
				.aclr (aclr),
				.clock (clock),
				.result (sub_wire0),
				.sum (1'b0));
	defparam
		lpm_mult_component.lpm_hint = "MAXIMIZE_SPEED=9",
		lpm_mult_component.lpm_pipeline = 1,
		lpm_mult_component.lpm_representation = "SIGNED",
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_widtha = 16,
		lpm_mult_component.lpm_widthb = 13,
		lpm_mult_component.lpm_widthp = 29;


endmodule
