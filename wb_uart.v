module wb_uart(
	input			clk		,
	input			rst		,
	input			rx		,
	output			tx		,
	
	input  [15:0]	dat_i	,
	// input  [15:0]	tga_i	,
	input			cyc_i	,
	input			stb_i	,
	input  [15:0] 	adr_i	,
	input			we_i	,
	input			sel_i	,
	// output			ack_o	,
	output reg[15:0] 	dat_o	
	// output [15:0]	tga_o
);
	
	wire vaild;
	wire ren,wen;
	wire[7:0] data_out;
	reg[7:0] data_in;
	
	assign vaild = cyc_i & stb_i;
	// assign ren = vaild & ~we_i & sel_i;
	assign ren = vaild & ~we_i & (adr_i[15:12] == 4'b1111);
	assign wen = vaild & we_i;
	
	// assign addr = vaild ? adr_i[0] : 1'b0;
	
	
	always @(*)
	begin
		if(vaild)
		begin
			data_in = dat_i[7:0];
			dat_o = {8'b0,data_out} ;
		end else 
		begin
			data_in = 8'b0;
			dat_o =	16'b0;
		end 
			
	end
	
	miniuart2 uart(
		.clk	  (clk),
		.rst      (rst),
		.rx		  (rx),
		.tx		  (tx),
		.io_rd	  (ren),
		.io_wr	  (wen),
		.io_addr  (adr_i[0]),
		.io_din   (data_in),
		.io_dout  (data_out)
	);
	
endmodule