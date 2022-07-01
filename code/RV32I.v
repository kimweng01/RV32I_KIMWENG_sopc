`include	"define.v"

module RV32I(
	input							clk,
	input							rst,
	
	//======================================
	input			[`RegBus]		rom_data_i,
	
	output			[`RegBus]		rom_addr_o,
	output							rom_ce_o,
	
	//=======================================
	input			[`RegBus]		ram_data_i,
	
	output			[`RegBus]		ram_addr_o,
	output			[`RegBus]		ram_data_o,
	output							ram_we_o,
	output			[3:0]			ram_sel_o,
	output							ram_ce_o,
	
	//========================================
	input			[15:0]			int_i,
	
	output							timer_int_o
	);
	
/*	//ctrl
	wire							stall_from_id;
	wire        					stall_from_ex;
	        
	wire       		[5:0]			stall;		*/
		
	
	//ID~IF
	wire			[`RegBus]		id_btaddr_o;
	wire							id_brflag_o;
	
	
	//IF/FD~ID
	wire			[`InstAddrBus]	pc;
	wire			[`InstAddrBus]	id_pc_i;
	wire			[`RegBus]		id_inst_i;
	wire			[`RegBus]		branch_target_address_i;
	wire							branch_flag_i;
	
	wire							stall_from_id;
	wire        					stall_from_ex;	 
	
	wire			[`RegBus]		id_excepttype_o;
	wire			[`RegBus]		id_current_inst_addr_o;
	
	
	//ID/EX~ID
	//wire							dlyslot_now;
	
	
	//ID~ID/EX
	wire			[`RegBus]		id_inst_o;
	
	wire			[`AluOpBus]		id_aluop_o;
	wire			[`AluSelBus]	id_alusel_o;
	
	wire			[`RegBus]		id_reg1_o;
	wire			[`RegBus]		id_reg2_o;
	wire							id_wreg_o;
	wire			[`RegAddrBus]	id_wd_o;
	
	//wire							id_dlyslot_now_o;
	wire			[`RegBus]		id_link_addr;
	//wire							next_dlyslot;
	wire			[`RegBus]		id_btaddr;
	wire							id_brflag;
	
	
	//ID/EX~EX
	wire			[`RegBus]		ex_inst_i;
	
	wire			[`AluOpBus]		ex_aluop_i;
	wire			[`AluSelBus]	ex_alusel_i;
	
	wire			[`RegBus]		ex_reg1_i;
	wire			[`RegBus]		ex_reg2_i;
	wire							ex_wreg_i;
	wire			[`RegAddrBus]	ex_wd_i;
	
	wire			[`RegBus]		ex_link_addr_i;
    wire							ex_dlyslot_now_i;
	
	wire			[`RegBus]		ex_current_inst_addr_i;
	wire			[`RegBus]		ex_excepttype_i;
	

	//EX~EX/MEM
	wire							ex_wreg_o;
	wire			[`RegAddrBus]	ex_wd_o;
	wire			[`RegBus]		ex_wdata_o;
	
	//wire			[`RegBus]		ex_hi_o;	
	//wire			[`RegBus]		ex_lo_o;
	//wire							ex_whilo_o;
	
	wire			[`AluOpBus]		ex_aluop_o;
	wire			[`RegBus]		ex_mem_addr_o;
	wire			[`RegBus]		ex_reg2_o;
		
	//wire			[`DoubleRegBus]	ex_maddsub_temp_o;
	//wire			[`DoubleRegBus]	ex_div_temp_o;
	
	//wire							ex_cnt_mult_o;
	//wire			[4:0]			ex_cnt_div_o;
	
	//wire			[`DoubleRegBus]	ex_maddsub_temp_i;
	//wire			[`DoubleRegBus]	ex_div_temp_i;
	
	//wire							ex_cnt_mult_i;
	//wire			[4:0]			ex_cnt_div_i;
	
	wire							ex_csr_reg_we_o;
	wire			[4:0]			ex_csr_reg_wr_addr_o;
	wire			[`RegBus]		ex_csr_reg_data_o;
	
	wire			[4:0]			ex_csr_reg_rd_addr_o;
	
	//wire					 		ex_dlyslot_now_o;
	wire			[`RegBus]		ex_excepttype_o;
	wire			[`RegBus]		ex_current_inst_addr_o; 
	
	
	//EX/MEM~MEM
	wire							mem_wreg_i;
	wire			[`RegAddrBus]	mem_wd_i;
	wire			[`RegBus]		mem_wdata_i;
	
	//wire			[`RegBus]		mem_hi_i;	
	//wire			[`RegBus]		mem_lo_i;
	//wire							mem_whilo_i;
	
	wire			[`AluOpBus]		mem_aluop_i;
	wire			[`RegBus]		mem_mem_addr_i;
	wire			[`RegBus]		mem_reg2_i;
	
	wire							mem_csr_reg_we_i;
	wire			[4:0]			mem_csr_reg_wr_addr_i;
	wire			[`RegBus]		mem_csr_reg_data_i;
	
	//wire							mem_dlyslot_now_i;
	wire			[`RegBus]		mem_current_inst_addr_i;
	wire			[`RegBus]		mem_excepttype_i;
	
	
	//MEM~MEM/WB
	wire							mem_wreg_o;
	wire			[`RegAddrBus]	mem_wd_o;
	wire			[`RegBus]		mem_wdata_o;
	
	//wire			[`RegBus]		mem_hi_o;
	//wire			[`RegBus]		mem_lo_o;
	//wire							mem_whilo_o;
	
	//wire							mem_LLbit_we_o;
	//wire							mem_LLbit_value_o;
	
	wire							mem_csr_reg_we_o;
	wire			[4:0]			mem_csr_reg_wr_addr_o;
	wire			[`RegBus]		mem_csr_reg_data_o;
	
	
	//MEM/WB~Regfile
	wire							wb_wreg_i;
	wire			[`RegAddrBus]	wb_wd_i;
	wire			[`RegBus]		wb_wdata_i;
	
	
	//MEM/WB~HILO
	wire							wb_whilo_i;
	wire 			[`RegBus]		wb_hi_i;
	wire 			[`RegBus]		wb_lo_i;
	
	
	//HILO~EX
	wire 			[`RegBus]		wb_hi_o;
	wire 			[`RegBus]		wb_lo_o;
	
	
	//~LLbit
	//wire							flush;
	
	
	//MEM/WEB~LLbit
	wire							wb_LLbit_we_i;
	wire							wb_LLbit_value_i;
	
	
	//LLbit~MEM
	wire							wb_LLbit_o;
	
	
	//MEM~Hazard
	wire			[`RegBus]		mem_csr_mepc_o;
	
	
	//MEM~CP0
	wire							mem_dlyslot_now_o;
	wire			[`RegBus]		mem_excepttype_o;
	wire			[`RegBus]		mem_current_inst_addr_o;
	
	
	//MEM/WB~CP0
	wire							wb_csr_reg_we_i;
	wire			[4:0]			wb_csr_reg_wr_addr_i;
	wire			[`RegBus]		wb_csr_reg_data_i;

	
	//CP0~EX
	wire			[`RegBus]		csr_reg_data_o;
	
	
	//CP0~MEM
	/*wire			[`RegBus]		mem_csr_reg_we_i;
	wire			[`RegBus]		mem_csr_reg_wr_addr_i;
	wire			[`RegBus]		mem_csr_reg_data_i;	*/
	
	wire							mem_csr_mstatus_i;
	wire			[4:0]			mem_csr_mcause_i;
	wire			[`RegBus]		mem_csr_mepc_i;
	
	wire			[`RegBus]		mstatus_o;
	wire			[`RegBus]		mcause_o;
	wire			[`RegBus]		mepc_o;
	
	
	//Regfile
	wire							reg1_read;
	wire							reg2_read;
	wire			[`RegBus]		reg1_data;
	wire			[`RegBus]		reg2_data;
	wire			[`RegAddrBus]	reg1_addr;
	wire			[`RegAddrBus]	reg2_addr;
	
	
	//Hazard~
	wire			[5:0]			stall;
	wire							flush;
	wire			[`RegBus]		new_pc;
	
	
	//CLINT
	wire							clint_we_o;
	wire			[`RegBus]		clint_addr_o;
	wire			[`RegBus]		clint_data_o;
							
	wire			[`RegBus]		clint_data_i;

	
	//PLIC				
	wire							int_real;
	wire							time_up;
	


