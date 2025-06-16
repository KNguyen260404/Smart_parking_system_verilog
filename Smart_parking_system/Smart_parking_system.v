`include "../Sensor_interface/Sensor_interface.v"
`include "../Vehicle_counter/Vehicle_counter.v"
`include "../Barrier_control/Barrier_control.v"
`include "../FSM_control/Fsm_control.v"
`include "../Fee_calculator/Fee_calculator.v"
`include "../Display_module/Display_module.v"

module Smart_parking_system #(
    parameter MAX_CAPACITY = 63,  // Maximum parking capacity (6-bit value: 0-63)
    parameter DEBOUNCE_DELAY = 5, // Debounce delay for sensor inputs
    parameter BARRIER_DELAY = 10  // Delay for barrier operation
)(
    // Clock and reset
    input wire clk,              // System clock
    input wire reset,            // Synchronous reset, active high
    
    // Sensor inputs
    input wire raw_entry_sensor, // Raw signal from entry sensor
    input wire raw_exit_sensor,  // Raw signal from exit sensor
    
    // Authentication inputs
    input wire [3:0] card_id,    // Card/ID for authentication
    
    // Emergency input
    input wire emergency,        // Emergency signal
    
    // Barrier control outputs
    output wire entry_barrier,   // Entry barrier control: 0: closed, 1: open
    output wire exit_barrier,    // Exit barrier control: 0: closed, 1: open
    
    // Display outputs
    output wire [5:0] available_spaces, // Number of available parking spaces
    output wire [7:0] segment_display,  // 7-segment display control signal
    output wire [3:0] digit_select,     // Digit selection for display
    output wire parking_full,           // Indicator when parking is full
    output wire alarm,                  // Alarm signal
    output wire [3:0] led_indicators,   // System status LED indicators
    
    // Fee calculation output
    output wire [7:0] fee_amount        // Parking fee amount
);

    // Internal signals for module interconnections
    
    // Sensor interface signals
    wire entry_sensor;
    wire exit_sensor;
    wire entry_passed_internal;
    wire exit_passed;
    
    // FSM control signals
    wire [2:0] current_state;
    wire open_entry;
    wire open_exit;
    wire close_entry;
    wire close_exit;
    wire calculate_fee;
    wire verify_card;
    
    // Barrier control signals
    wire [1:0] barrier_status;
    
    // Vehicle counter signals
    wire [5:0] vehicle_count;
    
    // Fee calculator signals
    wire fee_valid;
    
    // Authentication signals
    wire card_valid;
    assign card_valid = (card_id != 4'b0000); // Simple validation for simulation
    
    // Time tracking for fee calculation
    reg [31:0] entry_time_storage0;  // Storage for entry times
    reg [31:0] entry_time_storage1;
    reg [31:0] entry_time_storage2;
    reg [31:0] entry_time_storage3;
    reg [31:0] entry_time_storage4;
    reg [31:0] entry_time_storage5;
    reg [31:0] entry_time_storage6;
    reg [31:0] entry_time_storage7;
    reg [31:0] entry_time_storage8;
    reg [31:0] entry_time_storage9;
    reg [31:0] entry_time_storage10;
    reg [31:0] entry_time_storage11;
    reg [31:0] entry_time_storage12;
    reg [31:0] entry_time_storage13;
    reg [31:0] entry_time_storage14;
    reg [31:0] entry_time_storage15;
    
    reg [31:0] current_time;             // System time counter
    reg [31:0] entry_time;               // Current entry time
    reg [31:0] exit_time;                // Current exit time
    reg [7:0] vehicle_id;                // Current vehicle ID
    reg [3:0] last_entry_id;             // Last entered vehicle ID (4-bit for 16 vehicles)
    reg [3:0] last_exit_id;              // Last exited vehicle ID
    
    // Time tracking and fee calculation logic
    always @(posedge clk) begin
        if (reset) begin
            current_time <= 32'd0;
            entry_time <= 32'd0;
            exit_time <= 32'd0;
            vehicle_id <= 8'd0;
            last_entry_id <= 4'd0;
            last_exit_id <= 4'd0;
            
            // Initialize entry time storage
            entry_time_storage0 <= 32'd0;
            entry_time_storage1 <= 32'd0;
            entry_time_storage2 <= 32'd0;
            entry_time_storage3 <= 32'd0;
            entry_time_storage4 <= 32'd0;
            entry_time_storage5 <= 32'd0;
            entry_time_storage6 <= 32'd0;
            entry_time_storage7 <= 32'd0;
            entry_time_storage8 <= 32'd0;
            entry_time_storage9 <= 32'd0;
            entry_time_storage10 <= 32'd0;
            entry_time_storage11 <= 32'd0;
            entry_time_storage12 <= 32'd0;
            entry_time_storage13 <= 32'd0;
            entry_time_storage14 <= 32'd0;
            entry_time_storage15 <= 32'd0;
        end
        else begin
            // Increment system time
            current_time <= current_time + 32'd1;
            
            // Record entry time when vehicle enters
            if (entry_passed_internal) begin
                last_entry_id <= last_entry_id + 4'd1;
                
                // Store entry time based on ID
                case(last_entry_id)
                    4'd0: entry_time_storage0 <= current_time;
                    4'd1: entry_time_storage1 <= current_time;
                    4'd2: entry_time_storage2 <= current_time;
                    4'd3: entry_time_storage3 <= current_time;
                    4'd4: entry_time_storage4 <= current_time;
                    4'd5: entry_time_storage5 <= current_time;
                    4'd6: entry_time_storage6 <= current_time;
                    4'd7: entry_time_storage7 <= current_time;
                    4'd8: entry_time_storage8 <= current_time;
                    4'd9: entry_time_storage9 <= current_time;
                    4'd10: entry_time_storage10 <= current_time;
                    4'd11: entry_time_storage11 <= current_time;
                    4'd12: entry_time_storage12 <= current_time;
                    4'd13: entry_time_storage13 <= current_time;
                    4'd14: entry_time_storage14 <= current_time;
                    4'd15: entry_time_storage15 <= current_time;
                endcase
                
                vehicle_id <= {4'd0, last_entry_id}; // Use ID for tracking
            end
            
            // Set entry and exit times for fee calculation when vehicle exits
            if (exit_passed) begin
                last_exit_id <= last_exit_id + 4'd1;
                
                // Get stored entry time based on ID
                case(last_exit_id)
                    4'd0: entry_time <= entry_time_storage0;
                    4'd1: entry_time <= entry_time_storage1;
                    4'd2: entry_time <= entry_time_storage2;
                    4'd3: entry_time <= entry_time_storage3;
                    4'd4: entry_time <= entry_time_storage4;
                    4'd5: entry_time <= entry_time_storage5;
                    4'd6: entry_time <= entry_time_storage6;
                    4'd7: entry_time <= entry_time_storage7;
                    4'd8: entry_time <= entry_time_storage8;
                    4'd9: entry_time <= entry_time_storage9;
                    4'd10: entry_time <= entry_time_storage10;
                    4'd11: entry_time <= entry_time_storage11;
                    4'd12: entry_time <= entry_time_storage12;
                    4'd13: entry_time <= entry_time_storage13;
                    4'd14: entry_time <= entry_time_storage14;
                    4'd15: entry_time <= entry_time_storage15;
                endcase
                
                exit_time <= current_time;
                vehicle_id <= {4'd0, last_exit_id}; // Use ID for tracking
            end
        end
    end

    // Only allow entry_passed when card is valid
    wire entry_passed;
    assign entry_passed = entry_passed_internal & card_valid;

    // Instantiate Sensor Interface Module with configurable debounce delay
    Sensor_interface #(
        .DEBOUNCE_DELAY(DEBOUNCE_DELAY)
    ) sensor_interface_inst (
        .clk(clk),
        .reset(reset),
        .raw_entry_sensor(raw_entry_sensor),
        .raw_exit_sensor(raw_exit_sensor),
        .entry_sensor(entry_sensor),
        .exit_sensor(exit_sensor),
        .entry_passed(entry_passed_internal),
        .exit_passed(exit_passed)
    );
    
    // Instantiate Vehicle Counter Module
    Vehicle_counter #(
        .MAX_CAPACITY(MAX_CAPACITY)
    ) vehicle_counter_inst (
        .clk(clk),
        .reset(reset),
        .entry_passed(entry_passed),
        .exit_passed(exit_passed),
        .max_capacity(MAX_CAPACITY[5:0]),
        .vehicle_count(vehicle_count),
        .available_spaces(available_spaces),
        .parking_full(parking_full)
    );
    
    // Instantiate Barrier Control Module with configurable delay
    Barrier_control #(
        .BARRIER_DELAY(BARRIER_DELAY)
    ) barrier_control_inst (
        .clk(clk),
        .reset(reset),
        .open_entry(open_entry),
        .open_exit(open_exit),
        .close_entry(close_entry),
        .close_exit(close_exit),
        .emergency(emergency),
        .vehicle_direction(exit_sensor), // 0: entry, 1: exit
        .entry_barrier(entry_barrier),
        .exit_barrier(exit_barrier),
        .barrier_status(barrier_status)
    );
    
    // Instantiate FSM Control Module
    Fsm_control fsm_control_inst (
        .clk(clk),
        .reset(reset),
        .entry_sensor(entry_sensor),
        .exit_sensor(exit_sensor),
        .entry_passed(entry_passed),
        .exit_passed(exit_passed),
        .parking_full(parking_full),
        .card_id(card_id),
        .card_valid(card_valid),
        .emergency(emergency),
        .barrier_status(barrier_status),
        .fee_valid(fee_valid),
        .current_state(current_state),
        .open_entry(open_entry),
        .open_exit(open_exit),
        .close_entry(close_entry),
        .close_exit(close_exit),
        .alarm(alarm),
        .calculate_fee(calculate_fee),
        .verify_card(verify_card)
    );
    
    // Instantiate Fee Calculator Module
    Fee_calculator fee_calculator_inst (
        .clk(clk),
        .reset(reset),
        .entry_time(entry_time),
        .exit_time(exit_time),
        .vehicle_id(vehicle_id),
        .calculate_fee(calculate_fee),
        .fee_amount(fee_amount),
        .fee_valid(fee_valid)
    );
    
    // Instantiate Display Module
    Display_module display_module_inst (
        .clk(clk),
        .reset(reset),
        .vehicle_count(vehicle_count),
        .available_spaces(available_spaces),
        .current_state(current_state),
        .barrier_status(barrier_status),
        .alarm(alarm),
        .fee_amount(fee_amount),
        .segment_display(segment_display),
        .digit_select(digit_select),
        .led_indicators(led_indicators)
    );

endmodule
