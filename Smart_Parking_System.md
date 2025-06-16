# Dự án Hệ thống bãi đậu xe thông minh (Smart Parking System)

## Mô tả dự án
Thiết kế một hệ thống bãi đậu xe thông minh sử dụng Verilog, có khả năng đếm số chỗ trống, điều khiển barrier ra vào và hiển thị thông tin cho người dùng. Dự án này sẽ mô phỏng hoạt động của một bãi đậu xe thực tế với các chức năng tự động hóa.

## Yêu cầu chức năng
1. Đếm số xe vào và ra khỏi bãi đậu xe
2. Hiển thị số chỗ trống còn lại
3. Điều khiển barrier ra vào tự động
4. Phát hiện xe bằng cảm biến (được mô phỏng bằng đầu vào)
5. Cảnh báo khi bãi đậu xe đầy
6. Tính toán và hiển thị phí đậu xe (tùy chọn)

## Thiết kế hệ thống

### Đặc tả đầu vào - đầu ra
| Port | Bus size | Direction | Description |
|:----:|:--------:|:---------:|:------------|
| clk | 1 | input | Tín hiệu đồng hồ hệ thống |
| reset | 1 | input | Tín hiệu reset đồng bộ, active-high |
| raw_entry_sensor | 1 | input | Tín hiệu thô từ cảm biến phát hiện xe vào |
| raw_exit_sensor | 1 | input | Tín hiệu thô từ cảm biến phát hiện xe ra |
| card_id | 4 | input | Mã số thẻ để xác thực |
| emergency | 1 | input | Tín hiệu khẩn cấp |
| entry_barrier | 1 | output | Điều khiển barrier vào: 0: đóng, 1: mở |
| exit_barrier | 1 | output | Điều khiển barrier ra: 0: đóng, 1: mở |
| available_spaces | 6 | output | Số lượng chỗ đỗ xe còn trống (0-63) |
| segment_display | 8 | output | Tín hiệu điều khiển đèn LED 7 đoạn |
| digit_select | 4 | output | Chọn chữ số hiển thị trên LED 7 đoạn |
| parking_full | 1 | output | Báo hiệu bãi đỗ xe đã đầy |
| alarm | 1 | output | Tín hiệu cảnh báo |
| led_indicators | 4 | output | Đèn LED chỉ thị trạng thái hệ thống |
| fee_amount | 8 | output | Số tiền phí đỗ xe |

### Các module chính
1. **Vehicle Counter Module**: Đếm số xe vào và ra
2. **Barrier Control Module**: Điều khiển barrier ra vào
3. **Sensor Interface Module**: Giao tiếp với cảm biến phát hiện xe
4. **Display Module**: Hiển thị thông tin cho người dùng
5. **Fee Calculator Module**: Tính toán phí đậu xe
6. **FSM Control Module**: Điều khiển máy trạng thái của hệ thống

### Đầu vào/Đầu ra của các module

#### 1. Vehicle Counter Module
| Port | Bus size | Direction | Kết nối |
|:----:|:--------:|:---------:|:--------|
| clk | 1 | input | Từ hệ thống |
| reset | 1 | input | Từ hệ thống |
| entry_passed | 1 | input | Từ Sensor Interface Module |
| exit_passed | 1 | input | Từ Sensor Interface Module |
| max_capacity | 6 | input | Từ cài đặt hệ thống |
| vehicle_count | 6 | output | → FSM Control Module<br>→ Display Module |
| available_spaces | 6 | output | → Display Module<br>→ Đầu ra hệ thống (available_spaces) |
| parking_full | 1 | output | → FSM Control Module<br>→ Display Module<br>→ Đầu ra hệ thống (parking_full) |

#### 2. Barrier Control Module
| Port | Bus size | Direction | Kết nối |
|:----:|:--------:|:---------:|:--------|
| clk | 1 | input | Từ hệ thống |
| reset | 1 | input | Từ hệ thống |
| open_entry | 1 | input | Từ FSM Control Module |
| open_exit | 1 | input | Từ FSM Control Module |
| close_entry | 1 | input | Từ FSM Control Module |
| close_exit | 1 | input | Từ FSM Control Module |
| emergency | 1 | input | Từ hệ thống |
| vehicle_direction | 1 | input | Từ cảm biến (0: vào, 1: ra) |
| entry_barrier | 1 | output | → Cơ chế barrier vào<br>→ Đầu ra hệ thống |
| exit_barrier | 1 | output | → Cơ chế barrier ra<br>→ Đầu ra hệ thống |
| barrier_status | 2 | output | → FSM Control Module<br>→ Display Module |