//IF
If If0(
	.clk						(clk),
	.rst						(rst),
	
	.branch_tar_addr_pred		(branch_tar_addr_pred),
	.branch_flag_pred			(branch_flag_pred),
	
	//-----------------------------
	.pc							(pc),
	.new_pc						(new_pc),
	.ce							(rom_ce_o),

	//-----------------------------
	.stall						(stall),
	.flush						(flush)
	);
	
assign	rom_addr_o = pc; //pc+4 for rom_addr_o


//IF/RD
if_id if_id0(
	.clk			(clk),
	.rst			(rst),
	
	.if_pc	 		(pc),
	.if_inst		(rom_data_i),
	
	//-----------------------------
	.id_pc			(id_pc_i),
	.id_inst		(id_inst_i),
		
	//-----------------------------
	.stall			(stall),
	.flush			(flush),
	
	//------------------------------
	.branch_tar_addr_pred	(branch_tar_addr_pred),
	.branch_flag_pred		(branch_flag_pred)
	);

	
//ID
id id0(
	//.rst						(rst),
	
	.pc_i						(id_pc_i),
	.inst_i						(id_inst_i),
				
	.reg1_data_i				(reg1_data),
	.reg2_data_i				(reg2_data),
	.reg1_read_o				(reg1_read),
	.reg2_read_o				(reg2_read),
	.reg1_addr_o				(reg1_addr),
	.reg2_addr_o				(reg2_addr),
				
	.ex_wd_i					(ex_wd_o),
    .ex_wreg_i     				(ex_wreg_o),
    .ex_wdata_i     			(ex_wdata_o),
	.ex_aluop_i					(ex_aluop_o),
				
    .mem_wd_i					(mem_wd_o),
    .mem_wreg_i    				(mem_wreg_o),
    .mem_wdata_i    			(mem_wdata_o),
				
	//.dlyslot_now_i				(dlyslot_now),

	//=======================================
	.inst_o						(id_inst_o),
				
	.aluop_o					(id_aluop_o),
	.alusel_o					(id_alusel_o),
				
	.reg1_o						(id_reg1_o),
	.reg2_o						(id_reg2_o),
	.wd_o						(id_wd_o),
	.wreg_o						(id_wreg_o),
	
	//.dlyslot_now_o				(id_dlyslot_now_o),
	.link_addr_o				(id_link_addr),
	//.branch_tar_addr_real_o		(branch_tar_addr_real),
	//.branch_flag_real_o			(branch_flag_real),
	//.next_dlyslot_o				(next_dlyslot),
	.branch_tar_addr_real_o		(id_branch_tar_addr_real_o),
	.branch_flag_real_o			(id_branch_flag_real_o),
	
	.excepttype_o				(id_excepttype_o),
	.current_inst_addr_o		(id_current_inst_addr_o),
	
	//=======================================
	/*.rst						(rst),
			
	.stallreq_from_id			(stall_from_id),
	.stallreq_from_ex			(stall_from_ex),
			
	.stall						(stall), */
	.stallreq					(stall_from_id)
	);

	
