module game_logic(
	input clk,
	input rst,
	input [5:0] select_loc, 						// location of the picked piece
	output reg [27:0] legal_move,
	output wire [191:0] serialized_board
);

/* board [ first 3 bits == x_axis, second 3 bits == y_axis] = 
[2 == is there a piece in here(1 = yes),  1 == color(1 = red), 0 == is this a king(1 = yes)] */
reg [2:0] board[63:0];
reg [2:0] switch_color;
reg [5:0] piece_change_loc;
reg board_change_en;
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
   end else begin
		if ((switch_color == 3'd0) && (board_change_en == 1))	 		 board[piece_change_loc] <= 0;
		else if ((switch_color == 3'b110) && (board_change_en == 1)) board[piece_change_loc] <= 3'b110;
		else if ((switch_color == 3'b100) && (board_change_en == 1)) board[piece_change_loc] <= 3'b100;
		else if ((switch_color == 3'b111) && (board_change_en == 1)) board[piece_change_loc] <= 3'b111;
		else if ((switch_color == 3'b101) && (board_change_en == 1)) board[piece_change_loc] <= 3'b101;
	end 
end


// serializing the board
genvar i;
generate for (i=0; i<64; i=i+1) begin: PACK_BOARD
	assign serialized_board[i*3+2 : i*3] = board[i];
end
endgenerate	

// fsm 
reg [2:0] S;
reg [2:0] NS;
parameter START = 3'b000,
			 PIECE_SELECTION = 3'b001, 
			 MOVE = 3'b010,
			 CREATE_NEW_PIECE = 3'b011,
			 DELETE_CAPTURE_PIECE = 3'b100,
			 DELETE_OLD_PIECE = 3'b101,
			 SWITCH_PLAYER = 3'b110;
			
always@(posedge clk or negedge rst)	begin 
	if (rst == 1'b0) 
		S <= START;
	else
		S <= NS;
end

reg [5:0] old_loc;
reg [2:0] x_diff;
reg [2:0] y_diff;
always @(*) begin
	if (select_loc[5:3] >= old_loc[5:3]) x_diff = select_loc[5:3] - old_loc[5:3];
	else											 x_diff = old_loc[5:3] - select_loc[5:3];
	
	if (select_loc[2:0] >= old_loc[2:0]) y_diff = select_loc[2:0] - old_loc[2:0];
	else										    y_diff = old_loc[2:0] - select_loc[2:0];
end

// defining legal moves
reg [3:0] x_mid;
reg [3:0] y_mid;
reg is_legal;
reg capturable;
always @(*) begin 
	if ((x_diff == y_diff) && (x_diff == 1)) begin
		is_legal = 1;
		capturable = 0;
		x_mid = 0;
		y_mid = 0;
	end
	else if ((x_diff == y_diff) && (x_diff == 2)) begin
		is_legal = 1;
		x_mid = ({1'b0, select_loc[5:3]} + {1'b0, old_loc[5:3]}) / 2;
		y_mid = ({1'b0, select_loc[2:0]} + {1'b0, old_loc[2:0]}) / 2;
		capturable = 1;
	end 
	else begin
		is_legal = 0;
		capturable =0;
		x_mid = 0;
		y_mid = 0;
	end
end 

always@(posedge clk or negedge rst) begin 
	if (rst == 1'b0) begin
		switch_color <= 3'd1; // this values is not used
		board_change_en <= 0;
		old_loc <= {3'b0,3'b1};
		piece_change_loc <= 0;
	end
	else begin
		case(S)
			START: begin
				switch_color <= 3'd1; // this values is not used
				board_change_en <= 0;
				NS <= PIECE_SELECTION;
			end
			PIECE_SELECTION: begin
				if (board[select_loc] [2] == 1'b1) begin // if there is a piece at selected location
					switch_color <= board[select_loc];
					old_loc <= select_loc;
					NS <= MOVE;
				end 
				else begin
					NS <= PIECE_SELECTION;
				end
			end
			MOVE: begin 
				if (is_legal == 1'b1)
					NS <= CREATE_NEW_PIECE;
				else
					NS <= MOVE;
			end 
			CREATE_NEW_PIECE: begin
				board_change_en <= 1;
				piece_change_loc <= select_loc;
				NS <= DELETE_CAPTURE_PIECE;
			end
			DELETE_CAPTURE_PIECE: begin
				if (capturable == 1'b1) begin
					piece_change_loc <= {x_mid, y_mid};
					switch_color <= 0;
				end
				NS <= DELETE_OLD_PIECE;
			end
			DELETE_OLD_PIECE: begin
				piece_change_loc <= old_loc;
				switch_color <= 0;
				NS <= SWITCH_PLAYER;
			end
			SWITCH_PLAYER:begin 
				board_change_en <= 0;
				NS <= START;
			end
		endcase
	end 
end 

/* legal move have 7 seven bit buses
the first bit is to see if the move is the legal move exist ( respresented by 1)
the next 6 bit is the location of the legal move
*/
// logic defining the location of the legal move
always @(posedge clk or negedge rst) begin
	if (rst == 1'b0)
		legal_move <= 0;
	// only legal if piece has piece
	else if (board[select_loc] [2] == 1'b1)  begin
		// if a piece is a red or a king 
		if((board[select_loc] [1] == 1'b1) || (board[select_loc] [0] == 1'b1)) begin
		//legal moves needs to stay in the board
			if ((select_loc[5:3] > 3'd0) && (select_loc[2:0] < 3'd7) && (board[{select_loc[5:3] - 1, select_loc[2:0] + 1}] [2] == 1'b0)) begin
				// this move is on the top left
				legal_move[6:0] <= {1'b1, select_loc[5:3] - 3'b1, select_loc[2:0] + 3'b1};
			end else if ((select_loc[5:3] > 3'd1) && (select_loc[2:0] < 3'd6) && (board[{select_loc[5:3] - 2, select_loc[2:0] + 2}] [2] == 1'b0) && (board[{select_loc[5:3] - 2, select_loc[2:0] + 2}] [1] != board[select_loc] [1])) begin
				// this this to find the legal move space for jumping
				legal_move[6:0] <= {1'b1, select_loc[5:3] - 3'd2, select_loc[2:0] + 3'd2};
			end
			else begin
				legal_move[6:0] <= 0;
			end
			
			if ((select_loc[5:3] < 3'd7) && (select_loc[2:0] < 3'd7) && (board[{select_loc[5:3] + 1, select_loc[2:0] + 1}] [2] == 1'b0)) begin
				// this move is on the top right
				legal_move[13:7] <= {1'b1, select_loc[5:3] + 3'b1, select_loc[2:0] + 3'b1};
			end else if ((select_loc[5:3] < 3'd6) && (select_loc[2:0] < 3'd6) && (board[{select_loc[5:3] + 2, select_loc[2:0] + 2}] [2] == 1'b0) && (board[{select_loc[5:3] + 2, select_loc[2:0] + 2}] [1] != board[select_loc] [1])) begin
				// draw legal move for jump
				legal_move[13:7] <= {1'b1, select_loc[5:3] + 3'd2, select_loc[2:0] + 3'd2};
			end
			else begin
				legal_move[13:7] <= 0;
			end
			
			if (board[select_loc] [0] != 1'b1)
				legal_move[27:14] <= 0;
		end
		
		// if a piece is a white or a king
		if((board[select_loc] [1] == 1'b0) || (board[select_loc] [0] == 1'b1)) begin
		//legal moves needs to stay in the board
			if ((select_loc[5:3] > 3'd0) && (select_loc[2:0] > 3'd0) && (board[{select_loc[5:3] - 1, select_loc[2:0] - 1}] [2] == 1'b0)) begin
				// this move is on the bottom left
				legal_move[20:14] <= {1'b1, select_loc[5:3] - 3'b1, select_loc[2:0] - 3'b1};
			end else if ((select_loc[5:3] > 3'd1) && (select_loc[2:0] > 3'd1) && (board[{select_loc[5:3] - 2, select_loc[2:0] - 2}] [2] == 1'b0) && (board[{select_loc[5:3] - 2, select_loc[2:0] - 2}] [1] != board[select_loc] [1])) begin
				legal_move[20:14] <= {1'b1, select_loc[5:3] - 3'd2, select_loc[2:0] - 3'd2};
			end
			else begin
				legal_move[20:14] <= 0;
			end
			
			if ((select_loc[5:3] < 3'd7) && (select_loc[2:0] > 3'd0) && (board[{select_loc[5:3] + 1, select_loc[2:0] - 1}] [2] == 1'b0)) begin
				// this move is on the bottom right
				legal_move[27:21] <= {1'b1, select_loc[5:3] + 3'b1, select_loc[2:0] - 3'b1};
			end else if ((select_loc[5:3] < 3'd6) && (select_loc[2:0] > 3'd1) && (board[{select_loc[5:3] + 2, select_loc[2:0] - 2}] [2] == 1'b0) && (board[{select_loc[5:3] + 2, select_loc[2:0] - 2}] [1] != board[select_loc] [1])) begin
				legal_move[27:21] <= {1'b1, select_loc[5:3] + 3'd2, select_loc[2:0] - 3'd2};
			end
			else begin
				legal_move[27:21] <= 0;
			end
			
			if (board[select_loc] [1] != 1'b0)
				legal_move[13:0] <= 0;
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