#### 3. Sensor Interface Module
| Port | Bus size | Direction | Kết nối |
|:----:|:--------:|:---------:|:--------|
| clk | 1 | input | Từ hệ thống |
| reset | 1 | input | Từ hệ thống |
| raw_entry_sensor | 1 | input | Từ cảm biến vào |
| raw_exit_sensor | 1 | input | Từ cảm biến ra |
| entry_sensor | 1 | output | → FSM Control Module |
| exit_sensor | 1 | output | → FSM Control Module |
| entry_passed | 1 | output | → FSM Control Module<br>→ Vehicle Counter Module |
| exit_passed | 1 | output | → FSM Control Module<br>→ Vehicle Counter Module |

#### 4. Display Module
| Port | Bus size | Direction | Kết nối |
|:----:|:--------:|:---------:|:--------|
| clk | 1 | input | Từ hệ thống |
| reset | 1 | input | Từ hệ thống |
| vehicle_count | 6 | input | Từ Vehicle Counter Module |
| available_spaces | 6 | input | Từ Vehicle Counter Module |
| current_state | 3 | input | Từ FSM Control Module |
| barrier_status | 2 | input | Từ Barrier Control Module |
| alarm | 1 | input | Từ FSM Control Module |
| fee_amount | 8 | input | Từ Fee Calculator Module |
| segment_display | 8 | output | → Đầu ra hệ thống |
| digit_select | 4 | output | → Đầu ra hệ thống |
| led_indicators | 4 | output | → Đầu ra hệ thống |

#### 5. Fee Calculator Module
| Port | Bus size | Direction | Kết nối |
|:----:|:--------:|:---------:|:--------|
| clk | 1 | input | Từ hệ thống |
| reset | 1 | input | Từ hệ thống |
| entry_time | 32 | input | Từ hệ thống thời gian |
| exit_time | 32 | input | Từ hệ thống thời gian |
| vehicle_id | 8 | input | Từ hệ thống xác thực |
| calculate_fee | 1 | input | Từ FSM Control Module |
| fee_amount | 8 | output | → Display Module<br>→ Đầu ra hệ thống (fee_amount) |
| fee_valid | 1 | output | → FSM Control Module |

#### 6. FSM Control Module
| Port | Bus size | Direction | Kết nối |
|:----:|:--------:|:---------:|:--------|
| clk | 1 | input | Từ hệ thống |
| reset | 1 | input | Từ hệ thống |
| entry_sensor | 1 | input | Từ Sensor Interface Module |
| exit_sensor | 1 | input | Từ Sensor Interface Module |
| entry_passed | 1 | input | Từ Sensor Interface Module |
| exit_passed | 1 | input | Từ Sensor Interface Module |
| parking_full | 1 | input | Từ Vehicle Counter Module |
| card_id | 4 | input | Từ người dùng |
| card_valid | 1 | input | Từ hệ thống xác thực |
| emergency | 1 | input | Từ hệ thống |
| barrier_status | 2 | input | Từ Barrier Control Module |
| fee_valid | 1 | input | Từ Fee Calculator Module |
| current_state | 3 | output | → Display Module<br>→ Đầu ra hệ thống (state_out) |
| open_entry | 1 | output | → Barrier Control Module |
| open_exit | 1 | output | → Barrier Control Module |
| close_entry | 1 | output | → Barrier Control Module |
| close_exit | 1 | output | → Barrier Control Module |
| alarm | 1 | output | → Display Module<br>→ Đầu ra hệ thống |
| calculate_fee | 1 | output | → Fee Calculator Module |
| verify_card | 1 | output | → Hệ thống xác thực |

### Liên kết giữa các module

Sơ đồ liên kết giữa các module trong hệ thống bãi đỗ xe thông minh:

![Sơ đồ liên kết giữa các module](./image/module_connections.png)

Mô hình liên kết giữa các module:

1. **Sensor Interface Module** → **FSM Control Module**:
   - Truyền các tín hiệu: entry_sensor, exit_sensor, entry_passed, exit_passed
   - FSM Control Module sử dụng các tín hiệu này để xác định trạng thái tiếp theo

2. **Sensor Interface Module** → **Vehicle Counter Module**:
   - Truyền các tín hiệu: entry_passed, exit_passed
   - Vehicle Counter Module sử dụng để cập nhật số lượng xe

3. **Vehicle Counter Module** → **FSM Control Module**:
   - Truyền các tín hiệu: vehicle_count, parking_full
   - FSM Control Module sử dụng để quyết định có cho phép xe vào không

4. **Vehicle Counter Module** → **Display Module**:
   - Truyền các tín hiệu: vehicle_count, available_spaces
   - Display Module hiển thị thông tin này cho người dùng

5. **FSM Control Module** → **Barrier Control Module**:
   - Truyền các lệnh: open_entry, open_exit, close_entry, close_exit
   - Barrier Control Module thực hiện các lệnh điều khiển barrier

