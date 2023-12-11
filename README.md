# ECE287_checker
final project for ece287

this is a checker game on the fpga using verilog, the game can be view on a screen using a vga cable.
for context I have declare [63:0] board [2:0] where 
[{first 3 bits are the x axis, second 3 bits are the y axis}] board [{first bit is to check if this square has a checker piece( 1 means yes ), second bit  check what is the color of the piece (1 means red, 0 means white), this check if the piece is a king(1 means yes)}]
the board is divided into 64 square and numbered using x and y axis values from 0 to 7, the origin (0,0) is at the bottom left of the board. 

