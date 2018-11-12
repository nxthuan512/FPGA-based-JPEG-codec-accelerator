module ic_gb8_mux2 (
			select,
			x,	// select = 1
			y,	// select = 0
			z
		);

input 			select;
input	[31:0] 	x,
				y;
output	[31:0]	z;
				
assign z = (select) ? x : y;
		
endmodule
