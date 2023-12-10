module cursor_control(
    input clk,              	// Clock input
    input rst,           	   // rst input
    input in_btn_up,       	// Button input for moving up
    input in_btn_down,     	// Button input for moving down
    input in_btn_left,     	// Button input for moving left
    input in_btn_right,    	// Button input for moving right
	 input in_selected,			// Button input for picking a piece
	 output reg [5:0]sel_loc,	// Debounced pickign input button
    output reg [5:0] location // Location of the cursor
);
 
// Registers for storing the current position
reg [2:0] x;
reg [2:0] y;

// declaring states
parameter START = 2'b00,
			 GETTING_READY = 2'b01, 
			 UPDATE = 2'b10,
			 RETURN = 2'b11; 
reg [1:0] S; 
reg [1:0] NS; 

// flip the input button for moving values as they are always hot 
 reg btn_up;       	
 reg btn_down;    
 reg btn_left;     
 reg btn_right;


always @(*) 
begin 
	btn_up = ~in_btn_up;
	btn_down = ~in_btn_down;
	btn_left = ~in_btn_left;
	btn_right = ~in_btn_right;
end 

// using a finite state machine so cursor only move up once no matter how long it is pressed
always @(posedge clk or negedge rst) 
begin
	if (rst == 1'b0)
		S <= START;
	else 
		S <= NS;
end

// temporary values
reg temp_up = 0;
reg temp_down = 0;
reg temp_left = 0;
reg temp_right = 0;

// position update
always @(posedge clk or negedge rst) begin
    if (rst == 1'b0) begin
        // rst the position 
        x <= 3'b000;
        y <= 3'b000;
    end 
	 else begin
		  case(S)
				START: // only move on if a button is pressed
				begin
					if (btn_up | btn_down | btn_left | btn_right) begin
						NS <= GETTING_READY; 
						if(btn_up) temp_up <= 1;
						if(btn_down) temp_down <= 1;
						if(btn_left) temp_left <= 1;
						if(btn_right) temp_right <=1;
						end
					else
						NS <= START;
				end
				GETTING_READY: // only move on if a button is released
				begin
					if (btn_up | btn_down | btn_left | btn_right)
						NS <= GETTING_READY; 
					else
						NS <= UPDATE;
				end
				UPDATE:
				begin
					// Update the cursor position based on button presses
					if (temp_up) begin
						y <= y + 3'b001;
						temp_up <= 0;
						end
					if (temp_down) begin
						y <= y - 3'b001;
						temp_down <= 0;
						end
					if (temp_left) begin 
						x <= x - 3'b001;
						temp_left <= 0;
						end
					if (temp_right) begin
						x <= x + 3'b001;
						temp_right <= 0;
						end
					NS <= START;
				end
				default: NS <= RETURN;
			endcase
    end
end

// Update the output position and selected location 
always @(posedge clk) 
begin
    location <= {x,y}; 
	 if (rst == 1'b0)
		 sel_loc <= {3'b0,3'b1};
	 if (in_selected == 1'b1)
		 sel_loc <= location;
end

endmodule
