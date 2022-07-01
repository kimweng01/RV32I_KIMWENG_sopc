`include	"define.v"

module hazard(
	input					stallreq_from_if,
	input					stallreq_from_id,
	input					stallreq_from_ex,
	input					stallreq_from_mem,
	
	input		[`RegBus]	excepttype_i,
	input		[`RegBus]	mepc_i,
	input		[`RegBus]	mtvec_i,
	
	input		[`RegBus]	branch_tar_addr_real_i,
	input					branch_flag_real_i,
	
	output reg	[5:0]		stall,
	output reg				flush,
	
	output reg	[`RegBus]	new_pc		
	);
	
	

always @(*) begin
	if(excepttype_i != `ZeroWord) begin
		flush = 1'b1;
		stall = 6'b000000;
		case(excepttype_i)
			32'h00000000: begin
				if(mtvec_i[1:0] == 2'b00)
					new_pc = {mtvec_i[31:2], 2'b00};
				else
					new_pc = {mtvec_i[31:2], 2'b00} + {30'd11, 2'b00}; //32'd11 * 4
			end
			32'h00000001: begin
				if(mtvec_i[1:0] == 2'b00)
					new_pc = {mtvec_i[31:2], 2'b00};
				else
					new_pc = {mtvec_i[31:2], 2'b00} + {30'd1, 2'b00}; //32'd11 * 4
			end
			32'h00000002: begin
				if(mtvec_i[1:0] == 2'b00)
					new_pc = {mtvec_i[31:2], 2'b00};
				else
					new_pc = {mtvec_i[31:2], 2'b00} + {30'd1, 2'b00}; //32'd11 * 4
			end
			32'h00000003: begin
				if(mtvec_i[1:0] == 2'b00)
					new_pc = {mtvec_i[31:2], 2'b00};
				else
					new_pc = {mtvec_i[31:2], 2'b00} + {30'd7, 2'b00}; //32'd11 * 4
			end
			32'h00000004: begin
				if(mtvec_i[1:0] == 2'b00)
					new_pc = {mtvec_i[31:2], 2'b00};
				else
					new_pc = {mtvec_i[31:2], 2'b00} + {30'd16, 2'b00}; //32'd11 * 4
			end
			32'h00000005: begin
				if(mtvec_i[1:0] == 2'b00)
					new_pc = {mtvec_i[31:2], 2'b00};
				else
					new_pc = {mtvec_i[31:2], 2'b00};
			end
			32'h00000006: begin
				if(mtvec_i[1:0] == 2'b00)
					new_pc = {mtvec_i[31:2], 2'b00};
				else
					new_pc = {mtvec_i[31:2], 2'b00};
			end
			32'h00000007: begin
				if(mtvec_i[1:0] == 2'b00)
					new_pc = {mtvec_i[31:2], 2'b00};
				else
					new_pc = {mtvec_i[31:2], 2'b00};
			end
			32'hffffffff:
				new_pc = mepc_i;
			default: begin
				new_pc = `ZeroWord;
			end
		endcase
	end else if(branch_flag_real_i) begin
		stall = 6'b000000;
		flush = 1'b1;
		
		new_pc = branch_tar_addr_real_i;
	end else if(stallreq_from_mem == `Stop) begin
		stall = 6'b011111; //1=stop, continue from next of mem
		flush = 0;
	
		new_pc = `ZeroWord;
	end else if(stallreq_from_ex == `Stop) begin
		stall = 6'b001111; //1=stop, continue from next of ex
		flush = 0;
		
		new_pc = `ZeroWord;
	end else if(stallreq_from_id == `Stop) begin
		stall = 6'b000111; //1=stop, continue from next of id
		flush = 0;
		
		new_pc = `ZeroWord;
	end else if(stallreq_from_if == `Stop) begin
		stall = 6'b000111; //1=stop, see textbook p.12-20!
		flush = 0;
	
		new_pc = `ZeroWord;
	end else begin
		stall = 6'b000000;
		flush = 0;
		
		new_pc = `ZeroWord;
	end 
end 


endmodule