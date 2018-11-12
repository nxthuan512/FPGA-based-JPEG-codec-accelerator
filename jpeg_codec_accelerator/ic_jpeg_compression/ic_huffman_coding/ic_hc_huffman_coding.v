// *******************************************************************
// Dieu khien Huffman coding
// *******************************************************************	
module ic_hc_huffman_coding (
				clk,
				reset_n,
				// Inputs
				inputready,
				pre_IC_EndOfImage,
				MUX_select,
				readdata_value,
				readdata_RSL,
				// Outputs
				outputready,
				ack_pre_IC_EndOfImage,
				writedata,
				IC_ByteCount
			);

// ----------------------------------------
// DC: readdata_RSL = 11'h0 + length
// AC: writedata_RSL = EOB + M16zeroes + number_of_zeroes + length
//						1		2			6				 4		
input			clk,
				reset_n,
				inputready,
				pre_IC_EndOfImage;
// 00: DCY
// 01: DCCb
// 10: ACY
// 11: ACCb
input 	[1:0] 	MUX_select;
input	[12:0]	readdata_value,
				readdata_RSL;
output			outputready,
				ack_pre_IC_EndOfImage;
output	[31:0]	writedata,
				IC_ByteCount;

// ------------------ Reg Declarations --------------------
reg				state0,
				ack_pre_IC_EndOfImage,
				add_00,
				outputready;
reg		[1:0]	wd_bytecount;
reg		[6:0]	count_pre_IC_EndOfImage;
reg		[5:0]	bufferPos;
reg	 	[31:0] 	writedata,
				IC_ByteCount;
reg		[63:0]	buffer;

// ------------------ Wire Declarations -------------------
wire			endofbytes,
				bufferPos_gt_8;
wire	[1:0]	M16zeroes;
//wire	[5:0]	number_of_zeroes;
wire	[3:0]	value_length;
wire	[12:0]	value;
wire  	[4:0] 	code_length;
wire  	[15:0]  code;

wire	[3:0]	fillbits_length;
wire	[7:0]	fillbits_value;

wire	[3:0]	DC_address;
wire	[7:0]	AC_address;
wire	[20:0]	DCY_tab,
				ACY_tab,
				DCCb_tab,
				ACCb_tab;
wire	[7:0]	p1_writedata;
wire	[63:0]	p1_buffer_eob,
				p1_buffer_m16zeroes_1,
				p1_buffer_m16zeroes_2,
				p1_buffer_m16zeroes_3,
				p1_buffer;
wire	[5:0]	p1_bufferPos_eob,
				p1_bufferPos_m16zeroes_1,
				p1_bufferPos_m16zeroes_2,
				p1_bufferPos_m16zeroes_3,
				p1_bufferPos;

// ------------------ Wire Declarations --------------------
// neu co hon 16 so 0 thi lay phan du
// assign number_of_zeroes = readdata_RSL[9:4];
assign endofbytes		= readdata_RSL[12];		// = 13'h1FFF	
assign M16zeroes 		= readdata_RSL[11:10];

assign value_length		= readdata_RSL[3:0];
assign value 			= readdata_value;

assign DC_address = readdata_RSL[3:0];
// number_of_zeroes = number_of_zeroes * 10 + value_length;
assign AC_address = {readdata_RSL[8:4], 3'h0} + {readdata_RSL[9:4], 1'b0} + value_length;

