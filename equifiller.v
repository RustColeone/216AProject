module EquifillingProgramAllocator(
    input clk_i,               // Clock signal
    input rst_i,             // Reset signal
    input [5:0] height_i, // Size of the incoming program
    input [5:0] width_i, // Size of the incoming program
    output reg strike_o,     // Strike signal
    output reg [7:0] index_x_o, // X-coordinate of allocation
    output reg [7:0] index_y_o,  // Y-coordinate of allocation
    output reg [7:0] Occupied_Width[127:0]
);

// Parameters and Internal Variables
parameter ARRAY_SIZE = 128;
integer i, j; 
reg [ARRAY_SIZE-1:0] strips[12:0]; // Represents the 13 strips
reg [4:0] strip_heights[12:0] = {12, 4, 11, 5, 10, 6, 9, 7, 8, 8, 16, 16, 16}; 
reg [5:0] program_height, program_width;
reg strike;
reg [7:0] index_x;
reg [7:0] index_y;
// Strip heights
// We will be putting programs into the i-th strip n or n - 1

// Initialization
initial begin
    // Initialize strips to be empty since there were no strips at start
    // Reset logic: Reset all strips to empty state
    for (i = 0; i < 13; i++) begin
        strips[i] = 0; // Assuming 0 represents an empty strip
    end
    strike = 0;
    strike_o = 0;
    index_x = 0;
    index_x_o = 0;
    index_y = 0;
    index_y_o = 0;
    program_height = 0;
    program_width = 0;
    Occupied_Width = strips[i];
end

// Main Algorithm Logic
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        // Reset logic: Reset all strips to empty state
        for (i = 0; i < 13; i++) begin
            strips[i] = 0;
        end
        strike = 0;
        strike_o = 0;
        index_x = 0;
        index_x_o = 0;
        index_y = 0;
        index_y_o = 0;
        program_height = 0;
        program_width = 0;
        Occupied_Width = strips[i];
    end else begin
        // Algorithm to allocate program
        // Assuming program_size somehow translates to height and width
        
        // Assume allocation failure initially
        // If allocation successful, we change this back to 0
        strike = 1;
        index_y = 0;
        program_height = height_i;
        program_width = width_i;
        // Loop all the strips for suitable allocation
        for (i = 0; i < 13; i++) begin
            // Check if the program can fit in the current strip
            if (strip_heights[i] - program_height == 0 || strip_heights[i] - program_height == 1) begin
                // Check for available width in the strip
                if(ARRAY_SIZE - strips[i] - program_width >= 0) begin
                    index_x = strips[i]; // Set the starting x-coordinate
                    index_y = index_y/* calculate y-coordinate based on strip (not actually needed here) */;
                    strips[i] += program_width/* update strip state */;
                    strike = 0; // Allocation successful
                    break;
                end
            end
            if (strike == 0) break; // Exit if program placed
            // If we reach here it means we have not place an item in this row
            // Thus the new y coordinate will be the current added with the height of this strip
            index_y += strip_heights[i];
        end
        //Calculation is complete at this point
        strike_o = strike;
        index_x_o = index_x;
        index_y_o = index_y;
        Occupied_Width = strips;
    end
end

// Additional functions or tasks (if required)

endmodule
