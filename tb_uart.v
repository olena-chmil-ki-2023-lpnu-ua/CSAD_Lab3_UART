
`timescale 1ns / 1ps

module tb_uart;

    // Параметри симуляції
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam BIT_TIME = CLKS_PER_BIT * 20;

    // Вхідні сигнали
    reg clk = 0;
    reg reset = 1;
    reg tx_start = 0;
    reg [7:0] tx_data = 0;

    // Вихідні сигнали
    wire tx;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_done;

    integer errors = 0;
    integer received_count = 0;

    // Тактовий сигнал 50 МГц
    always #10 clk = ~clk;

    // З'єднання передавача з приймачем
    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .rx(tx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // Підрахунок прийнятих байтів
    always @(posedge rx_done) begin
        received_count = received_count + 1;
    end

    // Передавання та перевірка одного байта
    task send_and_check;
        input [7:0] data;
        integer previous_count;
        begin
            previous_count = received_count;

            // Запуск передавача
            @(negedge clk);
            tx_data = data;
            tx_start = 1;

            @(negedge clk);
            tx_start = 0;

            // Очікування завершення приймання
            wait(received_count > previous_count);
            #1;

            // Перевірка результату
            if (rx_data === data) begin
                $display("PASS: Sent %h, Received %h",
                         data, rx_data);
            end else begin
                $display("FAIL: Sent %h, Received %h",
                         data, rx_data);
                errors = errors + 1;
            end

            // Очікування готовності передавача
            wait(tx_busy == 0);
            repeat (5) @(posedge clk);
        end
    endtask

    // Основний процес тестування
    initial begin

        // Створення файлу осцилограм
        $dumpfile("uart_wave.vcd");
        $dumpvars(0, tb_uart);

        $display("UART simulation started");

        // Скидання
        repeat (5) @(negedge clk);
        reset = 0;

        // Тестування трьох байтів
        send_and_check(8'hA5);
        send_and_check(8'h3C);
        send_and_check(8'h5A);

        // Підсумок тестування
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $display("UART simulation finished");
        $finish;
    end

    // Захист від нескінченного очікування
    initial begin
        #1000000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
