module Display_module (
    input wire clk,
    input wire reset,
    input wire [7:0] available_spaces,    // Number of available parking spaces
    input wire [7:0] total_vehicles,      // Total number of vehicles in the parking
    input wire parking_full,              // Indicator for parking full status
    input wire [31:0] fee,                // Calculated fee for display
    input wire calculation_done,          // Signal indicating fee calculation is complete
    input wire [2:0] system_state,        // Current state of the parking system FSM
    output reg [7:0] display_data,        // Data to be displayed (multiplexed)
    output reg [3:0] display_select,      // Select which display to update
    output reg [7:0] status_leds          // Status LEDs for visual indication
);

    // State definitions from FSM_control for reference
    parameter IDLE           = 3'b000;
    parameter VEHICLE_ENTRY  = 3'b001;
    parameter VEHICLE_PARKED = 3'b010;
    parameter PAYMENT        = 3'b011;
    parameter VEHICLE_EXIT   = 3'b100;
    parameter EMERGENCY      = 3'b111;
    
    // Display select values
    parameter DISP_AVAILABLE = 4'b0001;
    parameter DISP_TOTAL     = 4'b0010;
    parameter DISP_FEE_LOW   = 4'b0100;
    parameter DISP_FEE_HIGH  = 4'b1000;
    
    // Internal registers
    reg [1:0] display_state;         // For cycling through displays
    reg [31:0] fee_to_display;       // Store fee when calculation is done
    reg [7:0] refresh_counter;       // Counter for display refresh (reduced from 20 to 8 bits)
    
    // Display refresh logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            refresh_counter <= 0;
            display_state <= 0;
            fee_to_display <= 0;
            display_data <= 0;
            display_select <= DISP_AVAILABLE;
            status_leds <= 0;
        end else begin
            // Update fee to display when calculation is done
            if (calculation_done) begin
                fee_to_display <= fee;
            end
            
            // Refresh counter for display multiplexing
            refresh_counter <= refresh_counter + 1;
            
            // Change display selection every 20 clock cycles (much faster for simulation)
            if (refresh_counter == 8'h14) begin
                refresh_counter <= 0;
                display_state <= display_state + 1;
                
                case (display_state)
                    2'b00: begin
                        display_select <= DISP_AVAILABLE;
                        display_data <= available_spaces;
                    end
                    2'b01: begin
                        display_select <= DISP_TOTAL;
                        display_data <= total_vehicles;
                    end
                    2'b10: begin
                        display_select <= DISP_FEE_LOW;
                        display_data <= fee_to_display[7:0];  // Lower 8 bits of fee
                    end
                    2'b11: begin
                        display_select <= DISP_FEE_HIGH;
                        display_data <= fee_to_display[15:8]; // Upper 8 bits of fee (up to 65535)
                    end
                endcase
            end
            
            // Update status LEDs based on system state and parking status
            status_leds[0] <= parking_full;                  // Parking full indicator
            status_leds[1] <= (system_state == VEHICLE_ENTRY); // Entry in progress
            status_leds[2] <= (system_state == VEHICLE_EXIT);  // Exit in progress
            status_leds[3] <= (system_state == PAYMENT);       // Payment in progress
            status_leds[4] <= (available_spaces < 5);        // Low space warning
            status_leds[5] <= (system_state == EMERGENCY);     // Emergency indicator
            status_leds[7:6] <= 2'b00;                       // Reserved for future use
        end
    end
    
endmodule
