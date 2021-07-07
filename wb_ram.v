module wb_ram(
	input				clk		,
	input				rst		,
	
	input  wire[15:0]	dat_i	,
	input  wire[15:0]	pc_i	,
	input  wire			cyc_i	,
	input  wire			stb_i	,
	input  wire[15:0] 	adr_i	,
	input  wire			we_i	,
	// input  wire			sel_i	,
	// output wire			ack_o	,
	output reg[15:0] 	dat_o	,
	output reg[15:0]	inst_o
);
	reg [15:0] ram[0:16383]; 
	initial $readmemh("E:/j1.hex", ram);

	
	
	
	wire vaild;
	assign vaild = cyc_i & stb_i;

	// assign ack_o = vaild;
	always @(posedge clk)
	begin
		if(rst)
		begin
			dat_o <= 16'b0;
			inst_o <= 16'b0;
		end else if(vaild)
		begin
			if(we_i)
				ram[adr_i[15:1]] <= dat_i;
			// dat_o <= ram[adr_i[15:1]] === 16'hx ? 16'b0:ram[adr_i[15:1]]; // 仿真
			dat_o <= ram[adr_i[15:1]]; // 综合
			inst_o <= ram[pc_i[12:0]];
		end else
		begin
			dat_o <= 16'b0;
			inst_o <= ram[pc_i[12:0]];
		end 
	end
	
endmodule