//Regfile
regfile regfile0(
	.clk			(clk),
	.rst			(rst),
	
	//-------------------------------
	.we				(wb_wreg_i),
	.waddr			(wb_wd_i),
	.wdata			(wb_wdata_i),
	
	//===============================
	.re1			(reg1_read),
	.raddr1			(reg1_addr),
	.rdata1			(reg1_data),
	.re2			(reg2_read),
	.raddr2			(reg2_addr),
	.rdata2			(reg2_data)
	);

	
//ID/EX
id_ex id_ex0(
	.clk					(clk),
	.rst					(rst),
			
	.id_inst				(id_inst_o),
			
	.id_aluop				(id_aluop_o),
	.id_alusel				(id_alusel_o),
			
	.id_reg1				(id_reg1_o),
	.id_reg2				(id_reg2_o),
	.id_wd					(id_wd_o),
	.id_wreg				(id_wreg_o),
		
	//.id_dlyslot_now			(id_dlyslot_now_o),
	.id_link_addr			(id_link_addr),
	//.next_dlyslot			(next_dlyslot),
	
	.id_branch_tar_addr_real(id_branch_tar_addr_real_o),
	.id_branch_flag_real	(id_branch_flag_rea_o),	
	
	.id_current_inst_addr	(id_current_inst_addr_o),
	.id_excepttype			(id_excepttype_o),
	
	//==========================================
	.ex_inst				(ex_inst_i),
	
	.ex_aluop				(ex_aluop_i),
	.ex_alusel				(ex_alusel_i),
	
	.ex_reg1				(ex_reg1_i),
	.ex_reg2				(ex_reg2_i),
	.ex_wd					(ex_wd_i),
	.ex_wreg				(ex_wreg_i),
		
	.ex_link_addr			(ex_link_addr_i),
	//.ex_dlyslot_now			(ex_dlyslot_now_i),
	//.dlyslot_now			(dlyslot_now),
	
	.ex_branch_tar_addr_real(ex_branch_tar_addr_real_i),
	.ex_branch_flag_real	(ex_branch_flag_rea_i),	
	
	
	.ex_current_inst_addr	(ex_current_inst_addr_i),
	.ex_excepttype			(ex_excepttype_i),

	//-----------------------------
	.stall					(stall),
	.flush					(flush)
	);

	
