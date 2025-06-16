module Fee_calculator_tb;
    // Parameters
    parameter CLK_PERIOD = 10;       // Clock period in ns
    
    // Testbench signals
    reg clk;
    reg reset;
    reg [31:0] entry_time;
    reg [31:0] exit_time;
    reg [7:0] vehicle_id;
    reg calculate_fee;
    
    wire [7:0] fee_amount;
    wire fee_valid;
    
    // Fee calculation parameters (must match module parameters)
    parameter BASE_FEE = 10;         // Base fee for parking
    parameter HOURLY_RATE = 5;       // Additional fee per hour
    parameter MINIMUM_TIME = 60;     // Minimum time unit (e.g., 60 minutes)
    
    // Instantiate the Unit Under Test (UUT)
    Fee_calculator uut (
        .clk(clk),
        .reset(reset),
        .entry_time(entry_time),
        .exit_time(exit_time),
        .vehicle_id(vehicle_id),
        .calculate_fee(calculate_fee),
        .fee_amount(fee_amount),
        .fee_valid(fee_valid)
    );
    
    // VCD file generation for GTKWave
    initial begin
        $dumpfile("fee_calculator_waveform.vcd");
        $dumpvars(0, Fee_calculator_tb);
    end
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Display status changes
    always @(posedge fee_valid) begin
        $display("Time=%0t: Fee calculation complete - Fee=%0d for vehicle_id=%0d, duration=%0d time units", 
                 $time, fee_amount, vehicle_id, exit_time - entry_time);
    end
    
    // Function to calculate expected fee
    function [7:0] calculate_expected_fee;
        input [31:0] e_time;
        input [31:0] x_time;
        reg [7:0] hours;
        begin
            if (x_time < e_time) begin
                // Handle overflow case
                calculate_expected_fee = BASE_FEE;
            end else if (x_time == e_time) begin
                // Minimum 1 hour for zero duration
                calculate_expected_fee = BASE_FEE + HOURLY_RATE;
            end else begin
                // Calculate hours
                if ((x_time - e_time) % MINIMUM_TIME > 0)
                    hours = ((x_time - e_time) / MINIMUM_TIME) + 8'd1;
                else
                    hours = (x_time - e_time) / MINIMUM_TIME;
                
                calculate_expected_fee = BASE_FEE + (HOURLY_RATE * hours);
            end
        end
    endfunction
    
    // Task to calculate fee and wait for result
    task calculate_and_wait;
        input [31:0] e_time;
        input [31:0] x_time;
        input [7:0] v_id;
        reg [7:0] expected_fee;
        begin
            // Set inputs
            entry_time = e_time;
            exit_time = x_time;
            vehicle_id = v_id;
            
            // Calculate expected fee
            expected_fee = calculate_expected_fee(e_time, x_time);
            
            // Trigger calculation
            calculate_fee = 1;
            #(CLK_PERIOD);
            calculate_fee = 0;
            
            // Wait for calculation to complete
            wait(fee_valid);
            #(CLK_PERIOD);
            
            // Display expected fee calculation
            $display("Expected fee: BASE_FEE(%0d) + HOURLY_RATE(%0d) * hours_parked = %0d", 
                     BASE_FEE, HOURLY_RATE, expected_fee);
                     
            // Verify calculation
            if (fee_amount == expected_fee)
                $display("PASS: Fee calculation is correct");
            else
                $display("FAIL: Fee calculation is incorrect - Got %0d, Expected %0d", 
                         fee_amount, expected_fee);
                
            // Wait a bit before next test
            #(CLK_PERIOD*5);
        end
    endtask
    
    // Test stimulus
    initial begin
        // Initialize inputs
        reset = 1;
        entry_time = 0;
        exit_time = 0;
        vehicle_id = 0;
        calculate_fee = 0;
        
        // Apply reset
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD);
        
        // Test Case 1: Short duration (1 hour)
        $display("\nTest Case 1: Short duration (1 hour = 60 time units)");
        calculate_and_wait(32'd0, 32'd60, 8'd1);
        
        // Test Case 2: Medium duration (2 hours)
        $display("\nTest Case 2: Medium duration (2 hours = 120 time units)");
        calculate_and_wait(32'd100, 32'd220, 8'd2);
        
        // Test Case 3: Long duration (5 hours)
        $display("\nTest Case 3: Long duration (5 hours = 300 time units)");
        calculate_and_wait(32'd500, 32'd800, 8'd3);
        
        // Test Case 4: Very short duration (less than minimum)
        $display("\nTest Case 4: Very short duration (30 time units)");
        calculate_and_wait(32'd1000, 32'd1030, 8'd4);
        
        // Test Case 5: Different vehicle IDs
        $display("\nTest Case 5: Different vehicle IDs");
        calculate_and_wait(32'd2000, 32'd2120, 8'd10);
        calculate_and_wait(32'd3000, 32'd3180, 8'd20);
        calculate_and_wait(32'd4000, 32'd4240, 8'd30);
        
        // Test Case 6: Edge case (exit_time = entry_time)
        $display("\nTest Case 6: Edge case (exit_time = entry_time)");
        calculate_and_wait(32'd5000, 32'd5000, 8'd5);
        
        // Test Case 7: Edge case (exit_time < entry_time)
        $display("\nTest Case 7: Edge case (exit_time < entry_time)");
        calculate_and_wait(32'd6000, 32'd5900, 8'd6);
        
        // Test Case 8: Reset during operation
        $display("\nTest Case 8: Reset during operation");
        entry_time = 32'd7000;
        exit_time = 32'd7120;
        vehicle_id = 8'd7;
        calculate_fee = 1;
        #(CLK_PERIOD/2);
        reset = 1;
        #(CLK_PERIOD*2);
        reset = 0;
        calculate_fee = 0;
        #(CLK_PERIOD*5);
        $display("Time=%0t: After reset - fee_amount=%0d, fee_valid=%0d", 
                 $time, fee_amount, fee_valid);
        
        // Test Case 9: Rapid consecutive calculations
        $display("\nTest Case 9: Rapid consecutive calculations");
        calculate_and_wait(32'd8000, 32'd8060, 8'd8);
        calculate_and_wait(32'd9000, 32'd9120, 8'd9);
        calculate_and_wait(32'd10000, 32'd10180, 8'd10);
        
        // Test Case 10: Large time values
        $display("\nTest Case 10: Large time values");
        calculate_and_wait(32'd1000000, 32'd1000600, 8'd11);
        
        // End simulation
        #(CLK_PERIOD*10);
        $display("\nSimulation completed successfully");
        $finish;
    end
endmodule
