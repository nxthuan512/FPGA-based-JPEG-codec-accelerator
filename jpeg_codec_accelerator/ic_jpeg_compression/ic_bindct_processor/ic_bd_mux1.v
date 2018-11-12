// ============================================================
// MUX
// ============================================================	
module ic_bd_mux1 (
			select,
			z,
			x,
			y
		);

input 			select;
input	[95:0]	z;
output	[95:0] 	x,
				y;
				
assign x = (select) ? z  : {8{12'h0}};
assign y = (~select) ? z : {8{12'h0}};
		
endmodule 
