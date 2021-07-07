`timescale 1ns / 1ps
module j1_top(
	input  		clk_in	,
	input  		rx		,
	output 		tx
);

	wire clk;
	wire rst;
	
	wire [15:0] wb_dat_i	;
	wire 		wb_ack		;
	wire [15:0] wb_pc		;
	wire [15:0] wb_adr		;
	wire [15:0] wb_dat_o	;
	wire 		wb_we 		;
	wire 		wb_sel		;
	wire 		wb_stb		;
	wire 		wb_cyc		;
	wire [15:0] wb_inst	;
	
	wire[15:0] ram_dat_o,uart_dat_o;

	wire valid;
	wire ram_sel, uart_sel;
	reg ram_sel_r, uart_sel_r;

	
	// clock c(.clk_in(clk_in), .clk(clk) );
	clock ck(.clk_in(clk_in), .clk(clk));
	
	wb_j1_cpu j1(
		.clk  (clk)		,
		.rst  (rst)		,
		.dat_i(wb_dat_o	),
		// .ack_i(cpu_ack_i),
		.inst_i(wb_inst	),
		.adr_o(wb_adr	),
		.dat_o(wb_dat_i	),
		.we_o (wb_we	),
		.sel_o(wb_sel	),
		.stb_o(wb_stb	),
		.cyc_o(wb_cyc	),
		.pc_o(wb_pc	)
	); 
	
	wb_ram ram(
		.clk	(clk),
		.rst	(rst),
		.dat_i  (wb_dat_i	),
		.pc_i  (wb_pc	),
		.cyc_i  (wb_cyc	& (ram_sel | ram_sel_r)),
		.stb_i  (wb_stb		),
		.adr_i  (wb_adr		),
		.we_i   (wb_we		),
		// .sel_i  (ram_sel_i),
		// .ack_o  (ram_ack_o),
		.dat_o  (ram_dat_o	),
		.inst_o  (wb_inst	)
	); 
	
	wb_uart uart(
		.clk	(clk),
		.rst	(rst),
		.dat_i  (wb_dat_i	),
		// .tga_i  (uart_tga_i),
		.cyc_i  (wb_cyc	& (uart_sel | uart_sel_r)),
		.stb_i  (wb_stb		),
		.adr_i  (wb_adr		),
		.we_i   (wb_we		),
		.sel_i  (wb_sel		),
		// .ack_o  (uart_ack_o),
		.dat_o  (uart_dat_o	),
		// .tga_o  (uart_tga_o),
		.rx		(rx),
		.tx		(tx)
	);
	
	
	
	
	assign valid = wb_cyc & wb_stb;
	assign ram_sel = valid && (wb_adr[15] == 1'b0);
	assign uart_sel = valid && (wb_adr[15:12] == 4'b1111);

	always @(posedge clk)
	begin
		if(rst)
		begin
			ram_sel_r <= 1'b0;
			uart_sel_r <= 1'b0;
		end else 
		begin
			ram_sel_r <= ram_sel;
			uart_sel_r <= uart_sel;
		end
	end
	
	
	assign wb_dat_o = ((ram_dat_o & {16{ram_sel_r}}) | (uart_dat_o & {16{uart_sel_r}}));
	
	
	
	
	
	
	reg[4-1:0] count = 4'b1111;
	always @(posedge clk)
	begin
		if(count > 1'b0)
			count <= count - 1'b1;
	end
	assign rst = count > 0 ? 1'b1 : 1'b0 ;
	
endmodule