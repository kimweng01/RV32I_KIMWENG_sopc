`include	"define.v"

module wishbone_buf_if(
	input					cpu_ce_i,
	input		[`RegBus]	cpu_data_i,
	input		[`RegBus]	cpu_addr_i,
	input					cpu_we_i,
	input			[3:0]	cpu_sel_i,
	
	output reg	[`RegBus]	cpu_data_o,
	
	//=================================
	input		[`RegBus]	ram_data_i,
	
	output reg				ram_ce_o,
	output reg	[`RegBus]	ram_data_o,
	output reg	[`RegBus]	ram_addr_o,
	output reg				ram_we_o,
	output reg		[3:0]	ram_sel_o,

	
	input		[`RegBus]	clint_data_i,
	
	output reg				clint_ce_o,
	output reg	[`RegBus]	clint_data_o,
	output reg	[`RegBus]	clint_addr_o,
	output reg				clint_we_o
	);
	
always@(*) begin
	if(ram_ce_o == `ChipEnable) begin
		if(cpu_we_i == `WriteEnable) begin
			if(cpu_addr_i[31:16] == 16'h200) begin //WR CLINT
				cpu_data_o		=	`ZeroWord;
			
				ram_ce_o		=	`ChipDisable;
				ram_data_o  	=	`ZeroWord;
				ram_addr_o  	=	`ZeroWord;
				ram_we_o    	=	`WriteDisable;
				ram_sel_o   	=	4'b0000;		                
													
				clint_ce_o  	=	cpu_ce_i;  
				clint_data_o	=	cpu_data_i;
				clint_addr_o	=	cpu_addr_i;   
				clint_we_o  	=	`WriteEnable;    
		
			end else begin //WR CLINT
				cpu_data_o		=	`ZeroWord;
			
				ram_ce_o		=	cpu_ce_i;  
				ram_data_o  	=	cpu_data_i; 
				ram_addr_o  	=	cpu_addr_i; 
				ram_we_o    	=	`WriteEnable;
				ram_sel_o   	=	cpu_sel_i;
														
				clint_ce_o  	=	`ChipDisable;	
				clint_data_o	=	`ZeroWord;
				clint_addr_o	=	`ZeroWord;	
				clint_we_o  	=	`WriteDisable;	
														
			end
		
		end else begin //cpu_we_i == `WriteDisEnable
			if(cpu_addr_i[31:16] == 16'h200) begin //RD CLINT
				cpu_data_o		=	clint_data_i;
			
				ram_ce_o		=	`ChipDisable;
				ram_data_o  	=	`ZeroWord;
				ram_addr_o  	=	`ZeroWord;
				ram_we_o    	=	`WriteDisable;
				ram_sel_o   	=	4'b0000;		
													
				clint_ce_o  	=	cpu_ce_i;  
				clint_data_o	=	`ZeroWord;
				clint_addr_o	=	cpu_addr_i;   
				clint_we_o  	=	`WriteEnable; 
			
			end else begin //RD RAM
				cpu_data_o		=	ram_data_i;
			
				ram_ce_o		=	cpu_ce_i;  
				ram_data_o  	=	`ZeroWord;
				ram_addr_o  	=	cpu_addr_i; 
				ram_we_o    	=	`WriteEnable;
				ram_sel_o   	=	cpu_sel_i;
													
				clint_ce_o  	=	`ChipDisable;	
				clint_data_o	=	`ZeroWord;
				clint_addr_o	=	`ZeroWord;	
				clint_we_o  	=	`WriteDisable;
													
			end
		end
	
	end else begin//ram_ce_o == `ChipDisable
		cpu_data_o		=	`ZeroWord;
		
		ram_ce_o		=	cpu_ce_i;  
		ram_data_o  	=	`ZeroWord;
		ram_addr_o  	=	cpu_addr_i; 
		ram_we_o    	=	`WriteEnable;
		ram_sel_o   	=	cpu_sel_i;
											
		clint_ce_o  	=	`ChipDisable;	
		clint_data_o	=	`ZeroWord;
		clint_addr_o	=	`ZeroWord;	
		clint_we_o  	=	`WriteDisable;
		
	end
end


endmodule