6. **Barrier Control Module** → **FSM Control Module**:
   - Truyền trạng thái: barrier_status
   - FSM Control Module biết được trạng thái hiện tại của barrier

7. **FSM Control Module** → **Display Module**:
   - Truyền các tín hiệu: current_state, alarm
   - Display Module hiển thị trạng thái và cảnh báo

8. **FSM Control Module** → **Fee Calculator Module**:
   - Truyền lệnh: calculate_fee
   - Fee Calculator Module bắt đầu tính toán phí

9. **Fee Calculator Module** → **Display Module**:
   - Truyền kết quả: fee_amount
   - Display Module hiển thị số tiền phí

10. **Fee Calculator Module** → **FSM Control Module**:
    - Truyền tín hiệu: fee_valid
    - FSM Control Module biết rằng phí đã được tính xong

### Máy trạng thái (FSM)

```
IDLE → VEHICLE_DETECTED → CARD_VERIFICATION → [thẻ hợp lệ → OPEN_BARRIER → VEHICLE_PASSING → CLOSE_BARRIER → UPDATE_COUNT → IDLE]
                                             → [thẻ không hợp lệ → ALARM → IDLE]
                        → [emergency → EMERGENCY_MODE → RESET → IDLE]
```

#### Sơ đồ máy trạng thái chi tiết

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

### Luồng hoạt động của hệ thống

1. **Khởi đầu**:
   - Hệ thống khởi tạo với barrier đóng, số xe = 0, số chỗ trống = MAX_CAPACITY
   - FSM Control Module ở trạng thái IDLE cho cả lối vào và lối ra

2. **Xe vào bãi đỗ**:
   - Sensor Interface Module phát hiện xe đến lối vào (entry_sensor = 1)
   - FSM Control Module nhận tín hiệu và kiểm tra trạng thái bãi đỗ (parking_full = 0)
   - FSM Control Module chuyển từ trạng thái IDLE sang VEHICLE_DETECTED
   - FSM Control Module yêu cầu xác thực thẻ (verify_card = 1)
   - Nếu thẻ hợp lệ (card_valid = 1), FSM Control Module chuyển sang OPEN_BARRIER
   - Nếu thẻ không hợp lệ (card_valid = 0), FSM Control Module chuyển sang ALARM rồi trở về IDLE
   - FSM Control Module gửi lệnh mở barrier vào (open_entry = 1)
   - Barrier Control Module mở barrier vào (entry_barrier = 1)
   - FSM Control Module chuyển sang trạng thái VEHICLE_PASSING
   - Sensor Interface Module phát hiện xe đã đi qua (entry_passed = 1)
   - FSM Control Module chuyển sang trạng thái CLOSE_BARRIER
   - FSM Control Module gửi lệnh đóng barrier vào (close_entry = 1)
   - Barrier Control Module đóng barrier vào (entry_barrier = 0)
   - FSM Control Module chuyển sang UPDATE_COUNT
   - Vehicle Counter Module tăng biến đếm xe (vehicle_count + 1) và giảm số chỗ trống (available_spaces - 1)
   - Display Module cập nhật hiển thị số chỗ trống mới
   - FSM Control Module trở về trạng thái IDLE

3. **Xe ra khỏi bãi đỗ**:
   - Sensor Interface Module phát hiện xe đến lối ra (exit_sensor = 1)
   - FSM Control Module nhận tín hiệu và kiểm tra nếu có xe trong bãi (vehicle_count > 0)
   - FSM Control Module chuyển từ trạng thái IDLE sang VEHICLE_DETECTED
   - FSM Control Module yêu cầu xác thực thẻ (verify_card = 1)
   - Nếu thẻ hợp lệ (card_valid = 1), FSM Control Module chuyển sang OPEN_BARRIER
   - FSM Control Module gửi lệnh tính phí (calculate_fee = 1)
   - Fee Calculator Module tính toán phí dựa trên thời gian đỗ xe
   - FSM Control Module gửi lệnh mở barrier ra (open_exit = 1)
   - Barrier Control Module mở barrier ra (exit_barrier = 1)
   - FSM Control Module chuyển sang trạng thái VEHICLE_PASSING
   - Sensor Interface Module phát hiện xe đã đi qua (exit_passed = 1)
   - FSM Control Module chuyển sang trạng thái CLOSE_BARRIER
   - FSM Control Module gửi lệnh đóng barrier ra (close_exit = 1)
   - Barrier Control Module đóng barrier ra (exit_barrier = 0)
   - FSM Control Module chuyển sang UPDATE_COUNT
   - Vehicle Counter Module giảm biến đếm xe (vehicle_count - 1) và tăng số chỗ trống (available_spaces + 1)
   - Display Module cập nhật hiển thị số chỗ trống mới và phí đỗ xe
   - FSM Control Module trở về trạng thái IDLE

