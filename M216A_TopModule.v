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
//integer current, i, j; 
reg [1:0] current;
reg [3:0] i[1:0];

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
    current = 0;
    // Initialize strips to be empty since there were no strips at start
    // Reset logic: Reset all strips to empty state
    for (i[0] = 0; i[0] < 13; i[0] = i[0] + 1) begin
        Occupied_Width[i[0]] = 0; //set to empty strip
    end
    strip_heights[0] = 12;  //0000  0
    strip_heights[1] = 4;   //0001  12
    strip_heights[2] = 11;  //0010  16
    strip_heights[3] = 5;   //0011  21
    strip_heights[4] = 10;  //0100  31
    strip_heights[5] = 6;   //0101  37
    strip_heights[6] = 9;   //0110  48
    strip_heights[7] = 7;   //0111  57
    strip_heights[8] = 8;   //1000  64
    strip_heights[9] = 8;   //1001  72
    strip_heights[10] = 16; //1010  80
    strip_heights[11] = 16; //1011  96
    strip_heights[12] = 16; //1100  112
    for (i[0] = 0; i[0] < 2; i[0] = i[0] + 1) begin
        min_priority[i[0]] = 0;
        min_row[i[0]]=0;
        min_y[i[0]]=ARRAY_SIZE;//Some maximum
        min_row_width[i[0]]=255;
        current_stage[i[0]] = 0;
        strike[i[0]] = 1;
        index_x[i[0]] = 0;
        index_y[i[0]] = 0;
        program_height[i[0]] = 0;
        program_width[i[0]] = 0;
    end
    strike_o = 0;
    index_x_o = 0;
    index_y_o = 0;
    counter = 3;
    i[0] = 0;
end

task find_suitable_strip;
    input [1:0] current;
    inout [3:0] i_current;
    input [3:0] i_target;
    inout [7:0] min_row_width;
    inout [3:0] min_row;
    inout [7:0] min_y;
    inout [3:0] min_priority;
    reg [3:0] index;
    // Add other necessary inputs and outputs
    begin
        //The iteration is only necessary if we did not find a match, in that case min_y == ARRAY_SIZE
        for (index = 0; index < 13; index = index + 1) begin
            if(index < i_target && index >= i_current) begin
                //does not need to be 13, adjust accordingly for timing we can do the rest in later stages
                //And also we do not need to set this specifically to be 0 because when new input came in this is defaulted to zero
                //find suitable strip that is not full
                //strip_heights[i[current]] - program_height[current] == 0 optimized to strip_heights[i[current]] == program_height[current] so no adder needed
                //strip_heights[i[current]] - program_height[current] == 1 optimized to strip_heights[i[current]] - 1 == program_height[current] because strip_heights[i[current]] is only 4 bit
                if (strip_heights[index] == program_height[current] || strip_heights[index] - 1 == program_height[current] || (strip_heights[index] == 16 && program_height[current] >= 13))begin
                    //This is for debugging
                    //if(program_width[current] == 12 && program_height[current] == 12) begin
                        //current = current;
                    //end
                    //Is a parameter considered a constant? or does it takes up some space?
                    //ARRAY_SIZE - Occupied_Width[i[current]] >= program_width[current] optimized to ARRAY_SIZE >= program_width[current] + Occupied_Width[i[current]]
                    //Possibly avoided the need for computing additional complements
                    if(ARRAY_SIZE >= program_width[current] + Occupied_Width[index]) begin
                        if(Occupied_Width[index] < min_row_width) begin
                            if(strip_heights[index] == program_height[current] || program_height[current] >= 13) begin
                                min_priority = 1;
                            end
                            min_row = index;
                            min_y=index_y[current];
                            min_row_width = Occupied_Width[index];
                        end else if(Occupied_Width[index] == min_row_width && min_priority != 1)begin 
                            min_priority = 1;
                            min_row = index;
                            min_y = index_y[current];
                            min_row_width = Occupied_Width[index];
                        end
                    end
                end
                if(strike[current] == 1) begin
                    index_y[current] = index_y[current] + strip_heights[index];
                end
            end
        end
    end
endtask


