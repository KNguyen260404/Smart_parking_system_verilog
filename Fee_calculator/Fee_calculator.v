module Fee_calculator (
    // Clock and reset
    input wire clk,              // System clock
    input wire reset,            // Synchronous reset, active high
    
    // Time inputs
    input wire [31:0] entry_time, // Entry time of vehicle
    input wire [31:0] exit_time,  // Exit time of vehicle
    
    // Vehicle identification
    input wire [7:0] vehicle_id,  // Vehicle ID for tracking
    
    // Control inputs
    input wire calculate_fee,     // Signal to start fee calculation
    
    // Outputs
    output reg [7:0] fee_amount,  // Calculated fee amount
    output reg fee_valid          // Signal indicating fee calculation is valid
);

    // Fee calculation parameters
    parameter BASE_FEE = 8'd10;         // Base fee for parking
    parameter HOURLY_RATE = 8'd5;       // Additional fee per hour
    parameter MINIMUM_TIME = 32'd60;    // Minimum time unit (e.g., 60 minutes)
    
    // Internal registers
    reg [31:0] parking_duration;        // Duration of parking in time units
    reg [7:0] hours_parked;             // Number of hours parked
    reg calculation_in_progress;        // Flag to track calculation state
    reg [1:0] calculation_state;        // State machine for calculation
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam CALC_DURATION = 2'b01;
    localparam CALC_FEE = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // Fee calculation logic
    always @(posedge clk) begin
        if (reset) begin
            fee_amount <= 8'd0;
            fee_valid <= 1'b0;
            parking_duration <= 32'd0;
            hours_parked <= 8'd0;
            calculation_in_progress <= 1'b0;
            calculation_state <= IDLE;
        end else begin
            // Default values
            fee_valid <= 1'b0;
            
            case (calculation_state)
                IDLE: begin
                    if (calculate_fee) begin
                        calculation_state <= CALC_DURATION;
                        calculation_in_progress <= 1'b1;
                    end
                end
                
                CALC_DURATION: begin
                    // Calculate parking duration
                    if (exit_time >= entry_time) begin
                        parking_duration <= exit_time - entry_time;
                        
                        // Calculate hours parked
                        if ((exit_time - entry_time) == 0) begin
                            // Minimum 1 hour for zero duration
                            hours_parked <= 8'd1;
                        end else if ((exit_time - entry_time) % MINIMUM_TIME > 0) begin
                            // Add 1 for partial hour
                            hours_parked <= ((exit_time - entry_time) / MINIMUM_TIME) + 8'd1;
                        end else begin
                            // Exact hours
                            hours_parked <= (exit_time - entry_time) / MINIMUM_TIME;
                        end
                    end else begin
                        // Handle time overflow case
                        parking_duration <= 32'd0;
                        hours_parked <= 8'd0;
                    end
                    
                    calculation_state <= CALC_FEE;
                end
                
                CALC_FEE: begin
                    // Calculate fee: base fee + hourly rate * hours
                    fee_amount <= BASE_FEE + (HOURLY_RATE * hours_parked);
                    calculation_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    // Set fee valid flag
                    fee_valid <= 1'b1;
                    calculation_in_progress <= 1'b0;
                    calculation_state <= IDLE;
                end
                
                default: calculation_state <= IDLE;
            endcase
        end
    end

endmodule
