`include    "define.v"

module csr(
    input                    clk,
    input                    rst,
    
    input        [`RegBus]   inst_i,
    
    input                    we_i,
    input        [11:0]      addr_i,
    input        [`RegBus]   data_i,
    
    //input        [5:0]       int_i,
    
    //input                    dlyslot_now_i,
    input        [`RegBus]   current_inst_addr_i,
    input        [`RegBus]   excepttype_i,
    
    //========================================================================
    output reg    [`RegBus]  data_o,
    //output reg    [`RegBus]  mtime_o,
    //output reg    [`RegBus]  mtimecmp_o,
    output reg    [`RegBus]  mtvec_o,
    //output reg    [`RegBus]  mcause_o,
    output reg    [`RegBus]  mepc_o,
    //output reg    [`RegBus]  mtval_o, useless mem.v不需要隨時查看mtval_o, 暫時不需要接出去
    output reg    [`RegBus]  mstatus_o,     //                                             |
    output reg    [`RegBus]  mie_o          //                                             |
    //output reg    [`RegBus]  mip_o        //                                             |
    //output reg    [`RegBus]  config_o,    //                                             |
    //output reg    [`RegBus]  prid_o,      //                                             |
                                            //                                             |
    //output reg               timer_int_o  //                                             |
    );                                      //                                             |
                                            //                                             |
                                            //                                             |
    //reg            [`RegBus] mtime_o;     //                                             |
    //reg            [`RegBus] mtimecmp_o;  //                                             |
    //reg            [`RegBus] config_o;    //                                             |
    //reg            [`RegBus] prid_o;      //                                             |
    reg           [`RegBus]  mtval_o;       //     <----------------------------------------
    reg           [`RegBus]  mcause_o;
    reg           [`RegBus]  mip_o;
    


//##############################################################################################
always @(posedge clk) begin //WR
    if(rst == `RstEnable) begin
        //mtime_o     <= `ZeroWord;
        //mtimecmp_o  <= `ZeroWord;
        mstatus_o     <= 32'b0_00000000_0_0_0_0_0_0_00_00_11_00_0_0_0_0_0_0_0_0_0; //see page 244
        mcause_o      <= `ZeroWord;
        mepc_o        <= `ZeroWord;
        mepc_o        <= `ZeroWord;
        mtval_o       <= `ZeroWord;

        //config_o    <= 32'b0000_0000_0000_0000_1000_0000_0000_0000;
        //prid_o      <= 32'b00000000_01001011_0000000100_000010; //K
        
        //timer_int_o <= `InterruptNotAssert;
    
    end else begin
        //mtime_o         <= mtime_o + 1'b1;
        //mcause_o[15:10] <= int_i;
        
        //if(mtimecmp_o != `ZeroWord  &&  mtime_o == mtimecmp_o)
        //    timer_int_o <= `InterruptAssert;
        
        if(we_i == `WriteEnable) begin
            case(addr_i)
                //`CSR_REG_MTIME:     
                //    mtime_o       <= data_i;
                //`CSR_REG_MTIMECMP: begin
                //    mtimecmp_o    <= data_i;
                //    timer_int_o   <= `InterruptNotAssert;
                //end
                `CSR_REG_MTVEC:        
                    mtvec_o         <= data_i;
                `CSR_REG_MCAUSE:        
                    mcause_o        <= data_i;
                `CSR_REG_MEPC:         
                    mepc_o          <= data_i;
                `CSR_REG_MTVAL:
                    mtval_o         <= data_i;
                `CSR_REG_MSTATUS:
                    mstatus_o       <= data_i;
                `CSR_REG_MIE:
                    mie_o           <= data_i;
                `CSR_REG_MIP:    
                        //mip_o[3], mip_o[7], mip_o[11]為不可寫，只能讀 
                    mip_o           <= {data_i[31:12], mip_o[11], data_i[10:8], mip_o[7], data_i[6:4], mip_o[3], data_i[2:0]};
            endcase
        end
        
        case(excepttype_i)
            32'h00000000: begin //interrupt
                mcause_o        <= {1'b1, 31'd11};
                mepc_o          <= current_inst_addr_i;
                mstatus_o[7]    <= mstatus_o[3];    //MPIE <- MIE
                mstatus_o[3]    <= 0;                //MIE <- 0
                mip_o[11]       <= 1'b1;
            end 
            32'h00000001: begin //syscall(ECALL)
                mcause_o        <= {1'b1, 31'd1};
                mepc_o            <= current_inst_addr_i;
                mstatus_o[7]    <= mstatus_o[3];    //MPIE <- MIE
                mstatus_o[3]    <= 0;                //MIE <- 0
                mip_o[3]        <= 1'b1;
            end 
            32'h00000002: begin //trap
                mcause_o        <= {1'b1, 31'd1};
                mepc_o          <= current_inst_addr_i;
                mstatus_o[7]    <= mstatus_o[3];    //MPIE <- MIE
                mstatus_o[3]    <= 0;                //MIE <- 0
                mip_o[3]        <= 1'b1;
            end
            32'h00000003: begin //timer
                mcause_o        <= {1'b1, 31'd7};
                mepc_o          <= current_inst_addr_i;
                mstatus_o[7]    <= mstatus_o[3];    //MPIE <- MIE
                mstatus_o[3]    <= 0;                //MIE <- 0
                mip_o[7]        <= 1'b1;
            end 
            
            32'h00000004: begin //ov
                mcause_o        <= {1'b1, 31'd16};
                mepc_o          <= current_inst_addr_i;
                mstatus_o[7]    <= mstatus_o[3];    //MPIE <- MIE
                mstatus_o[3]    <= 0;                //MIE <- 0
            end 
            32'h00000005: begin //inst_invalid
                mcause_o        <= {1'b0, 31'd2};
                mepc_o          <= current_inst_addr_i;
                mtval_o         <= inst_i;
                mstatus_o[7]    <= mstatus_o[3];    //MPIE <- MIE
                mstatus_o[3]    <= 0;                //MIE <- 0
            end
            32'h00000006: begin //load_misalign
                mcause_o        <= {1'b0, 31'd4};
                mepc_o          <= current_inst_addr_i;
                mstatus_o[7]    <= mstatus_o[3];    //MPIE <- MIE
                mstatus_o[3]    <= 0;                //MIE <- 0
            end
            32'h00000007: begin //store_misalign
                mcause_o        <= {1'b0, 31'd6};
                mepc_o          <= current_inst_addr_i;
                mstatus_o[7]    <= mstatus_o[3];    //MPIE <- MIE
                mstatus_o[3]    <= 0;                //MIE <- 0
            end
            
            //--------------------------------------------
            32'hffffffff: begin        //eret
                mstatus_o[3]    <= mstatus_o[7];    //MIE <- MPIE
                mstatus_o[7]    <= 1'b1;            //MPIE <- 1
                mip_o[7]        <= 0;
            end
            
            default: begin
            end 

        endcase
    end 
end 


//=====================================================================
always @(*) begin //RD
    case(addr_i)
        //`CSR_REG_MTIME:     
        //    data_o        = mtime_o;
        //`CSR_REG_MTIMECMP:
        //    data_o        = mtimecmp_o;
        `CSR_REG_MSTATUS:    
            data_o        = mstatus_o;           
        `CSR_REG_MEPC:                            
            data_o        = mepc_o;              
        `CSR_REG_MCAUSE:                       
            data_o        = mcause_o;
        `CSR_REG_MTVEC:
            data_o        = mtvec_o;
        `CSR_REG_MTVAL:
            data_o        = mtval_o;
        `CSR_REG_MIE:
            data_o        = mie_o;
        `CSR_REG_MIP:
            data_o        = mip_o;
        //`CSR_REG_PRId:
        //    data_o        = prid_o;
        //`CSR_REG_CONFIG:  
        //    data_o        = config_o;
        default: 
            data_o        = `ZeroWord;
    endcase
end 


endmodule             