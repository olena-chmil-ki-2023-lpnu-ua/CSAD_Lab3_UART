
module uart_tx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire reset,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx,
    output reg tx_busy
);

localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

reg [1:0] state = IDLE;
reg [15:0] clk_count = 0;
reg [2:0] bit_index = 0;
reg [7:0] data_reg = 0;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        clk_count <= 0;
        bit_index <= 0;
        data_reg <= 0;
        tx <= 1;
        tx_busy <= 0;
    end else begin
        case (state)

            IDLE: begin
                tx <= 1;
                tx_busy <= 0;
                clk_count <= 0;

                if (tx_start) begin
                    data_reg <= tx_data;
                    tx_busy <= 1;
                    state <= START;
                end
            end

            START: begin
                tx <= 0;

                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    bit_index <= 0;
                    state <= DATA;
                end else
                    clk_count <= clk_count + 1;
            end

            DATA: begin
                tx <= data_reg[bit_index];

                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;

                    if (bit_index == 7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1;
                end else
                    clk_count <= clk_count + 1;
            end

            STOP: begin
                tx <= 1;

                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    tx_busy <= 0;
                    state <= IDLE;
                end else
                    clk_count <= clk_count + 1;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
