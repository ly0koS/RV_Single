
`include "include/rv_pc.sv"
`include "include/rv_mem_1024.sv"
`include "include/rv_instr_mem.sv"
`include "include/rv_decode_64ic.sv"
`include "include/rv_reg.sv"
`include "include/rv_2mux64.sv"
`include "include/rv_3mux64.sv"
`include "include/rv_alu_64ic.sv"
`include "include/rv_cs_64ic.sv"

module rv_single
	(
	  input		wire 	clk, 
	  input		wire 	rst_n,
	  input		wire	c_en,
//	  input		wire	instr_wr_en,
//	  input		wire 	[31:0] instr_in,
//	  input		wire	[15:0]instr_addr_in,
//	  output	wire	[31:0]instr_o,					//Debug ONLY
	  output 	wire 	[7:0]gpio_out
	);

	// ************************************************************************
	// Internal wires and regs                                                *
	// ************************************************************************  

	//DEBUG
	// (*keep*)reg		[63:0]debug_reg1;
	// (*keep*)reg		[63:0]debug_reg2;

	//PC_IN mux
	logic	[1:0]pc_sel;

	//Program Counter
	logic	[63:0]pc_in;
	logic	[63:0]pc_o;

	//PC Bypass
	logic	[63:0]instr_addr;
	
	//MUX for PC
	logic	pc_add_sel;
	logic	[63:0]pc_sel_out;

	//PC Adder
	logic	[63:0]pc_seq_next;


	//Instr. Memory
	logic	[31:0]instr;
	
	//Decode
	logic	[6:0]opcode;
	logic	[1:0]bitlen;
	logic	[4:0]rs1;
	logic	[4:0]rs2;
	logic	[4:0]rd;
	logic 	[1:0]funct2;
	logic	[2:0]funct3;
	logic	[6:0]funct7;
	logic 	[20:0]imm_decode;
	logic	c_flag;
	
	//Register File
	logic	reg_wr_en;	//Register Write Enable
	logic	[63:0]regdat_out1;
	logic	[63:0]regdat_out2;
	logic	[7:0]gpio_data;

	//CSG (Control Signal Generation)
	logic	[63:0]imm_out;
	logic	stall_top;
	logic	stall_csg;

	//OpA Mux
	logic OpA_Sel;

	//OpB Mux
	logic OpB_Sel;

	//ALU
	logic	[63:0]OpA;
	logic	[63:0]OpB;		
	logic	[3:0]ALU_CTRL;
	logic	[63:0]ALU_Out;
	logic	zero;
	logic	neg;

	//Data Memory
	logic	[63:0]Data_in;
	logic	[63:0]Data_out;
	logic	D_wr_en;
	
	//Out Mux
	logic	[1:0]Out_Sel;
	logic	[63:0]Out_OUT;

	// ************************************************************************
	// Instantiation                                                *
	// ************************************************************************  

	rv_mux3_64 pc_in_mux(
		
		.rst_n(rst_n),
		.inA(pc_seq_next),
		.inB(ALU_Out),
		.inC(pc_o),
		.sel(pc_sel),
		.out(pc_in)
	);

	rv_pc pc_reg
	(
		.clk(clk),
		.rst_n(rst_n),
		.pc_in(pc_in),
		.pc_out(pc_o)
	);

	rv_mux2_64 pc_add
	(
		.rst_n(rst_n),
		.inA(64'd4),
		.inB(64'd2),
		.sel(pc_add_sel),
		.out(pc_sel_out)
	);

	rv_alu_64ic	pc_adder
	(
		.rst_n(rst_n),
		.opa(pc_sel_out),
		.opb(pc_o),
		.alu_ctrl(4'b0000),
		.result(pc_seq_next)
	);

	rv_mux2_64 pc_bypass
	(
		.rst_n(rst_n),
		.inA(pc_o),
		.inB(16'd0),
		.sel(1'b0),
		.out(instr_addr)
	);

	/* rv_pc fetch_reg
	(
		.clk(clk),
		.rst_n(rst_n),
		.pc_in(pc_result),
		.pc_out(pc_o)
	); */

	rv_instr_mem inst_mem(
		.clk(clk),
		.instr_wr_en(1'b0),
		.instr_in(16'd0),
		.addr(pc_in),
		.instr_o(instr)
	);

	rv_decode_64ic decode(
		.rst_n(rst_n),
		.instr(instr),
		.c_en(c_en),
		.XLEN(bitlen),
		.Wr_idx(rd),
		.R1_idx(rs1),
		.R2_idx(rs2),
		.opcode(opcode),
		.funct2_o(funct2),
		.funct3_o(funct3),
		.funct7_o(funct7),
		.imm(imm_decode),
		.c_flag_o(c_flag)
	);

	rv_cs_64ic csg(
		.rst_n(rst_n),
		.bitlen(bitlen),
		.rs1(regdat_out1),
		.rs2(regdat_out2),
		.c_flag(c_flag),
		.opcode(opcode),
		.funct2(funct2),
		.funct3(funct3),
		.funct7(funct7),
		.imm_in(imm_decode),
		.stall_top(stall_top),
		.stall_csg(stall_csg),
		.pc_sel(pc_sel),
        .pc_adder_sel(pc_add_sel),
        .OpA_Sel(OpA_Sel),
        .OpB_Sel(OpB_Sel),
        .alu_Sel(ALU_CTRL),
        .reg_wr_en(reg_wr_en),
        .Data_wr_en(D_wr_en),
        .Out_Sel(Out_Sel),
        .imm_out(imm_out)
	);

	rv_mux2_64 opa_mux(
		
		.rst_n(rst_n),
		.inA(pc_o),
		.inB(regdat_out1),
		.sel(OpA_Sel),
		.out(OpA)
	);

	rv_mux2_64 opb_mux(
		
		.rst_n(rst_n),
		.inA(regdat_out2),
		.inB(imm_out),
		.sel(OpB_Sel),
		.out(OpB)
	);

	rv_alu_64ic	alu(
		.rst_n(rst_n),
		.opa(OpA),
		.opb(OpB),
		.alu_ctrl(ALU_CTRL),
		.zero(zero),
		.neg(neg),
		.result(ALU_Out)
	);

	rv_reg	registers(
		.clk(clk),
		.rst_n(rst_n),
		.Wr_idx(rd),
		.R1_idx(rs1),
		.R2_idx(rs2),
		.wr_en(reg_wr_en),
		.Data_in(Out_OUT),
		.out1(regdat_out1),
		.out2(regdat_out2),
		.gpio(gpio_data)
	);
	rv_mem_1024 d_mem(
		.clk(clk),
		.wr_en(D_wr_en),
		.addr(ALU_Out),
		.data_in(regdat_out2),
		.data_out(Data_out)
	);

	rv_mux3_64 out_mux(
		
		.rst_n(rst_n),
		.inA(pc_seq_next),
		.inB(ALU_Out),
		.inC(Data_out),
		.sel(Out_Sel),
		.out(Out_OUT)
	);


/* 	rv_pc debugger1(
		.clk(clk),
		.rst_n(rst_n),
		.pc_in(opcode),
		.pc_out(debug_reg1)
	);

	rv_pc debugger2(
		.clk(clk),
		.rst_n(rst_n),
		.pc_in(pc_in),
		.pc_out(debug_reg2)
	); */

	always_ff @(posedge clk ) begin : stall_filp
		if (rst_n == 1'b0) begin
			stall_top <= 1'b0;
		end
		else begin
			stall_top <= stall_csg;
		end
	end


//	assign instr_o  = instr;
	assign gpio_out = gpio_data;
endmodule