// tb_uart_core.sv
// iverilog -g2012 -o simv \
//   uart_pkg.sv baud_nco.sv uart_tx.sv uart_rx.sv uart_core.sv tb_uart_core.sv
// vvp simv
`timescale 1ns/1ps
timeunit 1ns; timeprecision 1ps;

module tb_uart_core;
  // Parámetros del DUT
  localparam int unsigned F_CLK_HZ = 48_000_000;
  localparam int unsigned BAUD     = 115_200;
  localparam int unsigned OVERS    = 16;

  // Reloj y reset
  logic clk = 0;
  logic rst = 1;

  // Periodo de reloj en ns (48 MHz → 20.833333 ns)
  real CLK_PER_NS = 1e9 / F_CLK_HZ;

  // Señales DUT (uart_core)
  logic i_rxd, o_txd;
  logic        tx_valid;
  logic [7:0]  tx_data;
  logic        tx_ready;
  logic        rx_valid;
  logic [7:0]  rx_data;
  logic        rx_ready = 1'b1;   // auto-clear de valid
  logic        framing_err, parity_err;

  // Instancia del DUT
  uart_core #(.F_CLK_HZ(F_CLK_HZ), .BAUD(BAUD), .OVERS(OVERS)) DUT (
    .clk(clk),
    .rst(rst),
    .i_rxd(i_rxd),
    .o_txd(o_txd),
    .tx_valid(tx_valid),
    .tx_data(tx_data),
    .tx_ready(tx_ready),
    .rx_valid(rx_valid),
    .rx_data(rx_data),
    .rx_ready(rx_ready),
    .framing_err(framing_err),
    .parity_err(parity_err)
  );

  // Generación de reloj
  always begin
    #(CLK_PER_NS/2.0) clk = ~clk;
  end

  // Reset síncrono
  initial begin
    rst <= 1;
    repeat (8) @(posedge clk);
    rst <= 0;
  end

  // -----------------------------
  // Prueba 1: LOOPBACK INTERNO
  // -----------------------------
  // Conecta la línea TX del DUT a su RX (loopback lógico)
  assign i_rxd = o_txd;

  // Cola de esperados y recibidos
  byte unsigned exp_q[$];
  byte unsigned rcv_q[$];

  // Captura de datos recibidos (pulso de 1 ciclo)
  always @(posedge clk) if (!rst && rx_valid) rcv_q.push_back(rx_data);

  // Tarea: enviar un byte vía interfaz TX del core
  task automatic send_byte(input byte unsigned b);
    // espera a que el transmisor esté listo
    @(posedge clk);
    wait (tx_ready == 1'b1);
    tx_data  <= b;
    tx_valid <= 1'b1;
    @(posedge clk);
    tx_valid <= 1'b0;
    exp_q.push_back(b);
  endtask

  // Secuencia de la prueba 1
  initial begin : TEST1_LOOPBACK
    // espera a salir de reset
    wait (!rst);
    // patrón básico
    send_byte(8'h55);
    send_byte(8'hAA);
    send_byte(8'h00);
    send_byte(8'hFF);

    // unos cuantos aleatorios
    for (int i = 0; i < 16; i++) begin
      send_byte($urandom_range(0,255));
    end

    // Espera a recibir todo con timeout razonable
    // Tiempo por byte ~ 10 bits / BAUD
    real T_BYTE_NS = (10.0 * 1e9) / real'(BAUD);
    time timeout = $time + time'(T_BYTE_NS * (exp_q.size()+8));
    wait (rcv_q.size() == exp_q.size() || $time > timeout);

    // Comprobación
    if (rcv_q.size() != exp_q.size()) begin
      $error("TEST1 timeout: recibidos %0d / esperados %0d", rcv_q.size(), exp_q.size());
      $fatal;
    end
    foreach (exp_q[i]) begin
      if (rcv_q[i] !== exp_q[i]) begin
        $error("TEST1 mismatch en idx %0d: got %02x exp %02x", i, rcv_q[i], exp_q[i]);
        $fatal;
      end
    end
    $display("[PASS] TEST1 loopback interno OK (%0d bytes)", exp_q.size());
  end

  // ---------------------------------------------
  // Prueba 2: RX con transmisor externo desajustado
  // ---------------------------------------------
  // Instancia adicional SOLO RX (mismo diseño que el DUT) para alimentarlo con una línea externa
  logic        rx2_valid;
  logic [7:0]  rx2_data;
  logic        rx2_ready = 1'b1;
  logic        fe2, pe2, rx2_busy;
  logic        line2; // línea serie externa hacia RX2

  uart_rx #(.F_CLK_HZ(F_CLK_HZ), .BAUD(BAUD), .OVERS(OVERS), .DATA_BITS(8), .STOP_BITS(1)) URX2 (
    .clk(clk), .rst(rst),
    .i_rxd(line2),
    .o_rx_valid(rx2_valid),
    .o_rx_data(rx2_data),
    .i_rx_ready(rx2_ready),
    .o_framing_err(fe2),
    .o_parity_err(pe2),
    .o_busy(rx2_busy)
  );

  // Driver de línea serie con error de baud configurable (ppm_frac = +0.02 → +2%)
  real TBIT_NS   = (1e9 / BAUD); // bit time ideal (ns)
  initial line2 = 1'b1;          // reposo alto

  task automatic drive_serial_byte(input byte unsigned b, input real ppm_frac);
    // start
    line2 <= 1'b0;  #(TBIT_NS*(1.0+ppm_frac));
    // 8 datos LSB-first
    for (int i=0; i<8; i++) begin
      line2 <= b[i]; #(TBIT_NS*(1.0+ppm_frac));
    end
    // stop
    line2 <= 1'b1;  #(TBIT_NS*(1.0+ppm_frac));
    // pequeña pausa
    #(TBIT_NS*(0.5));
  endtask

  byte unsigned exp2_q[$];
  byte unsigned rcv2_q[$];

  always @(posedge clk) if (!rst && rx2_valid) rcv2_q.push_back(rx2_data);

  initial begin : TEST2_RX_TOLERANCE
    // espera a que acabe TEST1 más o menos
    wait (!rst);
    #(TBIT_NS*50.0);

    // Inyecta con +2% de error (más rápido)
    real ppm_fast = +0.02;
    // Patrón de prueba
    byte unsigned vec2[$] = {8'h12,8'h34,8'h56,8'h78,8'h9A,8'hBC,8'hDE,8'hF0};
    foreach (vec2[i]) begin
      drive_serial_byte(vec2[i], ppm_fast);
      exp2_q.push_back(vec2[i]);
    end

    // Espera recepción
    time timeout2 = $time + time'(TBIT_NS * 12.0 * vec2.size());
    wait (rcv2_q.size()==exp2_q.size() || $time>timeout2);

    if (rcv2_q.size()!=exp2_q.size()) begin
      $error("TEST2(+2%%) timeout: recibidos %0d / esperados %0d", rcv2_q.size(), exp2_q.size());
      $fatal;
    end
    foreach (exp2_q[i]) begin
      if (rcv2_q[i] !== exp2_q[i]) begin
        $error("TEST2(+2%%) mismatch idx %0d: got %02x exp %02x", i, rcv2_q[i], exp2_q[i]);
        $fatal;
      end
    end
    $display("[PASS] TEST2 RX con +2%% de error OK");

    // Limpieza colas y prueba con -2% (más lento)
    exp2_q.delete(); rcv2_q.delete();
    real ppm_slow = -0.02;
    foreach (vec2[i]) begin
      drive_serial_byte(vec2[i], ppm_slow);
      exp2_q.push_back(vec2[i]);
    end

    time timeout3 = $time + time'(TBIT_NS * 12.0 * vec2.size());
    wait (rcv2_q.size()==exp2_q.size() || $time>timeout3);

    if (rcv2_q.size()!=exp2_q.size()) begin
      $error("TEST2(-2%%) timeout: recibidos %0d / esperados %0d", rcv2_q.size(), exp2_q.size());
      $fatal;
    end
    foreach (exp2_q[i]) begin
      if (rcv2_q[i] !== exp2_q[i]) begin
        $error("TEST2(-2%%) mismatch idx %0d: got %02x exp %02x", i, rcv2_q[i], exp2_q[i]);
        $fatal;
      end
    end
    $display("[PASS] TEST2 RX con -2%% de error OK");

    $display("== TODOS LOS TESTS OK ==");
    $finish;
  end

endmodule
