module Display_module (
    // Clock and reset
    input wire clk,              // System clock
    input wire reset,            // Synchronous reset, active high
    
    // Status inputs
    input wire [5:0] vehicle_count,     // Current number of vehicles in parking
    input wire [5:0] available_spaces,  // Number of available parking spaces
    input wire [2:0] current_state,     // Current state of FSM
    input wire [1:0] barrier_status,    // Status of entry/exit barriers
    input wire alarm,                   // Alarm signal
    input wire [7:0] fee_amount,        // Parking fee amount
    
    // Display outputs
    output reg [7:0] segment_display,   // 7-segment display control signal
    output reg [3:0] digit_select,      // Digit selection for display
    output reg [3:0] led_indicators     // System status LED indicators
);

    // Parameters for display refresh
    parameter REFRESH_RATE = 1000;  // Display refresh rate in clock cycles
    
    // Internal registers
    reg [9:0] refresh_counter;      // Counter for display refresh
    reg [1:0] digit_index;          // Current digit to display
    reg [3:0] current_digit;        // Value of current digit
    
    // 7-segment display patterns for digits 0-9
    function [7:0] get_segment_pattern;
        input [3:0] digit;
        begin
            case (digit)
                4'h0: get_segment_pattern = 8'b11000000;  // 0
                4'h1: get_segment_pattern = 8'b11111001;  // 1
                4'h2: get_segment_pattern = 8'b10100100;  // 2
                4'h3: get_segment_pattern = 8'b10110000;  // 3
                4'h4: get_segment_pattern = 8'b10011001;  // 4
                4'h5: get_segment_pattern = 8'b10010010;  // 5
                4'h6: get_segment_pattern = 8'b10000010;  // 6
                4'h7: get_segment_pattern = 8'b11111000;  // 7
                4'h8: get_segment_pattern = 8'b10000000;  // 8
                4'h9: get_segment_pattern = 8'b10010000;  // 9
                default: get_segment_pattern = 8'b11111111; // All segments off
            endcase
        end
    endfunction
    
    // Display refresh logic
    always @(posedge clk) begin
        if (reset) begin
            refresh_counter <= 10'd0;
            digit_index <= 2'd0;
            segment_display <= 8'b11111111; // All segments off
            digit_select <= 4'b1111;        // All digits off
            current_digit <= 4'd0;
        end else begin
            // Update refresh counter
            if (refresh_counter < REFRESH_RATE) begin
                refresh_counter <= refresh_counter + 1'b1;
            end else begin
                refresh_counter <= 10'd0;
                
                // Rotate through digits
                digit_index <= digit_index + 1'b1;
                
                // Select current digit
                case (digit_index)
                    2'b00: begin
                        digit_select <= 4'b1110; // Enable digit 0 (rightmost)
                        current_digit <= available_spaces[3:0]; // Display lower 4 bits
                    end
                    2'b01: begin
                        digit_select <= 4'b1101; // Enable digit 1
                        current_digit <= {2'b00, available_spaces[5:4]}; // Display upper 2 bits
                    end
                    2'b10: begin
                        digit_select <= 4'b1011; // Enable digit 2
                        current_digit <= vehicle_count[3:0]; // Display lower 4 bits
                    end
                    2'b11: begin
                        digit_select <= 4'b0111; // Enable digit 3 (leftmost)
                        current_digit <= {2'b00, vehicle_count[5:4]}; // Display upper 2 bits
                    end
                endcase
                
                // Set segment pattern for current digit
                segment_display <= get_segment_pattern(current_digit);
            end
        end
    end
    
    // LED indicators logic
    always @(posedge clk) begin
        if (reset) begin
            led_indicators <= 4'b0000;
        end else begin
            // LED 0: Parking availability status
            led_indicators[0] <= (available_spaces > 0) ? 1'b1 : 1'b0;
            
            // LED 1: Barrier status
            led_indicators[1] <= (barrier_status != 2'b00) ? 1'b1 : 1'b0;
            
            // LED 2: System state indicator (blinks in emergency)
            led_indicators[2] <= (current_state == 3'b111) ? refresh_counter[9] : 1'b0;
            
            // LED 3: Alarm indicator
            led_indicators[3] <= alarm;
        end
    end

endmodule
