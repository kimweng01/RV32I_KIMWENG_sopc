`include	"define.v"

module ram_interface(
	input							ce,
	input							we,
	input		[`DataAddrBus]		addr,
	input		[3:0]				sel,
	input		[`DataBus]			data_i,
	
	output reg	[`DataBus]			data_o
);


endmodule