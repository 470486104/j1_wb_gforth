`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/26 14:39:35
// Design Name: 
// Module Name: test_j1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_j1;
	wire rx,tx;
	reg clk_in;
	
	j1_top j1_test(clk_in,rx,tx);
	initial 
	begin
		clk_in=1;
		forever #(10)
			clk_in = ~clk_in;
	end

endmodule
