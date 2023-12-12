module display(
    input clk,
    input wire rst,       // Reset input
	 input [191:0] serialized_board, // board state
	 input [5:0] cursor_loc, //location of the cursor
	 input [5:0] select_loc, //loaction of selected piece
	 input [27:0] legal_move, // legal move
    output wire hsync,     // Horizontal sync output
    output wire vsync,     // Vertical sync output
    output reg [7:0] red,   // Red channel
    output reg [7:0] green, // Green channel
    output reg [7:0] blue   // Blue channel
);

wire [9:0] h_count; // current bit x axis
wire [9:0] v_count; // current bit y axis

	 
vga_driver driver(
	.clk(clk), 
	.rst(rst),      
	.hsync(hsync),     
	.vsync(vsync),  
	.h_count(h_count),
	.v_count(v_count)
);
	 
// VGA parameters for 640x480 resolution
parameter h_front_porch = 16;
parameter h_sync_pulse = 96;
parameter h_back_porch = 48;
parameter h_total_pixels = 800;

parameter v_front_porch = 10;
parameter v_sync_pulse = 2;
parameter v_back_porch = 33;
parameter v_total_lines = 525;
	
parameter empty_space = 80;

// Defining the display area
wire display_active = (h_count >= h_sync_pulse + h_back_porch + empty_space) &&
                      (h_count < h_total_pixels - h_front_porch - empty_space) &&
                      (v_count >= v_sync_pulse + v_back_porch) &&
                      (v_count < v_total_lines - v_front_porch);

// logic for the border
reg border_loc;
always @(*)
begin
	border_loc = (v_count <= v_sync_pulse + v_back_porch + 11) ||
					 (v_count >= v_total_lines - v_front_porch - 11)||
					 (h_count <= h_sync_pulse + h_back_porch + 11 + empty_space)||
					 (h_count >= h_total_pixels - h_front_porch - 11 - empty_space); 
end

// converting pixels to the axis
// defining the x axis 
reg [2:0] x_axis; 
reg [9:0] x_center;
always @ (*)
begin
	if ((h_count >= 236) && (h_count < 293)) begin
		x_axis = 3'd0; 
		x_center = 265;
	end else if (h_count < 350) begin
		x_axis = 3'd1; 
		x_center = 322;
	end else if (h_count < 407) begin
		x_axis = 3'd2;
		x_center = 379;
	end else if (h_count < 464) begin
		x_axis = 3'd3;
		x_center = 436;
	end else if (h_count < 521) begin
		x_axis = 3'd4;
		x_center = 493;
	end else if (h_count < 578) begin
		x_axis = 3'd5;
		x_center = 550;
	end else if (h_count < 635) begin
		x_axis = 3'd6;
		x_center = 607;
	end else begin
		x_axis = 3'd7;
		x_center = 664;
	end
end 

// defining the y axis 
reg [2:0] y_axis;
reg [9:0] y_center;
always @ (*)
begin
	if ((v_count >= 47) && (v_count < 104)) begin
		y_axis = 3'd7; 
		y_center = 76;
	end else if (v_count < 161) begin
		y_axis = 3'd6;
		y_center = 133;
	end else if (v_count < 218) begin
		y_axis = 3'd5;
		y_center = 190;
	end else if (v_count < 275) begin
		y_axis = 3'd4;
		y_center = 247;
	end else if (v_count < 332) begin
		y_axis = 3'd3;
		y_center = 304;
	end else if (v_count < 389) begin
		y_axis = 3'd2;
		y_center = 361;
	end else if (v_count < 446) begin
		y_axis = 3'd1;
		y_center = 418;
	end else begin
		y_axis = 3'd0;
		y_center = 475;
	end
end 

// check if a square is a black or white space
wire is_black_square; 
assign is_black_square = ((y_axis + x_axis) % 2) == 0; 

// drawing the checker piece, a piece with consist of two circle, 
wire is_in_big_circle = ((h_count - x_center) * (h_count - x_center) + (v_count - y_center) * (v_count - y_center)) <= (25 * 25);
wire is_in_small_circle = ((h_count - x_center) * (h_count - x_center) + (v_count - y_center) * (v_count - y_center)) <= (20 * 20);

wire draw_cursor = ({x_axis, y_axis} == cursor_loc) && ((h_count < x_center - 25) || (h_count > x_center + 25)
																		 || (v_count < y_center - 25) || (v_count > y_center + 25)); // draw the cursor
wire draw_select = ({x_axis, y_axis} == select_loc); //draw the selected piece

