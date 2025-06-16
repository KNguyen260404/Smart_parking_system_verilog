module Display_module_tb;
    // Parameters
    parameter CLK_PERIOD = 10;       // Clock period in ns
    parameter REFRESH_RATE = 100;    // Shorter refresh rate for simulation
    
    // Testbench signals
    reg clk;
    reg reset;
    reg [5:0] vehicle_count;
    reg [5:0] available_spaces;
    reg [2:0] current_state;
    reg [1:0] barrier_status;
    reg alarm;
    reg [7:0] fee_amount;
    
    wire [7:0] segment_display;
    wire [3:0] digit_select;
    wire [3:0] led_indicators;
    
    // State names for display
    reg [64*8-1:0] state_name;
    
    // Instantiate the Unit Under Test (UUT)
    Display_module #(
        .REFRESH_RATE(REFRESH_RATE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .vehicle_count(vehicle_count),
        .available_spaces(available_spaces),
        .current_state(current_state),
        .barrier_status(barrier_status),
        .alarm(alarm),
        .fee_amount(fee_amount),
        .segment_display(segment_display),
        .digit_select(digit_select),
        .led_indicators(led_indicators)
    );
    
    // VCD file generation for GTKWave
    initial begin
        $dumpfile("display_module_waveform.vcd");
        $dumpvars(0, Display_module_tb);
    end
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Function to convert state to string for display
    always @(*) begin
        case(current_state)
            3'b000: state_name = "IDLE";
            3'b001: state_name = "VEHICLE_DETECTED";
            3'b010: state_name = "CARD_VERIFICATION";
            3'b011: state_name = "OPEN_BARRIER";
            3'b100: state_name = "VEHICLE_PASSING";
            3'b101: state_name = "CLOSE_BARRIER";
            3'b110: state_name = "UPDATE_COUNT";
            3'b111: state_name = "EMERGENCY_MODE";
            default: state_name = "UNKNOWN";
        endcase
    end
    
    // Function to convert barrier status to string
    function [64*8-1:0] barrier_status_to_string;
        input [1:0] status;
        begin
            case(status)
                2'b00: barrier_status_to_string = "BARRIERS_CLOSED";
                2'b01: barrier_status_to_string = "ENTRY_OPEN";
                2'b10: barrier_status_to_string = "EXIT_OPEN";
                2'b11: barrier_status_to_string = "BOTH_OPEN";
                default: barrier_status_to_string = "UNKNOWN";
            endcase
        end
    endfunction
    
    // Function to decode 7-segment display
    function [3:0] decode_7segment;
        input [7:0] segment;
        begin
            case(segment)
                8'b11000000: decode_7segment = 4'd0;
                8'b11111001: decode_7segment = 4'd1;
                8'b10100100: decode_7segment = 4'd2;
                8'b10110000: decode_7segment = 4'd3;
                8'b10011001: decode_7segment = 4'd4;
                8'b10010010: decode_7segment = 4'd5;
                8'b10000010: decode_7segment = 4'd6;
                8'b11111000: decode_7segment = 4'd7;
                8'b10000000: decode_7segment = 4'd8;
                8'b10010000: decode_7segment = 4'd9;
                default: decode_7segment = 4'd15; // Invalid
            endcase
        end
    endfunction
    
    // Display selected digit and LED status
    always @(digit_select or segment_display or led_indicators) begin
        $display("Time=%0t: Digit Select=%b, Segment Display=%b (Value=%0d), LEDs=%b", 
                 $time, digit_select, segment_display, decode_7segment(segment_display), led_indicators);
    end
    
    // Test stimulus
    initial begin
        // Initialize inputs
        reset = 1;
        vehicle_count = 6'd0;
        available_spaces = 6'd63;
        current_state = 3'b000; // IDLE
        barrier_status = 2'b00; // BARRIERS_CLOSED
        alarm = 0;
        fee_amount = 8'd0;
        
        // Apply reset
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD*10);
        
        // Display initial state
        $display("\nTime=%0t: Initial state - vehicle_count=%0d, available_spaces=%0d, state=%s, barrier_status=%s", 
                 $time, vehicle_count, available_spaces, state_name, barrier_status_to_string(barrier_status));
        
        // Test Case 1: Normal parking operation
        $display("\nTest Case 1: Normal parking operation");
        vehicle_count = 6'd5;
        available_spaces = 6'd58;
        current_state = 3'b000; // IDLE
        #(CLK_PERIOD*REFRESH_RATE*10); // Wait for display refresh cycles
        
        // Test Case 2: Vehicle detected
        $display("\nTest Case 2: Vehicle detected");
        current_state = 3'b001; // VEHICLE_DETECTED
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 3: Card verification
        $display("\nTest Case 3: Card verification");
        current_state = 3'b010; // CARD_VERIFICATION
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 4: Open barrier
        $display("\nTest Case 4: Open barrier");
        current_state = 3'b011; // OPEN_BARRIER
        barrier_status = 2'b01; // ENTRY_OPEN
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 5: Vehicle passing
        $display("\nTest Case 5: Vehicle passing");
        current_state = 3'b100; // VEHICLE_PASSING
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 6: Close barrier
        $display("\nTest Case 6: Close barrier");
        current_state = 3'b101; // CLOSE_BARRIER
        barrier_status = 2'b00; // BARRIERS_CLOSED
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 7: Update count
        $display("\nTest Case 7: Update count");
        current_state = 3'b110; // UPDATE_COUNT
        vehicle_count = 6'd6;
        available_spaces = 6'd57;
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 8: Low space warning
        $display("\nTest Case 8: Low space warning");
        vehicle_count = 6'd60;
        available_spaces = 6'd3;
        current_state = 3'b000; // IDLE
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 9: Parking full
        $display("\nTest Case 9: Parking full");
        vehicle_count = 6'd63;
        available_spaces = 6'd0;
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 10: Fee calculation
        $display("\nTest Case 10: Fee calculation");
        fee_amount = 8'd75; // $75 fee
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 11: Alarm triggered
        $display("\nTest Case 11: Alarm triggered");
        alarm = 1;
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 12: Emergency mode
        $display("\nTest Case 12: Emergency mode");
        current_state = 3'b111; // EMERGENCY_MODE
        barrier_status = 2'b11; // BOTH_OPEN
        #(CLK_PERIOD*REFRESH_RATE*10); // Wait longer to see LED blinking
        
        // Test Case 13: Exit operation
        $display("\nTest Case 13: Exit operation");
        alarm = 0;
        current_state = 3'b001; // VEHICLE_DETECTED
        barrier_status = 2'b00; // BARRIERS_CLOSED
        #(CLK_PERIOD*REFRESH_RATE*2);
        
        current_state = 3'b011; // OPEN_BARRIER
        barrier_status = 2'b10; // EXIT_OPEN
        #(CLK_PERIOD*REFRESH_RATE*2);
        
        current_state = 3'b100; // VEHICLE_PASSING
        #(CLK_PERIOD*REFRESH_RATE*2);
        
        current_state = 3'b101; // CLOSE_BARRIER
        barrier_status = 2'b00; // BARRIERS_CLOSED
        #(CLK_PERIOD*REFRESH_RATE*2);
        
        current_state = 3'b110; // UPDATE_COUNT
        vehicle_count = 6'd62;
        available_spaces = 6'd1;
        #(CLK_PERIOD*REFRESH_RATE*2);
        
        current_state = 3'b000; // IDLE
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // Test Case 14: Reset during operation
        $display("\nTest Case 14: Reset during operation");
        reset = 1;
        #(CLK_PERIOD*2);
        reset = 0;
        vehicle_count = 6'd0;
        available_spaces = 6'd63;
        current_state = 3'b000; // IDLE
        barrier_status = 2'b00; // BARRIERS_CLOSED
        alarm = 0;
        fee_amount = 8'd0;
        #(CLK_PERIOD*REFRESH_RATE*5);
        
        // End simulation
        $display("\nSimulation completed successfully");
        $finish;
    end
endmodule 