// Main Algorithm Logic
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i == 1) begin
        // Reset logic: Reset all strips to empty state
        for (i[0] = 0; i[0] < 13; i[0] = i[0] + 1) begin
            Occupied_Width[i[0]] = 0; // Assuming 0 represents an empty strip
        end
        for (i[0] = 0; i[0] < 2; i[0] = i[0] + 1) begin
            min_priority[i[0]] = 0;
            min_row[i[0]]=0;
            min_y[i[0]]=ARRAY_SIZE;//Some maximum
            min_row_width[i[0]]=255;
            strike[i[0]] = 1;
            index_x[i[0]] = 0;
            index_y[i[0]] = 0;
            program_height[i[0]] = 0;
            program_width[i[0]] = 0;
        end
        strike_o = 0;
        index_x_o = 0;
        index_y_o = 0;
        counter = 3;
        i[0] = 0;
    end else begin
        // Pipelining, If counter counted to 3, read
        // in to their next part, if output is available, output them
        //And they were meant to copy the last one if there were not input
        //So the output does not change

        /* disregard for now
        for (i = 7; i >= 1; i--) begin
            strike[i[current]] = strike[i-1];
            index_x[i[current]] = index_x[i-1];
            index_y[i[current]] = index_y[i-1];
            program_height[i[current]] = program_height[i-1];
            program_width[i[current]] = program_width[i-1];
        end*/

        //Every four clock read an input 
        //(since counter is 2 bit it loops when overflow no "reset" needed)
        if(counter == 0) begin
            //Instead of shifting position each clock
            //Shift up when input comes
            i[1] = i[0];
            min_priority[1] = min_priority[0];
            min_row[1] = min_row[0];
            min_y[1] = min_y[0];
            min_row_width[1] = min_row_width[0];
            strike[1] = strike[0];

            i[0] = 0;
            min_priority[0] = 0;
            min_row[0] = 0;
            min_y[0] = ARRAY_SIZE;//Some maximum
            min_row_width[0] = 255;
            strike[0] = 1;//assume always error

            current_stage[1] = current_stage[0];
            program_height[1] = program_height[0];
            program_width[1] = program_width[0];
            index_x[1] = index_x[0];
            index_y[1] = index_y[0];

            current_stage[0] = 0;
            program_height[0] = height_i;
            program_width[0] = width_i;
            index_x[0] = 0;
            index_y[0] = 0;
        end
        counter = counter + 1;

        //Start processing those of stage 7,6,5,4,3,2,1,0
        for(current = 0; current < 2; current = current + 1) begin
            if(program_height[current] != 0 && program_width[current] != 0) begin
                //If there were any errors we simply continues to the end
                case (current_stage[current])
                    0: begin//setups
                        
                        /////////////////////////////////////////////////////////////////////
                        //TODO: Adjust this so that this is distributed along all the stage//
                        //As so the clock time can be adjusted                             //
                        /////////////////////////////////////////////////////////////////////

                        //The iteration is only necessary if we did not find a match, in that case min_y == ARRAY_SIZE
                        find_suitable_strip(current, i[current], 2, min_row_width[current], min_row[current], min_y[current], min_priority[current]);
                    end
                    1: begin
                        find_suitable_strip(current, i[current], 5, min_row_width[current], min_row[current], min_y[current], min_priority[current]);
                    end
                    2: begin
                        find_suitable_strip(current, i[current], 8, min_row_width[current], min_row[current], min_y[current], min_priority[current]);
                    end
                    3: begin
                        find_suitable_strip(current, i[current], 10, min_row_width[current], min_row[current], min_y[current], min_priority[current]);

                        //If items were placed before this stage this is absolutely necessary
                        //If we wer able to find anything at this point the results must be updated in the register before the next came in
                        //Optimized ARRAY_SIZE - min_y[current] - program_height[current] >= 0 to ARRAY_SIZE >= min_y[current] + program_height[current] to avoid multiple subtraction
                        if(ARRAY_SIZE >= min_y[current] + program_height[current]) begin//means found a fit
                            index_x[current] = min_row_width[current]; // Set the starting x-coordinate
                            index_y[current] = min_y[current]/* calculate y-coordinate based on strip (not actually needed here) */;
                            Occupied_Width[min_row[current]] = Occupied_Width[min_row[current]] + program_width[current]/* update strip state */;
                            strike[current] = 0; // Allocation successful
                        end
                    end
                    4: begin
                        find_suitable_strip(current, i[current], 11, min_row_width[current], min_row[current], min_y[current], min_priority[current]);
                    end
                    5: begin
                        find_suitable_strip(current, i[current], 12, min_row_width[current], min_row[current], min_y[current], min_priority[current]);
                    end
                    6: begin
                        find_suitable_strip(current, i[current], 13, min_row_width[current], min_row[current], min_y[current], min_priority[current]);
                        
                        if(strike[current] == 1 && ARRAY_SIZE >= min_y[current] + program_height[current]) begin//means found a fit
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
                        //Sent to output
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