4. **Bãi đỗ đầy**:
   - Khi Vehicle Counter Module phát hiện vehicle_count = MAX_CAPACITY, đặt parking_full = 1
   - FSM Control Module nhận tín hiệu parking_full = 1
   - FSM Control Module sẽ không chuyển sang trạng thái VEHICLE_DETECTED khi có xe đến lối vào (entry_sensor = 1)
   - Display Module hiển thị thông báo "FULL"

5. **Trường hợp khẩn cấp**:
   - Khi nhận tín hiệu emergency = 1
   - FSM Control Module chuyển sang trạng thái EMERGENCY_MODE
   - Barrier Control Module mở cả barrier vào và ra (entry_barrier = 1, exit_barrier = 1)
   - Display Module hiển thị thông báo khẩn cấp
   - Sau khi tình huống khẩn cấp được giải quyết (emergency = 0)
   - FSM Control Module chuyển sang RESET rồi về IDLE

## Mã Verilog

### Định nghĩa module chính
```verilog
module smart_parking_system #(
    parameter MAX_CAPACITY = 100,  // Sức chứa tối đa của bãi đậu xe
    parameter BARRIER_DELAY = 50   // Thời gian mở/đóng barrier (đơn vị: chu kỳ clock)
)(
    input wire clk,                // Xung clock hệ thống
    input wire reset,              // Reset hệ thống
    input wire entry_sensor,       // Cảm biến phát hiện xe ở lối vào
    input wire exit_sensor,        // Cảm biến phát hiện xe ở lối ra
    input wire entry_passed,       // Cảm biến xác nhận xe đã đi qua lối vào
    input wire exit_passed,        // Cảm biến xác nhận xe đã đi qua lối ra
    
    output reg entry_barrier,      // Điều khiển barrier lối vào (1: mở, 0: đóng)
    output reg exit_barrier,       // Điều khiển barrier lối ra (1: mở, 0: đóng)
    output reg [7:0] available_spaces,  // Số chỗ trống còn lại
    output reg parking_full,       // Báo hiệu bãi đậu xe đầy
    output reg [2:0] entry_state,  // Trạng thái của hệ thống tại lối vào
    output reg [2:0] exit_state    // Trạng thái của hệ thống tại lối ra
);

    // Định nghĩa các trạng thái
    parameter IDLE = 3'b000;
    parameter VEHICLE_DETECTED = 3'b001;
    parameter OPEN_BARRIER = 3'b010;
    parameter VEHICLE_PASSING = 3'b011;
    parameter CLOSE_BARRIER = 3'b100;
    
    // Biến đếm và điều khiển
    reg [7:0] vehicle_count;        // Số xe hiện tại trong bãi
    reg [15:0] entry_barrier_timer; // Bộ đếm thời gian cho barrier lối vào
    reg [15:0] exit_barrier_timer;  // Bộ đếm thời gian cho barrier lối ra
    
    // Khởi tạo
    initial begin
        entry_barrier = 0;
        exit_barrier = 0;
        vehicle_count = 0;
        available_spaces = MAX_CAPACITY;
        parking_full = 0;
        entry_state = IDLE;
        exit_state = IDLE;
        entry_barrier_timer = 0;
        exit_barrier_timer = 0;
    end
    
    // Xử lý trạng thái lối vào
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            entry_state <= IDLE;
            entry_barrier <= 0;
            entry_barrier_timer <= 0;
        end
        else begin
            case (entry_state)
                IDLE: begin
                    if (entry_sensor && !parking_full) begin
                        entry_state <= VEHICLE_DETECTED;
                    end
                end
                
                VEHICLE_DETECTED: begin
                    entry_state <= OPEN_BARRIER;
                    entry_barrier_timer <= 0;
                end
                
                OPEN_BARRIER: begin
                    entry_barrier <= 1;  // Mở barrier
                    
                    if (entry_barrier_timer >= BARRIER_DELAY) begin
                        entry_state <= VEHICLE_PASSING;
                        entry_barrier_timer <= 0;
                    end
                    else begin
                        entry_barrier_timer <= entry_barrier_timer + 1;
                    end
                end
                
                VEHICLE_PASSING: begin
                    if (entry_passed) begin
                        entry_state <= CLOSE_BARRIER;
                        entry_barrier_timer <= 0;
                    end
                end
                
                CLOSE_BARRIER: begin
                    if (entry_barrier_timer >= BARRIER_DELAY) begin
                        entry_barrier <= 0;  // Đóng barrier
                        entry_state <= IDLE;
                    end
                    else begin
                        entry_barrier_timer <= entry_barrier_timer + 1;
                    end
                end
                
                default: entry_state <= IDLE;
            endcase
        end
    end
    
    // Xử lý trạng thái lối ra
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            exit_state <= IDLE;
            exit_barrier <= 0;
            exit_barrier_timer <= 0;
        end
        else begin
            case (exit_state)
                IDLE: begin
                    if (exit_sensor && vehicle_count > 0) begin
                        exit_state <= VEHICLE_DETECTED;
                    end
                end
                
                VEHICLE_DETECTED: begin
                    exit_state <= OPEN_BARRIER;
                    exit_barrier_timer <= 0;
                end
                
                OPEN_BARRIER: begin
                    exit_barrier <= 1;  // Mở barrier
                    
                    if (exit_barrier_timer >= BARRIER_DELAY) begin
                        exit_state <= VEHICLE_PASSING;
                        exit_barrier_timer <= 0;
                    end
                    else begin
                        exit_barrier_timer <= exit_barrier_timer + 1;
                    end
                end
                
                VEHICLE_PASSING: begin
                    if (exit_passed) begin
                        exit_state <= CLOSE_BARRIER;
                        exit_barrier_timer <= 0;
                    end
                end
                
                CLOSE_BARRIER: begin
                    if (exit_barrier_timer >= BARRIER_DELAY) begin
                        exit_barrier <= 0;  // Đóng barrier
                        exit_state <= IDLE;
                    end
                    else begin
                        exit_barrier_timer <= exit_barrier_timer + 1;
                    end
                end
                
                default: exit_state <= IDLE;
            endcase
        end
    end
    
    // Đếm xe và cập nhật số chỗ trống
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            vehicle_count <= 0;
            available_spaces <= MAX_CAPACITY;
            parking_full <= 0;
        end
        else begin
            // Xe vào bãi đậu xe
            if (entry_state == VEHICLE_PASSING && entry_passed && vehicle_count < MAX_CAPACITY) begin
                vehicle_count <= vehicle_count + 1;
                available_spaces <= available_spaces - 1;
                
                if (vehicle_count + 1 >= MAX_CAPACITY)
                    parking_full <= 1;
            end
            
            // Xe ra khỏi bãi đậu xe
            if (exit_state == VEHICLE_PASSING && exit_passed && vehicle_count > 0) begin
                vehicle_count <= vehicle_count - 1;
                available_spaces <= available_spaces + 1;
                parking_full <= 0;
            end
        end
    end
endmodule
```

