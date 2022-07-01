module plic(
	input		[15:0]	int_i,
	output 				int_o
	);
	
assign int_o = 	int_i[ 0] ? int_i[ 0] :
				int_i[ 1] ? int_i[ 1] :
				int_i[ 2] ? int_i[ 2] :
				int_i[ 3] ? int_i[ 3] :
				int_i[ 4] ? int_i[ 4] :
				int_i[ 5] ? int_i[ 5] :
				int_i[ 6] ? int_i[ 6] :
				int_i[ 7] ? int_i[ 7] :
				int_i[ 8] ? int_i[ 8] :
				int_i[ 9] ? int_i[ 9] :
				int_i[10] ? int_i[10] :
				int_i[11] ? int_i[11] :
				int_i[12] ? int_i[12] :
				int_i[13] ? int_i[13] :
				int_i[14] ? int_i[14] :
				int_i[15] ;
				

endmodule