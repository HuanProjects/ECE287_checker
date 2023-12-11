module game_logic(
	input rst,
	input clk,
	input [5:0] select_loc, 						// location of the picked piece
	output reg [5:0] legal_move, 
	output wire [191:0] serialized_board
);

/* board [ first 3 bits == x_axis, second 3 bits == y_axis] = 
[2 == is there a piece in here(1 = yes),  1 == color(1 = red), 0 == is this a king(1 = yes)] */
reg[2:0] board[63:0];

// initial board
always@(posedge clk or negedge rst)
begin
	if (rst == 1'b0) begin
		board[{3'd0,3'd0}] <= 3'b110; 
		board[{3'd0,3'd1}] <= 3'b0;
		board[{3'd0,3'd2}] <= 3'b110;
		board[{3'd0,3'd3}] <= 3'b0;
		board[{3'd0,3'd4}] <= 3'b0;
		board[{3'd0,3'd5}] <= 3'b0;
		board[{3'd0,3'd6}] <= 3'b100;
		board[{3'd0,3'd7}] <= 3'b0;
		board[{3'd1,3'd0}] <= 3'b0;
		board[{3'd1,3'd1}] <= 3'b110;
		board[{3'd1,3'd2}] <= 3'b0;
		board[{3'd1,3'd3}] <= 3'b0;
		board[{3'd1,3'd4}] <= 3'b0;
		board[{3'd1,3'd5}] <= 3'b100;
		board[{3'd1,3'd6}] <= 3'b0;
		board[{3'd1,3'd7}] <= 3'b100;
		board[{3'd2,3'd0}] <= 3'b110;
		board[{3'd2,3'd1}] <= 3'b0;
		board[{3'd2,3'd2}] <= 3'b110;
		board[{3'd2,3'd3}] <= 3'b0;
		board[{3'd2,3'd4}] <= 3'b0;
		board[{3'd2,3'd5}] <= 3'b0;
		board[{3'd2,3'd6}] <= 3'b100;
		board[{3'd2,3'd7}] <= 3'b0;
		board[{3'd3,3'd0}] <= 3'b0;
		board[{3'd3,3'd1}] <= 3'b110;
		board[{3'd3,3'd2}] <= 3'b0;
		board[{3'd3,3'd3}] <= 3'b0;
		board[{3'd3,3'd4}] <= 3'b0;
		board[{3'd3,3'd5}] <= 3'b100;
		board[{3'd3,3'd6}] <= 3'b0;
		board[{3'd3,3'd7}] <= 3'b100;
		board[{3'd4,3'd0}] <= 3'b110;
		board[{3'd4,3'd1}] <= 3'b0;
		board[{3'd4,3'd2}] <= 3'b110;
		board[{3'd4,3'd3}] <= 3'b0;
		board[{3'd4,3'd4}] <= 3'b0;
		board[{3'd4,3'd5}] <= 3'b0;
		board[{3'd4,3'd6}] <= 3'b100;
		board[{3'd4,3'd7}] <= 3'b0;
		board[{3'd5,3'd0}] <= 3'b0;
		board[{3'd5,3'd1}] <= 3'b110;
		board[{3'd5,3'd2}] <= 3'b0;
		board[{3'd5,3'd3}] <= 3'b0;
		board[{3'd5,3'd4}] <= 3'b0;
		board[{3'd5,3'd5}] <= 3'b100;
		board[{3'd5,3'd6}] <= 3'b0;
		board[{3'd5,3'd7}] <= 3'b100;
		board[{3'd6,3'd0}] <= 3'b110;
		board[{3'd6,3'd1}] <= 3'b0;
		board[{3'd6,3'd2}] <= 3'b110;
		board[{3'd6,3'd3}] <= 3'b0;
		board[{3'd6,3'd4}] <= 3'b0;
		board[{3'd6,3'd5}] <= 3'b0;
		board[{3'd6,3'd6}] <= 3'b100;
		board[{3'd6,3'd7}] <= 3'b0;
		board[{3'd7,3'd0}] <= 3'b0;
		board[{3'd7,3'd1}] <= 3'b110;
		board[{3'd7,3'd2}] <= 3'b0;
		board[{3'd7,3'd3}] <= 3'b0;
		board[{3'd7,3'd4}] <= 3'b0;
		board[{3'd7,3'd5}] <= 3'b100;
		board[{3'd7,3'd6}] <= 3'b0;
		board[{3'd7,3'd7}] <= 3'b100;
	end
end

// serializing the board
genvar i;
generate for (i=0; i<64; i=i+1) begin: PACK_BOARD
	assign serialized_board[i*3+2 : i*3] = board[i];
end
endgenerate	

// defining legal moves
always @(*) begin
	// only legal if piece has piece
	if (board[select_loc] [2] == 1'b1) begin
		// if a piece is a red or a king
		if((board[select_loc] [1] == 1'b1) || (board[select_loc] [0] == 1'b1)) begin
		//legal moves needs to stay in the board
			if ((select_loc[5:3] > 0) && (select_loc[2:0] < 7) && (board[{select_loc[5:3] - 1, select_loc[2:0] + 1}] [2] == 1'b0)) begin
				legal_move = {select_loc[5:3] - 1, select_loc[2:0] + 1};
			end
		end
		// if a piece is white or a king
		/*else if((board[select_loc] [1] == 1'b0) && (board[select_loc] [0] == 1'b1)) begin
		//legal moves needs to stay in the board
		end*/
	end else begin
		legal_move = 0;
	end
end
endmodule 