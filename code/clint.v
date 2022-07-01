`include	"define.v"

module clint(
	input					clk,
	input					rst,
	
	input					ce_i,
	input					we_i,
	input		[4:0]		addr_i,
	input		[`RegBus]	data_i,
	
	//========================================================================
	output reg	[`RegBus]	data_o,
	output reg				time_up_o,
	
	output reg	[`RegBus]	msip_o
	);
	
	
	reg			[`RegBus]	mtime_o;
	reg			[`RegBus]	mtimecmp_o;
	


//##############################################################################################
always @(posedge clk) begin //WR
	if(rst == `RstEnable) begin
		mtime_o 	<= `ZeroWord;
		mtimecmp_o	<= `ZeroWord;
		
		time_up_o 	<= 0;
		
		
		msip_o		<= 0;
	
	end else if(ce_i == `ChipEnable) begin
		mtime_o		<= mtime_o + 1'b1;
		
		if(mtimecmp_o != `ZeroWord  &&  mtime_o == mtimecmp_o)
			time_up_o	<= 1'b1;
		
		if(we_i == `WriteEnable) begin
			case(addr_i)
				`CLINT_REG_MTIME: 	
					mtime_o			<= data_i;
					
				`CLINT_REG_MTIMECMP: begin
					mtimecmp_o		<= data_i;
					time_up_o 		<= `InterruptNotAssert;
				end 
				
				`CLINT_REG_MSIP:
					msip_o			<= data_i;
			endcase
		end	
	end 
end 


//=====================================================================
always @(*) begin //RD
	if(ce_i == `ChipEnable) begin
		case(addr_i)
			`CLINT_REG_MTIME: 	
				data_o		= mtime_o;
			`CLINT_REG_MTIMECMP:
				data_o		= mtimecmp_o;
								
			`CLINT_REG_MSIP:
				data_o		= msip_o; //trapassert from ex.v
						
			default:
				data_o		= `ZeroWord;
		endcase
	end
end 


endmodule