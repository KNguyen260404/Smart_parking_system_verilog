module Fee_calculator (
    input wire clk,
    input wire reset,
    input wire [31:0] entry_time,    // Time when vehicle entered (in seconds)
    input wire [31:0] exit_time,     // Time when vehicle exited (in seconds)
    input wire calculate,            // Trigger to calculate fee
    input wire [1:0] vehicle_type,   // 0: standard, 1: premium, 2: reserved, 3: special
    output reg [31:0] fee,           // Calculated fee
    output reg calculation_done      // Indicates calculation is complete
);

    // Parameters for fee calculation
    parameter BASE_FEE = 10;         // Base fee in currency units
    parameter HOURLY_RATE = 5;       // Standard hourly rate
    parameter PREMIUM_MULTIPLIER = 2; // Multiplier for premium spots
    parameter RESERVED_FLAT_FEE = 50; // Flat fee for reserved spots
    parameter SECONDS_PER_HOUR = 3600;
    
    // Internal variables
    reg [31:0] duration;             // Parking duration in seconds
    reg [31:0] hours;                // Parking duration in hours (rounded up)
    
    // Fee calculation logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fee <= 0;
            calculation_done <= 0;
            duration <= 0;
            hours <= 0;
        end else if (calculate) begin
            // Calculate duration in seconds
            if (exit_time >= entry_time) begin
                duration <= exit_time - entry_time;
            end else begin
                // Handle case where exit_time wraps around (e.g., overnight)
                duration <= (32'hFFFFFFFF - entry_time) + exit_time + 1;
            end
            
            // Calculate fee based on vehicle type
            case (vehicle_type)
                2'b00: begin // Standard parking
                    // Calculate hours (rounded up)
                    if (exit_time >= entry_time) begin
                        hours <= (exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                        fee <= BASE_FEE + ((exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR * HOURLY_RATE);
                    end else begin
                        // Handle overnight parking
                        hours <= ((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                        fee <= BASE_FEE + (((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR * HOURLY_RATE);
                    end
                end
                2'b01: begin // Premium parking
                    if (exit_time >= entry_time) begin
                        hours <= (exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                        fee <= BASE_FEE + ((exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR * HOURLY_RATE * PREMIUM_MULTIPLIER);
                    end else begin
                        // Handle overnight parking
                        hours <= ((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                        fee <= BASE_FEE + (((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR * HOURLY_RATE * PREMIUM_MULTIPLIER);
                    end
                end
                2'b10: begin // Reserved parking
                    if (exit_time >= entry_time) begin
                        hours <= (exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                    end else begin
                        hours <= ((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                    end
                    fee <= RESERVED_FLAT_FEE;
                end
                2'b11: begin // Special (e.g., handicapped, electric vehicles)
                    if (exit_time >= entry_time) begin
                        hours <= (exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                        fee <= BASE_FEE + ((exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR * HOURLY_RATE / 2); // 50% discount
                    end else begin
                        // Handle overnight parking
                        hours <= ((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                        fee <= BASE_FEE + (((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR * HOURLY_RATE / 2); // 50% discount
                    end
                end
                default: begin
                    if (exit_time >= entry_time) begin
                        hours <= (exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                        fee <= BASE_FEE + ((exit_time - entry_time + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR * HOURLY_RATE);
                    end else begin
                        // Handle overnight parking
                        hours <= ((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR;
                        fee <= BASE_FEE + (((32'hFFFFFFFF - entry_time) + exit_time + 1 + SECONDS_PER_HOUR - 1) / SECONDS_PER_HOUR * HOURLY_RATE);
                    end
                end
            endcase
            
            calculation_done <= 1;
        end else begin
            calculation_done <= 0;
        end
    end
    
endmodule
