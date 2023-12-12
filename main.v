module main (	 
	 input wire clk_50MHz, // 50 MHz system clock
    output reg clk_25MHz, // 25 MHz clock output
	 //control input
	 input btn_up,       	// Button input for moving up
    input btn_down,     	// Button input for moving down
    input btn_left,     	// Button input for moving left
    input btn_right,    	// Button input for moving right
	 input selected,			// Button input for picking a piece
	 input wire input_rst,  // Reset input
	 // display outputs
    input wire clk_rst,    // reset clk
    output wire hsync,     // Horizontal sync output
    output wire vsync,     // Vertical sync output
    output [7:0] red,   // Red channel
    output [7:0] green, // Green channel
    output [7:0] blue,   // Blue channel	
	 output [7:0] turn_count
);


// Clock divider to generate 25 MHz clock from 50 MHz clock
always @(posedge clk_50MHz) begin
	if (clk_rst) begin
		clk_25MHz <= 0;
   end else begin
      clk_25MHz <= ~clk_25MHz;
   end
end


//example input for cursor and selected values
reg[5:0] cursor_loc;
reg[5:0] select_loc;
// boardstate the board
wire [191:0] serialized_board;
wire [27:0] legal_move;

cursor_control mod(
    .clk(clk_50MHz),             					 	// Clock input
    .rst(input_rst),           	 					   // rst input
    .in_btn_up(btn_up),       							// Button input for moving up
    .in_btn_down(btn_down),     							// Button input for moving down
    .in_btn_left(btn_left),     							// Button input for moving left
    .in_btn_right(btn_right),    						// Button input for moving right
	 .in_selected(selected),								// Button input for picking a piece
	 .sel_loc(select_loc),									// Location of selected piece
    .location(cursor_loc) 									// Location of the cursor
);

display screen(
    .clk(clk_25MHz), 										// 25 MHz clock output
    .rst(clk_rst),      								   // Reset input
	 .serialized_board(serialized_board), 				// board state
	 .cursor_loc(cursor_loc),								// cursor location
	 .select_loc(select_loc),								// selected piece location
	 .legal_move(legal_move),								// location of the legal move
    .hsync(hsync),     										// Horizontal sync output
    .vsync(vsync),  										   // Vertical sync output
    .red(red),  											   // Red channel
    .green(green), 											// Green channel
    .blue(blue) 											   // Blue channel
);

game_logic gameplay(
	.clk(clk_50MHz),             					 	// Clock input
   .rst(input_rst),
	.select_loc(select_loc), 						// location of the picked piece
	.legal_move(legal_move),
	.serialized_board(serialized_board),
	.turn_count(turn_count)
);
endmodule 