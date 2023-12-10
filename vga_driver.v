module vga_driver (
    input wire clk, // 50 MHz system clock
    input wire rst,       // Reset input
    output reg hsync,     // Horizontal sync output
    output reg vsync,     // Vertical sync output
	 output reg [9:0] h_count,
    output reg [9:0] v_count
);

	 // VGA parameters for 640x480 resolution
    parameter h_sync_pulse = 96;
    parameter h_total_pixels = 800;

    parameter v_sync_pulse = 2;
    parameter v_total_lines = 525;

    // Updating horizontal and vertical counters
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count < h_total_pixels - 1) begin
                h_count <= h_count + 1;
            end else begin
                h_count <= 0;
                if (v_count < v_total_lines - 1) begin
                    v_count <= v_count + 1;
                end else begin
                    v_count <= 0;
                end
            end
        end
    end

    // Generating hsync and vsync signals
    always @(*) begin
        hsync = ~(h_count < h_sync_pulse);
        vsync = ~(v_count < v_sync_pulse);
    end

endmodule
