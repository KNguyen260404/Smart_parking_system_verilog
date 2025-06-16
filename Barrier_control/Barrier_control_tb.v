module Barrier_control_tb;
    // Parameters
    parameter CLK_PERIOD = 10;       // Clock period in ns
    parameter BARRIER_DELAY = 10;    // Barrier delay for testing
    parameter MAX_WAIT = 50;         // Maximum wait cycles for barrier operations
    
    // Testbench signals
    reg clk;
    reg reset;
    reg open_entry;
    reg open_exit;
    reg close_entry;
    reg close_exit;
    reg emergency;
    reg vehicle_direction;
    
    wire entry_barrier;
    wire exit_barrier;
    wire [1:0] barrier_status;
    
    // Internal signals for monitoring
    wire entry_opening;
    wire exit_opening;
    wire entry_closing;
    wire exit_closing;
    
    // Instantiate the Unit Under Test (UUT)
    Barrier_control #(
        .BARRIER_DELAY(BARRIER_DELAY)
    ) uut (
        .clk(clk),
        .reset(reset),
        .open_entry(open_entry),
        .open_exit(open_exit),
        .close_entry(close_entry),
        .close_exit(close_exit),
        .emergency(emergency),
        .vehicle_direction(vehicle_direction),
        .entry_barrier(entry_barrier),
        .exit_barrier(exit_barrier),
        .barrier_status(barrier_status)
    );
    
    // Connect internal signals for monitoring (if needed)
    assign entry_opening = uut.entry_opening;
    assign exit_opening = uut.exit_opening;
    assign entry_closing = uut.entry_closing;
    assign exit_closing = uut.exit_closing;
    
    // VCD file generation for GTKWave
    initial begin
        $dumpfile("barrier_control_waveform.vcd");
        $dumpvars(0, Barrier_control_tb);
    end
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Function to return barrier status as a string
    function [64*8-1:0] decode_barrier_status;
        input [1:0] status;
        begin
            case (status)
                2'b00: decode_barrier_status = "BARRIERS_CLOSED";
                2'b01: decode_barrier_status = "ENTRY_OPEN";
                2'b10: decode_barrier_status = "EXIT_OPEN";
                2'b11: decode_barrier_status = "BOTH_OPEN";
                default: decode_barrier_status = "UNKNOWN";
            endcase
        end
    endfunction
    
    // Display status changes
    always @(barrier_status or entry_barrier or exit_barrier) begin
        $display("Time=%0t: entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b (%s)", 
                 $time, entry_barrier, exit_barrier, barrier_status, decode_barrier_status(barrier_status));
    end
    
    // Display internal state changes
    always @(entry_opening or exit_opening or entry_closing or exit_closing) begin
        $display("Time=%0t: Internal state - entry_opening=%0b, exit_opening=%0b, entry_closing=%0b, exit_closing=%0b", 
                 $time, entry_opening, exit_opening, entry_closing, exit_closing);
    end
    
    // Task to wait for barrier operation to complete with timeout
    task wait_for_barrier_operation;
        input is_entry;
        input is_opening;
        integer wait_count;
        begin
            wait_count = 0;
            
            if (is_entry && is_opening) begin
                // Wait for entry barrier to open fully
                while (wait_count < MAX_WAIT) begin
                    if (!entry_opening && entry_barrier) begin
                        $display("Time=%0t: Entry barrier fully opened", $time);
                        wait_count = MAX_WAIT; // Exit loop
                    end else begin
                        #(CLK_PERIOD);
                        wait_count = wait_count + 1;
                    end
                end
                if (wait_count == MAX_WAIT && (entry_opening || !entry_barrier))
                    $display("Time=%0t: WARNING - Timeout waiting for entry barrier to open", $time);
            end else if (is_entry && !is_opening) begin
                // Wait for entry barrier to close fully
                while (wait_count < MAX_WAIT) begin
                    if (!entry_closing && !entry_barrier) begin
                        $display("Time=%0t: Entry barrier fully closed", $time);
                        wait_count = MAX_WAIT; // Exit loop
                    end else begin
                        #(CLK_PERIOD);
                        wait_count = wait_count + 1;
                    end
                end
                if (wait_count == MAX_WAIT && (entry_closing || entry_barrier))
                    $display("Time=%0t: WARNING - Timeout waiting for entry barrier to close", $time);
            end else if (!is_entry && is_opening) begin
                // Wait for exit barrier to open fully
                while (wait_count < MAX_WAIT) begin
                    if (!exit_opening && exit_barrier) begin
                        $display("Time=%0t: Exit barrier fully opened", $time);
                        wait_count = MAX_WAIT; // Exit loop
                    end else begin
                        #(CLK_PERIOD);
                        wait_count = wait_count + 1;
                    end
                end
                if (wait_count == MAX_WAIT && (exit_opening || !exit_barrier))
                    $display("Time=%0t: WARNING - Timeout waiting for exit barrier to open", $time);
            end else if (!is_entry && !is_opening) begin
                // Wait for exit barrier to close fully
                while (wait_count < MAX_WAIT) begin
                    if (!exit_closing && !exit_barrier) begin
                        $display("Time=%0t: Exit barrier fully closed", $time);
                        wait_count = MAX_WAIT; // Exit loop
                    end else begin
                        #(CLK_PERIOD);
                        wait_count = wait_count + 1;
                    end
                end
                if (wait_count == MAX_WAIT && (exit_closing || exit_barrier))
                    $display("Time=%0t: WARNING - Timeout waiting for exit barrier to close", $time);
            end
        end
    endtask
    
    // Test stimulus
    initial begin
        // Initialize inputs
        reset = 1;
        open_entry = 0;
        open_exit = 0;
        close_entry = 0;
        close_exit = 0;
        emergency = 0;
        vehicle_direction = 0;
        
        // Apply reset
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD);
        
        // Display initial state
        $display("\nTime=%0t: Initial state - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 1: Open entry barrier
        $display("\nTest Case 1: Open entry barrier");
        open_entry = 1;
        #(CLK_PERIOD);
        open_entry = 0;
        wait_for_barrier_operation(1, 1);
        $display("Time=%0t: After open entry - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 2: Close entry barrier
        $display("\nTest Case 2: Close entry barrier");
        close_entry = 1;
        #(CLK_PERIOD);
        close_entry = 0;
        wait_for_barrier_operation(1, 0);
        $display("Time=%0t: After close entry - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 3: Open exit barrier
        $display("\nTest Case 3: Open exit barrier");
        open_exit = 1;
        #(CLK_PERIOD);
        open_exit = 0;
        wait_for_barrier_operation(0, 1);
        $display("Time=%0t: After open exit - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 4: Close exit barrier
        $display("\nTest Case 4: Close exit barrier");
        close_exit = 1;
        #(CLK_PERIOD);
        close_exit = 0;
        wait_for_barrier_operation(0, 0);
        $display("Time=%0t: After close exit - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 5: Emergency mode
        $display("\nTest Case 5: Emergency mode");
        emergency = 1;
        #(CLK_PERIOD * 5);
        $display("Time=%0t: During emergency - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // End emergency and close barriers
        emergency = 0;
        #(CLK_PERIOD * 5);
        close_entry = 1;
        close_exit = 1;
        #(CLK_PERIOD);
        close_entry = 0;
        close_exit = 0;
        wait_for_barrier_operation(1, 0);
        wait_for_barrier_operation(0, 0);
        $display("Time=%0t: After emergency - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 6: Simultaneous open commands
        $display("\nTest Case 6: Simultaneous open commands");
        open_entry = 1;
        open_exit = 1;
        #(CLK_PERIOD);
        open_entry = 0;
        open_exit = 0;
        wait_for_barrier_operation(1, 1);
        wait_for_barrier_operation(0, 1);
        $display("Time=%0t: After simultaneous open - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 7: Simultaneous close commands
        $display("\nTest Case 7: Simultaneous close commands");
        close_entry = 1;
        close_exit = 1;
        #(CLK_PERIOD);
        close_entry = 0;
        close_exit = 0;
        wait_for_barrier_operation(1, 0);
        wait_for_barrier_operation(0, 0);
        $display("Time=%0t: After simultaneous close - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 8: Priority of close over open
        $display("\nTest Case 8: Priority of close over open");
        // First open the barriers
        open_entry = 1;
        #(CLK_PERIOD);
        open_entry = 0;
        #(CLK_PERIOD * (BARRIER_DELAY/2)); // Wait half the delay
        
        // Now try to close while still opening
        close_entry = 1;
        #(CLK_PERIOD);
        close_entry = 0;
        wait_for_barrier_operation(1, 0);
        $display("Time=%0t: After priority test - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 9: Reset during operation
        $display("\nTest Case 9: Reset during operation");
        open_entry = 1;
        open_exit = 1;
        #(CLK_PERIOD);
        open_entry = 0;
        open_exit = 0;
        #(CLK_PERIOD * (BARRIER_DELAY/2));
        reset = 1;
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD*5);
        $display("Time=%0t: After reset - entry_barrier=%0b, exit_barrier=%0b, barrier_status=%0b", 
                 $time, entry_barrier, exit_barrier, barrier_status);
        
        // Test Case 10: Faster closing time
        $display("\nTest Case 10: Faster closing time");
        // Open entry barrier
        open_entry = 1;
        #(CLK_PERIOD);
        open_entry = 0;
        wait_for_barrier_operation(1, 1);
        
        // Measure time to close
        $display("Time=%0t: Starting barrier close timing test", $time);
        close_entry = 1;
        #(CLK_PERIOD);
        close_entry = 0;
        wait_for_barrier_operation(1, 0);
        $display("Time=%0t: Barrier close timing test completed", $time);
        
        // End simulation
        #(CLK_PERIOD*10);
        $display("\nSimulation completed successfully");
        $finish;
    end
endmodule
