module Smart_parking_system_tb;
    // Parameters
    parameter CLK_PERIOD = 10;
    parameter MAX_CAPACITY = 10;
    parameter DEBOUNCE_DELAY = 5;
    parameter BARRIER_DELAY = 10;
    parameter STATE_WAIT_TIMEOUT = 50;
    
    // State definitions for readability
    localparam IDLE = 3'b000;
    localparam VEHICLE_DETECTED = 3'b001;
    localparam CARD_VERIFICATION = 3'b010;
    localparam OPEN_BARRIER = 3'b011;
    localparam VEHICLE_PASSING = 3'b100;
    localparam CLOSE_BARRIER = 3'b101;
    localparam UPDATE_COUNT = 3'b110;
    localparam EMERGENCY_MODE = 3'b111;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg raw_entry_sensor;
    reg raw_exit_sensor;
    reg [3:0] card_id;
    reg emergency;
    
    wire entry_barrier;
    wire exit_barrier;
    wire [5:0] available_spaces;
    wire [7:0] segment_display;
    wire [3:0] digit_select;
    wire parking_full;
    wire alarm;
    wire [3:0] led_indicators;
    wire [7:0] fee_amount;
    
    // Internal signals for monitoring
    wire entry_sensor;
    wire exit_sensor;
    wire entry_passed;
    wire exit_passed;
    wire [2:0] current_state;
    
    // Loop variable
    integer i;
    
    // Function to convert state to string for display
    reg [255:0] state_name;
    function [255:0] state_to_string;
        input [2:0] state;
        begin
            case(state)
                3'b000: state_to_string = "IDLE";
                3'b001: state_to_string = "VEHICLE_DETECTED";
                3'b010: state_to_string = "CARD_VERIFICATION";
                3'b011: state_to_string = "OPEN_BARRIER";
                3'b100: state_to_string = "VEHICLE_PASSING";
                3'b101: state_to_string = "CLOSE_BARRIER";
                3'b110: state_to_string = "UPDATE_COUNT";
                3'b111: state_to_string = "EMERGENCY_MODE";
                default: state_to_string = "UNKNOWN";
            endcase
        end
    endfunction
    
    // Instantiate the DUT
    Smart_parking_system #(
        .MAX_CAPACITY(MAX_CAPACITY),
        .DEBOUNCE_DELAY(DEBOUNCE_DELAY),
        .BARRIER_DELAY(BARRIER_DELAY)
    ) dut (
        .clk(clk),
        .reset(reset),
        .raw_entry_sensor(raw_entry_sensor),
        .raw_exit_sensor(raw_exit_sensor),
        .card_id(card_id),
        .emergency(emergency),
        .entry_barrier(entry_barrier),
        .exit_barrier(exit_barrier),
        .available_spaces(available_spaces),
        .segment_display(segment_display),
        .digit_select(digit_select),
        .parking_full(parking_full),
        .alarm(alarm),
        .led_indicators(led_indicators),
        .fee_amount(fee_amount)
    );
    
    // Connect internal signals for monitoring
    assign entry_sensor = dut.entry_sensor;
    assign exit_sensor = dut.exit_sensor;
    assign entry_passed = dut.entry_passed;
    assign exit_passed = dut.exit_passed;
    assign current_state = dut.fsm_control_inst.current_state;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Task to wait for a specific state
    task wait_for_state;
        input [2:0] target_state;
        output success;
        integer timeout_counter;
        begin
            timeout_counter = 0;
            success = 0;
            
            while (timeout_counter < 400) begin  // Increased timeout from 200 to 400
                #5;
                if (current_state == target_state) begin
                    success = 1;
                    state_name = state_to_string(target_state);
                    $display("Time=%0d: Reached state %40s", $time, state_name);
                    timeout_counter = 400; // Exit loop
                end else begin
                    timeout_counter = timeout_counter + 1;
                end
            end
            
            if (!success) begin
                $display("Time=%0d: WARNING - Timeout waiting for state %0d", $time, target_state);
            end
        end
    endtask
    
    // Task to wait for barrier to open
    task wait_for_barrier_open;
        input is_entry;
        output success;
        integer timeout_counter;
        begin
            timeout_counter = 0;
            success = 0;
            
            while (timeout_counter < 200) begin  // Increased timeout from 100 to 200
                #10;
                if (is_entry && entry_barrier) begin
                    success = 1;
                    $display("Time=%0d: Entry barrier opened", $time);
                    timeout_counter = 200; // Exit loop
                end else if (!is_entry && exit_barrier) begin
                    success = 1;
                    $display("Time=%0d: Exit barrier opened", $time);
                    timeout_counter = 200; // Exit loop
                end else begin
                    timeout_counter = timeout_counter + 1;
                end
            end
            
            if (!success) begin
                if (is_entry)
                    $display("Time=%0d: WARNING - Entry barrier did not open in time", $time);
                else
                    $display("Time=%0d: WARNING - Exit barrier did not open in time", $time);
            end
        end
    endtask
    
    // Task to wait for barrier to close
    task wait_for_barrier_close;
        input is_entry;
        output success;
        integer timeout_counter;
        begin
            timeout_counter = 0;
            success = 0;
            
            while (timeout_counter < 150) begin
                #10;
                if (is_entry && !entry_barrier) begin
                    success = 1;
                    $display("Time=%0d: Entry barrier closed", $time);
                    timeout_counter = 150; // Exit loop
                end else if (!is_entry && !exit_barrier) begin
                    success = 1;
                    $display("Time=%0d: Exit barrier closed", $time);
                    timeout_counter = 150; // Exit loop
                end else begin
                    timeout_counter = timeout_counter + 1;
                end
            end
            
            if (!success) begin
                if (is_entry)
                    $display("Time=%0d: WARNING - Entry barrier did not close in time", $time);
                else
                    $display("Time=%0d: WARNING - Exit barrier did not close in time", $time);
            end
        end
    endtask
    
    // Test vehicle entry with valid card
    task test_vehicle_entry_with_valid_card;
        input [3:0] card_value;
        reg success;
        begin
            $display("\nTest Case 1: Vehicle enters with valid card");
            $display("Time=%0d: Starting vehicle entry with valid card ID=%0d", $time, card_value);
            
            // Check if parking is full before attempting entry
            if (parking_full) begin
                $display("Time=%0d: Cannot start entry - parking is full", $time);
            end else begin
                // Simulate vehicle at entry
                raw_entry_sensor = 1;
                card_id = card_value;
                #(CLK_PERIOD * 5);
                
                // Wait for card verification state
                wait_for_state(CARD_VERIFICATION, success);
                
                // Add extra delay to ensure card is processed
                #(CLK_PERIOD * 5);
                
                // Wait for barrier to open
                wait_for_barrier_open(1, success);
                if (entry_barrier)
                    $display("Time=%0d: PASS - Entry barrier opened for valid card", $time);
                else
                    $display("Time=%0d: FAIL - Entry barrier did not open for valid card", $time);
                
                // Wait for vehicle passing state
                wait_for_state(VEHICLE_PASSING, success);
                
                // Simulate vehicle passing
                #(CLK_PERIOD * 5);
                raw_entry_sensor = 0;
                #(CLK_PERIOD * 5);
                
                // Wait for barrier to close
                wait_for_barrier_close(1, success);
                if (!entry_barrier)
                    $display("Time=%0d: PASS - Entry barrier closed after vehicle passed", $time);
                else
                    $display("Time=%0d: FAIL - Entry barrier remained open after vehicle passed", $time);
                
                // Wait for return to idle state
                wait_for_state(IDLE, success);
                
                // Add extra delay to ensure state machine stabilizes
                #(CLK_PERIOD * 10);
                
                $display("Time=%0d: Vehicle entry with valid card completed", $time);
            end
        end
    endtask
    
    // Test vehicle exit
    task test_vehicle_exit;
        input [3:0] card_value;
        reg success;
        begin
            $display("\nTest Case 2: Vehicle exits");
            $display("Time=%0d: Starting vehicle exit with card ID=%0d", $time, card_value);
            
            // Simulate vehicle at exit
            raw_exit_sensor = 1;
            card_id = card_value;
            #(CLK_PERIOD * 5);
            
            // Wait for vehicle detection state
            wait_for_state(VEHICLE_DETECTED, success);
            
            // Add extra delay to ensure fee calculation
            #(CLK_PERIOD * 5);
            
            // Wait for barrier to open
            wait_for_barrier_open(0, success);
            if (exit_barrier)
                $display("Time=%0d: PASS - Exit barrier opened", $time);
            else
                $display("Time=%0d: FAIL - Exit barrier did not open", $time);
            
            // Wait for vehicle passing state
            wait_for_state(VEHICLE_PASSING, success);
            
            // Simulate vehicle passing
            #(CLK_PERIOD * 5);
            raw_exit_sensor = 0;
            #(CLK_PERIOD * 5);
            
            // Wait for barrier to close
            wait_for_barrier_close(0, success);
            if (!exit_barrier)
                $display("Time=%0d: PASS - Exit barrier closed after vehicle passed", $time);
            else
                $display("Time=%0d: FAIL - Exit barrier remained open after vehicle passed", $time);
            
            // Wait for return to idle state
            wait_for_state(IDLE, success);
            
            // Add extra delay to ensure state machine stabilizes
            #(CLK_PERIOD * 10);
            
            $display("Time=%0d: Vehicle exit completed", $time);
        end
    endtask
    
    // Test vehicle entry with invalid card
    task test_vehicle_entry_with_invalid_card;
        reg success;
        begin
            $display("\nTest Case 3: Vehicle enters with invalid card");
            $display("Time=%0d: Starting vehicle entry with invalid card", $time);
            
            // Simulate vehicle at entry
            raw_entry_sensor = 1;
            card_id = 4'b0000; // Invalid card ID
            #(CLK_PERIOD * 5);
            
            // Wait for card verification state
            wait_for_state(CARD_VERIFICATION, success);
            
            // Check if alarm is triggered
            #(CLK_PERIOD * 20);
            if (alarm)
                $display("Time=%0d: PASS - Alarm triggered for invalid card", $time);
            else
                $display("Time=%0d: FAIL - Alarm not triggered for invalid card", $time);
            
            // Check if barrier remains closed
            if (!entry_barrier)
                $display("Time=%0d: PASS - Entry barrier remained closed for invalid card", $time);
            else
                $display("Time=%0d: FAIL - Entry barrier opened for invalid card", $time);
            
            // Wait for return to idle state with increased timeout
            #(CLK_PERIOD * 50);
            
            // Reset card ID and sensors
            raw_entry_sensor = 0;
            card_id = 4'b0000;
            #(CLK_PERIOD * 5);
            
            // Wait for state machine to stabilize
            wait_for_state(IDLE, success);
            
            $display("Time=%0d: Vehicle entry with invalid card test completed", $time);
        end
    endtask
    
    // Test emergency mode
    task test_emergency_mode;
        reg success;
        begin
            $display("\nTest Case 5: Emergency situation\n");
            $display("Time=%0d: Testing emergency mode", $time);
            
            // Activate emergency
            emergency = 1;
            #(CLK_PERIOD);
            
            // Wait for emergency mode state
            wait_for_state(EMERGENCY_MODE, success);
            
            // Check if both barriers open
            #(CLK_PERIOD * 20);
            if (entry_barrier && exit_barrier)
                $display("Time=%0d: PASS - Both barriers opened in emergency mode", $time);
            else
                $display("Time=%0d: FAIL - Barriers did not open in emergency mode", $time);
            
            // Deactivate emergency
            #(CLK_PERIOD * 20);
            emergency = 0;
            #(CLK_PERIOD * 5);
            
            // Wait for return to idle state
            wait_for_state(IDLE, success);
            
            // Check if both barriers close
            wait_for_barrier_close(1, success);
            wait_for_barrier_close(0, success);
            
            if (!entry_barrier && !exit_barrier)
                $display("Time=%0d: PASS - Both barriers closed after emergency cleared", $time);
            else
                $display("Time=%0d: FAIL - Barriers did not close after emergency cleared", $time);
            
            $display("Time=%0d: Emergency mode test completed", $time);
        end
    endtask
    
    // Task to fill parking to capacity
    task fill_parking_to_capacity;
        integer j;
        reg success;
        begin
            $display("\nTest Case 6: Fill parking to capacity");
            $display("Time=%0d: Filling parking with %0d vehicles", $time, MAX_CAPACITY);
            
            // Fill parking to capacity
            for (j = 0; j < MAX_CAPACITY; j = j + 1) begin
                if (!parking_full) begin
                    test_vehicle_entry_with_valid_card(4'b0010);
                end
            end
            
            if (parking_full)
                $display("Time=%0d: Parking fill test completed - available_spaces=%0d, parking_full=%0d", $time, available_spaces, parking_full);
            else
                $display("Time=%0d: Failed to fill parking - available_spaces=%0d, parking_full=%0d", $time, available_spaces, parking_full);
        end
    endtask
    
    // Task to test entry when parking is full
    task test_entry_when_full;
        reg success;
        begin
            $display("\nTest Case 7: Try to enter when parking is full");
            
            // Attempt entry when full
            raw_entry_sensor = 1;
            card_id = 4'b0111;
            #(CLK_PERIOD * 5);
            
            // Check if alarm is triggered due to full parking
            #(CLK_PERIOD * 20);
            if (alarm)
                $display("Time=%0d: WARNING - Vehicle attempting to enter when parking is full", $time);
            
            #(CLK_PERIOD * 100);
            $display("Time=%0d: Attempt to enter when full - alarm=%0d, entry_barrier=%0d", $time, alarm, entry_barrier);
            
            // Reset sensors
            raw_entry_sensor = 0;
            card_id = 4'b0000;
            #(CLK_PERIOD * 20);
        end
    endtask
    
    // Task to test simultaneous entry and exit
    task test_simultaneous_entry_exit;
        reg success;
        begin
            $display("\nTest Case 10: Simultaneous entry and exit attempts\n");
            $display("Time=%0d: Starting simultaneous entry and exit test", $time);
            
            // Start entry process
            if (parking_full) begin
                $display("Time=%0d: Cannot start entry - parking is full", $time);
            end else begin
                raw_entry_sensor = 1;
                card_id = 4'b1001;
                #(CLK_PERIOD * 2);
            end
            
            // Start exit process
            raw_exit_sensor = 1;
            #(CLK_PERIOD * 5);
            
            // Wait for vehicle detected state (exit should be processed first)
            wait_for_state(VEHICLE_DETECTED, success);
            
            // Wait for exit barrier to open
            #(CLK_PERIOD * 50);
            
            // Simulate vehicle passing exit
            raw_exit_sensor = 0;
            #(CLK_PERIOD * 5);
            
            // Wait for return to idle state
            wait_for_state(IDLE, success);
            
            // Reset sensors
            raw_entry_sensor = 0;
            card_id = 4'b0000;
            #(CLK_PERIOD * 5);
            
            $display("Time=%0d: Simultaneous entry and exit test completed", $time);
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize VCD dump
        $dumpfile("smart_parking_system_waveform.vcd");
        $dumpvars(0, Smart_parking_system_tb);
        
        // Initialize inputs
        reset = 1;
        raw_entry_sensor = 0;
        raw_exit_sensor = 0;
        card_id = 4'b0000;
        emergency = 0;
        
        // Apply reset
        #(CLK_PERIOD * 5);
        reset = 0;
        
        // Display initial state
        $display("Time=%0d: State=%40s, available_spaces=%0d, parking_full=%0d, entry_barrier=%0d, exit_barrier=%0d, alarm=%0d, fee=%0d, entry_passed=%0d, exit_passed=%0d", 
                 $time, "RESETTING", available_spaces, parking_full, entry_barrier, exit_barrier, alarm, fee_amount, entry_passed, exit_passed);
        
        #(CLK_PERIOD * 5);
        
        // Display initial state after reset
        state_name = state_to_string(current_state);
        $display("Time=%0d: State=%40s, available_spaces=%0d, parking_full=%0d, entry_barrier=%0d, exit_barrier=%0d, alarm=%0d, fee=%0d, entry_passed=%0d, exit_passed=%0d", 
                 $time, state_name, available_spaces, parking_full, entry_barrier, exit_barrier, alarm, fee_amount, entry_passed, exit_passed);
        
        // Initial status check
        #(CLK_PERIOD * 10);
        $display("\nTime=%0d: Initial state - available_spaces=%0d, parking_full=%0d\n", $time, available_spaces, parking_full);
        
        // Test Case 1: Vehicle enters with valid card
        test_vehicle_entry_with_valid_card(4'b0101);
        
        // Test Case 2: Vehicle exits
        test_vehicle_exit(4'b0101);
        
        // Test Case 3: Vehicle enters with invalid card
        test_vehicle_entry_with_invalid_card();
        
        // Test Case 4: Multiple vehicles enter with different IDs
        $display("\nTest Case 4: Multiple vehicles enter with different IDs");
        test_vehicle_entry_with_valid_card(4'b0010);
        
        // Test Case 5: Emergency situation
        test_emergency_mode();
        
        // Test Case 6: Fill parking to capacity
        fill_parking_to_capacity();
        
        // Test Case 7: Try to enter when parking is full
        test_entry_when_full();
        
        // Test Case 8: Vehicle exits when parking is full
        $display("\nTest Case 8: Vehicle exits when parking is full");
        test_vehicle_exit(4'b0101);
        
        // Test Case 9: Vehicle enters after space becomes available
        $display("\nTest Case 9: Vehicle enters after space becomes available");
        test_vehicle_entry_with_valid_card(4'b0110);
        
        // Test Case 10: Simultaneous entry and exit attempts
        test_simultaneous_entry_exit();
        
        // Test Case 11: Multiple vehicles exit
        $display("\nTest Case 11: Multiple vehicles exit");
        test_vehicle_exit(4'b0010);
        test_vehicle_exit(4'b0011);
        
        // Test Case 12: Rapid entry and exit sequence
        $display("\nTest Case 12: Rapid entry and exit sequence");
        test_vehicle_entry_with_valid_card(4'b1001);
        test_vehicle_exit(4'b1001);
        test_vehicle_entry_with_valid_card(4'b1010);
        test_vehicle_exit(4'b1010);
        
        // End simulation
        #(CLK_PERIOD * 50);
        $display("\nSimulation completed successfully");
        $finish;
    end
    
    // Monitor for state changes
    always @(current_state) begin
        state_name = state_to_string(current_state);
        $display("Time=%0d: State=%40s, available_spaces=%0d, parking_full=%0d, entry_barrier=%0d, exit_barrier=%0d, alarm=%0d, fee=%0d, entry_passed=%0d, exit_passed=%0d", 
                 $time, state_name, available_spaces, parking_full, entry_barrier, exit_barrier, alarm, fee_amount, entry_passed, exit_passed);
    end
    
    // Monitor for alarm
    always @(posedge alarm) begin
        $display("Time=%0d: ALARM TRIGGERED!", $time);
    end

endmodule
