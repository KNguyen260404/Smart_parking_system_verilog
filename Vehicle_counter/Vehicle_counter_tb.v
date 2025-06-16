module Vehicle_counter_tb;
    // Parameters
    parameter CLK_PERIOD = 10;       // Clock period in ns
    parameter MAX_CAPACITY = 63;     // Maximum parking capacity (6-bit value)
    
    // Testbench signals
    reg clk;
    reg reset;
    reg entry_passed;
    reg exit_passed;
    reg [5:0] max_capacity;
    
    wire [5:0] vehicle_count;
    wire [5:0] available_spaces;
    wire parking_full;
    
    // Instantiate the Unit Under Test (UUT)
    Vehicle_counter #(
        .MAX_CAPACITY(MAX_CAPACITY)
    ) uut (
        .clk(clk),
        .reset(reset),
        .entry_passed(entry_passed),
        .exit_passed(exit_passed),
        .max_capacity(max_capacity),
        .vehicle_count(vehicle_count),
        .available_spaces(available_spaces),
        .parking_full(parking_full)
    );
    
    // VCD file generation for GTKWave
    initial begin
        $dumpfile("vehicle_counter_waveform.vcd");
        $dumpvars(0, Vehicle_counter_tb);
    end
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Task for simulating a vehicle entry
    task simulate_vehicle_entry;
        begin
            $display("\n=== Simulating Vehicle Entry ===");
            entry_passed = 1;
            #(CLK_PERIOD);
            entry_passed = 0;
            #(CLK_PERIOD);
            
            $display("Vehicle entered: count=%0d, available=%0d, full=%0b", 
                    vehicle_count, available_spaces, parking_full);
        end
    endtask
    
    // Task for simulating a vehicle exit
    task simulate_vehicle_exit;
        begin
            $display("\n=== Simulating Vehicle Exit ===");
            exit_passed = 1;
            #(CLK_PERIOD);
            exit_passed = 0;
            #(CLK_PERIOD);
            
            $display("Vehicle exited: count=%0d, available=%0d, full=%0b", 
                    vehicle_count, available_spaces, parking_full);
        end
    endtask
    
    // Task for testing simultaneous entry and exit
    task test_simultaneous_entry_exit;
        begin
            $display("\n=== Testing Simultaneous Entry and Exit ===");
            entry_passed = 1;
            exit_passed = 1;
            #(CLK_PERIOD);
            entry_passed = 0;
            exit_passed = 0;
            #(CLK_PERIOD);
            
            $display("After simultaneous entry/exit: count=%0d, available=%0d, full=%0b", 
                    vehicle_count, available_spaces, parking_full);
        end
    endtask
    
    // Task for testing parking full condition
    task test_parking_full;
        input integer target_count;
        begin
            $display("\n=== Testing Parking Full Condition ===");
            $display("Filling parking to capacity (%0d vehicles)...", target_count);
            
            // Fill parking to the target count
            while (vehicle_count < target_count) begin
                entry_passed = 1;
                #(CLK_PERIOD);
                entry_passed = 0;
                #(CLK_PERIOD);
            end
            
            $display("Parking status: count=%0d, available=%0d, full=%0b", 
                    vehicle_count, available_spaces, parking_full);
                    
            // Try to add one more vehicle when full
            if (parking_full) begin
                $display("Attempting to add vehicle when parking is full...");
                entry_passed = 1;
                #(CLK_PERIOD);
                entry_passed = 0;
                #(CLK_PERIOD);
                
                if (vehicle_count == target_count)
                    $display("PASS: Vehicle entry blocked when parking is full");
                else
                    $display("FAIL: Vehicle count increased despite parking being full");
            end
        end
    endtask
    
    // Task for testing max capacity update
    task test_max_capacity_update;
        input [5:0] new_capacity;
        begin
            $display("\n=== Testing Max Capacity Update ===");
            $display("Changing max_capacity from %0d to %0d", max_capacity, new_capacity);
            
            max_capacity = new_capacity;
            #(CLK_PERIOD*2);
            
            $display("After capacity update: count=%0d, available=%0d, full=%0b", 
                    vehicle_count, available_spaces, parking_full);
                    
            // Check if available spaces updated correctly
            if (vehicle_count <= new_capacity) begin
                // Normal case: vehicle_count is less than or equal to new_capacity
                if (available_spaces == (new_capacity - vehicle_count))
                    $display("PASS: Available spaces updated correctly");
                else
                    $display("FAIL: Available spaces not updated correctly");
            end else begin
                // Edge case: vehicle_count exceeds new_capacity
                if (available_spaces == 0)
                    $display("PASS: Available spaces updated correctly to 0 when vehicle count exceeds capacity");
                else
                    $display("FAIL: Available spaces should be 0 when vehicle count exceeds capacity");
            end
                
            // Check if parking_full flag is set correctly
            if ((vehicle_count >= new_capacity && parking_full) || 
                (vehicle_count < new_capacity && !parking_full))
                $display("PASS: Parking full flag updated correctly");
            else
                $display("FAIL: Parking full flag not updated correctly");
        end
    endtask
    
    // Task for testing reset functionality
    task test_reset;
        begin
            $display("\n=== Testing Reset Functionality ===");
            
            // Apply reset
            reset = 1;
            #(CLK_PERIOD*2);
            reset = 0;
            #(CLK_PERIOD);
            
            // Check if all outputs are reset
            if (vehicle_count == 0 && available_spaces == max_capacity && !parking_full)
                $display("PASS: All outputs reset to initial values");
            else
                $display("FAIL: Not all outputs reset correctly");
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        entry_passed = 0;
        exit_passed = 0;
        max_capacity = MAX_CAPACITY;
        
        // Apply reset
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD*2);
        
        $display("=== Starting Vehicle Counter Tests ===");
        $display("Initial state: count=%0d, available=%0d, full=%0b", 
                vehicle_count, available_spaces, parking_full);
        
        // Test 1: Single vehicle entry
        simulate_vehicle_entry();
        
        // Test 2: Multiple vehicle entries
        $display("\n=== Testing Multiple Vehicle Entries ===");
        repeat(5) begin
            simulate_vehicle_entry();
        end
        
        // Test 3: Single vehicle exit
        simulate_vehicle_exit();
        
        // Test 4: Multiple vehicle exits
        $display("\n=== Testing Multiple Vehicle Exits ===");
        repeat(3) begin
            simulate_vehicle_exit();
        end
        
        // Test 5: Simultaneous entry and exit
        test_simultaneous_entry_exit();
        
        // Test 6: Filling parking to capacity
        test_parking_full(max_capacity);
        
        // Test 7: Test vehicle exit when parking is full
        $display("\n=== Testing Vehicle Exit When Parking Is Full ===");
        simulate_vehicle_exit();
        
        // Test 8: Changing max capacity to a lower value
        test_max_capacity_update(10);
        
        // Test 9: Changing max capacity to a higher value
        test_max_capacity_update(MAX_CAPACITY);
        
        // Test 10: Reset during operation
        test_reset();
        
        // Test 11: Edge case - try to exit when count is 0
        $display("\n=== Testing Exit When Count is 0 ===");
        simulate_vehicle_exit();
        if (vehicle_count == 0)
            $display("PASS: Count remained at 0 when attempting to exit from empty parking");
        else
            $display("FAIL: Count changed when attempting to exit from empty parking");
        
        // End simulation
        #(CLK_PERIOD*10);
        $display("\n=== Vehicle Counter Tests Completed Successfully ===");
        $finish;
    end
    
    // Monitor for important state changes
    always @(parking_full) begin
        if (parking_full)
            $display("Time=%0t: PARKING FULL FLAG ACTIVATED", $time);
        else if ($time > 0)
            $display("Time=%0t: PARKING FULL FLAG DEACTIVATED", $time);
    end
    
endmodule
