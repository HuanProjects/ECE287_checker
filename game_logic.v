module game_logic(
	input clk,
	input rst,
	input [5:0] select_loc, 						// location of the picked piece
	output reg [27:0] legal_move,
	output wire [191:0] serialized_board,
	output reg [7:0]turn_count
);

/* board [ first 3 bits == x_axis, second 3 bits == y_axis] = 
[2 == is there a piece in here(1 = yes),  1 == color(1 = red), 0 == is this a king(1 = yes)] */
reg[2:0] board[63:0];
reg board_change_en;
reg [5:0] new_loc;
reg [2:0] new_piece;
reg player_turn;
reg [5:0] old_loc;
reg [27:0] possible_move; // the transition values for the legal moves 

always@(posedge clk or negedge rst)
begin
	
	if (rst == 1'b0) begin
		board[{3'd0,3'd0}] <= 3'b0; 
		board[{3'd0,3'd1}] <= 3'b0;
		board[{3'd0,3'd2}] <= 3'b0;
		board[{3'd0,3'd3}] <= 3'b0;
		board[{3'd0,3'd4}] <= 3'b0;
		board[{3'd0,3'd5}] <= 3'b0;
		board[{3'd0,3'd6}] <= 3'b0;
		board[{3'd0,3'd7}] <= 3'b0;
		board[{3'd1,3'd0}] <= 3'b0;
		board[{3'd1,3'd1}] <= 3'b100;
		board[{3'd1,3'd2}] <= 3'b0;
		board[{3'd1,3'd3}] <= 3'b0;
		board[{3'd1,3'd4}] <= 3'b0;
		board[{3'd1,3'd5}] <= 3'b0;
		board[{3'd1,3'd6}] <= 3'b0;
		board[{3'd1,3'd7}] <= 3'b0;
		board[{3'd2,3'd0}] <= 3'b0;
		board[{3'd2,3'd1}] <= 3'b0;
		board[{3'd2,3'd2}] <= 3'b0;
		board[{3'd2,3'd3}] <= 3'b0;
		board[{3'd2,3'd4}] <= 3'b0;
		board[{3'd2,3'd5}] <= 3'b0;
		board[{3'd2,3'd6}] <= 3'b0;
		board[{3'd2,3'd7}] <= 3'b0;
		board[{3'd3,3'd0}] <= 3'b0;
		board[{3'd3,3'd1}] <= 3'b0;
		board[{3'd3,3'd2}] <= 3'b0;
		board[{3'd3,3'd3}] <= 3'b0;
		board[{3'd3,3'd4}] <= 3'b0;
		board[{3'd3,3'd5}] <= 3'b101;
		board[{3'd3,3'd6}] <= 3'b0;
		board[{3'd3,3'd7}] <= 3'b0;
		board[{3'd4,3'd0}] <= 3'b0;
		board[{3'd4,3'd1}] <= 3'b0;
		board[{3'd4,3'd2}] <= 3'b0;
		board[{3'd4,3'd3}] <= 3'b0;
		board[{3'd4,3'd4}] <= 3'b0;
		board[{3'd4,3'd5}] <= 3'b0;
		board[{3'd4,3'd6}] <= 3'b0;
		board[{3'd4,3'd7}] <= 3'b0;
		board[{3'd5,3'd0}] <= 3'b0;
		board[{3'd5,3'd1}] <= 3'b0;
		board[{3'd5,3'd2}] <= 3'b0;
		board[{3'd5,3'd3}] <= 3'b0;
		board[{3'd5,3'd4}] <= 3'b0;
		board[{3'd5,3'd5}] <= 3'b0;
		board[{3'd5,3'd6}] <= 3'b0;
		board[{3'd5,3'd7}] <= 3'b0;
		board[{3'd6,3'd0}] <= 3'b0;
		board[{3'd6,3'd1}] <= 3'b0;
		board[{3'd6,3'd2}] <= 3'b110;
		board[{3'd6,3'd3}] <= 3'b0;
		board[{3'd6,3'd4}] <= 3'b0;
		board[{3'd6,3'd5}] <= 3'b0;
		board[{3'd6,3'd6}] <= 3'b111;
		board[{3'd6,3'd7}] <= 3'b0;
		board[{3'd7,3'd0}] <= 3'b0;
		board[{3'd7,3'd1}] <= 3'b0;
		board[{3'd7,3'd2}] <= 3'b0;
		board[{3'd7,3'd3}] <= 3'b0;
		board[{3'd7,3'd4}] <= 3'b0;
		board[{3'd7,3'd5}] <= 3'b0;
		board[{3'd7,3'd6}] <= 3'b0;
		board[{3'd7,3'd7}] <= 3'b0;
	end 
	else if (board_change_en == 1'b1) begin 
		board[new_loc] <= new_piece;
		board[old_loc] <= 0;
	end
end


// good ole fsm for players turn and moving pieces
parameter START = 3'd0,
			 PIECE_SELECTION = 3'd1,
			 MOVE = 3'd2,
			 PIECE_CHANGE = 3'd3,
			 SWITCH_PLAYER = 3'd4; 
reg [1:0] S; 
reg [1:0] NS;

always @ (posedge clk or negedge rst)
begin 
	if (rst == 1'b0)
		S <= START;
	else 
		S <= NS; 
end

always @ (posedge clk or negedge rst)
begin 
	if (rst == 1'b0) begin
		board_change_en <= 0;
		new_loc <= 0;
		new_piece <=0;
		player_turn <= 1; // red player goes first
		old_loc <= 0;
		turn_count = 0;
		possible_move = 0;
	end
	else begin
		case (S) 
			START: NS = PIECE_SELECTION;  
			PIECE_SELECTION: begin // player pick a piece
				if (board[select_loc] [2] == 1'b1 && board[select_loc] [1] == player_turn) begin
					old_loc <= select_loc;
					possible_move = legal_move;
					NS <= MOVE;
				end else begin
					NS <= PIECE_SELECTION;
				end
			end
			MOVE: begin // player choose a square to move to
				if (((possible_move[6] == 1) && (select_loc == possible_move[5:0])) ||
					((possible_move[13] == 1) && (select_loc == possible_move[12:7])) ||
					((possible_move[20] == 1) && (select_loc == possible_move[19:14])) ||
					((possible_move[27] == 1) && (select_loc == possible_move[26:21])))
				begin
					new_loc <= select_loc;
					new_piece = board[old_loc];
					NS <= PIECE_CHANGE;
				end
				else begin
					NS <= PIECE_SELECTION;
				end 
			end
			PIECE_CHANGE: begin 
				board_change_en <= 1;
				NS <= SWITCH_PLAYER;
			end
			SWITCH_PLAYER: begin
				board_change_en = 0;
				player_turn <= ~player_turn;
				NS <= PIECE_SELECTION;
				turn_count = turn_count + 1;
			end
		endcase
	end
end
















// serializing the board
genvar i;
generate for (i=0; i<64; i=i+1) begin: PACK_BOARD
	assign serialized_board[i*3+2 : i*3] = board[i];
end
endgenerate	


/* legal move have 7 seven bit buses
the first bit is to see if the move is the legal move exist ( respresented by 1)
the next 6 bit is the location of the legal move
*/
// defining legal moves
always @(posedge clk or negedge rst) begin
	if (rst == 1'b0)
		legal_move <= 0;
	// only legal if piece has piece
	else if (board[select_loc] [2] == 1'b1)  begin
		// if piece is a king
		if (board[select_loc] [0] == 1'b1) begin
			if ((select_loc[5:3] > 3'd0) && (select_loc[2:0] < 3'd7) && (board[{select_loc[5:3] - 1, select_loc[2:0] + 1}] [2] == 1'b0)) begin
				// this move is on the top left
				legal_move[6:0] <= {1'b1, select_loc[5:3] - 3'b1, select_loc[2:0] + 3'b1};
			end else begin
				legal_move[6:0] <= 0;
			end
			
			if ((select_loc[5:3] < 3'd7) && (select_loc[2:0] < 3'd7) && (board[{select_loc[5:3] - 1, select_loc[2:0] + 1}] [2] == 1'b0)) begin
				// this move is on the top right
				legal_move[13:7] <= {1'b1, select_loc[5:3] + 3'b1, select_loc[2:0] + 3'b1};
			end else begin
				legal_move[13:7] <= 0;
			end
			
			if ((select_loc[5:3] > 3'd0) && (select_loc[2:0] > 3'd0) && (board[{select_loc[5:3] - 1, select_loc[2:0] - 1}] [2] == 1'b0)) begin
				// this move is on the bottom left
				legal_move[20:14] <= {1'b1, select_loc[5:3] - 3'b1, select_loc[2:0] - 3'b1};
			end else begin
				legal_move[20:14] <= 0;
			end
			
			if ((select_loc[5:3] < 3'd7) && (select_loc[2:0] > 3'd0) && (board[{select_loc[5:3] + 1, select_loc[2:0] - 1}] [2] == 1'b0)) begin
				// this move is on the bottom right
				legal_move[27:21] <= {1'b1, select_loc[5:3] + 3'b1, select_loc[2:0] - 3'b1};
			end else begin
				legal_move[27:21] <= 0;
			end
		end
		// if a piece is a red
		else if(board[select_loc] [1] == 1'b1) begin
		//legal moves needs to stay in the board
			if ((select_loc[5:3] > 3'd0) && (select_loc[2:0] < 3'd7) && (board[{select_loc[5:3] - 1, select_loc[2:0] + 1}] [2] == 1'b0)) begin
				// this move is on the top left
				legal_move[6:0] <= {1'b1, select_loc[5:3] - 3'b1, select_loc[2:0] + 3'b1};
			end else begin
				legal_move[6:0] <= 0;
			end
			
			if ((select_loc[5:3] < 3'd7) && (select_loc[2:0] < 3'd7) && (board[{select_loc[5:3] - 1, select_loc[2:0] + 1}] [2] == 1'b0)) begin
				// this move is on the top right
				legal_move[13:7] <= {1'b1, select_loc[5:3] + 3'b1, select_loc[2:0] + 3'b1};
			end else begin
				legal_move[13:7] <= 0;
			end
		end
		// if a piece is a white
		else if(board[select_loc] [1] == 1'b0) begin
		//legal moves needs to stay in the board
			if ((select_loc[5:3] > 3'd0) && (select_loc[2:0] > 3'd0) && (board[{select_loc[5:3] - 1, select_loc[2:0] - 1}] [2] == 1'b0)) begin
				// this move is on the bottom left
				legal_move[20:14] <= {1'b1, select_loc[5:3] - 3'b1, select_loc[2:0] - 3'b1};
			end else begin
				legal_move[20:14] <= 0;
			end
			
			if ((select_loc[5:3] < 3'd7) && (select_loc[2:0] > 3'd0) && (board[{select_loc[5:3] + 1, select_loc[2:0] - 1}] [2] == 1'b0)) begin
				// this move is on the bottom right
				legal_move[27:21] <= {1'b1, select_loc[5:3] + 3'b1, select_loc[2:0] - 3'b1};
			end else begin
				legal_move[27:21] <= 0;
			end
		end
	end else begin
		legal_move[27:0] <= 0;
	end
end

/*
// checking win condition, one color wins if there is none left of the other piece
integer i;
reg [5:0] red_count = 0;
reg [5:0] white_count = 0;
reg red_win;
reg white_win;
always @(board) begin
    red_count = 0;
    white_count = 0;

    for (i = 0; i < 64; i = i + 1) begin
        if (board[i][2] == 1'b1) begin  // Check if a piece is present
            if (board[i][1] == 1'b1) begin
                red_count = red_count + 1;  // Red piece
            end else begin
                white_count = white_count + 1;  // White piece
            end
        end
    end
	 if (red_count == 0)
		 white_win = 1;
	 else
		 white_win = 0;
		 
	 if (white_count == 0)
		 red_win =1;
	 else
		 red_win = 0;
end
*/
endmodule
