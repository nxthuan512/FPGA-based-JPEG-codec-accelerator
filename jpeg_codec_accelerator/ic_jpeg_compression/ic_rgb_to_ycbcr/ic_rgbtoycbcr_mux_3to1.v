// ================================================================
// MODULE MUX_3to1
// ================================================================
module ic_rgbtoycbcr_mux_3to1 (
					select,
					a0,
					a1,
					a2,
					a
				);	

input	[2:0]	select;
input	[63:0]	a0, a1, a2;

output	[63:0]	a;

assign a = 	(select == 3'b001) ? a0 : 
			(select == 3'b010) ? a1 :
			(select == 3'b100) ? a2	: 64'h0;
endmodule
