
`timescale 1ns / 1ps

module tb_uart_rx;

    // Параметри UART
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam BIT_TIME = CLKS_PER_BIT * 20;

    // Вхідні сигнали приймача
    reg clk = 0;
    reg reset = 1;
    reg rx = 1;

    // Вихідні сигнали приймача
    wire [7:0] rx_data;
    wire rx_done;

    integer errors = 0;
    integer received_count = 0;

    // Генерація CLK 50 МГц
    always #10 clk = ~clk;

    // Підключення приймача UART
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // Підрахунок отриманих байтів
    always @(posedge rx_done)
        received_count = received_count + 1;

    // Імітація зовнішнього UART-передавача
    task send_external_byte;
        input [7:0] data;
        integer i;
        integer previous_count;
        begin
            previous_count = received_count;

            // Стартовий біт
            @(negedge clk);
            rx = 0;
            #(BIT_TIME);

            // Передавання 8 бітів даних
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_TIME);
            end

            // Стоповий біт
            rx = 1;
            #(BIT_TIME);

            // Перевірка прийнятого байта
            if (received_count == previous_count + 1 &&
                rx_data === data) begin

                $display("PASS: External %h, Received %h",
                         data, rx_data);
            end else begin
                $display("FAIL: External %h, Received %h",
                         data, rx_data);
                errors = errors + 1;
            end

            // Пауза між кадрами
            #(BIT_TIME);
        end
    endtask

    // Основний процес тестування
    initial begin

        $dumpfile("uart_rx_external.vcd");
        $dumpvars(0, tb_uart_rx);

        $display("External UART RX test started");

        // Скидання приймача
        repeat (5) @(negedge clk);
        reset = 0;

        // Тестові байти
        send_external_byte(8'hA5);
        send_external_byte(8'h3C);
        send_external_byte(8'h5A);

        // Підсумок
        if (errors == 0)
            $display("ALL EXTERNAL RX TESTS PASSED");
        else
            $display("RX TEST FAILED: %0d errors", errors);

        $finish;
    end

    // Захист від зависання симуляції
    initial begin
        #1000000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