//EX
ex ex0(
	//.rst				(rst),
	
	.inst_i				(ex_inst_i),
			
	.aluop_i			(ex_aluop_i),
	.alusel_i			(ex_alusel_i),
			
	.reg1_i				(ex_reg1_i),
	.reg2_i				(ex_reg2_i),
			
	.wd_i				(ex_wd_i),
	.wreg_i				(ex_wreg_i),
	
	//----------------------------------
	//.hi_i				(wb_hi_o),
	//.lo_i				(wb_lo_o),
	
	//.wb_hi_i			(wb_hi_i),
	//.wb_lo_i			(wb_lo_i),
	//.wb_whilo_i			(wb_whilo_i),
		
	//.mem_hi_i			(mem_hi_o),
	//.mem_lo_i			(mem_lo_o),
	//.mem_whilo_i		(mem_whilo_o),
	
	//------------------------------------
	.annul_i			(1'b0),
	
	//.maddsub_temp_i		(ex_maddsub_temp_i),
	//.div_temp_i			(ex_div_temp_i),
	
	//.cnt_mult_i			(ex_cnt_mult_i),
	//.cnt_div_i			(ex_cnt_div_i),
	
	.link_addr_i		(ex_link_addr_i),
	//.dlyslot_now_i		(ex_dlyslot_now_i),
	
	//**********************************
	.mem_csr_reg_we		(mem_csr_reg_we_o),
	.mem_csr_reg_wr_addr(mem_csr_reg_wr_addr_o),
	.mem_csr_reg_data	(mem_csr_reg_data_o),
	
	.wb_csr_reg_we		(wb_csr_reg_we_i),
	.wb_csr_reg_wr_addr	(wb_csr_reg_wr_addr_i),
	.wb_csr_reg_data   	(wb_csr_reg_data_i),
	
	.csr_reg_data_i		(csr_reg_data_o),
	
	//++++++++++++++++++++++++++++++++++
	.current_inst_addr_i(ex_current_inst_addr_i),
	.excepttype_i		(ex_excepttype_i),

	.branch_tar_addr_real_i	(ex_branch_tar_addr_real_i),
	.branch_flag_real_i		(ex_excepttype_i),	
		
	//============================================
	.inst_o				(ex_inst_o),
	
	.wd_o				(ex_wd_o),
	.wreg_o				(ex_wreg_o),
	.wdata_o			(ex_wdata_o),
	
	//-----------------------------------
	//.hi_o				(ex_hi_o),
	//.lo_o				(ex_lo_o),
	//.whilo_o			(ex_whilo_o),
	
	//-----------------------------------
	//.maddsub_temp_o		(ex_maddsub_temp_o),
	//.div_temp_o			(ex_div_temp_o),
		
	//.cnt_mult_o			(ex_cnt_mult_o),
	//.cnt_div_o			(ex_cnt_div_o),
	
	//----------------------------------
	.aluop_o			(ex_aluop_o),
	.mem_addr_o			(ex_mem_addr_o),
	.reg2_o				(ex_reg2_o),
	
	//***********************************
	.csr_reg_we_o		(ex_csr_reg_we_o),
	.csr_reg_wr_addr_o  (ex_csr_reg_wr_addr_o),	
	.csr_reg_data_o     (ex_csr_reg_data_o),	

	.csr_reg_rd_addr_o  (ex_csr_reg_rd_addr_o),
	
	//++++++++++++++++++++++++++++++++++++
	.branch_tar_addr_real_o	(ex_branch_tar_addr_real_o),
	.branch_flag_real_o		(ex_branch_flag_real_o),
	
	.stallreq			(stall_from_ex),
	
	//.dlyslot_now_o		(ex_dlyslot_now_o),
	.excepttype_o		(ex_excepttype_o),
	.current_inst_addr_o(ex_current_inst_addr_o),
	
	.trapassert_o		(ex_trapassert_o)
	);

	
//EX/MEM
ex_mem	ex_mem0(	
	.clk					(clk),
	.rst					(rst),
	
	.ex_inst				(ex_inst_o),
	
	.ex_wd					(ex_wd_o),
	.ex_wreg				(ex_wreg_o),
	.ex_wdata				(ex_wdata_o),
			
	//.ex_hi					(ex_hi_o),	
	//.ex_lo					(ex_lo_o),
	//.ex_whilo				(ex_whilo_o),
			
	.ex_aluop				(ex_aluop_o),
	.ex_mem_addr			(ex_mem_addr_o),
	.ex_reg2				(ex_reg2_o),
	
	//.ex_branch_tar_addr_real(ex_branch_tar_addr_real_o),
	//.ex_branch_flag_real	(ex_branch_flag_real_o),

	//---------------------------------
	.mem_inst				(mem_inst_i),
	
	.mem_wd					(mem_wd_i),
	.mem_wreg				(mem_wreg_i),
	.mem_wdata				(mem_wdata_i),
			
	//.mem_hi					(mem_hi_i),	
	//.mem_lo         		(mem_lo_i),
	//.mem_whilo      		(mem_whilo_i),
			
	.mem_aluop				(mem_aluop_i),
	.mem_mem_addr			(mem_mem_addr_i),
	.mem_reg2				(mem_reg2_i),
		
	//-----------------------------
	//.maddsub_temp_i			(ex_maddsub_temp_o),
	//.div_temp_i				(ex_div_temp_o),
			
	//.cnt_mult_i				(ex_cnt_mult_o),
	//.cnt_div_i				(ex_cnt_div_o),
			
	//.maddsub_temp_o			(ex_maddsub_temp_i),
	//.div_temp_o				(ex_div_temp_i),
			
	//.cnt_mult_o				(ex_cnt_mult_i),
	//.cnt_div_o				(ex_cnt_div_i),
	
	//--------------------------------
	.ex_csr_reg_we			(ex_csr_reg_we_o),
	.ex_csr_reg_wr_addr 	(ex_csr_reg_wr_addr_o),	
	.ex_csr_reg_data    	(ex_csr_reg_data_o),
		
	.mem_csr_reg_we			(mem_csr_reg_we_i),
	.mem_csr_reg_wr_addr	(mem_csr_reg_wr_addr_i),
	.mem_csr_reg_data   	(mem_csr_reg_data_i),
	
	//---------------------------------
	//.ex_dlyslot_now			(ex_dlyslot_now_o),
	.ex_current_inst_addr	(ex_current_inst_addr_o),
	.ex_excepttype			(ex_excepttype_o), 
	
	//.mem_dlyslot_now		(mem_dlyslot_now_i),
	.mem_current_inst_addr	(mem_current_inst_addr_i),
	.mem_excepttype			(mem_excepttype_i),
	
	.mem_branch_tar_addr_real(hazard_branch_tar_addr_real_i),
	.mem_branch_flag_real	 (hazard_branch_flag_real_i),
	//---------------------------------
	.stall					(stall),
	.flush					(flush),
	
	//---------------------------------
	.ex_trapassert			(ex_trapassert_o),
	.mem_trapassert         (mem_trapassert_i)
	);

	
//MEM
mem mem0(
	//.rst					(rst),
	
	.wd_i					(mem_wd_i),
	.wreg_i					(mem_wreg_i),
	.wdata_i				(mem_wdata_i),
			
	//.hi_i					(mem_hi_i),
	//.lo_i					(mem_lo_i),
	//.whilo_i				(mem_whilo_i),
			
	.aluop_i				(mem_aluop_i),
	.mem_addr_i				(mem_mem_addr_i),
	.reg2_i					(mem_reg2_i),
			
	.mem_data_i				(cpu_data_o), //from wishbone for data
		
	//.LLbit_i				(wb_LLbit_o),
	//.wb_LLbit_we_i			(wb_LLbit_we_i),
	//.wb_LLbit_value_i		(wb_LLbit_value_i),
		
	.wb_csr_reg_we_i		(wb_csr_reg_we_i),
	.wb_csr_reg_wr_addr_i	(wb_csr_reg_wr_addr_i),
	.wb_csr_reg_data_i		(wb_csr_reg_data_i),
		
	.csr_mstatus_i			(mstatus_o),
	.csr_mcause_i			(mcause_o),
	.csr_mepc_i				(mepc_o),
	
	.csr_reg_we_i			(mem_csr_reg_we_i),
	.csr_reg_wr_addr_i		(mem_csr_reg_wr_addr_i),
	.csr_reg_data_i   		(mem_csr_reg_data_i),
	
	//.dlyslot_now_i			(mem_dlyslot_now_i),
	.current_inst_addr_i	(mem_current_inst_addr_i),
	.excepttype_i			(mem_excepttype_i),
	
	.int_i					(int_real),
	.time_up_i				(time_up),
	
	.trapassert_i			(mem_trapassert_i),
	//-------------------------
	.wd_o					(mem_wd_o),
	.wreg_o					(mem_wreg_o),
	.wdata_o				(mem_wdata_o),
			
	//.hi_o					(mem_hi_o),
	//.lo_o					(mem_lo_o),
	//.whilo_o				(mem_whilo_o),
			
	.mem_addr_o				(ram_addr_o),
	.mem_we_o				(ram_we_o),
	.mem_sel_o				(ram_sel_o),
	.mem_data_o				(ram_data_o),
	.mem_ce_o				(ram_ce_o),
			
	//.LLbit_we_o				(mem_LLbit_we_o),
	//.LLbit_value_o			(mem_LLbit_value_o),
		
	.csr_reg_we_o			(mem_csr_reg_we_o),
	.csr_reg_wr_addr_o		(mem_csr_reg_wr_addr_o),
	.csr_reg_data_o  		(mem_csr_reg_data_o),
		
	//.dlyslot_now_o			(mem_dlyslot_now_o),
	.excepttype_o			(mem_excepttype_o),
	.current_inst_addr_o	(mem_current_inst_addr_o),
		
	.csr_mepc_o				(mem_csr_mepc_o),
	.csr_mtvec_o			(mem_csr_mtvec_o)
	);

	
//MEM/WB
mem_wb mem_wb0(
	.clk					(clk),
	.rst					(rst),
			
	.mem_wd					(mem_wd_o),
	.mem_wreg				(mem_wreg_o),
	.mem_wdata				(mem_wdata_o),
			
	//.mem_hi					(mem_hi_o),
	//.mem_lo         		(mem_lo_o),
	//.mem_whilo      		(mem_whilo_o),
			
	//.mem_LLbit_we			(mem_LLbit_we_o),
	//.mem_LLbit_value		(mem_LLbit_value_o),
	
	.mem_csr_reg_we			(mem_csr_reg_we_o),
	.mem_csr_reg_wr_addr	(mem_csr_reg_wr_addr_o),
	.mem_csr_reg_data		(mem_csr_reg_data_o),
	
	//=========================================
	.wb_wd					(wb_wd_i),
	.wb_wreg				(wb_wreg_i),
	.wb_wdata				(wb_wdata_i),
			
	//.wb_hi					(wb_hi_i),
	//.wb_lo					(wb_lo_i),
	//.wb_whilo				(wb_whilo_i),
			
	//-----------------------------
	//.wb_LLbit_we			(wb_LLbit_we_i),
	//.wb_LLbit_value			(wb_LLbit_value_i),
	
	//-----------------------------
	.wb_csr_reg_we			(wb_csr_reg_we_i),
	.wb_csr_reg_wr_addr		(wb_csr_reg_wr_addr_i),
	.wb_csr_reg_data		(wb_csr_reg_data_i),
	
	.stall					(stall),
	.flush					(flush)
	);

	
//HILO
//hilo_reg hilo_reg0(
//	.clk			(clk),
//	.rst			(rst),
//	
//	.we				(wb_whilo_i),
//	.hi_i			(wb_hi_i),
//	.lo_i           (wb_lo_i),
//	
//	.hi_o			(wb_hi_o),
//	.lo_o           (wb_lo_o)
//	);
	
	
//LLbit
//LLbit_reg LLbit_reg0(
//	.clk			(clk),
//	.rst			(rst),
//	
//	.flush			(1'b0),
//
//	.LLbit_i		(wb_LLbit_value_i),
//	.we				(wb_LLbit_we_i),
//	
//	//----------------------------
//	.LLbit_o		(wb_LLbit_o)
//	);

	
//CSR
csr csr0(
	.clk				(clk),	
	.rst            	(rst),
	
	.inst_i				(mem_inst_i),

	.we_i           	(wb_csr_reg_we_i),
	.waddr_i       	 	(wb_csr_reg_wr_addr_i),
	.raddr_i			(ex_csr_reg_rd_addr_o),
	.data_i       	 	(wb_csr_reg_data_i),

	//.int_i				(int_i), //INPUT
	
	//.dlyslot_now_i		(mem_dlyslot_now_o),
	.excepttype_i		(mem_excepttype_o),
	.current_inst_addr_i(mem_current_inst_addr_o),
	
	//----------------------------
	.data_o				(csr_reg_data_o),
	//.count_o       	(count_o),
	//.compare_o		(compare_o),
	.mtvec_o			(mtvec_o),
	.mcause_o			(mcause_o),
	.mepc_o				(mepc_o),
	.mtval_o			(mtval_o),
	.mstatus_o			(mstatus_o),
	
	//.config_o			(config_o),
	//.prid_o			(prid_o),
	
	.timer_int_o		(timer_int_o) //OUTPUT
	);
	
	
//Hazard
hazard hazard0(
	.stallreq_from_if		(1'b0),
	.stallreq_from_id		(stall_from_id),
	.stallreq_from_ex   	(stall_from_ex),
	.stallreq_from_mem  	(1'b0),
	
	.excepttype_i			(mem_excepttype_o),
    .mepc_i					(mem_csr_mepc_o),
    .mtvec_i				(mem_csr_mtvec_o),
	
	.branch_tar_addr_real_i	(hazard_branch_tar_addr_real_i),
	.branch_flag_real_i		(hazard_branch_flag_real_i),
	
    .stall             	 	(stall),
	.flush					(flush),
	
	.new_pc					(new_pc)
	);
	
	
//CLINT
clint clint0(
	.clk			(clk),	
	.rst            (rst),  

	.we_i           (clint_we_o),
	.addr_i        	(clint_addr_o),
	.data_i         (clint_data_o),
	
	//------------------------------------
	.data_o        	(clint_data_i)
	);


//PLIC
plic plic0(
	.int_i			(int_i),
	
	.int_o			(int_real)
	);
	

//wishbone for data
wishbone_buf_if wishbone_buf_if0(
	.cpu_ce_i			(cpu_ce_i),
	.cpu_data_i			(cpu_data_i),
	.cpu_addr_i			(cpu_addr_i),
	.cpu_we_i			(cpu_we_i),
	.cpu_sel_i			(cpu_sel_i),
	
	.cpu_data_o			(cpu_data_o),
	
	//---------------------------------
	.ram_data_i			(ram_data_i),
						
	.ram_ce_o			(ram_ce_o),
	.ram_data_o			(ram_data_o),
	.ram_addr_o			(ram_addr_o),
	.ram_we_o			(ram_we_o),
	.ram_sel_o			(ram_sel_o),
						
						
	.clint_data_i		(clint_data_i),
						
	.clint_ce_o			(clint_ce_o),
	.clint_data_o		(clint_data_o),
	.clint_addr_o		(clint_addr_o),
	.clint_we_o			(clint_we_o)
	);	

	
endmodule