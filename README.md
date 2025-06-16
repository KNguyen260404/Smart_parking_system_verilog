# Smart Parking System

## Project Overview
The Smart Parking System is a digital design project implemented in Verilog that simulates an automated parking management system. It provides real-time monitoring of available parking spaces, automated entry/exit barriers, and fee calculation based on parking duration.

## System Architecture
The system consists of six main modules:

1. **Vehicle Counter Module**: Counts entering/exiting vehicles and tracks available spaces
2. **Barrier Control Module**: Controls entry/exit barriers
3. **Sensor Interface Module**: Processes sensor signals
4. **Display Module**: Manages all user-facing displays
5. **Fee Calculator Module**: Calculates parking fees
6. **FSM Control Module**: Manages system state and coordinates all modules

### Module Connections
![Module Connections](./image/module_connections.png)

## Specifications

- **Clock frequency**: 50MHz
- **Maximum parking capacity**: 100 vehicles
- **Barrier operation time**: 3 seconds for opening/closing
- **Card verification time**: 2 seconds
- **Fee calculation types**: Hourly (5₫/hour), Daily (50₫/day), Weekly (200₫/week)
- **Sensor debounce delay**: 100ms
- **Display refresh rate**: 1kHz (7-segment LED display)
- **Vehicle detection timeout**: 10 seconds
- **Emergency response time**: <500ms
- **Supported interfaces**: Entry/exit sensors, card reader, barrier control, LED displays
- **Data storage**: Up to 1000 vehicle records (entry/exit times)

### Hardware Requirements
1. **Hardware Platform**: FPGA board (Xilinx/Altera recommended)
2. **Development Tools**: 
   - Verilog HDL compatible IDE (Vivado/Quartus/ModelSim)
   - Simulation tools for testing

### Functional Requirements

#### 1. Vehicle Detection
- Detect vehicles at entry and exit points using sensors
- Process raw sensor signals to generate clean detection signals
- Confirm vehicle passage through entry/exit points

#### 2. Barrier Control
- Automated opening/closing of entry and exit barriers
- Safety measures to prevent barrier closing while vehicle is passing
- Emergency override capability for all barriers

#### 3. Space Management
- Track total number of vehicles in the parking area
- Calculate and display available parking spaces
- Prevent entry when parking is full

#### 4. Authentication
- Card/ID verification before entry/exit
- Support for different access levels (optional)

#### 5. Fee Calculation
- Record entry time for each vehicle
- Calculate parking fee based on duration
- Display fee amount at exit

#### 6. User Interface
- 7-segment display showing available spaces
- Status indicators for system state
- Fee display at exit points
- Visual/audible alarms for error conditions

### Technical Specifications

#### Input/Output Ports
| Port | Bus size | Direction | Description |
|:----:|:--------:|:---------:|:------------|
| clk | 1 | input | System clock signal |
| reset | 1 | input | Synchronous reset, active-high |
| raw_entry_sensor | 1 | input | Raw signal from entry sensor |
| raw_exit_sensor | 1 | input | Raw signal from exit sensor |
| card_id | 4 | input | Card/ID for authentication |
| emergency | 1 | input | Emergency signal |
| entry_barrier | 1 | output | Entry barrier control: 0: closed, 1: open |
| exit_barrier | 1 | output | Exit barrier control: 0: closed, 1: open |
| available_spaces | 8 | output | Number of available parking spaces (0-100) |
| segment_display | 8 | output | 7-segment display control signal |
| digit_select | 4 | output | Digit selection for display |
| parking_full | 1 | output | Indicator when parking is full |
| alarm | 1 | output | Alarm signal |
| led_indicators | 4 | output | System status LED indicators |
| fee_amount | 8 | output | Parking fee amount |

### State Machine
The system operates using a finite state machine with the following states:
- IDLE
- VEHICLE_DETECTED
- CARD_VERIFICATION
- OPEN_BARRIER
- VEHICLE_PASSING
- CLOSE_BARRIER
- UPDATE_COUNT
- ALARM
- EMERGENCY_MODE
- RESET