// 00: DCY
// 01: DCCb
// 10: ACY
// 11: ACCb
assign code_length = 	(MUX_select == 2'b00) ? DCY_tab[20:16] : 
						(MUX_select == 2'b01) ? DCCb_tab[20:16] :
						(MUX_select == 2'b10) ? ACY_tab[20:16] : ACCb_tab[20:16];
            
assign code = 			(MUX_select == 2'b00) ? DCY_tab[15:0] : 
						(MUX_select == 2'b01) ? DCCb_tab[15:0] :
						(MUX_select == 2'b10) ? ACY_tab[15:0] : ACCb_tab[15:0];

// ------------- dich du lieu vao buffer --------------
assign p1_buffer_eob = (buffer << code_length) | code;
assign p1_buffer_m16zeroes_1 = (buffer << (value_length + code_length + 64'd11)) | (11'b11111111001 << (value_length + code_length)) | (code << value_length) | value;
assign p1_buffer_m16zeroes_2 = (buffer << (value_length + code_length + 6'd22)) | ({2{11'b11111111001}} << (value_length + code_length)) | (code << value_length) | value;
assign p1_buffer_m16zeroes_3 = (buffer << (value_length + code_length + 6'd33)) | ({3{11'b11111111001}} << (value_length + code_length)) | (code << value_length) | value;
assign p1_buffer = (buffer << (value_length + code_length)) | (code << value_length) | value;

assign p1_bufferPos_eob = bufferPos + code_length;
assign p1_bufferPos_m16zeroes_1 = bufferPos + value_length + code_length + 6'd11;
assign p1_bufferPos_m16zeroes_2 = bufferPos + value_length + code_length + 6'd22;
assign p1_bufferPos_m16zeroes_3 = bufferPos + value_length + code_length + 6'd33;
assign p1_bufferPos = bufferPos + value_length + code_length;

always @ (posedge clk)
begin
	if (~reset_n)
	begin
		bufferPos <= 6'h0;
		buffer <= 64'h0;
		state0 <= 1'b0;
	end
	
	else 
	begin
		if (state0 || inputready)
			state0 <= ~state0;
			
		if (state0)
		begin
			// EOB
			if (endofbytes)
			begin
				buffer <= p1_buffer_eob;
				bufferPos <= p1_bufferPos_eob;
			end
			// M16 ZEROES = 2'h1: 1 M16 ZEROES
			else if (M16zeroes == 2'h1)
			begin
				buffer <= p1_buffer_m16zeroes_1;
				bufferPos <= p1_bufferPos_m16zeroes_1;
			end
			// M16 ZEROES = 2'h2: 2 M16 ZEROES
			else if (M16zeroes == 2'h2)
			begin
				buffer <= p1_buffer_m16zeroes_2;
				bufferPos <= p1_bufferPos_m16zeroes_2;
			end
			// M16 ZEROES = 2'h3: 3 M16 ZEROES
			else if (M16zeroes == 2'h3)
			begin
				buffer <= p1_buffer_m16zeroes_3;
				bufferPos <= p1_bufferPos_m16zeroes_3;
			end
			// Con lai
			else
			begin
				buffer <= p1_buffer;
				bufferPos <= p1_bufferPos;
			end
		end
		
		else if (bufferPos_gt_8)
			bufferPos = bufferPos - 4'h8;
	end
end

// ------------- bao du lieu ra hop le --------------
// xx xx xx ff: wd_bytecount: 0 -> 2 
// xx xx ff xx: wd_bytecount: 1 -> 3
// xx ff xx xx: wd_bytecount: 2 -> 0: xuat
// ff xx xx xx: wd_bytecount: 3 -> 1: xuat

always @ (posedge clk)
begin
	if (~reset_n)
		outputready <= 1'b0;
	else if (~state0 && bufferPos_gt_8)
	begin
		if (&wd_bytecount)
			outputready <= 1'b1;
		else if (wd_bytecount[1] && (&p1_writedata))
			outputready <= 1'b1;
		else
			outputready <= 1'b0;
	end
	else if (count_pre_IC_EndOfImage == 7'd126)
		outputready <= 1'b1;
	else
		outputready <= 1'b0;
end

// ------------- ket thuc anh ---------------------------
always @ (posedge clk)
begin
	if (~reset_n)
		count_pre_IC_EndOfImage <= 7'h0;
	else if (pre_IC_EndOfImage)
		count_pre_IC_EndOfImage <= count_pre_IC_EndOfImage + 1'b1;
end

always @ (posedge clk)
begin
	if (~reset_n)
		ack_pre_IC_EndOfImage <= 1'b0;
	else if (&count_pre_IC_EndOfImage)
		ack_pre_IC_EndOfImage <= 1'b1;
end

// -------------------------------------------------------
// IC_ByteCount: so byte luu vao bo nho
// wd_bytecount: dem so byte dua vao writedata, du 4 byte thi xuat ra
always @ (posedge clk)
begin
	if (~reset_n)
	begin
		IC_ByteCount <= 1'b0;
		wd_bytecount <= 2'h0;
	end
	
	else if (~state0 & bufferPos_gt_8)
	begin
		IC_ByteCount <= IC_ByteCount + 1'b1 + (&p1_writedata);
		wd_bytecount <= wd_bytecount + 1'b1 + (&p1_writedata);
	end
	
	else if (count_pre_IC_EndOfImage == 7'd125)
		IC_ByteCount <= IC_ByteCount + 1'b1 + (&fillbits_value);
end

// ------------- lay du lieu ra buffer --------------
// kiem tra thanh ghi > 32 bits
assign bufferPos_gt_8 = (bufferPos > 3'h7);
assign p1_writedata =  	{buffer[bufferPos - 3'b1], buffer[bufferPos - 3'h2], buffer[bufferPos - 3'h3], 
						 buffer[bufferPos - 3'h4], buffer[bufferPos - 3'h5], buffer[bufferPos - 3'h6], buffer[bufferPos - 3'h7], buffer[bufferPos - 4'h8]};

always @ (posedge clk)
begin
	if (~reset_n)
		add_00 <= 1'b0;
	else if ((&wd_bytecount) && (&p1_writedata) && bufferPos_gt_8)
		add_00 <= 1'b1;
	else if (wd_bytecount == 2'h2)
		add_00 <= 1'b0;
end

// -------------------------------------------------------
assign fillbits_length = 4'h8 - bufferPos;
assign fillbits_value = (1'b1 << fillbits_length) - 1'b1;

always @ (posedge clk)
begin
	if (~reset_n)
		writedata <= 32'h0;
	
	else if (~state0 & bufferPos_gt_8)
	begin
		case (wd_bytecount)
			2'h0: writedata <= {24'h0, p1_writedata};
			2'h1: 
				if (~add_00)
					writedata <= {16'h0, p1_writedata, writedata[7:0]};
				else
					writedata <= {16'h0, p1_writedata, 8'h0};
			2'h2: writedata <= {8'h0, p1_writedata, writedata[15:0]};
			2'h3: writedata <= {p1_writedata, writedata[23:0]};
		endcase
	end		
	// bo sung bit thieu
	else if (count_pre_IC_EndOfImage == 7'd125)
	begin
		case (wd_bytecount)
			2'h0: writedata <= {24'h0, fillbits_value};
			2'h1: writedata <= {16'h0, fillbits_value, writedata[7:0]};
			2'h2: writedata <= {8'h0, fillbits_value, writedata[15:0]};
			2'h3: writedata <= {fillbits_value, writedata[23:0]};
		endcase
	end		
	
end
// -------------------------------------------------------------------------------------  
ic_hc_DCYtab HC_DCYTAB (
				.address		(DC_address),
				.clock			(clk),
				.q				(DCY_tab)
			);

// Ta khong dat ZRL vao bang cho de trong tinh toan
// address = number_of_zeroes * 10 + value_length			
ic_hc_ACYtab HC_ACYTAB (
				.address		(AC_address),
				.clock			(clk),
				.q				(ACY_tab)
			);
			
ic_hc_DCCbtab HC_DCCbTAB (
				.address		(DC_address),
				.clock			(clk),
				.q				(DCCb_tab)
			);
		
ic_hc_ACCbtab HC_ACCbTAB (
				.address		(AC_address),
				.clock			(clk),
				.q				(ACCb_tab)
			);			
endmodule	
