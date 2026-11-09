
module uart_rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire reset,
    input wire rx,
    output reg [7:0] rx_data,
    output reg rx_done
);

// Кількість тактів на один біт
localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

// Стани приймача
localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

reg [1:0] state;
reg [15:0] clk_count;
reg [2:0] bit_index;
reg [7:0] data_reg;

// Синхронізація асинхронного входу
reg rx_sync1, rx_sync2;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        rx_sync1 <= 1'b1;
        rx_sync2 <= 1'b1;
    end else begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end
end

// Основна логіка приймача
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        clk_count <= 0;
        bit_index <= 0;
        data_reg <= 0;
        rx_data <= 0;
        rx_done <= 0;
    end else begin
        rx_done <= 0;

        case (state)

            IDLE: begin
                clk_count <= 0;
                bit_index <= 0;

                if (rx_sync2 == 0)
                    state <= START;
            end

            START: begin
                if (clk_count == CLKS_PER_BIT/2-1) begin
                    clk_count <= 0;

                    if (rx_sync2 == 0)
                        state <= DATA;
                    else
                        state <= IDLE;
                end else
                    clk_count <= clk_count + 1;
            end

            DATA: begin
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    data_reg[bit_index] <= rx_sync2;

                    if (bit_index == 7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1;
                end else
                    clk_count <= clk_count + 1;
            end

            STOP: begin
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;

                    if (rx_sync2 == 1) begin
                        rx_data <= data_reg;
                        rx_done <= 1;
                    end

                    state <= IDLE;
                end else
                    clk_count <= clk_count + 1;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
