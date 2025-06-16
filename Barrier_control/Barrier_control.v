module Barrier_control #(
    parameter BARRIER_DELAY = 10  // Delay for barrier operation
)(
    // Clock and reset
    input wire clk,              // System clock
    input wire reset,            // Synchronous reset, active high
    
    // Control inputs
    input wire open_entry,       // Signal to open entry barrier
    input wire open_exit,        // Signal to open exit barrier
    input wire close_entry,      // Signal to close entry barrier
    input wire close_exit,       // Signal to close exit barrier
    input wire emergency,        // Emergency signal
    input wire vehicle_direction, // Direction of vehicle (0: entry, 1: exit)
    
    // Barrier outputs
    output reg entry_barrier,    // Entry barrier control: 0: closed, 1: open
    output reg exit_barrier,     // Exit barrier control: 0: closed, 1: open
    output wire [1:0] barrier_status // Current barrier status
);

    // Barrier status
    localparam BARRIERS_CLOSED = 2'b00;
    localparam ENTRY_OPEN = 2'b01;
    localparam EXIT_OPEN = 2'b10;
    localparam BOTH_OPEN = 2'b11;
    
    // Barrier delay counters
    reg [9:0] entry_delay_counter;
    reg [9:0] exit_delay_counter;
    
    // Barrier operation in progress flags
    reg entry_opening;
    reg exit_opening;
    reg entry_closing;
    reg exit_closing;
    
    // Barrier status output
    assign barrier_status = {exit_barrier, entry_barrier};
    
    // Barrier control logic
    always @(posedge clk) begin
        if (reset) begin
            entry_barrier <= 1'b0;  // Closed
            exit_barrier <= 1'b0;   // Closed
            entry_delay_counter <= 10'd0;
            exit_delay_counter <= 10'd0;
            entry_opening <= 1'b0;
            exit_opening <= 1'b0;
            entry_closing <= 1'b0;
            exit_closing <= 1'b0;
        end else begin
            // Emergency handling - open both barriers immediately
            if (emergency) begin
                entry_barrier <= 1'b1;  // Open
                exit_barrier <= 1'b1;   // Open
                entry_delay_counter <= 10'd0;
                exit_delay_counter <= 10'd0;
                entry_opening <= 1'b0;
                exit_opening <= 1'b0;
                entry_closing <= 1'b0;
                exit_closing <= 1'b0;
            end else begin
                // Entry barrier control
                if (open_entry && !entry_closing && !entry_barrier) begin
                    // Start opening entry barrier
                    entry_opening <= 1'b1;
                    entry_delay_counter <= 10'd0;
                end else if (close_entry && !entry_opening) begin
                    // Start closing entry barrier
                    entry_closing <= 1'b1;
                    entry_delay_counter <= 10'd0;
                end
                
                // Exit barrier control
                if (open_exit && !exit_closing && !exit_barrier) begin
                    // Start opening exit barrier
                    exit_opening <= 1'b1;
                    exit_delay_counter <= 10'd0;
                end else if (close_exit && !exit_opening) begin
                    // Start closing exit barrier
                    exit_closing <= 1'b1;
                    exit_delay_counter <= 10'd0;
                end
                
                // Entry barrier delay handling
                if (entry_opening) begin
                    if (entry_delay_counter >= BARRIER_DELAY) begin
                        entry_barrier <= 1'b1;  // Open
                        entry_opening <= 1'b0;
                    end else begin
                        entry_delay_counter <= entry_delay_counter + 10'd1;
                    end
                end else if (entry_closing) begin
                    if (entry_delay_counter >= BARRIER_DELAY / 2) begin  // Close faster
                        entry_barrier <= 1'b0;  // Closed
                        entry_closing <= 1'b0;
                    end else begin
                        entry_delay_counter <= entry_delay_counter + 10'd1;
                    end
                end
                
                // Exit barrier delay handling
                if (exit_opening) begin
                    if (exit_delay_counter >= BARRIER_DELAY) begin
                        exit_barrier <= 1'b1;  // Open
                        exit_opening <= 1'b0;
                    end else begin
                        exit_delay_counter <= exit_delay_counter + 10'd1;
                    end
                end else if (exit_closing) begin
                    if (exit_delay_counter >= BARRIER_DELAY / 2) begin  // Close faster
                        exit_barrier <= 1'b0;  // Closed
                        exit_closing <= 1'b0;
                    end else begin
                        exit_delay_counter <= exit_delay_counter + 10'd1;
                    end
                end
                
                // Priority handling - if close command is received during opening
                if (close_entry && entry_opening && entry_delay_counter < BARRIER_DELAY/2) begin
                    entry_opening <= 1'b0;
                    entry_closing <= 1'b1;
                    entry_delay_counter <= 10'd0;
                end
                
                if (close_exit && exit_opening && exit_delay_counter < BARRIER_DELAY/2) begin
                    exit_opening <= 1'b0;
                    exit_closing <= 1'b1;
                    exit_delay_counter <= 10'd0;
                end
            end
        end
    end

endmodule

