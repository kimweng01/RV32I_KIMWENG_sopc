`include    "define.v"

module mem(
    //input                        rst,

    input        [`RegAddrBus]    wd_i,
    input                         wreg_i,
    input        [`RegBus]        wdata_i,
    
    //input        [`RegBus]        hi_i,
    //input        [`RegBus]        lo_i,
    //input                         whilo_i,
    
    input        [`AluOpBus]      aluop_i,
    input        [`RegBus]        mem_addr_i,
    input        [`RegBus]        reg2_i,
    
    input        [`RegBus]        mem_data_i,
    
    //input                         LLbit_i,
    //input                         wb_LLbit_we_i,
    //input                         wb_LLbit_value_i,
    
    input                         wb_csr_reg_we_i,
    input        [11:0]           wb_csr_reg_addr_i,
    input        [`RegBus]        wb_csr_reg_data_i,
    
    input        [`RegBus]        csr_mstatus_i,
    //input        [`RegBus]        csr_mcause_i, useless
    input        [`RegBus]        csr_mepc_i,
    input        [`RegBus]        csr_mtvec_i,
    //input        [`RegBus]        csr_mtval_i, useless
    input        [`RegBus]        csr_mie_i,
    //input        [`RegBus]        csr_mip_i, useless
    
    input                         csr_reg_we_i,
    input        [11:0]           csr_reg_addr_i,
    input        [`RegBus]        csr_reg_data_i,
    
    //input                         dlyslot_now_i,
    input        [`RegBus]        current_inst_addr_i,
    input        [`RegBus]        excepttype_i,
    
    input                         int_i,
    input                         time_up_i,
    
    //input                        trapassert_i,
    //========================================    
    output reg    [`RegAddrBus]   wd_o,
    output reg                    wreg_o,
    output reg    [`RegBus]       wdata_o,
    
    //output reg    [`RegBus]       hi_o,
    //output reg    [`RegBus]       lo_o,
    //output reg                    whilo_o,
    
    output reg    [`RegBus]       mem_addr_o,
    output                        mem_we_o,
    output reg    [3:0]           mem_sel_o,
    output reg    [`RegBus]       mem_data_o,
    output reg                    mem_ce_o,
    
    //output reg                    LLbit_we_o,
    //output reg                    LLbit_value_o,
    
    output reg                    csr_reg_we_o,
    output reg    [11:0]          csr_reg_addr_o,
    output reg    [`RegBus]       csr_reg_data_o,
    
    //output                         dlyslot_now_o,
    output reg    [`RegBus]       excepttype_o,
    output         [`RegBus]      current_inst_addr_o,
    
    output reg    [`RegBus]       csr_mepc_o,       //要接入Hazard.v
    output reg    [`RegBus]       csr_mtvec_o       //要接入Hazard.v
    );
    
    
    wire        [`RegBus]         zero32;
    reg                           mem_we;
    
    //reg                            LLbit;
    
    
    reg            [`RegBus]      csr_mstatus;
    //reg            [`RegBus]       csr_mcause;
    reg            [`RegBus]      csr_mie;
    //reg            [`RegBus]        csr_mip;
    
    reg            [1:0]          misalign;
    
    wire        [`RegBus]         excepttype_fine;
    
    
    
//assign zero32 = `ZeroWord;

//always @(*) begin
//    if(wb_LLbit_we_i)
//        LLbit = wb_LLbit_value_i; //dependent
//    else
//        LLbit = LLbit_i;
//end


always @(*) begin
    wd_o                = wd_i;
    wreg_o              = wreg_i;
    //wdata_o             = wdata_i;
    
    //hi_o                = hi_i;
    //lo_o                = lo_i;
    //whilo_o             = whilo_i;
    
    csr_reg_we_o        = csr_reg_we_i;        
    csr_reg_addr_o      = csr_reg_addr_i;
    csr_reg_data_o      = csr_reg_data_i;
end


always @(*) begin
/*    wd_o    = wd_i;
    wreg_o    = wreg_i;
    wdata_o = wdata_i;
    
    hi_o    = hi_i;
    lo_o     = lo_i;
    whilo_o    = whilo_i;    */
    if( (csr_mstatus[3] == 1'b1  &&  current_inst_addr_i != `ZeroWord)  && //current_inst_addr_i != `ZeroWord --> wait for new first inst, see textbook 11-40(2)!
        (excepttype_fine[8] | excepttype_fine[10]) ) begin
    //     ^~~~~~~~~~~~~~~~~~   ^~~~~~~~~~~~~~~~~~
    //         ecall                trapassert
        mem_addr_o    = `CLINT_REG_MSIP;
        mem_we      = `WriteEnable;
        mem_ce_o    = `ChipEnable;
        
        //LLbit_we_o    = 0;
        //LLbit_value_o    = 0;
        
        mem_data_o   = 32'b1;
        misalign     = `MisalignNotAssert;
        
        wdata_o      = wdata_i;
        mem_sel_o    = 4'b0000;

    end else begin
        case(aluop_i) //segment read, maintain write
            `EXE_LB_OP: begin
                mem_addr_o  =  mem_addr_i;
                mem_we      = `WriteDisable;
                mem_ce_o    = `ChipEnable;
                
                //LLbit_we_o        = 0;
                //LLbit_value_o    = 0;
                
                mem_data_o  = `ZeroWord;
                misalign    = `MisalignNotAssert;
                case(mem_addr_i[1:0])
                    2'b00: begin
                        wdata_o      = { {24{mem_data_i[31]}}, mem_data_i[31:24] }; //sign extend
                        mem_sel_o    = 4'b0001; //useless, just mark
                    end
                    2'b01: begin
                        wdata_o      = { {24{mem_data_i[23]}}, mem_data_i[23:16] };
                        mem_sel_o    = 4'b0010;
                    end
                    2'b10: begin
                        wdata_o      = { {24{mem_data_i[15]}}, mem_data_i[15:8] };
                        mem_sel_o    = 4'b0100;
                    end
                    default: begin //2'b11
                        wdata_o      = { {24{mem_data_i[7]}}, mem_data_i[7:0] };
                        mem_sel_o    = 4'b1000;
                    end
                endcase
            end
            `EXE_LBU_OP: begin
                mem_addr_o  = mem_addr_i;
                mem_we      = `WriteDisable;
                mem_ce_o    = `ChipEnable;
                
                //LLbit_we_o       = 0;
                //LLbit_value_o    = 0;
                
                mem_data_o    = `ZeroWord;
                misalign    = `MisalignNotAssert;
                case(mem_addr_i[1:0])
                    2'b00: begin
                        wdata_o      = { {24{1'b0}}, mem_data_i[31:24] }; //unsign extend
                        mem_sel_o    = 4'b0001;
                    end
                    2'b01: begin
                        wdata_o      = { {24{1'b0}}, mem_data_i[23:16] };
                        mem_sel_o    = 4'b0010;
                    end
                    2'b10: begin
                        wdata_o      = { {24{1'b0}}, mem_data_i[15:8] };
                        mem_sel_o    = 4'b0100;
                    end
                    default: begin //2'b11
                        wdata_o      = { {24{1'b0}}, mem_data_i[7:0] };
                        mem_sel_o    = 4'b1000;
                    end
                endcase
            end
            `EXE_LH_OP: begin
                mem_addr_o    = mem_addr_i;
                mem_we      = `WriteDisable;
                mem_ce_o    = `ChipEnable;
                
                //LLbit_we_o        = 0;
                //LLbit_value_o    = 0;
                
                mem_data_o    = `ZeroWord;
                misalign    = `MisalignNotAssert;
                case(mem_addr_i[1:0])
                    2'b00: begin
                        wdata_o      = { {16{mem_data_i[31]}}, mem_data_i[31:16] };
                        mem_sel_o    = 4'b0011;
                    end
                    2'b10: begin
                        wdata_o      = { {16{mem_data_i[15]}}, mem_data_i[15:0] };
                        mem_sel_o    = 4'b1100;
                    end
                    default: begin
                        wdata_o      = `ZeroWord;
                        mem_sel_o    = 4'b0000;
                        misalign     = `L_MisalignAssert;
                    end
                endcase
            end
            `EXE_LHU_OP: begin
                mem_addr_o  = mem_addr_i;
                mem_we      = `WriteDisable;
                mem_ce_o    = `ChipEnable;
                
                //LLbit_we_o        = 0;
                //LLbit_value_o    = 0;
                
                mem_data_o    = `ZeroWord;
                misalign    = `MisalignNotAssert;
                case(mem_addr_i[1:0])
                    2'b00: begin
                        wdata_o      = { {16{1'b0}}, mem_data_i[31:16] };
                        mem_sel_o    = 4'b0011;
                    end
                    2'b10: begin
                        wdata_o      = { {16{1'b0}}, mem_data_i[15:0] };
                        mem_sel_o    = 4'b1100;
                    end
                    default: begin
                        wdata_o      = `ZeroWord;
                        mem_sel_o    = 4'b0000;
                        misalign     = `L_MisalignAssert;
                    end
                endcase
            end
            `EXE_LW_OP: begin
                mem_addr_o  = mem_addr_i;
                mem_we      = `WriteDisable;
                mem_ce_o    = `ChipEnable;
                mem_sel_o   = 4'b1111;
                
                //LLbit_we_o        = 0;
                //LLbit_value_o    = 0;
                
                mem_data_o  = `ZeroWord;
                misalign    = `MisalignNotAssert;
                case(mem_addr_i[1:0])
                    2'b00: begin
                        wdata_o      = mem_data_i;
                        mem_sel_o    = 4'b1111;
                    end
                    default: begin //2'b11
                        wdata_o      = `ZeroWord;
                        mem_sel_o    = 4'b0000;
                        misalign     = `L_MisalignAssert;
                    end
                endcase
            end
            //`EXE_LWL_OP: begin
            //    mem_addr_o    = {mem_addr_i[31:2], 2'b00}; //not requires alignment, need to load two zeros.
            //    mem_we        = `WriteDisable;
            //    mem_ce_o      = `ChipEnable;
            //    mem_sel_o     = 4'b1111;
            //    
            //    //LLbit_we_o        = 0;
            //    //LLbit_value_o     = 0;
            //    
            //    mem_data_o    = `ZeroWord;
            //    case(mem_addr_i[1:0])
            //        2'b00:    wdata_o = mem_data_i;
            //        2'b01:    wdata_o = {mem_data_i[23:0], reg2_i[7:0]};
            //        2'b10:    wdata_o = {mem_data_i[15:0], reg2_i[15:0]};
            //        default:wdata_o = {mem_data_i[7:0], reg2_i[23:0]};
            //    endcase
            //end
            //`EXE_LWR_OP: begin
            //    mem_addr_o    = mem_addr_i;
            //    mem_we        = `WriteDisable;
            //    mem_ce_o      = `ChipEnable;
            //    mem_sel_o     = 4'b1111;
            //    
            //    //LLbit_we_o        = 0;
            //    //LLbit_value_o    = 0;
            //    
            //    mem_data_o    = `ZeroWord;
            //    case(mem_addr_i[1:0])
            //        2'b00:    wdata_o = {reg2_i[31:8], mem_data_i[31:24]};
            //        2'b01:    wdata_o = {reg2_i[31:16], mem_data_i[31:16]};
            //        2'b10:    wdata_o = {reg2_i[31:24], mem_data_i[31:8]}; 
            //        default:wdata_o = mem_data_i;
            //    endcase
            //end
            `EXE_SB_OP: begin
                mem_addr_o  = mem_addr_i;
                mem_we      = `WriteEnable;
                mem_ce_o    = `ChipEnable;
                
                //LLbit_we_o        = 0;
                //LLbit_value_o    = 0;
                
                mem_data_o  = {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
                wdata_o     = `ZeroWord;
                misalign    = `MisalignNotAssert;
                case(mem_addr_i[1:0])
                    2'b00: mem_sel_o    = 4'b0001;
                    2'b01: mem_sel_o    = 4'b0010;
                    2'b10: mem_sel_o    = 4'b0100;
                    default: mem_sel_o  = 4'b1000;
                endcase
            end
            `EXE_SH_OP: begin
                mem_addr_o  = mem_addr_i;
                mem_we      = `WriteEnable;
                mem_ce_o    = `ChipEnable;
                
                //LLbit_we_o        = 0;
                //LLbit_value_o    = 0;
                
                mem_data_o  = {reg2_i[15:0], reg2_i[15:0]};
                wdata_o     = `ZeroWord;
                misalign    = `MisalignNotAssert;
                case(mem_addr_i[1:0])
                    2'b00: mem_sel_o    = 4'b0011;
                    2'b10: mem_sel_o    = 4'b1100;
                    default: begin
                        mem_sel_o       = 4'b0000;
                        misalign        = `MisalignNotAssert;
                    end
                endcase
            end
            `EXE_SW_OP: begin
                mem_addr_o    = mem_addr_i;
                mem_we        = `WriteEnable;
                mem_ce_o      = `ChipEnable;
                
                //LLbit_we_o        = 0;
                //LLbit_value_o    = 0;
                
                mem_data_o    = reg2_i;
                wdata_o       = `ZeroWord;
                misalign      = `MisalignNotAssert;
                case(mem_addr_i[1:0])
                    2'b00: mem_sel_o    = 4'b1111;
                    default: begin
                        mem_sel_o       = 4'b0000;
                        misalign        = `MisalignNotAssert;
                    end
                endcase
            //end
            //`EXE_SWL_OP: begin
            //    mem_addr_o    = mem_addr_i;
            //    mem_we        = `WriteEnable;
            //    mem_ce_o      = `ChipEnable;
            //    
            //    //LLbit_we_o     = 0;
            //    //LLbit_value_o  = 0;    
            //    
            //    wdata_o      = `ZeroWord;
            //    case(mem_addr_i[1:0])
            //        2'b00: begin
            //            mem_data_o   = reg2_i;
            //            mem_sel_o    = 4'b1111;
            //        end
            //        2'b01: begin
            //            mem_data_o   = {zero32[7:0], reg2_i[31:8]}; //zero32 useless
            //            mem_sel_o    = 4'b0111;
            //        end
            //        2'b10: begin
            //            mem_data_o   = {zero32[15:0], reg2_i[31:16]};
            //            mem_sel_o    = 4'b0011;
            //        end
            //        default: begin //2'b11
            //            mem_data_o   = {zero32[23:0], reg2_i[31:24]};
            //            mem_sel_o    = 4'b0001;
            //        end
            //    endcase
            //end
            //`EXE_SWR_OP: begin
            //    mem_addr_o  = mem_addr_i;
            //    mem_we      = `WriteEnable;
            //    mem_ce_o    = `ChipEnable;
            //    
            //    //LLbit_we_o       = 0;
            //    //LLbit_value_o    = 0;    
            //    
            //    wdata_o     = `ZeroWord;
            //    case(mem_addr_i[1:0])
            //        2'b00: begin
            //            mem_data_o   = {reg2_i[7:0], zero32[23:0]};
            //            mem_sel_o    = 4'b1000;
            //        end
            //        2'b01: begin
            //            mem_data_o   = {reg2_i[15:0], zero32[15:0]};
            //            mem_sel_o    = 4'b1100;
            //        end
            //        2'b10: begin
            //            mem_data_o   = {reg2_i[23:0], zero32[7:0]};
            //            mem_sel_o    = 4'b1110;
            //        end
            //        default: begin //2'b11
            //            mem_data_o   = reg2_i;
            //            mem_sel_o    = 4'b1111;
            //        end
            //    endcase
            //end
            //`EXE_LL_OP: begin
            //    mem_addr_o  = mem_addr_i;
            //    mem_we      = `WriteDisable;
            //    mem_ce_o    = `ChipEnable;
            //    
            //    //LLbit_we_o       = 1'b1;
            //    //LLbit_value_o    = 1'b1;
            //    
            //    wdata_o      = mem_data_i;
            //    mem_data_o   = `ZeroWord;
            //    mem_sel_o    = 4'b1111;
            //end
            //`EXE_SC_OP: begin
            //    if(LLbit) begin
            //        mem_addr_o  = mem_addr_i;
            //        mem_we      = `WriteEnable;
            //        mem_ce_o    = `ChipEnable;
            //        
            //        //LLbit_we_o       = 1'b1;
            //        //LLbit_value_o    = 0;
            //        
            //        wdata_o      = 32'b1;
            //        mem_data_o   = reg2_i;
            //        mem_sel_o    = 4'b1111;
            //    end else begin
            //        mem_addr_o    = mem_addr_i;
            //        mem_we      = `WriteDisable;
            //        mem_ce_o    = `ChipDisable;
            //        
            //        //LLbit_we_o       = 0;
            //        //LLbit_value_o    = 0;
            //        
            //        wdata_o      = `ZeroWord;
            //        mem_data_o   = `ZeroWord;
            //        mem_sel_o    = 4'b0000;
            //    end
            end
            default: begin //other inst
                mem_addr_o  = mem_addr_i;
                mem_we      = `WriteDisable;
                mem_ce_o    = `ChipDisable;
                
                //LLbit_we_o        = 0;
                //LLbit_value_o    = 0;
                
                wdata_o     = wdata_i;
                misalign    = `MisalignNotAssert;
                
                mem_data_o  = `ZeroWord;
                mem_sel_o   = 4'b0000;
            end
        endcase
    end
end


//===========================================================================
//assign dlyslot_now_o         = dlyslot_now_i;
assign current_inst_addr_o     = current_inst_addr_i;

//-----------------------------------------------
always @(*) begin
    if(wb_csr_reg_we_i == `WriteEnable  &&  wb_csr_reg_addr_i == `CSR_REG_MSTATUS)
        csr_mstatus = wb_csr_reg_data_i;
    else  
        csr_mstatus = csr_mstatus_i;
end

//always @(*) begin        //USELESS!!!
//    if(wb_csr_reg_we_i == `WriteEnable  &&  wb_csr_reg_addr_i == `CSR_REG_MCAUSE)
//        csr_mcause = wb_csr_reg_data_i;
//    else
//        csr_mcause = csr_mcause_i;
//end 

always @(*) begin
    if(wb_csr_reg_we_i == `WriteEnable  &&  wb_csr_reg_addr_i == `CSR_REG_MEPC)
        csr_mepc_o = wb_csr_reg_data_i;
    else  
        csr_mepc_o = csr_mepc_i;
end

always @(*) begin
    if(wb_csr_reg_we_i == `WriteEnable  &&  wb_csr_reg_addr_i == `CSR_REG_MTVEC)
        csr_mtvec_o = wb_csr_reg_data_i;
    else  
        csr_mtvec_o = csr_mtvec_i;
end

always @(*) begin
    if(wb_csr_reg_we_i == `WriteEnable  &&  wb_csr_reg_addr_i == `CSR_REG_MIE)
        csr_mie = wb_csr_reg_data_i;
    else  
        csr_mie = csr_mie_i;
end 

//always @(*) begin        //USELESS!!!
//    if(wb_csr_reg_we_i == `WriteEnable  &&  wb_csr_reg_addr_i == `CSR_REG_MIP)
//        csr_mip = wb_csr_reg_data_i;
//    else
//        //mip_o[3], mip_o[7], mip_o[11]為不可寫，只能讀
//        csr_mip = {wb_csr_reg_data_i[31:12], csr_mip_i[11], wb_csr_reg_data_i[10:8], csr_mip_i[7], wb_csr_reg_data_i[6:4], csr_mip_i[3], wb_csr_reg_data_i[2:0]};
//end 



//------------------------------------------------------
assign excepttype_fine = {excepttype_i[31:15], misalign, excepttype_i[12:0]};

always @(*) begin
    excepttype_o = `ZeroWord;
    if(csr_mstatus[3] == 1'b1  &&  current_inst_addr_i != `ZeroWord) begin //current_inst_addr_i != `ZeroWord --> wait for new first inst, see textbook 11-40(2)!    
        if(int_i == 1'b1  &&  csr_mie[11]) //interrupt
        //外部中斷可以被csr_mie_o屏蔽，所以要刻意接入csr_mie_o查看其MEIE位的狀況
            excepttype_o = 32'h00000000;
        else if(excepttype_fine[8]  &&  csr_mie[3])    //ecall(ECALL)
        //查看csr_mie_o的MSIE位的狀況
            excepttype_o = 32'h00000001;
        else if( (excepttype_fine[10]  &&  csr_mie[3])  ||
                (mem_addr_o    == `CLINT_REG_MSIP) )    //trap, 考慮到不用trap自身的指令而用load指令把1寫進msip的情況
        //查看csr_mie_o的MSIE位的狀況
            excepttype_o = 32'h00000002;
        else if(time_up_i  &&  csr_mie[7]) //timer
        //查看csr_mie_o的MTIE位的狀況
            excepttype_o = 32'h00000003;
        
        else if(excepttype_fine[9]) //inst_invalid
            excepttype_o = 32'h00000004;
        else if(excepttype_fine[11:10] == 2'b01) //load_misalign
            excepttype_o = 32'h00000005;
        else if(excepttype_fine[11:10] == 2'b10) //store_misalign
            excepttype_o = 32'h00000006;
        else if(excepttype_fine[11]) //ov
            excepttype_o = 32'h00000007;

        //-------------------------------
        else if(excepttype_fine[12]) //mret
            excepttype_o = 32'hffffffff;
    end 
end 
    
assign mem_we_o = mem_we & ( ~(|excepttype_o) ); //if excepttype_i has a "one", cancel the mem_we

    
endmodule