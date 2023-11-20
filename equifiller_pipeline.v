module M216A_TopModule (
    input clk_i,               // Clock signal
    input rst_i,             // Reset signal
    input [4:0] height_i, // Size of the incoming program
    input [4:0] width_i, // Size of the incoming program
    output reg [3:0] strike_o,     // Strike signal
    output reg [7:0] index_x_o, // X-coordinate of allocation
    output reg [7:0] index_y_o  // Y-coordinate of allocation
);

// Parameters and Internal Variables
parameter ARRAY_SIZE = 128;
integer current, i, j; 
reg [7:0] Occupied_Width[12:0]; // Represents the 13 strips
reg min_priority[1:0];
reg [3:0] min_row[1:0];
reg [7:0] min_y[1:0];
reg [7:0] min_row_width[1:0];
reg [7:0] program_height[1:0], program_width[1:0]; 
reg [4:0] strip_heights[12:0]; 
reg [3:0] strike[1:0];
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
    for (i = 0; i < 13; i = i + 1) begin
        Occupied_Width[i] = 0; //set to empty strip
    end
    strip_heights[0] = 12;  //0000
    strip_heights[1] = 4;   //0001
    strip_heights[2] = 11;  //0010
    strip_heights[3] = 5;   //0011
    strip_heights[4] = 10;  //0100
    strip_heights[5] = 6;   //0101
    strip_heights[6] = 9;   //0110
    strip_heights[7] = 7;   //0111
    strip_heights[8] = 8;   //1000
    strip_heights[9] = 8;   //1001
    strip_heights[10] =16;  //1010
    strip_heights[11] = 16; //1011
    strip_heights[12] = 16; //1100
    for (i = 0; i < 2; i = i + 1) begin
        min_priority[i] = 0;
        min_row[i]=0;
        min_y[i]=0;
        min_row_width[i]=255;
        current_stage[i] = 0;
        strike[i] = 0;
        index_x[i] = 0;
        index_y[i] = 0;
        program_height[i] = 0;
        program_width[i] = 0;
    end
    strike_o = 0;
    index_x_o = 0;
    index_y_o = 0;
    counter = 3;
end

// Main Algorithm Logic
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i == 1) begin
        // Reset logic: Reset all strips to empty state
        for (i = 0; i < 13; i = i + 1) begin
            Occupied_Width[i] = 0; // Assuming 0 represents an empty strip
        end
        for (i = 0; i < 2; i = i + 1) begin
            min_priority[i] = 0;
            min_row[i]=0;
            min_y[i]=0;
            min_row_width[i]=255;
            strike[i] = 0;
            index_x[i] = 0;
            index_y[i] = 0;
            program_height[i] = 0;
            program_width[i] = 0;
        end
        strike_o = 0;
        index_x_o = 0;
        index_y_o = 0;
        counter = 3;
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
            min_priority[1] = min_priority[0];
            min_row[1] = min_row[0];
            min_y[1] = min_y[0];
            min_row_width[1] = min_row_width[0];
            min_priority[0] = 0;
            min_row[0] = 0;
            min_y[0] = 0;
            min_row_width[0] = 255;

            current_stage[1] = current_stage[0];
            program_height[1] = program_height[0];
            program_width[1] = program_width[0];
            index_x[1] = index_x[0];
            index_y[1] = index_y[0];
            current_stage[0] = 0;
            program_height[0] = height_i;
            program_width[0] = width_i;
        end
        counter = counter + 1;

        //Start processing those of stage 7,6,5,4,3,2,1,0
        for(current = 0; current < 2; current = current + 1) begin
            if(program_height[current] != 0 && program_width[current] != 0) begin
                //If there were any errors we simply continues to the end
                case (current_stage[current])
                    0: begin//setups
                        //assume always error
                        strike[current] = 1;
                        //initializing for calculating y position
                        index_y[current] = 0;
                        
                        /////////////////////////////////////////////////////////////////////
                        //TODO: Adjust this so that this is distributed along all the stage//
                        //As so the clock time can be adjusted                             //
                        /////////////////////////////////////////////////////////////////////

                        for (i = 0; i < 13; i = i + 1) begin//does not need to be 13, adjust accordingly for timing we can do the rest in later stages
                            //find suitable strip that is not full
                            if (strip_heights[i] - program_height[current] == 0 || strip_heights[i] - program_height[current] == 1 || (strip_heights[i] == 16 && program_height[current] >= 13))begin
                                if(program_width[current] == 12 && program_height[current] == 12) begin
                                    current = current;
                                end
                                if(ARRAY_SIZE - Occupied_Width[i] >= program_width[current]) begin
                                    if(Occupied_Width[i] < min_row_width[current]) begin
                                        if(strip_heights[i] - program_height[current] == 0 || program_height[current] >= 13) begin
                                            min_priority[current] = 1;
                                        end
                                        min_row[current] = i;
                                        min_y[current]=index_y[current];
                                        min_row_width[current] = Occupied_Width[i];
                                    end else if(Occupied_Width[i] == min_row_width[current] && min_priority[current] != 1)begin 
                                        min_priority[current] = 1;
                                        min_row[current] = i;
                                        min_y[current]=index_y[current];
                                        min_row_width[current] = Occupied_Width[i];
                                    end
                                end
                            end
                            index_y[current] = index_y[current] + strip_heights[i];
                        end
                        if(ARRAY_SIZE - min_y[current] - program_height[current] >=0) begin//means found a fit
                            index_x[current] = min_row_width[current]; // Set the starting x-coordinate
                            index_y[current] = min_y[current]/* calculate y-coordinate based on strip (not actually needed here) */;
                            Occupied_Width[min_row[current]] = Occupied_Width[min_row[current]] + program_width[current]/* update strip state */;
                            strike[current] = 0; // Allocation successful
                        end
                        //if nothing is found index_y current should be 128 (clearly no suitable strip found)
                        if(index_y[current] >= 128 || index_x[current] >= 128 || strike[current] != 0)begin
                            //must be error
                            index_x[current] = 128;
                            index_y[current] = 128;
                            //continue;
                        end
                    end
                    1: begin
                        if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                            //continue;
                            current=current;
                        end
                        // do nothing, for timing adjustments
                    end
                    2: begin
                        if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                            //continue;
                            current=current;
                        end
                        // do nothing, for timing adjustments
                    end
                    3: begin
                        if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                            //continue;
                            current=current;
                        end
                        // do nothing, for timing adjustments
                    end
                    4: begin
                        if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                            //continue;
                            current=current;
                        end
                        // do nothing, for timing adjustments
                    end
                    5: begin
                        if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                            //continue;
                            current=current;
                        end
                        // do nothing, for timing adjustments
                    end
                    6: begin
                        //if(index_y[current] >= 128 && index_x[current] >= 128 || strike[current] == 0)begin
                            //continue;
                            //current=current;
                        //end
                        // do nothing, for timing adjustments
                        strike_o = strike[current];
                        index_x_o = index_x[current];
                        index_y_o = index_y[current];
                    end
                    //7: begin
                        // output everything
                        //strike_o = strike[current];
                        //index_x_o = index_x[current];
                        //index_y_o = index_y[current];
                    //end
                endcase//end of case
                current_stage[current] = current_stage[current] + 1;
            end
        end//End of for loop h
        
        
    end
end

// Additional functions or tasks (if required)

endmodule
