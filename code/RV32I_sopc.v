`include    "define.v"

module RV32I_sopc(
    input                       clk,
    input                       rst,
    
    input        [15:0]         int_i
    );
    
    wire        [`InstAddrBus]  inst_addr;
    wire        [`InstBus]      inst;
    wire                        rom_ce;

    
    wire                        wishbone_ram_ce_o;
    wire                        wishbone_ram_we_o;
    wire        [`InstAddrBus]  wishbone_ram_addr_o;
    wire        [3:0]           wishbone_ram_sel_o;
    wire        [`DataBus]      wishbone_ram_data_o;
    wire        [`DataBus]      wishbone_ram_data_i;

                                
    wire                        time_up;
    wire                        int_real;


    wire        [`DataBus]      mem_data_i;
    
    wire                        mem_ce_o;
    wire        [`DataBus]      mem_data_o;
    wire        [`InstAddrBus]  mem_addr_o;
    wire                        mem_we_o;
    wire        [3:0]           mem_sel_o;


    wire        [`DataBus]      wishbone_clint_data_i;
                                
    wire                        wishbone_clint_ce_o;
    wire        [`DataBus]      wishbone_clint_data_o;
    wire        [`InstAddrBus]  wishbone_clint_addr_o;
    wire                        wishbone_clint_we_o;
    


//OpenMIPS
//assign int_i = {5'b00000, timer_int};

RV32I RV32I0(
    .clk            (clk),
    .rst            (rst),
    
    .rom_data_i     (inst),
    
    //.ram_data_i        (data),
    
    //=============================
    .rom_addr_o     (inst_addr),
    .rom_ce_o       (rom_ce),

    //.ram_addr_o       (data_addr),
    //.ram_data_o       (data_data),
    //.ram_we_o         (ram_we),
    //.ram_sel_o        (data_sel),
    //.ram_ce_o         (ram_ce),
    
    //=============================
    .int_real       (int_real),
    .time_up        (time_up),
    
    //=============================
    .mem_data_i     (mem_data_i), //把從ram或clint拿到的data送入mem.v

    .mem_ce_o       (mem_ce_o),
    .mem_data_o     (mem_data_o),
    .mem_addr_o     (mem_addr_o),
    .mem_we_o       (mem_we_o),
    .mem_sel_o      (mem_sel_o)
    );


//Inst_ROM
inst_rom inst_rom0(
    .ce              (rom_ce),
    .addr            (inst_addr),
    
    .inst            (inst)
    );
    
    
//Data_RAM
data_ram data_ram0(
    .clk            (clk),    
    .ce             (wishbone_ram_ce_o),
    .we             (wishbone_ram_we_o),
    .addr           (wishbone_ram_addr_o),
    .sel            (wishbone_ram_sel_o),
    .data_i         (wishbone_ram_data_o),
    
    .data_o         (wishbone_ram_data_i)
    );

    
//CLINT
clint clint0(
    .clk            (clk),    
    .rst            (rst),  

    .ce_i           (wishbone_clint_ce_o),
    .we_i           (wishbone_clint_we_o),
    .addr_i         (wishbone_clint_addr_o),
    .data_i         (wishbone_clint_data_o),
    
    //------------------------------------
    .data_o           (wishbone_clint_data_i),
    .time_up_o        (time_up)
    );


//PLIC
plic plic0(
    .int_i            (int_i),
    
    .int_o            (int_real)
    );
    

//wishbone for data
wishbone_buf_if wishbone_buf_if0(
    .cpu_ce_i           (mem_ce_o),
    .cpu_data_i         (mem_data_o),
    .cpu_addr_i         (mem_addr_o),
    .cpu_we_i           (mem_we_o),
    .cpu_sel_i          (mem_sel_o),
    
    .cpu_data_o         (mem_data_i), //把從ram或clint拿到的data送入mem.v
    
    //---------------------------------
    .ram_data_i         (wishbone_ram_data_i),
                        
    .ram_ce_o           (wishbone_ram_ce_o),
    .ram_data_o         (wishbone_ram_data_o),
    .ram_addr_o         (wishbone_ram_addr_o),
    .ram_we_o           (wishbone_ram_we_o),
    .ram_sel_o          (wishbone_ram_sel_o),
                        
                        
    .clint_data_i       (wishbone_clint_data_i),
                         
    .clint_ce_o         (wishbone_clint_ce_o),
    .clint_data_o       (wishbone_clint_data_o),
    .clint_addr_o       (wishbone_clint_addr_o),
    .clint_we_o         (wishbone_clint_we_o)
    );

    
endmodule