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
integer current, i, j; 
reg [ARRAY_SIZE-1:0] strips[12:0]; // Represents the 13 strips
reg [7:0] program_height[1:0], program_width[1:0]; 
reg [4:0] strip_heights[12:0] = {12, 4, 11, 5, 10, 6, 9, 7, 8, 8, 16, 16, 16}; 
reg [5:0] program_height[1:0], program_width[1:0];
reg strike[1:0];
reg [7:0] index_x[1:0];
reg [7:0] index_y[1:0];
reg [1:0] counter;
reg [3:0] current_stage[1:0];
// Strip heights
// We will be putting programs into the i-th strip n or n - 1

// Initialization
initial begin
    // Initialize strips to be empty since there were no strips at start
    // Reset logic: Reset all strips to empty state
    for (i = 0; i < 13; i++) begin
        strips[i] = 0; //set to empty strip
    end
    for (i = 0; i < 2; i++) begin
        current_stage[i] = 0
        strike[i] = 0;
        index_x[i] = 0;
        index_y[i] = 0;
        program_height[i] = 0;
        program_width[i] = 0;
    end
    Occupied_Width = strips[i];
    strike_o = strike;
    index_x_o = index_x;
    index_y_o = index_y;
    counter = 0;
end

// Main Algorithm Logic
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        // Reset logic: Reset all strips to empty state
        for (i = 0; i < 13; i++) begin
            strips[i] = 0; // Assuming 0 represents an empty strip
        end
        for (i = 0; i < 2; i++) begin
            strike[i] = 0;
            index_x[i] = 0;
            index_y[i] = 0;
            program_height[i] = 0;
            program_width[i] = 0;
        end
        Occupied_Width = strips[i];
        strike_o = 0;
        index_x_o = 0;
        index_y_o = 0;
    end else begin
        // Pipelining, If counter counted to 3, read
        // in to their next part, if output is available, output them
        //And they were meant to copy the last one if there were not input
        //So the output does not change

        /* disregard for now
        for (i = 7; i >= 1; i--) begin
            strike[i] = strike[i-1];
            index_x[i] = index_x[i-1];
            index_y[i] = index_y[i-1];
            program_height[i] = program_height[i-1];
            program_width[i] = program_width[i-1];
        end*/

        //Every four clock read an input 
        //(since counter is 2 bit it loops when overflow no "reset" needed)
        if(counter == 0) begin
            //Instead of shifting position each clock
            //Shift up when input comes
            current_stage[1] = current_stage[0]
            program_height[1] = program_height[0]
            program_width[1] = program_width[0]
            current_stage[0] = 0;
            program_height[0] = height_i
            program_width[0] = width_i
        end
        counter ++

        //Start processing those of stage 7,6,5,4,3,2,1,0
        for(current = 0; current < 2; current ++) begin
            if(program_height[current] == 0 && program_width[current] == 0) begin
                continue;
            end
            //If there were any errors we simply continues to the end
            begin case (current_stage[current])
                0: begin//setups
                    //assume always error
                    strike[current] = 1;
                    //initializing for calculating y position
                    index_y[current] = 0;
                    
                    /////////////////////////////////////////////////////////////////////
                    //TODO: Adjust this so that this is distributed along all the stage//
                    //As so the clock time can be adjusted                             //
                    /////////////////////////////////////////////////////////////////////

                    for (i = 0; i < 13; i++) begin//does not need to be 13, adjust accordingly for timing we can do the rest in later stages
                        //find suitable strip that is not full
                        if (strip_heights[i] - program_height[current] == 0 || strip_heights[i] - program_height[current] == 1)begin
                            if(ARRAY_SIZE - strips[i] - program_width >= 0) begin
                                index_x = strips[i]; // Set the starting x-coordinate
                                index_y = index_y/* calculate y-coordinate based on strip (not actually needed here) */;
                                strips[i] += program_width/* update strip state */;
                                strike = 0; // Allocation successful
                                break;
                            end
                        end
                        index_y[current] += strip_heights[i];
                    end
                    //if nothing is found index_y current should be 128 (clearly no suitable strip found)
                    if(index_y[current] >= 128)begin
                        //skip to the end with error out
                        strike[current] = 1;
                        index_x[current] = 128;
                        index_y[current] = 128;
                        continue;
                    end
                end
                1: begin
                    if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                        continue;
                    end
                    // do nothing, for timing adjustments
                end
                2: begin
                    if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                        continue;
                    end
                    // do nothing, for timing adjustments
                end
                3: begin
                    if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                        continue;
                    end
                    // do nothing, for timing adjustments
                end
                4: begin
                    if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                        continue;
                    end
                    ;// do nothing, for timing adjustments
                end
                5: begin
                    if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                        continue;
                    end
                    ;// do nothing, for timing adjustments
                end
                6: begin
                    if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                        continue;
                    end
                    ;// do nothing, for timing adjustments
                end
                7: begin
                    // output everything
                    strike_o = strike[current];
                    index_x_o = index_x[current];
                    index_y_o = index_y[current];
                    Occupied_Width = strips;
                end
            endcase//end of case
            current_stage[h] ++;
        end//End of for loop h
        
        
    end
end

// Additional functions or tasks (if required)

endmodule
