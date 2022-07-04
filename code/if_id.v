`include    "define.v"

module if_id(
    input                        clk,
    input                        rst,
    
    input        [`InstAddrBus]  if_pc,
    input        [`InstBus]      if_inst,
    
    input        [5:0]           stall,
    input                        flush,
    
    //====================================
    output reg    [`InstAddrBus] id_pc,
    output reg    [`InstBus]     id_inst,
    
    output reg    [`RegBus]      branch_tar_addr_pred,
    output reg                   branch_flag_pred
    //output                     next_if_is_16bit_flag_o,
    );
    
    
always @(posedge clk) begin
    if(rst == `RstEnable) begin
        id_pc    <= `ZeroWord;
        id_inst  <= `ZeroWord;
        
    end else if(flush == 1'b1) begin
        id_pc    <= `ZeroWord; 
        id_inst  <= `ZeroWord; 
        
    end else if(stall[1] == `Stop && stall[2] == `NoStop) begin
        id_pc    <= `ZeroWord;
        id_inst  <= `ZeroWord;
        
    end else if(stall[1] == `NoStop) begin
        id_pc    <= if_pc;
        id_inst  <= if_inst;
        
    end
end

always@(*) begin
    case(if_inst[6:0])
        7'b1100011: begin //BRAHCH
            if(if_inst[31] == 1'b1) begin
            //如果是 有條件分支 且 offset為負，則送出跳轉後的地址給pc
                branch_tar_addr_pred    = if_pc + {if_inst[31], if_inst[7], if_inst[30:25], if_inst[11:8], 1'b0};
                branch_flag_pred        = 1'b1;
            end else begin
                branch_tar_addr_pred    = `ZeroWord;
                branch_flag_pred        = 0;
            end
        end
        
        7'b1101111: begin //JAL
            branch_tar_addr_pred     = if_pc + {{9{if_inst[31]}}, if_inst[31], if_inst[19:12], if_inst[20], if_inst[30:21], 1'b0};
            branch_flag_pred         = 1'b1;
        end

        //7'b110111: begin //JALR                    <====== Ignore!
        //    branch_tar_addr_pred = `ZeroWord;      <======
        //    branch_flag_i             = 0;         <======
        //end                                        <======
        
        default: begin
            branch_tar_addr_pred     = `ZeroWord;
            branch_flag_pred         = 0;
        end
    endcase
end

//assign next_if_is_16bit_flag_o  =  if_inst[1:0]!=2'b11 ? 1'b1 : 0;

endmodule