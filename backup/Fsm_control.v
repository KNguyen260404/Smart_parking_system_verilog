module Fsm_control (
    input wire clk,
    input wire reset,
    input wire entry_sensor,        // Signal from entry sensor (1 when vehicle detected)
    input wire exit_sensor,         // Signal from exit sensor (1 when vehicle detected)
    input wire [7:0] available_spaces, // Number of available parking spaces
    input wire payment_complete,    // Signal indicating payment is complete
    input wire emergency,           // Emergency signal
    output reg open_entry,          // Signal to open entry barrier
    output reg close_entry,         // Signal to close entry barrier
    output reg open_exit,           // Signal to open exit barrier
    output reg close_exit,          // Signal to close exit barrier
    output reg calculate_fee,       // Signal to trigger fee calculation
    output reg [2:0] system_state   // Current state of the system
);

    // State definitions
    parameter IDLE           = 3'b000;
    parameter VEHICLE_ENTRY  = 3'b001;
    parameter VEHICLE_PARKED = 3'b010;
    parameter PAYMENT        = 3'b011;
    parameter VEHICLE_EXIT   = 3'b100;
    parameter EMERGENCY      = 3'b111;
    
    // Internal registers
    reg [2:0] current_state;
    reg [2:0] next_state;
    
    // Timeout counters
    parameter ENTRY_TIMEOUT = 100;  // Cycles to wait for vehicle to enter
    parameter EXIT_TIMEOUT = 100;   // Cycles to wait for vehicle to exit
    reg [7:0] timeout_counter;
    
    // State register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            timeout_counter <= 0;
        end else begin
            // Handle timeout counter
            if ((current_state == VEHICLE_ENTRY && timeout_counter < ENTRY_TIMEOUT) ||
                (current_state == VEHICLE_EXIT && timeout_counter < EXIT_TIMEOUT)) begin
                timeout_counter <= timeout_counter + 1;
            end else if (current_state != VEHICLE_ENTRY && current_state != VEHICLE_EXIT) begin
                timeout_counter <= 0;
            end
            
            // State transition
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        // Default: stay in current state
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (emergency)
                    next_state = EMERGENCY;
                else if (entry_sensor && available_spaces > 0)
                    next_state = VEHICLE_ENTRY;
                else if (exit_sensor)
                    next_state = PAYMENT;
            end
            
            VEHICLE_ENTRY: begin
                if (emergency)
                    next_state = EMERGENCY;
                else if (!entry_sensor) // Vehicle has passed the entry sensor
                    next_state = VEHICLE_PARKED;
                else if (timeout_counter >= ENTRY_TIMEOUT) // Timeout
                    next_state = IDLE;
            end
            
            VEHICLE_PARKED: begin
                if (emergency)
                    next_state = EMERGENCY;
                else
                    next_state = IDLE; // Return to idle after vehicle is parked
            end
            
            PAYMENT: begin
                if (emergency)
                    next_state = EMERGENCY;
                else if (payment_complete)
                    next_state = VEHICLE_EXIT;
            end
            
            VEHICLE_EXIT: begin
                if (emergency)
                    next_state = EMERGENCY;
                else if (!exit_sensor) // Vehicle has passed the exit sensor
                    next_state = IDLE;
                else if (timeout_counter >= EXIT_TIMEOUT) // Timeout
                    next_state = IDLE;
            end
            
            EMERGENCY: begin
                if (!emergency) // Emergency condition cleared
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            open_entry <= 0;
            close_entry <= 0;
            open_exit <= 0;
            close_exit <= 0;
            calculate_fee <= 0;
            system_state <= IDLE;
        end else begin
            // Default values
            open_entry <= 0;
            close_entry <= 0;
            open_exit <= 0;
            close_exit <= 0;
            calculate_fee <= 0;
            system_state <= current_state;
            
            case (current_state)
                IDLE: begin
                    // No specific outputs in IDLE state
                    close_entry <= 1; // Ensure barriers are closed
                    close_exit <= 1;
                end
                
                VEHICLE_ENTRY: begin
                    open_entry <= 1; // Open entry barrier
                end
                
                VEHICLE_PARKED: begin
                    close_entry <= 1; // Close entry barrier after vehicle is parked
                end
                
                PAYMENT: begin
                    calculate_fee <= 1; // Trigger fee calculation
                end
                
                VEHICLE_EXIT: begin
                    open_exit <= 1; // Open exit barrier
                end
                
                EMERGENCY: begin
                    open_entry <= 1; // Open both barriers in emergency
                    open_exit <= 1;
                end
                
                default: begin
                    // Default outputs
                    close_entry <= 1;
                    close_exit <= 1;
                end
            endcase
        end
    end
    
endmodule
