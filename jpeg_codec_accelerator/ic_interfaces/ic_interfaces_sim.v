// =============================================
// SIMULATION ONLY
// =============================================
module ic_print_MW_to_file (
                         clk,
                         outputready,
                         writedata
                      );

input           clk,
                outputready;
input [31:0]    writedata;
 
integer f1, f2;
integer count, temp, e;
integer t0, v0, v10, v11, v12, v13, v14;

initial
begin
	$display ("\n Print result to dat file\n");
	f1 = $fopen("modelsim_ic_MW_output_Huffman.dat", "w");
	f2 = $fopen("expected_output_huffman.dat", "r");
	count = 0;
	e = 0;
end

always @ (posedge clk)
begin
  if (outputready)
  begin   
    count = count + 1;
   
    t0 = writedata;
    $fwrite(f1,"%x\n ", t0);   
    
    temp = $fscanf(f2,"%x", v0);
    v10 = (v0 & 32'hff000000) >> 24;
		v11 = (v0 & 32'h00ff0000) >> 16;
		v12 = (v0 & 32'h0000ff00) >> 8;
		v13 = (v0 & 32'hff0000ff);
		v14 = (v13 << 24) + (v12 << 16) + (v11 << 8) + v10;
		 
    if 	 (v14 != t0)
    begin
      $display("Have Errors...");
      $display($time, " %3x \n", t0);
      $display($time, " %3x \n\n", v14);
      $stop;
    end    
  end
end

endmodule


/*
module print_MW_to_file (
                         clk,
                         outputready,
                         writedata
                      );

input           clk,
                outputready;
input [31:0]    writedata;
 
integer f1, f2;
integer count, temp, e;
integer t, v;

initial
begin
	$display ("\n Print result to dat file\n");
	f1 = $fopen("modelsim_MW_output_Huffman.dat", "w");
//	f2 = $fopen("expected_output_huffman.dat", "r");
	f2 = $fopen("golden_input_RGB_block8x8x3.dat", "r");
	count = 0;
	e = 1;
end

always @ (posedge clk)
begin
  if (outputready)
  begin   
    count = count + 1;
   
    t = writedata;
    $fwrite(f1,"%x\n", t);
    temp = $fscanf(f2,"%x", v);    
    if 	 (((v - t) > e) || ((t - v) < -e))
    begin
      $display("Have Errors...");
      $display($time, "%x\n", writedata);
      $display($time, "%x\n", v);
      $stop;
    end    
  end
end

endmodule
*/

/*
module print_MR_block8x8x3_to_file(
                        clk,
                        start,
                        data_valid,
                        data
                      );
                      
input           clk,
                start,
                data_valid;
input [31:0]    data;
integer f1, f2;
integer row, count, temp;
integer t0, t1, t2, t3, t4, t5, t6, t7;

initial
begin
	$display ("\n Print block8x8x3 to modelsim_MR_output_RGB_block8x8x3.dat\n");
	f1 = $fopen("modelsim_MR_output_RGB_block8x8x3.dat", "w");
	f2 = $fopen("golden_input_RGB_block8x8x3.dat", "r");
	row = 0;
	count = 0;
end

always @ (posedge clk)
begin
  if (data_valid)
  begin
    t0 = data & 32'h000000ff;  
    t1 = (data & 32'h0000ff00) >> 8; 
    t2 = (data & 32'h00ff0000) >> 16;  
    t3 = (data & 32'hff000000) >> 24;
    
    //if (t0 > 128) t0 = t0 - 256;
    //if (t1 > 128) t1 = t1 - 256;
    //if (t2 > 128) t2 = t2 - 256;
    //if (t3 > 128) t3 = t3 - 256;            
    
    $fwrite(f1,"%5d %5d %5d %5d", t0, t1, t2, t3);
    temp = $fscanf(f2,"%d %d %d %d", t4, t5, t6, t7);
    if ((t0 != t4) || (t1 != t5) || (t2 != t6) || (t3 != t7))
    begin
      $display("Have Errors...");
      $stop;
    end
    
    count = count + 1;
    if (count % 6 == 0) $fwrite (f1, "\n");
    if (count % 48 == 0) $fwrite (f1, "\n");
  end
  
end

endmodule
*/

// **************************************************************************