#### State Machine Diagram
```
+-------+                +------------------+                +-----------------+
|       |  entry_sensor  |                  |  card_valid    |                 |
| IDLE  +----------------> VEHICLE_DETECTED +----------------> OPEN_BARRIER    |
|       <----------------+                  |                |                 |
+---+---+  return_to_idle+--+---------------+                +------+----------+
    ^                       |                                       |
    |                       | card_invalid                          |
    |                       v                                       |
    |                    +--+---------------+                       |
    |                    |                  |                       |
    |                    |      ALARM       |                       |
    |                    |                  |                       |
    |                    +------------------+                       |
    |                                                               |
    |                                                               |
    |                                                               v
+---+---+                +------------------+                +------+----------+
|       |  update_done   |                  |  barrier_closed|                 |
| IDLE  <----------------+ UPDATE_COUNT     <----------------+ CLOSE_BARRIER   |
|       |                |                  |                |                 |
+-------+                +--+---------------+                +------+----------+
                            ^                                       |
                            |                                       |
                            |                                       |
                            |                +------------------+   |
                            |                |                  |   |
                            +----------------+ VEHICLE_PASSING  <---+
                             vehicle_passed  |                  |
                                             +------------------+
```

### System Operation Flow

#### Entry Process
1. **Sensor Interface Module** detects vehicle arrival (raw_entry_sensor → entry_sensor)
2. **FSM Control Module** receives signal and checks with **Vehicle Counter Module** if parking is available
3. **FSM Control Module** requests card verification and checks validity
4. **FSM Control Module** sends open barrier command (open_entry) to **Barrier Control Module**
5. **Barrier Control Module** opens entry barrier (entry_barrier = 1)
6. **Sensor Interface Module** detects vehicle passage (entry_passed = 1)
7. **FSM Control Module** sends close barrier command (close_entry) to **Barrier Control Module**
8. **Vehicle Counter Module** increments vehicle count and updates available spaces
9. **Display Module** updates the available spaces display

#### Exit Process
1. **Sensor Interface Module** detects vehicle at exit (raw_exit_sensor → exit_sensor)
2. **FSM Control Module** receives signal and requests card verification
3. **FSM Control Module** sends calculate fee command (calculate_fee) to **Fee Calculator Module**
4. **Fee Calculator Module** calculates fee and sends result (fee_amount) to **Display Module**
5. **FSM Control Module** sends open barrier command (open_exit) to **Barrier Control Module**
6. **Barrier Control Module** opens exit barrier (exit_barrier = 1)
7. **Sensor Interface Module** detects vehicle passage (exit_passed = 1)
8. **FSM Control Module** sends close barrier command (close_exit) to **Barrier Control Module**
9. **Vehicle Counter Module** decrements vehicle count and updates available spaces
10. **Display Module** updates the available spaces display

## Directory Structure
```
Smart_Parking_System/
├── Barrier_control/      # Barrier control module files
├── Display_module/       # Display module files
├── Fee_calculator/       # Fee calculator module files
├── FSM_control/          # FSM control module files
├── Sensor_interface/     # Sensor interface module files
├── Vehicle_counter/      # Vehicle counter module files
├── image/                # Documentation images
├── README.md             # Project documentation
└── backup/               # Backup files
```

## Testing Strategy
1. **Module Testing**: Individual test benches for each module
2. **Integration Testing**: Combined module testing
3. **System Testing**: Full system simulation with various scenarios:
   - Normal entry/exit flow
   - Full parking lot handling
   - Emergency situations
   - Error conditions

## Implementation Requirements
For physical implementation, the following components are needed:
1. FPGA or development board
2. Infrared or ultrasonic sensors for vehicle detection
3. Servo motors for barrier control
4. LED displays
5. Power supply

## Extension Possibilities
1. **Time Display**: Add parking duration display
2. **Advanced Fee Calculation**: Variable rates based on time of day
3. **Specific Parking Spot Management**: Track and display specific available spots
4. **License Plate Recognition**: Simulated license plate recognition
5. **Payment System Integration**: Interface with payment systems

## Implementation Guidelines
1. Use synchronous design principles
2. Implement debouncing for all sensor inputs
3. Use parameterized modules for flexibility
4. Include comprehensive test benches for each module
5. Document all module interfaces and state transitions 