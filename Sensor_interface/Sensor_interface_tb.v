module Sensor_interface_tb;
    // Parameters
    parameter CLK_PERIOD = 10;       // Clock period in ns
    parameter DEBOUNCE_DELAY = 5;    // Debounce delay in clock cycles (same as in DUT)
    
    // Testbench signals
    reg clk;
    reg reset;
    reg raw_entry_sensor;
    reg raw_exit_sensor;
    
    wire entry_sensor;
    wire exit_sensor;
    wire entry_passed;
    wire exit_passed;
    
    // Flags for monitoring passed signals
    reg entry_passed_detected;
    reg exit_passed_detected;
    
    // Instantiate the Unit Under Test (UUT)
    Sensor_interface #(
        .DEBOUNCE_DELAY(DEBOUNCE_DELAY)
    ) uut (
        .clk(clk),
        .reset(reset),
        .raw_entry_sensor(raw_entry_sensor),
        .raw_exit_sensor(raw_exit_sensor),
        .entry_sensor(entry_sensor),
        .exit_sensor(exit_sensor),
        .entry_passed(entry_passed),
        .exit_passed(exit_passed)
    );
    
    // VCD file generation for GTKWave
    initial begin
        $dumpfile("sensor_interface_waveform.vcd");
        $dumpvars(0, Sensor_interface_tb);
    end
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Monitor for entry_passed and exit_passed signals
    always @(posedge clk) begin
        if (entry_passed) begin
            entry_passed_detected = 1;
            $display("Time=%0t: ENTRY PASSED detected", $time);
        end
        
        if (exit_passed) begin
            exit_passed_detected = 1;
            $display("Time=%0t: EXIT PASSED detected", $time);
        end
    end
    
    // Task for simulating a vehicle entering
    task simulate_vehicle_entry;
        begin
            // Reset detection flag
            entry_passed_detected = 0;
            
            $display("\n=== Simulating Vehicle Entry ===");
            // Vehicle approaches entry sensor
            raw_entry_sensor = 1;
            #(CLK_PERIOD * (DEBOUNCE_DELAY + 2));
            
            // Check if entry sensor is activated
            if (entry_sensor)
                $display("PASS: Entry sensor activated after debounce delay");
            else
                $display("FAIL: Entry sensor not activated");
                
            // Vehicle passes through entry sensor
            #(CLK_PERIOD * 10); // Vehicle takes time to pass
            raw_entry_sensor = 0;
            #(CLK_PERIOD * (DEBOUNCE_DELAY + 10)); // Wait longer for signal to propagate
            
            // Check if entry_passed was detected at any point
            if (entry_passed_detected)
                $display("PASS: entry_passed signal was triggered");
            else
                $display("FAIL: entry_passed signal was not triggered");
                
            // Wait for signals to settle
            #(CLK_PERIOD * 5);
        end
    endtask
    
    // Task for simulating a vehicle exiting
    task simulate_vehicle_exit;
        begin
            // Reset detection flag
            exit_passed_detected = 0;
            
            $display("\n=== Simulating Vehicle Exit ===");
            // Vehicle approaches exit sensor
            raw_exit_sensor = 1;
            #(CLK_PERIOD * (DEBOUNCE_DELAY + 2));
            
            // Check if exit sensor is activated
            if (exit_sensor)
                $display("PASS: Exit sensor activated after debounce delay");
            else
                $display("FAIL: Exit sensor not activated");
                
            // Vehicle passes through exit sensor
            #(CLK_PERIOD * 10); // Vehicle takes time to pass
            raw_exit_sensor = 0;
            #(CLK_PERIOD * (DEBOUNCE_DELAY + 10)); // Wait longer for signal to propagate
            
            // Check if exit_passed was detected at any point
            if (exit_passed_detected)
                $display("PASS: exit_passed signal was triggered");
            else
                $display("FAIL: exit_passed signal was not triggered");
                
            // Wait for signals to settle
            #(CLK_PERIOD * 5);
        end
    endtask
    
    // Task for testing noise rejection
    task test_noise_rejection;
        input is_entry; // 1 for entry sensor, 0 for exit sensor
        begin
            if (is_entry)
                $display("\n=== Testing Entry Sensor Noise Rejection ===");
            else
                $display("\n=== Testing Exit Sensor Noise Rejection ===");
                
            // Apply short pulses (noise)
            for (integer i = 0; i < 3; i = i + 1) begin
                if (is_entry)
                    raw_entry_sensor = 1;
                else
                    raw_exit_sensor = 1;
                    
                #(CLK_PERIOD);
                
                if (is_entry)
                    raw_entry_sensor = 0;
                else
                    raw_exit_sensor = 0;
                    
                #(CLK_PERIOD);
            end
            
            // Check if sensors remained inactive (noise rejected)
            #(CLK_PERIOD);
            if (is_entry) begin
                if (!entry_sensor)
                    $display("PASS: Entry sensor rejected noise");
                else
                    $display("FAIL: Entry sensor activated by noise");
            end else begin
                if (!exit_sensor)
                    $display("PASS: Exit sensor rejected noise");
                else
                    $display("FAIL: Exit sensor activated by noise");
            end
            
            #(CLK_PERIOD * 2);
        end
    endtask
    
    // Task for testing reset functionality
    task test_reset;
        begin
            $display("\n=== Testing Reset Functionality ===");
            
            // Activate both sensors
            raw_entry_sensor = 1;
            raw_exit_sensor = 1;
            #(CLK_PERIOD * (DEBOUNCE_DELAY + 2));
            
            // Verify sensors are active
            if (entry_sensor && exit_sensor)
                $display("Sensors activated successfully before reset");
            
            // Apply reset
            reset = 1;
            #(CLK_PERIOD * 2);
            reset = 0;
            #(CLK_PERIOD);
            
            // Check if all outputs are reset
            if (!entry_sensor && !exit_sensor && !entry_passed && !exit_passed)
                $display("PASS: All outputs reset to 0");
            else
                $display("FAIL: Not all outputs reset to 0");
                
            // Return to inactive state
            raw_entry_sensor = 0;
            raw_exit_sensor = 0;
            #(CLK_PERIOD * 5);
        end
    endtask
    
    // Task for testing simultaneous entry and exit
    task test_simultaneous_entry_exit;
        begin
            // Reset detection flags
            entry_passed_detected = 0;
            exit_passed_detected = 0;
            
            $display("\n=== Testing Simultaneous Entry and Exit ===");
            
            // Activate both sensors
            raw_entry_sensor = 1;
            raw_exit_sensor = 1;
            #(CLK_PERIOD * (DEBOUNCE_DELAY + 2));
            
            // Check if both sensors are activated
            if (entry_sensor && exit_sensor)
                $display("PASS: Both sensors activated simultaneously");
            else
                $display("FAIL: Both sensors not activated");
                
            // Both vehicles pass through sensors
            #(CLK_PERIOD * 10);
            raw_entry_sensor = 0;
            raw_exit_sensor = 0;
            #(CLK_PERIOD * (DEBOUNCE_DELAY + 10)); // Wait longer for signals to propagate
            
            // Check if both passed signals were detected at any point
            if (entry_passed_detected && exit_passed_detected)
                $display("PASS: Both entry_passed and exit_passed signals were triggered");
            else
                $display("FAIL: Both passed signals were not triggered");
                
            #(CLK_PERIOD * 5);
        end
    endtask
    
    // Task for testing rapid sensor toggling (stress test)
    task test_rapid_toggling;
        input is_entry; // 1 for entry sensor, 0 for exit sensor
        begin
            if (is_entry)
                $display("\n=== Testing Rapid Entry Sensor Toggling ===");
            else
                $display("\n=== Testing Rapid Exit Sensor Toggling ===");
                
            // Rapidly toggle the sensor
            for (integer i = 0; i < 10; i = i + 1) begin
                if (is_entry)
                    raw_entry_sensor = ~raw_entry_sensor;
                else
                    raw_exit_sensor = ~raw_exit_sensor;
                    
                #(CLK_PERIOD);
            end
            
            // Let the debounce logic stabilize
            #(CLK_PERIOD * (DEBOUNCE_DELAY + 5));
            
            // Return to inactive state
            if (is_entry)
                raw_entry_sensor = 0;
            else
                raw_exit_sensor = 0;
                
            #(CLK_PERIOD * 5);
            $display("Rapid toggling test completed - check waveform for proper debouncing");
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize inputs and flags
        reset = 1;
        raw_entry_sensor = 0;
        raw_exit_sensor = 0;
        entry_passed_detected = 0;
        exit_passed_detected = 0;
        
        // Apply reset
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD*5);
        
        $display("=== Starting Sensor Interface Tests ===");
        
        // Test 1: Noise rejection for entry sensor
        test_noise_rejection(1);
        
        // Test 2: Noise rejection for exit sensor
        test_noise_rejection(0);
        
        // Test 3: Normal vehicle entry
        simulate_vehicle_entry();
        
        // Test 4: Normal vehicle exit
        simulate_vehicle_exit();
        
        // Test 5: Reset functionality
        test_reset();
        
        // Test 6: Simultaneous entry and exit
        test_simultaneous_entry_exit();
        
        // Test 7: Rapid toggling of entry sensor
        test_rapid_toggling(1);
        
        // Test 8: Rapid toggling of exit sensor
        test_rapid_toggling(0);
        
        // End simulation
        #(CLK_PERIOD*10);
        $display("\n=== Sensor Interface Tests Completed Successfully ===");
        $finish;
    end
    
endmodule
