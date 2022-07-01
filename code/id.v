`include	"define.v"

module id(
	//input						rst,
	
	input		[`InstAddrBus]	pc_i,
	input		[`InstBus]		inst_i,
	
	input		[`RegBus]		reg1_data_i,
	input		[`RegBus]		reg2_data_i,
	
	input						ex_wreg_i,
	input 		[`RegBus]		ex_wdata_i,
	input 		[`RegAddrBus]	ex_wd_i,
	input		[`AluOpBus]		ex_aluop_i, //load dep
	
	input 						mem_wreg_i,
	input		[`RegBus]		mem_wdata_i,
	input		[`RegAddrBus]	mem_wd_i,
	
	//input						dlyslot_now_i,
	
	//input						stallreq_from_id,
	//input						stallreq_from_ex,
	//===================================================
	output		[`RegBus]		inst_o,
	
	output reg					reg1_read_o,
	output reg					reg2_read_o,
	output		[`RegAddrBus]	reg1_addr_o,
	output		[`RegAddrBus]	reg2_addr_o,
	
	output reg	[`AluOpBus]		aluop_o,
	output reg	[`AluSelBus]	alusel_o,
	
	output reg	[`RegBus]		reg1_o,
	output reg	[`RegBus]		reg2_o,
	output reg	[`RegAddrBus]	wd_o,
	output reg					wreg_o,
	
	output reg	[`RegBus]		link_addr_o,		
	output reg	[`RegBus]		branch_tar_addr_real_o,
	output reg					branch_flag_real_o,		

	output 						stallreq,
	
	output 		[`RegBus]		excepttype_o,
	output		[`RegBus]		current_inst_addr_o
	);
	
	
	reg			[`RegBus]		imm;
	
	//wire 		[5:0]			op  = inst_i[31:26];
	//wire 		[4:0]			op2 = inst_i[10:6];
	//wire 		[5:0]			op3 = inst_i[5:0];
	//wire 		[4:0]			op4 = inst_i[11:7];
	//wire 		[4:0]			op5 = inst_i[25:21];
	
	wire		[6:0]			opcode;		
	wire		[2:0]			funct3;		
	wire		[6:0]			funct7;		

	wire		[`RegBus]		pc_plus_4;
	//wire		[`RegBus]		pc_plus_8;
	//wire		[`RegBus]		imm_sll2_signedext;
	
	//--------------------------------------
	wire						load_dep;
		
	reg							stallreq_from_id1;
	reg							stallreq_from_id2;
	wire						stallreq_from_id;
	
	reg							eret;
	reg							syscall;
	reg							instvalid;


//#################################################################################
assign inst_o = inst_i;

//-----------------------------------
assign opcode 		= inst_i[6:0];
assign funct3		= inst_i[14:12];
assign funct7		= inst_i[31:25];
//assign funct		= {funct7, funct3};

assign reg1_addr_o	= inst_i[19:15]; //rs1
assign reg2_addr_o	= inst_i[24:20]; //rs2


//-----------------------------------
//assign pc_plus_8 = pc_i + 4'h8; //you need to ignore delayslot
assign pc_plus_4 = pc_i + 3'h4;

//assign imm_sll2_signedext = { {14{inst_i[15]}}, inst_i[15:0], 2'b00};


//assign dlyslot_now_o = dlyslot_now_i;

