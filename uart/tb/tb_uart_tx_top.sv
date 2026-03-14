`timescale 1ns / 1ps

module tb_uart_tx_top;

    // 1. Parametry testu (Zegary i prędkość)
    // Zwiększamy Baud Rate do 10 Mbps, żeby symulacja trwała ułamek sekundy!
    localparam int CLK_FREQ  = 100_000_000;
    localparam int BAUD_RATE = 10_000_000; 

    // 2. Sygnały systemowe
    logic clk;
    logic rst_n;
    logic tx_serial_out;

    // 3. Interfejs (My nim sterujemy!)
    uart_tx_if tx_if();

    // 4. Instancja naszego Nadajnika (DUT - Design Under Test)
    uart_tx_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) DUT (
        .bus_i(tx_if.mac_mp),
        .clk_i(clk),
        .rst_ni(rst_n),
        .tx_o(tx_serial_out)
    );

    // 5. Generator Zegara (100 MHz -> Okres 10ns)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 6. Główny wątek testowy (Procesor wstrzykujący dane)
    initial begin
        // --- FAZA 1: INICJALIZACJA I RESET ---
        rst_n       = 1'b0;
        tx_if.valid = 1'b0;
        tx_if.data  = 8'h00;
        
        #20;
        rst_n = 1'b1;
        #20;
        
        $display("========================================");
        $display("[TB] Start testu nadajnika UART TX");
        $display("========================================");

        // --- FAZA 2: WYSŁANIE PIERWSZEGO BAJTU ---
        // Wyślemy wartość 8'h55 (binarnie 01010101) - to tzw. "wzór testowy", 
        // bo na oscyloskopie wygeneruje piękną falę prostokątną na linii TX.
        
        @(posedge clk); // Synchronizujemy się z zegarem
        tx_if.valid = 1'b1;
        tx_if.data  = 8'h55;
        $display("[TB] Wystawiono dane: 8'h55. Czekam na akceptacje (ready)...");

        // Czekamy, aż układ powie, że jest gotowy i przyjął dane
        while (tx_if.ready == 1'b0) begin
            @(posedge clk);
        end
        
        // Układ przyjął dane! W następnym cyklu zdejmujemy valid, żeby nie wysłać podwójnie
        @(posedge clk); 
        tx_if.valid = 1'b0;
        $display("[TB] Dane 8'h55 zaakceptowane przez DUT. Trwa transmisja szeregowa...");

        // --- FAZA 3: CZEKANIE NA ZAKOŃCZENIE TRANSMISJI ---
        // 1 bit przy naszych parametrach trwa 10 cykli zegara (100M / 10M).
        // Cała ramka (Start + 8 bitów + Stop) to 10 bitów, czyli 100 cykli.
        // Dajemy mu 150 cykli zapasu, żeby bezpiecznie skończył.
        repeat (150) @(posedge clk);

        // --- FAZA 4: WYSŁANIE DRUGIEGO BAJTU ---
        // Wyślemy wartość 8'hAB (binarnie 10101011)
        @(posedge clk);
        tx_if.valid = 1'b1;
        tx_if.data  = 8'hAB;
        
        while (tx_if.ready == 1'b0) begin
            @(posedge clk);
        end
        
        @(posedge clk);
        tx_if.valid = 1'b0;
        $display("[TB] Dane 8'hAB zaakceptowane. Czekam na zakonczenie...");

        repeat (150) @(posedge clk);

        // --- FAZA 5: ZAKOŃCZENIE ---
        $display("========================================");
        $display("[TB] Symulacja zakonczona sukcesem.");
        $display("========================================");
        $finish;
    end

endmodule
