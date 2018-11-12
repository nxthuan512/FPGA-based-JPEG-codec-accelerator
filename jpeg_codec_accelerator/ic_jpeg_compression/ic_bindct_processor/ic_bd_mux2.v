module ic_bd_mux2 (
			select,
			x,
			y,
			z
		);

input 			select;
input	[95:0] 	x,
				      y;
output	[95:0]	z;
				
assign z = (select) ? x : y;
		
endmodule 
