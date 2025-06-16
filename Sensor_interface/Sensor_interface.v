module Sensor_interface #(
    parameter DEBOUNCE_DELAY = 5 // Debounce delay in clock cycles (reduced for simulation)
)(
    // Clock and reset
    input wire clk,                // System clock
    input wire reset,              // Synchronous reset, active high
    
    // Raw sensor inputs
    input wire raw_entry_sensor,   // Raw signal from entry sensor
    input wire raw_exit_sensor,    // Raw signal from exit sensor
    
    // Processed sensor outputs
    output reg entry_sensor,       // Debounced entry sensor signal
    output reg exit_sensor,        // Debounced exit sensor signal
    output reg entry_passed,       // Signal indicating vehicle has fully entered
    output reg exit_passed         // Signal indicating vehicle has fully exited
);

    // Internal registers for debouncing
    reg [7:0] entry_counter;       // Counter for entry sensor debouncing (reduced size)
    reg [7:0] exit_counter;        // Counter for exit sensor debouncing (reduced size)
    reg entry_detected;            // Flag for entry detection
    reg exit_detected;             // Flag for exit detection
    reg entry_sensor_prev;         // Previous state of entry sensor
    reg exit_sensor_prev;          // Previous state of exit sensor
    
    // For simulation debugging
    reg entry_passed_debug;        // Debug signal
    reg exit_passed_debug;         // Debug signal
    
    // Initialize signals
    initial begin
        entry_sensor = 1'b0;
        exit_sensor = 1'b0;
        entry_passed = 1'b0;
        exit_passed = 1'b0;
        entry_counter = 8'h0;
        exit_counter = 8'h0;
        entry_detected = 1'b0;
        exit_detected = 1'b0;
        entry_sensor_prev = 1'b0;
        exit_sensor_prev = 1'b0;
        entry_passed_debug = 1'b0;
        exit_passed_debug = 1'b0;
    end
    
    // Debounce logic for entry sensor - simplified for simulation
    always @(posedge clk) begin
        if (reset) begin
            entry_counter <= 8'h0;
            entry_sensor <= 1'b0;
        end
        else begin
            if (raw_entry_sensor != entry_sensor) begin
                // If the input is different from the current stable value
                if (entry_counter >= DEBOUNCE_DELAY) begin
                    // Counter reached threshold, update the stable output
                    entry_sensor <= raw_entry_sensor;
                    entry_counter <= 8'h0;
                end
                else begin
                    // Increment counter
                    entry_counter <= entry_counter + 1;
                end
            end
            else begin
                // Input matches stable output, reset counter
                entry_counter <= 8'h0;
            end
        end
    end
    
    // Debounce logic for exit sensor - simplified for simulation
    always @(posedge clk) begin
        if (reset) begin
            exit_counter <= 8'h0;
            exit_sensor <= 1'b0;
        end
        else begin
            if (raw_exit_sensor != exit_sensor) begin
                // If the input is different from the current stable value
                if (exit_counter >= DEBOUNCE_DELAY) begin
                    // Counter reached threshold, update the stable output
                    exit_sensor <= raw_exit_sensor;
                    exit_counter <= 8'h0;
                end
                else begin
                    // Increment counter
                    exit_counter <= exit_counter + 1;
                end
            end
            else begin
                // Input matches stable output, reset counter
                exit_counter <= 8'h0;
            end
        end
    end
    
    // Vehicle passage detection logic
    always @(posedge clk) begin
        if (reset) begin
            entry_passed <= 1'b0;
            exit_passed <= 1'b0;
            entry_detected <= 1'b0;
            exit_detected <= 1'b0;
            entry_sensor_prev <= 1'b0;
            exit_sensor_prev <= 1'b0;
            entry_passed_debug <= 1'b0;
            exit_passed_debug <= 1'b0;
        end
        else begin
            // Store previous sensor states
            entry_sensor_prev <= entry_sensor;
            exit_sensor_prev <= exit_sensor;
            
            // Default values - reset after one cycle
            entry_passed <= 1'b0;
            exit_passed <= 1'b0;
            
            // Entry detection logic - simplified for simulation
            if (entry_sensor && !entry_sensor_prev) begin
                // Rising edge of entry sensor - vehicle detected
                entry_detected <= 1'b1;
            end
            else if (!entry_sensor && entry_sensor_prev && entry_detected) begin
                // Falling edge of entry sensor after detection - vehicle has passed
                entry_detected <= 1'b0;
                entry_passed <= 1'b1;
                entry_passed_debug <= 1'b1;  // For debugging
            end
            
            // Exit detection logic - simplified for simulation
            if (exit_sensor && !exit_sensor_prev) begin
                // Rising edge of exit sensor - vehicle detected
                exit_detected <= 1'b1;
            end
            else if (!exit_sensor && exit_sensor_prev && exit_detected) begin
                // Falling edge of exit sensor after detection - vehicle has passed
                exit_detected <= 1'b0;
                exit_passed <= 1'b1;
                exit_passed_debug <= 1'b1;  // For debugging
            end
            
            // Additional direct detection for simulation
            if (raw_entry_sensor == 1'b0 && entry_sensor_prev == 1'b1) begin
                entry_passed <= 1'b1;
            end
            
            if (raw_exit_sensor == 1'b0 && exit_sensor_prev == 1'b1) begin
                exit_passed <= 1'b1;
            end
        end
    end
    
endmodule
