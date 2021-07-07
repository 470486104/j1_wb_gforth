
module wb_j1_cpu(
   input clk, 
   input rst, 
   
   input wire[15:0]	dat_i	,
   // input  wire			ack_i	,
   input  wire[15:0]	inst_i	,
   output reg[15:0] 	adr_o	,
   output reg[15:0] 	dat_o	,
   output reg			we_o	,
   output reg			sel_o	,
   output reg 			stb_o	,
   output reg			cyc_o	,
   output reg[15:0]		pc_o
   );
	
  wire [15:0] insn;								//指令
  	assign insn = inst_i;
  wire [15:0] immediate = { 1'b0, insn[14:0] };	
	
  reg [4:0] dsp;  // 当前栈顶指针
  reg [4:0] _dsp;	// 在当前周期的指令执行后的 栈顶指针
  reg [15:0] st0; // 栈顶元素    T 
  reg [15:0] _st0;   // 在当前周期的指令执行后的 栈顶数据暂存 alu的结果最终赋值到 st0
  wire _dstkW;     // 数据堆栈写使能

  reg [12:0] pc;
  reg [12:0] _pc;
  reg [4:0] rsp; // 返回堆栈 栈顶指针
  reg [4:0] _rsp;
  reg _rstkW;     // 返回堆栈写使能
  reg [15:0] _rstkD; //写入到返回栈数据      // RAM write enable

  wire [15:0] pc_plus_1;
  assign pc_plus_1 = pc + 1;

/*******************************堆栈栈顶数据更新*******************************/
  // The D and R stacks
  reg [15:0] dstack[0:31];
  reg [15:0] rstack[0:31];
  always @(posedge clk)		//在系统时钟上升沿 如果 使能= 1 把数据写入到堆栈
  begin
    if (_dstkW)
      dstack[_dsp] = st0;	// 在执行st0<=_st0时此处st0仍是上个时钟的值并不是_st0
    if (_rstkW)
      rstack[_rsp] = _rstkD;
  end
  wire [15:0] st1 = dstack[dsp];	// 次栈顶 N
  wire [15:0] rst0 = rstack[rsp];	// 返回堆栈 栈顶元素
/*******************************堆栈栈顶数据更新 end*******************************/


/******************************译码阶段 decode*********************************/
  // st0sel is the ALU operation.  For branch and call the operation
  // is T, for 0branch it is N.  For ALU ops it is loaded from the instruction
  // field.
  reg [3:0] st0sel;  //指令类型 
  always @*
  begin
    case (insn[14:13])
      2'b00: st0sel = 0;          // ubranch
      2'b10: st0sel = 0;          // call
      2'b01: st0sel = 1;          // 0branch
      2'b11: st0sel = insn[11:8]; // ALU
      default: st0sel = 4'bxxxx;
    endcase
  end
/******************************译码结束 decode end*********************************/


/******************************执行阶段 *********************************/
  // Compute the new value of T.
  always @*
  begin
    if (insn[15])
      _st0 = immediate;
    else
      case (st0sel)
        4'b0000: _st0 = st0;
        4'b0001: _st0 = st1;
        4'b0010: _st0 = st0 + st1;
        4'b0011: _st0 = st0 & st1;
        4'b0100: _st0 = st0 | st1;
        4'b0101: _st0 = st0 ^ st1;
        4'b0110: _st0 = ~st0;
        4'b0111: _st0 = {16{(st1 == st0)}};
        4'b1000: _st0 = {16{($signed(st1) < $signed(st0))}};
        4'b1001: _st0 = st1 >> st0[3:0];
        4'b1010: _st0 = st0 - 1;
        4'b1011: _st0 = rst0;
        4'b1100: _st0 = dat_i;
        4'b1101: _st0 = st1 << st0[3:0];
        4'b1110: _st0 = {rsp, 3'b000, dsp};
        4'b1111: _st0 = {16{(st1 < st0)}};
        default: _st0 = 16'hxxxx;
      endcase
  end

	wire is_alu = (insn[15:13] == 3'b011);
	wire is_lit = (insn[15]);
	wire is_from_mem = (is_alu & (insn[11:8] == 4'hc)); // @
	wire is_to_mem = (is_alu & insn[5]);	// !

  assign _dstkW = is_lit | (is_alu & insn[7]);

  wire [1:0] dd = insn[1:0];  // D stack delta  栈顶指针移动
  wire [1:0] rd = insn[3:2];  // R stack delta	栈顶指针移动

  always @*
  begin
    if (is_lit) begin                       // literal
      _dsp = dsp + 1;
      _rsp = rsp;
      _rstkW = 0;
      _rstkD = _pc;
    end else if (is_alu) begin				
      _dsp = dsp + {dd[1], dd[1], dd[1], dd}; // dd是补码 若为负dd[1]=1 若为正dd[1]=0 
      _rsp = rsp + {rd[1], rd[1], rd[1], rd};
      _rstkW = insn[6];
      _rstkD = st0;
    end else begin                          // jump/call
      // predicated jump is like DROP
      if (insn[15:13] == 3'b001) begin		// ?branch
        _dsp = dsp - 1;
      end else begin
        _dsp = dsp;
      end
      if (insn[15:13] == 3'b010) begin 		// call
        _rsp = rsp + 1;
        _rstkW = 1;
        _rstkD = {pc_plus_1[14:0], 1'b0};
      end else begin
        _rsp = rsp;
        _rstkW = 0;
        _rstkD = _pc;
      end
    end
  end

  always @*
  begin
    if (rst)
      _pc = pc;
    else
      if ((insn[15:13] == 3'b000) |
          ((insn[15:13] == 3'b001) & (|st0 == 0)) |
          (insn[15:13] == 3'b010))
        _pc = insn[12:0];
      else if (is_alu & insn[12])
        _pc = rst0[15:1];
      else
        _pc = pc_plus_1;
  end

  always @(posedge clk)
  begin
    if (rst) begin
      pc <= 0;
      dsp <= 0;
      st0 <= 0;
      rsp <= 0;
    end else begin
      dsp <= _dsp;
      pc <= _pc;
      st0 <= _st0;
      rsp <= _rsp;
    end
  end

	// WishBone
	// initial sel_o = 1'b0;// uart sel read(rx) sign
	
	always @(posedge clk)
	begin
		if(rst)
		begin
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
		end else
		begin
			cyc_o <= 1'b1;
			stb_o <= 1'b1;	
		end 
	end 
	
	always @(*)
	begin
		if(is_from_mem && st0[15:12]==4'b1111) // uart operation
		begin
			adr_o = st0;
			we_o = 1'b0;
			// sel_o = 1'b1;
		end else if(is_to_mem)
		begin
			adr_o = _st0;
			dat_o = st1;
			we_o = 1'b1;
			// sel_o = 1'b0;
		end else
		begin
			adr_o = _st0;
			we_o = 1'b0;
			// sel_o = 1'b0;
		end 
		pc_o = _pc;
	end 

endmodule // j1