### Module hiển thị 7-đoạn
```verilog
module display_controller #(
    parameter CLK_FREQ = 50000000,  // Tần số clock (50MHz)
    parameter REFRESH_RATE = 1000   // Tần số làm mới màn hình (1kHz)
)(
    input wire clk,                // Xung clock hệ thống
    input wire reset,              // Reset hệ thống
    input wire [7:0] value,        // Giá trị cần hiển thị (0-99)
    
    output reg [6:0] segment,      // Đầu ra cho 7-đoạn (a-g)
    output reg [1:0] digit_select  // Chọn chữ số (0: hàng đơn vị, 1: hàng chục)
);

    // Biến nội bộ
    reg [3:0] digit_value;         // Giá trị của chữ số hiện tại (0-9)
    reg [15:0] refresh_counter;    // Bộ đếm làm mới màn hình
    wire refresh_tick;             // Xung làm mới màn hình
    
    // Tạo xung làm mới màn hình
    assign refresh_tick = (refresh_counter == 0);
    
    // Đếm chu kỳ làm mới
    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_counter <= 0;
        else begin
            if (refresh_counter >= (CLK_FREQ / REFRESH_RATE) - 1)
                refresh_counter <= 0;
            else
                refresh_counter <= refresh_counter + 1;
        end
    end
    
    // Chọn chữ số và giá trị hiển thị
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digit_select <= 0;
            digit_value <= 0;
        end
        else if (refresh_tick) begin
            // Luân phiên hiển thị các chữ số
            digit_select <= ~digit_select;
            
            // Chọn giá trị cho từng chữ số
            case (digit_select)
                1'b0: digit_value <= value % 10;        // Hàng đơn vị
                1'b1: digit_value <= (value / 10) % 10; // Hàng chục
            endcase
        end
    end
    
    // Chuyển đổi từ giá trị sang mã 7-đoạn
    always @(*) begin
        case (digit_value)
            4'd0: segment = 7'b1000000; // 0
            4'd1: segment = 7'b1111001; // 1
            4'd2: segment = 7'b0100100; // 2
            4'd3: segment = 7'b0110000; // 3
            4'd4: segment = 7'b0011001; // 4
            4'd5: segment = 7'b0010010; // 5
            4'd6: segment = 7'b0000010; // 6
            4'd7: segment = 7'b1111000; // 7
            4'd8: segment = 7'b0000000; // 8
            4'd9: segment = 7'b0010000; // 9
            default: segment = 7'b1111111; // Tắt
        endcase
    end
endmodule
```