// draw legal move
wire is_legal = ((legal_move[6] == 1) && ({x_axis, y_axis} == legal_move[5:0])) ||
					 ((legal_move[13] == 1) && ({x_axis, y_axis} == legal_move[12:7])) ||
					 ((legal_move[20] == 1) && ({x_axis, y_axis} == legal_move[19:14])) ||
					 ((legal_move[27] == 1) && ({x_axis, y_axis} == legal_move[26:21]));

//deserializing the board
wire[2:0] board[63:0];
genvar i;
generate for (i=0; i<64; i=i+1) begin: REWIRE_BOARD
	assign board[i] = serialized_board[i*3+2 : i*3];
end
endgenerate

// color control
always @(*) begin
	if (display_active) begin
		if (border_loc) begin
			red = 8'd150; // this makes a brown color
         green =  8'd75;
			blue = 8'h00;
		end 
		else begin
		//coloring the entire board
			// a square has a piece in it.
			if (board[{x_axis, y_axis}] [2] == 1'b1) begin
				// what is the color of the piece
				// red piece 
				if (board[{x_axis, y_axis}] [1] == 1'b1) begin
					// draw the small circle
					if (is_in_small_circle == 1'b1) begin
						// if the piece is a king, the middle circle will become yellow 
						if (board[{x_axis, y_axis}] [0] == 1'b1) begin
							red = 8'hFF; // yellow 
							green = 8'hFF;
							blue = 8'h00;
						end
						// if the piece is  a normal piece
						else begin
							red = 8'd255; // light red 
							green = 8'd127;
							blue = 8'd127;
						end
					end
					// draw the big circle
					else if (is_in_big_circle == 1'b1) begin
						red = 8'hFF; // bright red 
						green = 8'h00;
						blue = 8'h00;
					end else begin
						if (draw_select) begin // if piece is selected
							red = 8'h00; // black space
							green = 8'hFF;
							blue = 8'h00;
							if (draw_cursor) begin // draw cursor
								red = 8'h00; // dark green
								green = 8'h99;
								blue = 8'h00;
							end
						end
						else begin
							red = 8'h00; // black space
							green = 8'h00;
							blue = 8'h00;
							if (draw_cursor) begin // draw cursor
								red = 8'h00; // dark green
								green = 8'h99;
								blue = 8'h00;
							end
						end
					end
				end
				// white piece
				else begin
					// draw the small circle
					if (is_in_small_circle == 1'b1) begin
						if (board[{x_axis, y_axis}] [0] == 1'b1) begin
							red = 8'd246; // yellow 
							green = 8'd190;
							blue = 8'd00;
						end
						// if the piece is  a normal piece
						else begin
							red = 8'd211; // light grey 
							green = 8'd211;
							blue = 8'd211;
						end
					end
					// draw the big circle
					else if (is_in_big_circle == 1'b1) begin
						red = 8'hFF; // white 
						green = 8'hFF;
						blue = 8'hFF;
					end else begin
						if (draw_select) begin // if piece is selected
							red = 8'h00; // black space
							green = 8'hFF;
							blue = 8'h00;
							if (draw_cursor) begin // draw cursor
								red = 8'h00; // dark green
								green = 8'h99;
								blue = 8'h00;
							end
						end
						else begin
							red = 8'h00; // black space
							green = 8'h00;
							blue = 8'h00;
							if (draw_cursor) begin // draw cursor
								red = 8'h00; // dark green
								green = 8'h99;
								blue = 8'h00;
							end
						end
					end
				end
			end 
			// if a square does not has a piece in it 
			else begin
				if (is_black_square == 1'b1) begin
					red = 8'h00; // black space
					green = 8'h00;
					blue = 8'h00;
					// drawing legal move a white circle
					if (is_legal) begin
						if (is_in_small_circle == 1'b1) begin
							red = 8'd0; // black
							green = 8'd0;
							blue = 8'd0;
						end else if (is_in_big_circle == 1'b1) begin
							red = 8'hFF; // white
							green = 8'hFF;
							blue = 8'hFF;
						end
					end
					if (draw_cursor) begin // draw cursor
						red = 8'h00; // dark green
						green = 8'h99;
						blue = 8'h00;
					end
				end else begin
					red = 8'hFF; // white space
					green = 8'hFF;
					blue = 8'hFF;
					if (draw_cursor) begin // draw cursor
						red = 8'h00; // dark green
						green = 8'h99;
						blue = 8'h00;
					end
				end
			end
		end
   end else begin
		red = 8'h00; // this is black; anything outside the board will be black.
      green = 8'h00;
      blue = 8'h00;
   end
end
	 
endmodule
