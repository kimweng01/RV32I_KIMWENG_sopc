`include    "define.v"

module If(
    input                        clk,
    input                        rst,
    
    input   [5:0]                stall,
    
    input   [`RegBus]            branch_tar_addr_pred,
    input                        branch_flag_pred,
    
    //input                      branch_tar_addr_real,
    //input       [`RegBus] branch_flag_real,
    
    input                        flush,
    input       [`RegBus]        new_pc,
    
    //=========================================
    output reg                    ce,
    output reg  [`InstAddrBus]    pc
    );
    
    
always @(posedge clk) begin
    if(rst == `RstEnable)
        ce <= `ChipDisable;
    else
        ce <= `ChipEnable;
end 

always @(posedge clk) begin
    if(ce == `ChipDisable)
        pc <= 32'h3000_0000;
    else begin
        if(flush == 1'b1)
            pc <= new_pc; //預測失敗or有中斷或例外
        else if(stall[0] == `NoStop) begin
            if(branch_flag_pred == `Branch)
            //如果是 有條件分支 且 offset為負，則賦予跳轉後的地址(在if_id.v判斷)
                pc <= branch_tar_addr_pred;
            //else if(next_if_is_16bit_flag_i == `Next_if_is_16bit)
            //根據上一指令的分析，接下來要取16bit的指令(在if_id.v分析)
            //    pc <= pc + 2'h2;
            else
            //根據上一指令的分析，接下來要取32bit的指令(在if_id.v分析)
                pc <= pc + 3'h4;
        end
    end 
end
        
        
endmodule