### Testbench
```verilog
module smart_parking_system_tb;
    // Định nghĩa các tham số
    parameter MAX_CAPACITY = 10;  // Sức chứa tối đa của bãi đậu xe (nhỏ hơn để dễ mô phỏng)
    parameter BARRIER_DELAY = 5;  // Thời gian mở/đóng barrier (nhỏ hơn để dễ mô phỏng)
    
    // Định nghĩa các tín hiệu
    reg clk;
    reg reset;
    reg entry_sensor;
    reg exit_sensor;
    reg entry_passed;
    reg exit_passed;
    
    wire entry_barrier;
    wire exit_barrier;
    wire [7:0] available_spaces;
    wire parking_full;
    wire [2:0] entry_state;
    wire [2:0] exit_state;
    
    // Khởi tạo module
    smart_parking_system #(
        .MAX_CAPACITY(MAX_CAPACITY),
        .BARRIER_DELAY(BARRIER_DELAY)
    ) uut (
        .clk(clk),
        .reset(reset),
        .entry_sensor(entry_sensor),
        .exit_sensor(exit_sensor),
        .entry_passed(entry_passed),
        .exit_passed(exit_passed),
        .entry_barrier(entry_barrier),
        .exit_barrier(exit_barrier),
        .available_spaces(available_spaces),
        .parking_full(parking_full),
        .entry_state(entry_state),
        .exit_state(exit_state)
    );
    
    // Tạo xung clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz
    end
    
    // Chuyển đổi trạng thái thành chuỗi để hiển thị
    function [64*8-1:0] state_to_string;
        input [2:0] state;
        begin
            case (state)
                3'b000: state_to_string = "IDLE";
                3'b001: state_to_string = "VEHICLE_DETECTED";
                3'b010: state_to_string = "OPEN_BARRIER";
                3'b011: state_to_string = "VEHICLE_PASSING";
                3'b100: state_to_string = "CLOSE_BARRIER";
                default: state_to_string = "UNKNOWN";
            endcase
        end
    endfunction
    
    // Kịch bản kiểm tra
    initial begin
        // Khởi tạo
        reset = 1;
        entry_sensor = 0;
        exit_sensor = 0;
        entry_passed = 0;
        exit_passed = 0;
        
        #20;
        reset = 0;
        
        // Kịch bản 1: Xe vào bãi đậu xe
        // Xe đến lối vào
        #20 entry_sensor = 1;
        #10 entry_sensor = 0;
        
        // Đợi barrier mở
        wait(entry_barrier == 1);
        #30;
        
        // Xe đi qua lối vào
        entry_passed = 1;
        #10 entry_passed = 0;
        
        // Đợi barrier đóng
        wait(entry_barrier == 0);
        #50;
        
        // Kịch bản 2: Xe ra khỏi bãi đậu xe
        // Xe đến lối ra
        #20 exit_sensor = 1;
        #10 exit_sensor = 0;
        
        // Đợi barrier mở
        wait(exit_barrier == 1);
        #30;
        
        // Xe đi qua lối ra
        exit_passed = 1;
        #10 exit_passed = 0;
        
        // Đợi barrier đóng
        wait(exit_barrier == 0);
        #50;
        
        // Kịch bản 3: Bãi đậu xe đầy
        // Đưa nhiều xe vào cho đến khi đầy
        repeat (MAX_CAPACITY) begin
            // Xe đến lối vào
            #20 entry_sensor = 1;
            #10 entry_sensor = 0;
            
            // Đợi barrier mở
            wait(entry_barrier == 1);
            #30;
            
            // Xe đi qua lối vào
            entry_passed = 1;
            #10 entry_passed = 0;
            
            // Đợi barrier đóng
            wait(entry_barrier == 0);
            #50;
        end
        
        // Thử đưa thêm xe vào khi đã đầy
        #20 entry_sensor = 1;
        #50 entry_sensor = 0;  // Barrier không nên mở
        
        // Kết thúc mô phỏng
        #100 $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time=%0t | Entry=%s | Exit=%s | Spaces=%0d | Full=%b | EntryB=%b | ExitB=%b",
                 $time, state_to_string(entry_state), state_to_string(exit_state),
                 available_spaces, parking_full, entry_barrier, exit_barrier);
    end
endmodule
```

