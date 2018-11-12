// ============================================================
// MUX
// ============================================================	
module ic_gb8_mux1 (
			select,
			z,
			x,	// select = 1
			y	// select = 0
		);

input 			select;
input	[31:0]	z;
output	[31:0] 	x,
				y;
				
assign x = (select) ? z  : 32'h0;
assign y = (~select) ? z : 32'h0;
		
endmodule
