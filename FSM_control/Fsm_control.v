module Fsm_control (
    // Clock and reset
    input wire clk,              // System clock
    input wire reset,            // Synchronous reset, active high
    
    // Sensor inputs
    input wire entry_sensor,     // Entry sensor signal
    input wire exit_sensor,      // Exit sensor signal
    input wire entry_passed,     // Signal indicating vehicle has passed entry
    input wire exit_passed,      // Signal indicating vehicle has passed exit
    
    // Status inputs
    input wire parking_full,     // Signal indicating parking is full
    input wire [3:0] card_id,    // Card ID for authentication
    input wire card_valid,       // Card validation result
    input wire emergency,        // Emergency signal
    input wire [1:0] barrier_status, // Current barrier status
    input wire fee_valid,        // Fee calculation valid signal
    
    // Control outputs
    output reg [2:0] current_state, // Current state of the FSM
    output reg open_entry,      // Signal to open entry barrier
    output reg open_exit,       // Signal to open exit barrier
    output reg close_entry,     // Signal to close entry barrier
    output reg close_exit,      // Signal to close exit barrier
    output reg alarm,           // Alarm signal
    output reg calculate_fee,   // Signal to calculate fee
    output reg verify_card      // Signal to verify card
);

    // State definitions
    localparam IDLE = 3'b000;
    localparam VEHICLE_DETECTED = 3'b001;
    localparam CARD_VERIFICATION = 3'b010;
    localparam OPEN_BARRIER = 3'b011;
    localparam VEHICLE_PASSING = 3'b100;
    localparam CLOSE_BARRIER = 3'b101;
    localparam UPDATE_COUNT = 3'b110;
    localparam EMERGENCY_MODE = 3'b111;
    
    // Timeout counters
    reg [9:0] timeout_counter;
    localparam TIMEOUT_MAX = 10'd300;         // Increased from 100 to 300
    localparam VEHICLE_PASSING_TIMEOUT = 10'd600;  // Longer timeout for vehicle passing
    
    // Internal registers for tracking vehicle direction
    reg is_entry_direction;  // 1 for entry, 0 for exit
    reg card_verified;       // Flag to track if card was verified successfully
    
    // Additional registers for handling simultaneous events
    reg entry_in_progress;   // Flag for entry in progress
    reg exit_in_progress;    // Flag for exit in progress
    reg alarm_triggered;     // Flag to track if alarm was triggered
    reg [3:0] prev_card_id;  // Store previous card ID to detect changes
    reg card_check_done;     // Flag to indicate card check is completed
    reg idle_stabilized;     // Flag to ensure IDLE state is stable
    
    // FSM logic
    always @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            open_entry <= 1'b0;
            open_exit <= 1'b0;
            close_entry <= 1'b0;
            close_exit <= 1'b0;
            alarm <= 1'b0;
            calculate_fee <= 1'b0;
            verify_card <= 1'b0;
            timeout_counter <= 10'd0;
            is_entry_direction <= 1'b0;
            card_verified <= 1'b0;
            entry_in_progress <= 1'b0;
            exit_in_progress <= 1'b0;
            alarm_triggered <= 1'b0;
            prev_card_id <= 4'b0000;
            card_check_done <= 1'b0;
            idle_stabilized <= 1'b0;
        end else begin
            // Default values
            open_entry <= 1'b0;
            open_exit <= 1'b0;
            close_entry <= 1'b0;
            close_exit <= 1'b0;
            alarm <= alarm_triggered; // Maintain alarm state
            calculate_fee <= 1'b0;
            verify_card <= 1'b0;
            
            // Store previous card ID
            prev_card_id <= card_id;
            
            // Emergency handling has highest priority
            if (emergency) begin
                current_state <= EMERGENCY_MODE;
                open_entry <= 1'b1;
                open_exit <= 1'b1;
                entry_in_progress <= 1'b0;
                exit_in_progress <= 1'b0;
                alarm_triggered <= 1'b0; // Reset alarm during emergency
                card_check_done <= 1'b0;
                idle_stabilized <= 1'b0;
                timeout_counter <= 10'd0;
            end else begin
                case (current_state)
                    IDLE: begin
                        // Reset flags
                        alarm_triggered <= 1'b0;
                        card_check_done <= 1'b0;
                        
                        // Ensure IDLE state is stable for at least 5 clock cycles
                        if (timeout_counter < 5) begin
                            timeout_counter <= timeout_counter + 10'd1;
                            idle_stabilized <= (timeout_counter == 4);
                        end else begin
                            // Handle entry and exit separately to allow simultaneous operations
                            if (entry_sensor && !entry_in_progress && idle_stabilized) begin
                                if (parking_full) begin
                                    // Parking is full, trigger alarm
                                    alarm <= 1'b1;
                                    alarm_triggered <= 1'b1;
                                end else begin
                                    // Start entry process
                                    is_entry_direction <= 1'b1;
                                    entry_in_progress <= 1'b1;
                                    verify_card <= 1'b1;
                                    current_state <= CARD_VERIFICATION;
                                    timeout_counter <= 10'd0;
                                    idle_stabilized <= 1'b0;
                                end
                            end
                            
                            if (exit_sensor && !exit_in_progress && idle_stabilized) begin
                                // Start exit process
                                is_entry_direction <= 1'b0;
                                exit_in_progress <= 1'b1;
                                calculate_fee <= 1'b1;
                                
                                // If entry is not in progress, change state
                                if (!entry_in_progress) begin
                                    current_state <= VEHICLE_DETECTED;
                                    timeout_counter <= 10'd0;
                                    idle_stabilized <= 1'b0;
                                end
                            end
                        end
                        
                        // Always close barriers when in IDLE state
                        close_entry <= 1'b1;
                        close_exit <= 1'b1;
                    end
                    
                    VEHICLE_DETECTED: begin
                        if (is_entry_direction && entry_in_progress) begin
                            // Entry flow
                            if (parking_full) begin
                                // Parking is full, trigger alarm
                                alarm <= 1'b1;
                                alarm_triggered <= 1'b1;
                                entry_in_progress <= 1'b0;
                                current_state <= IDLE;
                                timeout_counter <= 10'd0;
                            end else begin
                                verify_card <= 1'b1;
                                current_state <= CARD_VERIFICATION;
                                timeout_counter <= 10'd0;
                            end
                        end else if (!is_entry_direction && exit_in_progress) begin
                            // Exit flow
                            if (fee_valid) begin
                                current_state <= OPEN_BARRIER;
                                timeout_counter <= 10'd0;
                            end
                        end else begin
                            // No vehicle detected anymore, return to idle
                            current_state <= IDLE;
                            entry_in_progress <= 1'b0;
                            exit_in_progress <= 1'b0;
                            timeout_counter <= 10'd0;
                        end
                        
                        // Timeout handling
                        if (timeout_counter >= TIMEOUT_MAX) begin
                            current_state <= IDLE;
                            entry_in_progress <= 1'b0;
                            exit_in_progress <= 1'b0;
                            timeout_counter <= 10'd0;
                        end else begin
                            timeout_counter <= timeout_counter + 10'd1;
                        end
                    end
                    
                    CARD_VERIFICATION: begin
                        // Only verify card when card_id changes or on first entry
                        if ((card_id != prev_card_id || timeout_counter == 0) && !card_check_done) begin
                            card_check_done <= 1'b1; // Mark card as checked
                            
                            // Check if card is valid
                            if (card_valid) begin
                                card_verified <= 1'b1;  // Mark card as verified
                                alarm_triggered <= 1'b0; // Clear any previous alarm
                                current_state <= OPEN_BARRIER;
                                timeout_counter <= 10'd0;
                            end else begin
                                // Invalid card, trigger alarm
                                alarm <= 1'b1;
                                alarm_triggered <= 1'b1;
                                card_verified <= 1'b0;  // Card not verified
                                
                                // Don't cancel entry process immediately
                                // Let the alarm stay on for a while, then return to IDLE
                                if (timeout_counter >= 20) begin
                                    entry_in_progress <= 1'b0; // Cancel entry process
                                    current_state <= IDLE;
                                    timeout_counter <= 10'd0;
                                end
                            end
                        end
                        
                        // Timeout handling - force return to IDLE if card is invalid
                        if (timeout_counter >= 50 && !card_valid) begin
                            current_state <= IDLE;
                            entry_in_progress <= 1'b0;
                            exit_in_progress <= 1'b0;
                            timeout_counter <= 10'd0;
                        end else if (timeout_counter >= TIMEOUT_MAX) begin
                            current_state <= IDLE;
                            entry_in_progress <= 1'b0;
                            exit_in_progress <= 1'b0;
                            timeout_counter <= 10'd0;
                        end else begin
                            timeout_counter <= timeout_counter + 10'd1;
                        end
                    end
                    
                    OPEN_BARRIER: begin
                        if (is_entry_direction && entry_in_progress && card_verified) begin
                            open_entry <= 1'b1;
                            current_state <= VEHICLE_PASSING;
                            timeout_counter <= 10'd0;
                        end else if (!is_entry_direction && exit_in_progress) begin
                            open_exit <= 1'b1;
                            current_state <= VEHICLE_PASSING;
                            timeout_counter <= 10'd0;
                        end else begin
                            // If entry direction but card not verified, go back to IDLE
                            entry_in_progress <= 1'b0;
                            current_state <= IDLE;
                            timeout_counter <= 10'd0;
                        end
                    end
                    
                    VEHICLE_PASSING: begin
                        if (is_entry_direction && entry_in_progress) begin
                            open_entry <= 1'b1;
                            if (entry_passed) begin
                                current_state <= CLOSE_BARRIER;
                                timeout_counter <= 10'd0;
                            end
                        end else if (!is_entry_direction && exit_in_progress) begin
                            open_exit <= 1'b1;
                            if (exit_passed) begin
                                current_state <= CLOSE_BARRIER;
                                timeout_counter <= 10'd0;
                            end
                        end else begin
                            current_state <= CLOSE_BARRIER;
                            timeout_counter <= 10'd0;
                        end
                        
                        // Timeout handling - longer timeout for vehicle passing
                        if (timeout_counter >= VEHICLE_PASSING_TIMEOUT) begin
                            current_state <= CLOSE_BARRIER;
                            timeout_counter <= 10'd0;
                        end else begin
                            timeout_counter <= timeout_counter + 10'd1;
                        end
                    end
                    
                    CLOSE_BARRIER: begin
                        if (is_entry_direction && entry_in_progress && entry_passed) begin
                            close_entry <= 1'b1;
                            current_state <= UPDATE_COUNT;
                            timeout_counter <= 10'd0;
                        end else if (!is_entry_direction && exit_in_progress && exit_passed) begin
                            close_exit <= 1'b1;
                            current_state <= UPDATE_COUNT;
                            timeout_counter <= 10'd0;
                        end else begin
                            close_entry <= 1'b1;
                            close_exit <= 1'b1;
                            current_state <= IDLE;
                            entry_in_progress <= 1'b0;
                            exit_in_progress <= 1'b0;
                            timeout_counter <= 10'd0;
                        end
                    end
                    
                    UPDATE_COUNT: begin
                        // Count update is handled by the Vehicle Counter module
                        card_verified <= 1'b0;  // Reset card verification status
                        card_check_done <= 1'b0; // Reset card check status
                        if (is_entry_direction) entry_in_progress <= 1'b0;
                        if (!is_entry_direction) exit_in_progress <= 1'b0;
                        
                        // If other operation is in progress, continue with it
                        if (entry_in_progress || exit_in_progress) begin
                            current_state <= VEHICLE_DETECTED;
                            timeout_counter <= 10'd0;
                        end else begin
                            current_state <= IDLE;
                            timeout_counter <= 10'd0;
                        end
                    end
                    
                    EMERGENCY_MODE: begin
                        open_entry <= 1'b1;
                        open_exit <= 1'b1;
                        alarm_triggered <= 1'b0; // Clear alarm in emergency mode
                        if (!emergency) begin
                            current_state <= IDLE;
                            entry_in_progress <= 1'b0;
                            exit_in_progress <= 1'b0;
                            timeout_counter <= 10'd0;
                        end
                    end
                    
                    default: current_state <= IDLE;
                endcase
            end
        end
    end

endmodule
