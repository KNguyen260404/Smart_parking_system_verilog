module Barrier_control #(
    parameter BARRIER_DELAY = 50  // Delay for barrier movement in clock cycles
)(
    // Clock and reset
    input wire clk,                // System clock
    input wire reset,              // Synchronous reset, active high
    
    // Control signals from FSM Controller
    input wire open_entry,         // Command to open entry barrier
    input wire open_exit,          // Command to open exit barrier
    input wire close_entry,        // Command to close entry barrier
    input wire close_exit,         // Command to close exit barrier
    input wire emergency,          // Emergency signal
    
    // Vehicle direction
    input wire vehicle_direction,  // 0: entry, 1: exit
    
    // Barrier outputs
    output reg entry_barrier,      // Entry barrier control: 0: closed, 1: open
    output reg exit_barrier,       // Exit barrier control: 0: closed, 1: open
    output reg [1:0] barrier_status // Barrier status: 00: both closed, 01: entry open, 10: exit open, 11: both open
);

    // Internal registers
    reg [31:0] entry_timer;        // Timer for entry barrier movement
    reg [31:0] exit_timer;         // Timer for exit barrier movement
    reg entry_in_motion;           // Flag indicating entry barrier is moving
    reg exit_in_motion;            // Flag indicating exit barrier is moving
    
    // Initialize signals
    initial begin
        entry_barrier = 1'b0;      // Initially closed
        exit_barrier = 1'b0;       // Initially closed
        barrier_status = 2'b00;    // Both barriers closed
        entry_timer = 32'h0;
        exit_timer = 32'h0;
        entry_in_motion = 1'b0;
        exit_in_motion = 1'b0;
    end
    
    // Barrier status logic
    always @(*) begin
        case ({entry_barrier, exit_barrier})
            2'b00: barrier_status = 2'b00; // Both closed
            2'b01: barrier_status = 2'b10; // Exit open
            2'b10: barrier_status = 2'b01; // Entry open
            2'b11: barrier_status = 2'b11; // Both open
        endcase
    end
    
    // Entry barrier control logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            entry_barrier <= 1'b0;     // Close barrier on reset
            entry_timer <= 32'h0;
            entry_in_motion <= 1'b0;
        end
        else if (emergency) begin
            entry_barrier <= 1'b1;     // Open barrier in emergency
            entry_timer <= 32'h0;
            entry_in_motion <= 1'b0;
        end
        else begin
            // Handle open command
            if (open_entry && !entry_barrier && !entry_in_motion) begin
                entry_in_motion <= 1'b1;
                entry_timer <= 32'h0;
            end
            
            // Handle close command
            if (close_entry && entry_barrier && !entry_in_motion) begin
                entry_in_motion <= 1'b1;
                entry_timer <= 32'h0;
            end
            
            // Barrier movement logic
            if (entry_in_motion) begin
                if (entry_timer >= BARRIER_DELAY) begin
                    entry_barrier <= !entry_barrier; // Toggle barrier state
                    entry_in_motion <= 1'b0;
                    entry_timer <= 32'h0;
                end
                else begin
                    entry_timer <= entry_timer + 1;
                end
            end
        end
    end
    
    // Exit barrier control logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            exit_barrier <= 1'b0;      // Close barrier on reset
            exit_timer <= 32'h0;
            exit_in_motion <= 1'b0;
        end
        else if (emergency) begin
            exit_barrier <= 1'b1;      // Open barrier in emergency
            exit_timer <= 32'h0;
            exit_in_motion <= 1'b0;
        end
        else begin
            // Handle open command
            if (open_exit && !exit_barrier && !exit_in_motion) begin
                exit_in_motion <= 1'b1;
                exit_timer <= 32'h0;
            end
            
            // Handle close command
            if (close_exit && exit_barrier && !exit_in_motion) begin
                exit_in_motion <= 1'b1;
                exit_timer <= 32'h0;
            end
            
            // Barrier movement logic
            if (exit_in_motion) begin
                if (exit_timer >= BARRIER_DELAY) begin
                    exit_barrier <= !exit_barrier; // Toggle barrier state
                    exit_in_motion <= 1'b0;
                    exit_timer <= 32'h0;
                end
                else begin
                    exit_timer <= exit_timer + 1;
                end
            end
        end
    end
    
    // Safety logic - prevent closing barrier when vehicle is passing
    // This would typically use additional sensors, but for simplicity
    // we'll just override close commands if a vehicle is detected
    // (Note: In a real system, this would be more sophisticated)
    
endmodule