//-------------------------------------
assign current_inst_addr_o = pc_i;
assign excepttype_o		   = {19'b0, eret, 2'b0, instvalid, syscall, 8'b00000000};


//================================================================
always @(*)	begin
	/*PARAM	
	wd_o				write address
	wreg_o				write enable?
	`InstValid			Instruction valid?
	
	reg?_read_o = 1'b1;	read address
	reg?_read_o = 0; 	read imm
	
	lui; load upper imm
	
	s: shift
	r: right	l: left
	l: logic	a: arithmetic
	(imm)		v: variable
	
	s: set
	l: less
	t: than...
	
	c: count
	l: leading
	z: zeros	o: ones
	
	b: branch
	eq:equal	nq:not equal
	
	j: jump
	r: register 	al: and link
	
	link_addr_o: 				return address
	branch_tar_addr_real_o:	target address
	
	*/
	
	syscall		= `False_v;
	eret		= `False_v;
	
	case(opcode)
		7'b0110111: begin //LUI
			wd_o						=	inst_i[11:7];
			wreg_o						=	`WriteEnable;
			aluop_o						=	`EXE_LUI_OP;	
			alusel_o					=	`EXE_RES_UPPER_IMM;
			reg1_read_o					= 	0;
			reg2_read_o					=	0;
			imm 						= 	{inst_i[31:12], 12'h0};
			link_addr_o					=	`ZeroWord;
			branch_tar_addr_real_o		=	`ZeroWord;
			branch_flag_real_o			=	`NotBranch;
			instvalid 					=	`InstValid;	
		end
		
		7'b0010111: begin //AUIPC
			wd_o						=	inst_i[11:7];
			wreg_o						=	`WriteEnable;
			aluop_o						=	`EXE_AUIPC_OP;
			alusel_o					=	`EXE_RES_UPPER_IMM;
			reg1_read_o					= 	0;
			reg2_read_o					=	0;
			imm 						= 	{inst_i[31:12], 12'h0};
			link_addr_o					=	`ZeroWord;
			branch_tar_addr_real_o		=	`ZeroWord;
			branch_flag_real_o			=	`NotBranch;
			instvalid 					=	`InstValid;
		end
		
		7'b1101111: begin //JAL
			wd_o						=	inst_i[11:7];
			wreg_o						=	`WriteEnable;
			aluop_o						=	`EXE_BRANCH_JUMP_OP;	
			alusel_o					=	`EXE_RES_JUMP_BRANCH;
			reg1_read_o					= 	0;
			reg2_read_o					=	0;
			imm 						=	0; //already used
			link_addr_o					=	pc_plus_4;
			branch_tar_addr_real_o		=	`ZeroWord;
			branch_flag_real_o			=	`NotBranch; //already branch
			instvalid 					=	`InstValid;	
		end
		
		7'b1100111: begin //JALR
			wd_o						=	inst_i[11:7];
			wreg_o						=	`WriteEnable;
			aluop_o						=	`EXE_BRANCH_JUMP_OP;	
			alusel_o					=	`EXE_RES_JUMP_BRANCH;
			reg1_read_o					= 	1'b1;
			reg2_read_o					=	0;
			imm 						=	{{20{inst_i[31]}}, inst_i[31:20]};
			link_addr_o					=	pc_plus_4;
			branch_tar_addr_real_o		=	reg1_o + imm;
			branch_flag_real_o			=	`Branch;
			instvalid 					=	`InstValid;	
		end
		
		7'b1100011: begin //BRANCH
			case(funct3)
				3'b000: begin //BEQ
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_BRANCH_JUMP_OP;	
					alusel_o					=	`EXE_RES_JUMP_BRANCH;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						=	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					instvalid 					=	`InstValid;
					if(reg1_o == reg2_o  &&  inst_i[31] == 0) begin
						//關係對，但因為offset為正，所以前面沒跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else if(reg1_o != reg2_o  &&  inst_i[31] == 1'b1) begin
						//關係錯，但因為offset為負，所以誤跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else begin
						//關係對且因為offset為負所以跳了，或是關係錯但因為offset為正所以前面沒跳，兩者皆預測成功的情況
						branch_tar_addr_real_o		=	`ZeroWord;
						branch_flag_real_o			=	`NotBranch;
					end
				end
				3'b001: begin //BNE
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_BRANCH_JUMP_OP;
					alusel_o					=	`EXE_RES_JUMP_BRANCH;
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						=	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					instvalid 					=	`InstValid;
					if(reg1_o != reg2_o  &&  inst_i[31] == 0) begin
						//關係對，但因為offset為正，所以前面沒跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else if(reg1_o == reg2_o  &&  inst_i[31] == 1'b1) begin
						//關係錯，但因為offset為負，所以誤跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else begin
						//關係對且因為offset為負所以跳了，或是關係錯但因為offset為正所以前面沒跳，兩者皆預測成功的情況
						branch_tar_addr_real_o		=	`ZeroWord;
						branch_flag_real_o			=	`NotBranch;
					end
				end
				3'b100: begin //BLT
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_BRANCH_JUMP_OP;	
					alusel_o					=	`EXE_RES_JUMP_BRANCH;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						=	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					instvalid 					=	`InstValid;
					if( ((reg1_o < reg2_o  &&  reg1_o[31] == 0  &&  reg2_o[31] == 0)  ||
						(reg1_o > reg2_o  &&  reg1_o[31] == 1'b1  &&  reg2_o[31] == 1'b1)  ||
						(reg1_o[31] == 1'b1  &&  reg2_o[31] == 0))  &&
						inst_i[31] == 0) begin
						//關係對，但因為offset為正，所以前面沒跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else if( (!(reg1_o < reg2_o  &&  reg1_o[31] == 0  &&  reg2_o[31] == 0)  ||
						(reg1_o > reg2_o  &&  reg1_o[31] == 1'b1  &&  reg2_o[31] == 1'b1)  ||
						(reg1_o[31] == 1'b1  &&  reg2_o[31] == 0))  &&
						inst_i[31] == 1'b1) begin
						//關係錯，但因為offset為負，所以誤跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else begin
						//關係對且因為offset為負所以跳了，或是關係錯但因為offset為正所以前面沒跳，兩者皆預測成功的情況
						branch_tar_addr_real_o		=	`ZeroWord;
						branch_flag_real_o			=	`NotBranch;
					end
				end
				3'b101: begin //BGE
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_BRANCH_JUMP_OP;	
					alusel_o					=	`EXE_RES_JUMP_BRANCH;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						=	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					instvalid 					=	`InstValid;
					if( ((reg1_o >= reg2_o  &&  reg1_o[31] == 0  &&  reg2_o[31] == 0)  ||
						(reg1_o <= reg2_o  &&  reg1_o[31] == 1'b1  &&  reg2_o[31] == 1'b1)  ||
						(reg1_o[31] == 0  &&  reg2_o[31] == 1'b1))  &&
						inst_i[31] == 0) begin
						//關係對，但因為offset為正，所以前面沒跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else if( (!(reg1_o >= reg2_o  &&  reg1_o[31] == 0  &&  reg2_o[31] == 0)  ||
						(reg1_o <= reg2_o  &&  reg1_o[31] == 1'b1  &&  reg2_o[31] == 1'b1)  ||
						(reg1_o[31] == 0  &&  reg2_o[31] == 1'b1))  &&
						inst_i[31] == 1'b1) begin
						//關係錯，但因為offset為負，所以誤跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else begin
						//關係對且因為offset為負所以跳了，或是關係錯但因為offset為正所以前面沒跳，兩者皆預測成功的情況
						branch_tar_addr_real_o		=	`ZeroWord;
						branch_flag_real_o			=	`NotBranch;
					end
				end
				3'b110: begin //BLTU
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_BRANCH_JUMP_OP;	
					alusel_o					=	`EXE_RES_JUMP_BRANCH;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						=	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					instvalid 					=	`InstValid;
					if(reg1_o < reg2_o  &&  inst_i[31] == 0) begin
						//關係對，但因為offset為正，所以前面沒跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else if(reg1_o >= reg2_o  &&  inst_i[31] == 1'b1) begin
						//關係錯，但因為offset為負，所以誤跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else begin
						//關係對且因為offset為負所以跳了，或是關係錯但因為offset為正所以前面沒跳，兩者皆預測成功的情況
						branch_tar_addr_real_o		=	`ZeroWord;
						branch_flag_real_o			=	`NotBranch;
					end
				end
				3'b111: begin //BGEU
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_BRANCH_JUMP_OP;	
					alusel_o					=	`EXE_RES_JUMP_BRANCH;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						=	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					instvalid 					=	`InstValid;
					if(reg1_o == reg2_o  &&  inst_i[31] == 0) begin
						//關係對，但因為offset為正，所以前面沒跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else if(reg1_o != reg2_o  &&  inst_i[31] == 1'b1) begin
						//關係錯，但因為offset為負，所以誤跳
						branch_tar_addr_real_o		=	pc_i + {{9{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
						branch_flag_real_o			=	`Branch;
					end else begin
						//關係對且因為offset為負所以跳了，或是關係錯但因為offset為正所以前面沒跳，兩者皆預測成功的情況
						branch_tar_addr_real_o		=	`ZeroWord;
						branch_flag_real_o			=	`NotBranch;
					end
				end
				default: begin
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_ECALL_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstInvalid;
				end
			endcase
		end
		
		7'b0000011: begin //LOAD
			case(funct3)
				3'b000: begin //LB
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_LB_OP;	
					alusel_o					=	`EXE_RES_LOAD_STORE; //becomes mark
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b001: begin //LH
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_LH_OP;	
					alusel_o					=	`EXE_RES_LOAD_STORE;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	//not need to read
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b010: begin //LW
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_LW_OP;	
					alusel_o					=	`EXE_RES_LOAD_STORE;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b100: begin //LBH
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_LBH_OP;
					alusel_o					=	`EXE_RES_LOAD_STORE;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b101: begin //LHU
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_LHU_OP;
					alusel_o					=	`EXE_RES_LOAD_STORE;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				default: begin
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_ECALL_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstInvalid;
				end
			endcase
		end
		
		7'b0100011: begin //STORE
			case(funct3)
				3'b000: begin //SB
					wd_o						=	`NOPRegAddr; //not need to write
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_SB_OP;	
					alusel_o					=	`EXE_RES_NOP;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b001: begin //SH
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_SH_OP;	
					alusel_o					=	`EXE_RES_NOP;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b100: begin //SW
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_SW_OP;	
					alusel_o					=	`EXE_RES_NOP;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	1'b1;	
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				default: begin
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_ECALL_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstInvalid;
				end
			endcase
		end
		
		7'b0010011: begin //LOGIC_and_ARITHMETIC_I
			case(funct3)
				3'b000: begin //ADDI
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_ADDI_OP;	
					alusel_o					=	`EXE_RES_ARITHMETIC;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	
					imm 						= 	{{20{inst_i[31]}}, inst_i[31:20]}; //sign
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b010: begin //SLTI
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_SLTI_OP;	
					alusel_o					=	`EXE_RES_ARITHMETIC;
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	
					imm 						=	{{20{inst_i[31]}}, inst_i[31:20]}; //sign
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;	
				end
				3'b011: begin //SLTIU
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_SLTIU_OP;	
					alusel_o					=	`EXE_RES_ARITHMETIC;
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	
					imm 						= 	{{20{inst_i[31]}}, inst_i[31:20]}; //sign
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;	
				end
				3'b100: begin //XORI
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_XOR_OP;	
					alusel_o					=	`EXE_RES_LOGIC;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	
					imm 						=	{{20{inst_i[31]}}, inst_i[31:20]}; //sign
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;	
				end
				3'b110: begin //ORI
					wd_o 						= 	inst_i[11:7];
					wreg_o						=	`WriteEnable;	
					aluop_o						=	`EXE_OR_OP;	
					alusel_o					=	`EXE_RES_LOGIC;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	
					imm 						= 	{{20{inst_i[31]}}, inst_i[31:20]}; //sign
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;	
				end
				3'b111: begin //ANDI
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;	
					aluop_o						=	`EXE_AND_OP;	
					alusel_o					=	`EXE_RES_LOGIC;	
					reg1_read_o					= 	1'b1;	
					reg2_read_o					=	0;	
					imm 						= 	{{20{inst_i[31]}}, inst_i[31:20]}; //sign
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;	
				end
				3'b001: begin
					case(funct7)
						7'b0000000: begin //SLLI
							wd_o						=	inst_i[11:7];
							wreg_o						=	`WriteEnable;	
							aluop_o						=	`EXE_SLL_OP;	
							alusel_o					=	`EXE_RES_SHIFT;	
							reg1_read_o					= 	1'b1;
							reg2_read_o					=	0;
							imm 						= 	{27'h0, inst_i[24:20]};
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end 
						default: begin
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_NOP_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstInvalid;
						end
					endcase
				end
				3'b101: begin
					case(funct7)
						7'b0000000: begin //SRLI
							wd_o						=	inst_i[11:7];
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_SRL_OP;	
							alusel_o					=	`EXE_RES_SHIFT;
							reg1_read_o					= 	1'b1;
							reg2_read_o					=	0;
							imm 						= 	{27'h0, inst_i[24:20]};
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						7'b0100000: begin //SRAI
							wd_o						=	inst_i[11:7];
							wreg_o						=	`WriteEnable;
							aluop_o						=	`EXE_SRA_OP;	
							alusel_o					=	`EXE_RES_SHIFT;	
							reg1_read_o					= 	1'b1;
							reg2_read_o					=	0;
							imm 						= 	{27'h0, inst_i[24:20]};
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;	
						end
						default: begin
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_NOP_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	{27'h0, inst_i[24:20]};
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstInvalid;
						end
					endcase
				end
				default: begin
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_NOP_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstInvalid;
				end
			endcase
		end
	
		7'b0110011: begin //LOGIC_and_ARITHMETIC
			case(funct3)
				3'b000: begin
					case(funct7)
						7'b0000000: begin //ADD
							wd_o						=	inst_i[11:7];
							wreg_o 						= 	`WriteEnable;				
							aluop_o						=	`EXE_ADD_OP;	
							alusel_o					=	`EXE_RES_ARITHMETIC;
							reg1_read_o					= 	1'b1;
							reg2_read_o					=	1'b1;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;	
						end
						7'b0100000: begin //SUB
							wd_o						=	inst_i[11:7];
							wreg_o 						= 	`WriteEnable;				
							aluop_o						=	`EXE_SUB_OP;	
							alusel_o					=	`EXE_RES_ARITHMETIC;
							reg1_read_o					= 	1'b1;
							reg2_read_o					=	1'b1;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						default: begin
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_NOP_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstInvalid;
						end
					endcase
				end
				3'b001: begin //SLL
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_SLL_OP;
					alusel_o					=	`EXE_RES_SHIFT;
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	1'b1;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b010: begin //SLT
					wd_o						=	inst_i[11:7];
					wreg_o 						=	 `WriteEnable;
					aluop_o						=	`EXE_SLT_OP;	
					alusel_o					=	`EXE_RES_ARITHMETIC;
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	1'b1;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;	
				end
				3'b011: begin //SLTU
					wd_o						=	inst_i[11:7];
					wreg_o 						= 	`WriteEnable;				
					aluop_o						=	`EXE_SLTU_OP;	
					alusel_o					=	`EXE_RES_ARITHMETIC;
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	1'b1;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;	
				end
				3'b100: begin //XOR
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_XOR_OP;	
					alusel_o					=	`EXE_RES_LOGIC;	
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	1'b1;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;	
				end
				3'b101: begin
					case(funct7)
						7'b0000000: begin //SRL
							wd_o						=	inst_i[11:7];
							wreg_o						=	`WriteEnable;
							aluop_o						=	`EXE_SRL_OP;
							alusel_o					=	`EXE_RES_SHIFT;
							reg1_read_o					= 	1'b1;
							reg2_read_o					=	1'b1;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						7'b0100000: begin //SRA
							wd_o						=	inst_i[11:7];
							wreg_o						=	`WriteEnable;
							aluop_o						=	`EXE_SRA_OP;
							alusel_o					=	`EXE_RES_SHIFT;
							reg1_read_o					= 	1'b1;
							reg2_read_o					=	1'b1;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						default: begin
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_NOP_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstInvalid;
						end
					endcase
				end
				3'b110: begin //OR
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_OR_OP;
					alusel_o					=	`EXE_RES_LOGIC;
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	1'b1;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b111: begin //AND
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_AND_OP;
					alusel_o					=	`EXE_RES_LOGIC;
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	1'b1;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
					end
				default: begin
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_NOP_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstInvalid;
				end
			endcase
		end
		
		7'b0001111: begin //ZIFENCEI
			case(funct3)
				3'b000: begin //FENCE
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_FENCE_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b001: begin //FENCE.I
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_FENCE_I_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				default: begin
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_NOP_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstInvalid;
				end
			endcase
		end
		
		7'b1110011: begin //SYSTEM
			case(funct3)
				3'b000: begin
					case(inst_i)
						32'b000000000000_00000_000_00000_1110011: begin //ECALL
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_ECALL_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						32'b000000000001_00000_000_00000_1110011: begin //EBREAK
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_EBREAK_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						32'b0000000_00010_00000_000_00000_1110011: begin //URET
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_URET_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						32'b0001000_00010_00000_000_00000_1110011: begin //SRET
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_SRET_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						32'b0011000_00010_00000_000_00000_1110011: begin //MRET
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_MRET_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
							
							eret						=	`True_v;
							
						end
						32'b0001000_00101_00000_000_00000_1110011: begin //WFI
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_WFI_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstValid;
						end
						default: begin
							wd_o						=	`NOPRegAddr;
							wreg_o						=	`WriteDisable;
							aluop_o						=	`EXE_NOP_OP;
							alusel_o					=	`EXE_RES_NOP;
							reg1_read_o					= 	0;
							reg2_read_o					=	0;
							imm 						= 	`ZeroWord;
							link_addr_o					=	`ZeroWord;
							branch_tar_addr_real_o		=	`ZeroWord;
							branch_flag_real_o			=	`NotBranch;
							instvalid 					=	`InstInvalid;
						end
					endcase
				end
				3'b001: begin //CSRRW
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_CSR_OP;
					alusel_o					=	`EXE_RES_MOVE;
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b010: begin //CSRRS
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_CSR_OP;
					alusel_o					=	`EXE_RES_MOVE;
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b011: begin //CSRRC
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_CSR_OP;
					alusel_o					=	`EXE_RES_MOVE;
					reg1_read_o					= 	1'b1;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b101: begin //CSRRWI
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_CSR_OP;
					alusel_o					=	`EXE_RES_MOVE;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	{27'h0, inst_i[19:15]};
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b110: begin //CSRRSI
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_CSR_OP;
					alusel_o					=	`EXE_RES_MOVE;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	{27'h0, inst_i[19:15]};
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				3'b111: begin //CSRRCI
					wd_o						=	inst_i[11:7];
					wreg_o						=	`WriteEnable;
					aluop_o						=	`EXE_CSR_OP;
					alusel_o					=	`EXE_RES_MOVE;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	{27'h0, inst_i[19:15]};
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstValid;
				end
				default: begin
					wd_o						=	`NOPRegAddr;
					wreg_o						=	`WriteDisable;
					aluop_o						=	`EXE_NOP_OP;
					alusel_o					=	`EXE_RES_NOP;
					reg1_read_o					= 	0;
					reg2_read_o					=	0;
					imm 						= 	`ZeroWord;
					link_addr_o					=	`ZeroWord;
					branch_tar_addr_real_o		=	`ZeroWord;
					branch_flag_real_o			=	`NotBranch;
					instvalid 					=	`InstInvalid;
				end
			endcase
		end
		
		default: begin
			wd_o						=	`NOPRegAddr;
			wreg_o						=	`WriteDisable;
			aluop_o						=	`EXE_NOP_OP;
			alusel_o					=	`EXE_RES_NOP;
			reg1_read_o					= 	0;
			reg2_read_o					=	0;
			imm 						= 	`ZeroWord;
			link_addr_o					=	`ZeroWord;
			branch_tar_addr_real_o		=	`ZeroWord;
			branch_flag_real_o			=	`NotBranch;
			instvalid 					=	`InstInvalid;
		end
	endcase
end


//=======================================================================
always @(*) begin //data dep
	if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o))
		reg1_o = ex_wdata_i;
	else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o))
		reg1_o = mem_wdata_i;
	else if(reg1_read_o == 1'b1) 
		reg1_o = reg1_data_i; 
	else
		reg1_o = imm; // if reg1_read_o == 0, read imm
end

always @(*) begin
	if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o))
		reg2_o = ex_wdata_i;
	else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o))
		reg2_o = mem_wdata_i;
	else if(reg2_read_o == 1'b1) 
		reg2_o = reg2_data_i;
	else
		reg2_o = imm; // if reg2_read_o == 0, read imm
end

//----------------------------------------------------
assign load_dep = (ex_aluop_i == `EXE_LB_OP		||
					ex_aluop_i == `EXE_LBU_OP	||
					ex_aluop_i == `EXE_LH_OP	||
					ex_aluop_i == `EXE_LHU_OP	||
					ex_aluop_i == `EXE_LW_OP
					//ex_aluop_i == `EXE_LWR_OP	||
					//ex_aluop_i == `EXE_LWL_OP	||
					//ex_aluop_i == `EXE_LL_OP	||
					//ex_aluop_i == `EXE_SC_OP	
					) ? 1'b1 : 1'b0 ;

always @(*) begin //load dep
	if((reg1_read_o == 1'b1) && (load_dep == 1'b1) && (ex_wd_i == reg1_addr_o))
		stallreq_from_id1 = `Stop;
	else
		stallreq_from_id1 = `NoStop;
end

always @(*) begin
	if((reg2_read_o == 1'b1) && (load_dep == 1'b1) && (ex_wd_i == reg2_addr_o))
		stallreq_from_id2 = `Stop;
	else                   
		stallreq_from_id2 = `NoStop;
end

assign stallreq = stallreq_from_id1 | stallreq_from_id2;

//##################################################################################################
/*always @(*) begin
	if(stallreq_from_ex == `Stop)
		stall = 6'b001111; //1=stop, continue from next of ex
	else if(stallreq_from_id == `Stop)
		stall = 6'b000111; //1=stop, continue from next of id
	else
		stall = 0;
end */


endmodule