module Vehicle_counter #(
    parameter MAX_CAPACITY = 63  // Maximum parking capacity (6-bit value: 0-63)
)(
    // Clock and reset
    input wire clk,              // System clock
    input wire reset,            // Synchronous reset, active high
    
    // Inputs from Sensor Interface Module
    input wire entry_passed,     // Signal indicating vehicle has entered
    input wire exit_passed,      // Signal indicating vehicle has exited
    
    // Input for configuration
    input wire [5:0] max_capacity, // Configurable maximum capacity
    
    // Outputs
    output reg [5:0] vehicle_count,    // Current number of vehicles in the parking
    output reg [5:0] available_spaces, // Number of available parking spaces
    output reg parking_full            // Signal indicating parking is full
);

    // Initialize signals
    initial begin
        vehicle_count = 6'b000000;
        available_spaces = max_capacity;
        parking_full = 1'b0;
    end
    
    // Main counter logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset counter values
            vehicle_count <= 6'b000000;
            available_spaces <= max_capacity;
            parking_full <= 1'b0;
        end
        else begin
            // Handle vehicle entry
            if (entry_passed && !parking_full) begin
                if (vehicle_count < max_capacity) begin
                    vehicle_count <= vehicle_count + 1'b1;
                    available_spaces <= available_spaces - 1'b1;
                    
                    // Check if parking becomes full after this entry
                    if (vehicle_count + 1'b1 >= max_capacity) begin
                        parking_full <= 1'b1;
                    end
                end
            end
            
            // Handle vehicle exit
            if (exit_passed && vehicle_count > 0) begin
                vehicle_count <= vehicle_count - 1'b1;
                available_spaces <= available_spaces + 1'b1;
                parking_full <= 1'b0; // No longer full after a vehicle exits
            end
        end
    end
    
    // Handle max_capacity changes
    always @(max_capacity) begin
        // Update available spaces based on new max_capacity
        if (vehicle_count <= max_capacity) begin
            available_spaces <= max_capacity - vehicle_count;
        end else begin
            // If current count exceeds new max_capacity
            available_spaces <= 0;
        end
        
        // Update parking_full flag based on new max_capacity
        parking_full <= (vehicle_count >= max_capacity) ? 1'b1 : 1'b0;
    end

endmodule
