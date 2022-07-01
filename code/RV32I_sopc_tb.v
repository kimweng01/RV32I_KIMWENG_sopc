`include	"define.v"

`timescale 1ns/1ps

module RV32I_sopc_tb();
	reg				CLOCK_50;
	reg				rst;
	
	reg		[5:0]	int_i;
	wire			timer_int_o;
	
	
initial begin
	CLOCK_50 = 0;
	forever #10 CLOCK_50 = ~CLOCK_50;
end

initial begin
	rst = `RstEnable;
	#195 rst = `RstDisable;
	#50000 $stop;
end

OpenMIPS_sopc OpenMIPS_cp0_sopc0(
	.clk			(CLOCK_50),
	.rst			(rst)
	);
	
endmodule