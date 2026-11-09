
module uart_top #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire reset,

    // Керування передавачем
    input wire tx_start,
    input wire [7:0] tx_data,
    output wire tx,
    output wire tx_busy,

    // Вхід та виходи приймача
    input wire rx,
    output wire [7:0] rx_data,
    output wire rx_done
);

// Модуль передавача UART
uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) transmitter (
    .clk(clk),
    .reset(reset),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy)
);

// Модуль приймача UART
uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) receiver (
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .rx_data(rx_data),
    .rx_done(rx_done)
);

endmodule