## Mở rộng dự án
1. **Hiển thị thời gian đậu xe**: Thêm chức năng đo thời gian đậu xe
2. **Tính phí đậu xe**: Tính toán phí dựa trên thời gian đậu xe
3. **Quản lý vị trí đậu xe**: Hiển thị và quản lý vị trí cụ thể của từng xe trong bãi
4. **Nhận dạng biển số xe**: Thêm chức năng nhận dạng biển số xe (mô phỏng)
5. **Giao tiếp với hệ thống thanh toán**: Kết nối với module thanh toán tự động

## Triển khai thực tế
Để triển khai dự án này trên phần cứng thực tế, bạn cần:

1. **FPGA hoặc board phát triển**: Như Xilinx Spartan, Altera Cyclone, v.v.
2. **Cảm biến**: Cảm biến hồng ngoại hoặc siêu âm để phát hiện xe
3. **Động cơ servo**: Để điều khiển barrier
4. **Màn hình LED**: Hiển thị số chỗ trống và thông tin khác
5. **Nguồn điện**: Nguồn cung cấp cho hệ thống

### Kết nối phần cứng
- Cảm biến kết nối với các chân đầu vào của FPGA
- Động cơ servo kết nối với các chân đầu ra PWM
- Màn hình LED kết nối với các chân đầu ra hiển thị

## Kết luận
Dự án hệ thống bãi đậu xe thông minh là một ứng dụng thực tế của hệ thống số sử dụng Verilog. Dự án này giúp người học hiểu cách thiết kế hệ thống điều khiển phức tạp, cách xử lý đầu vào từ cảm biến, và cách điều khiển các thiết bị đầu ra như barrier và màn hình hiển thị. Đây là một dự án tốt để hiểu về máy trạng thái hữu hạn (FSM) và ứng dụng trong các hệ thống tự động hóa thực tế.

### Chức năng và liên kết giữa các module

#### Chức năng của từng module

##### 1. Vehicle Counter Module
- **Chức năng chính**: Theo dõi số lượng xe trong bãi đỗ
- **Nhiệm vụ cụ thể**:
  - Đếm số xe vào/ra thông qua các tín hiệu entry_passed và exit_passed
  - Tính toán số chỗ trống còn lại (available_spaces = max_capacity - vehicle_count)
  - Phát hiện và báo hiệu khi bãi đỗ xe đầy (parking_full = 1)
  - Cung cấp thông tin số lượng xe và chỗ trống cho các module khác

##### 2. Barrier Control Module
- **Chức năng chính**: Điều khiển cơ chế đóng/mở barrier ra vào
- **Nhiệm vụ cụ thể**:
  - Mở barrier vào khi nhận lệnh open_entry từ FSM Control Module
  - Mở barrier ra khi nhận lệnh open_exit từ FSM Control Module
  - Đóng barrier vào/ra khi nhận lệnh close_entry/close_exit
  - Mở tất cả các barrier trong trường hợp khẩn cấp (emergency = 1)
  - Cung cấp thông tin về trạng thái barrier (barrier_status) cho các module khác

##### 3. Sensor Interface Module
- **Chức năng chính**: Xử lý tín hiệu từ các cảm biến phát hiện xe
- **Nhiệm vụ cụ thể**:
  - Lọc nhiễu và xử lý tín hiệu thô từ cảm biến (raw_entry_sensor, raw_exit_sensor)
  - Phát hiện xe đến lối vào/ra và tạo tín hiệu entry_sensor/exit_sensor
  - Phát hiện khi xe đã đi qua lối vào/ra và tạo tín hiệu entry_passed/exit_passed
  - Chống nhiễu và chống dội tín hiệu (debouncing)

##### 4. Display Module
- **Chức năng chính**: Hiển thị thông tin cho người dùng
- **Nhiệm vụ cụ thể**:
  - Hiển thị số chỗ trống còn lại trên màn hình LED 7-đoạn
  - Hiển thị trạng thái hệ thống (IDLE, FULL, ERROR, v.v.)
  - Hiển thị thông tin phí đỗ xe khi xe ra
  - Điều khiển các đèn LED chỉ thị trạng thái khác nhau của hệ thống

##### 5. Fee Calculator Module
- **Chức năng chính**: Tính toán phí đỗ xe dựa trên thời gian
- **Nhiệm vụ cụ thể**:
  - Ghi nhận thời gian xe vào bãi
  - Tính toán thời gian đỗ xe khi xe ra
  - Áp dụng biểu phí để tính số tiền cần thanh toán
  - Cung cấp thông tin phí cho Display Module để hiển thị

##### 6. FSM Control Module
- **Chức năng chính**: Điều khiển trạng thái của toàn bộ hệ thống
- **Nhiệm vụ cụ thể**:
  - Quản lý máy trạng thái (FSM) của hệ thống
  - Xử lý các sự kiện từ cảm biến và người dùng
  - Ra quyết định mở/đóng barrier dựa trên trạng thái hiện tại
  - Điều phối hoạt động giữa các module khác
  - Xử lý các tình huống đặc biệt (bãi đỗ đầy, khẩn cấp, v.v.)

#### Liên kết và luồng dữ liệu giữa các module

##### 1. Vehicle Counter Module → FSM Control Module
- **Dữ liệu truyền**: vehicle_count, parking_full
- **Mục đích**: FSM Control Module sử dụng thông tin này để quyết định có cho phép xe vào không và để cập nhật trạng thái hệ thống

##### 2. Vehicle Counter Module → Display Module
- **Dữ liệu truyền**: vehicle_count, available_spaces
- **Mục đích**: Display Module hiển thị thông tin này cho người dùng

##### 3. Sensor Interface Module → FSM Control Module
- **Dữ liệu truyền**: entry_sensor, exit_sensor, entry_passed, exit_passed
- **Mục đích**: FSM Control Module sử dụng các tín hiệu này để xác định khi nào có xe đến và khi nào xe đã đi qua

##### 4. Sensor Interface Module → Vehicle Counter Module
- **Dữ liệu truyền**: entry_passed, exit_passed
- **Mục đích**: Vehicle Counter Module sử dụng các tín hiệu này để tăng/giảm số lượng xe

##### 5. FSM Control Module → Barrier Control Module
- **Dữ liệu truyền**: open_entry, open_exit, close_entry, close_exit
- **Mục đích**: Điều khiển việc mở/đóng barrier dựa trên trạng thái hệ thống

##### 6. Barrier Control Module → FSM Control Module
- **Dữ liệu truyền**: barrier_status
- **Mục đích**: FSM Control Module biết được trạng thái hiện tại của barrier để điều khiển luồng hoạt động

##### 7. FSM Control Module → Display Module
- **Dữ liệu truyền**: current_state, alarm
- **Mục đích**: Display Module hiển thị trạng thái hiện tại và cảnh báo cho người dùng

##### 8. FSM Control Module → Fee Calculator Module
- **Dữ liệu truyền**: calculate_fee
- **Mục đích**: Yêu cầu tính toán phí khi xe ra khỏi bãi đỗ

##### 9. Fee Calculator Module → Display Module
- **Dữ liệu truyền**: fee_amount
- **Mục đích**: Display Module hiển thị số tiền phí cho người dùng

##### 10. Fee Calculator Module → FSM Control Module
- **Dữ liệu truyền**: fee_valid
- **Mục đích**: Xác nhận rằng phí đã được tính toán và sẵn sàng hiển thị

### Quy trình xử lý sự kiện

#### Quy trình xe vào bãi đỗ:
1. **Sensor Interface Module** phát hiện xe đến (raw_entry_sensor → entry_sensor)
2. **FSM Control Module** nhận tín hiệu và kiểm tra với **Vehicle Counter Module** xem bãi có còn chỗ không
3. **FSM Control Module** yêu cầu xác thực thẻ và kiểm tra tính hợp lệ
4. **FSM Control Module** gửi lệnh mở barrier (open_entry) đến **Barrier Control Module**
5. **Barrier Control Module** mở barrier vào (entry_barrier = 1)
6. **Sensor Interface Module** phát hiện xe đã đi qua (entry_passed = 1)
7. **FSM Control Module** gửi lệnh đóng barrier (close_entry) đến **Barrier Control Module**
8. **Vehicle Counter Module** tăng biến đếm xe và cập nhật số chỗ trống
9. **Display Module** cập nhật hiển thị số chỗ trống mới

#### Quy trình xe ra khỏi bãi đỗ:
1. **Sensor Interface Module** phát hiện xe đến lối ra (raw_exit_sensor → exit_sensor)
2. **FSM Control Module** nhận tín hiệu và yêu cầu xác thực thẻ
3. **FSM Control Module** gửi lệnh tính phí (calculate_fee) đến **Fee Calculator Module**
4. **Fee Calculator Module** tính toán phí và gửi kết quả (fee_amount) đến **Display Module**
5. **FSM Control Module** gửi lệnh mở barrier (open_exit) đến **Barrier Control Module**
6. **Barrier Control Module** mở barrier ra (exit_barrier = 1)
7. **Sensor Interface Module** phát hiện xe đã đi qua (exit_passed = 1)
8. **FSM Control Module** gửi lệnh đóng barrier (close_exit) đến **Barrier Control Module**
9. **Vehicle Counter Module** giảm biến đếm xe và cập nhật số chỗ trống
10. **Display Module** cập nhật hiển thị số chỗ trống mới 