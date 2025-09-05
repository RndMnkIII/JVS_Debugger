// osd_udec_writer_seq.sv — Conversor decimal sin signo (Double-Dabble secuencial).
//`default_nettype none

module osd_udec_writer_seq #(
  parameter int WIDTH = 32
)(
  input  logic        clk,
  input  logic        rst,

  input  logic        start,
  output logic        busy,
  output logic        done,

  input  logic [15:0]       base_addr,
  input  logic [7:0]        min_width,
  input  logic              zero_pad,
  input  logic [WIDTH-1:0]  value,

  output logic        char_we,
  output logic [15:0] char_addr,
  output logic  [7:0] char_data
);

  // ---------------------------------------------------------------------------
  // Parámetros internos
  // ---------------------------------------------------------------------------
  // Cobertura segura para distintos WIDTH
  localparam int MAX_DIGITS = (WIDTH <= 32) ? 10 : (WIDTH <= 64 ? 20 : 40);

  // ---------------------------------------------------------------------------
  // Registros de salida (_q) y sus “siguientes” (_d)
  // ---------------------------------------------------------------------------
  logic        char_we_q,   char_we_d;
  logic [15:0] char_addr_q, char_addr_d;
  logic  [7:0] char_data_q, char_data_d;

  assign char_we   = char_we_q;
  assign char_addr = char_addr_q;
  assign char_data = char_data_q;

  // Señales de estado
  logic busy_q, busy_d;
  logic done_q, done_d;

  assign busy = busy_q;
  assign done = done_q;

  // ---------------------------------------------------------------------------
  // Estado / buffers para la conversión y emisión
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {S_IDLE, S_CAPTURE, S_EXTRACT, S_PREP_EMIT, S_EMIT, S_DONE} state_t;
  state_t state_q, state_d;

  // Entradas latcheadas al iniciar
  logic [15:0]       base_addr_q, base_addr_d;
  logic [7:0]        min_width_q, min_width_d;
  logic              zero_pad_q,  zero_pad_d;

  // Valor restante por convertir (unsigned)
  logic [WIDTH-1:0] val_q, val_d;

  // Buffer de dígitos (0..9), guardados como nibbles; se generan LSB→MSB
  logic [3:0] digits_q [0:MAX_DIGITS-1];
  logic [3:0] digits_d [0:MAX_DIGITS-1];

  // Número de dígitos válidos en el buffer
  logic [$clog2(MAX_DIGITS+1)-1:0] len_q, len_d;

  // Contadores de emisión
  logic [7:0] pad_left_q, pad_left_d;  // cuántos padding quedan por emitir
  logic [$clog2(MAX_DIGITS+1)-1:0] emit_idx_q, emit_idx_d; // índice en digits (MSB→0)
  logic [15:0] out_pos_q, out_pos_d;   // desplazamiento desde base_addr

  // ---------------------------------------------------------------------------
  // Secuencial: único always_ff
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // Salidas
      char_we_q   <= 1'b0;
      char_addr_q <= '0;
      char_data_q <= '0;
      busy_q      <= 1'b0;
      done_q      <= 1'b0;

      // Estado
      state_q     <= S_IDLE;

      // Latches de entrada
      base_addr_q <= '0;
      min_width_q <= '0;
      zero_pad_q  <= 1'b0;

      // Conversión / buffers
      val_q       <= '0;
      len_q       <= '0;
      pad_left_q  <= '0;
      emit_idx_q  <= '0;
      out_pos_q   <= '0;

      // Limpiar digits
      for (int i = 0; i < MAX_DIGITS; i++) begin
        digits_q[i] <= '0;
      end
    end else begin
      // Salidas
      char_we_q   <= char_we_d;
      char_addr_q <= char_addr_d;
      char_data_q <= char_data_d;
      busy_q      <= busy_d;
      done_q      <= done_d;

      // Estado
      state_q     <= state_d;

      // Latches de entrada
      base_addr_q <= base_addr_d;
      min_width_q <= min_width_d;
      zero_pad_q  <= zero_pad_d;

      // Conversión / buffers
      val_q       <= val_d;
      len_q       <= len_d;
      pad_left_q  <= pad_left_d;
      emit_idx_q  <= emit_idx_d;
      out_pos_q   <= out_pos_d;

      for (int i = 0; i < MAX_DIGITS; i++) begin
        digits_q[i] <= digits_d[i];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Combinacional: único always_comb
  // ---------------------------------------------------------------------------
  always_comb begin
    // Por defecto, mantener estado y limpiar pulso de salida
    char_we_d   = 1'b0;
    char_addr_d = char_addr_q;
    char_data_d = char_data_q;

    busy_d = busy_q;
    done_d = 1'b0;     // done es pulso de 1 ciclo

    state_d = state_q;

    base_addr_d = base_addr_q;
    min_width_d = min_width_q;
    zero_pad_d  = zero_pad_q;

    val_d      = val_q;
    len_d      = len_q;
    pad_left_d = pad_left_q;
    emit_idx_d = emit_idx_q;
    out_pos_d  = out_pos_q;

    // Mantener buffer por defecto
    for (int i = 0; i < MAX_DIGITS; i++) begin
      digits_d[i] = digits_q[i];
    end

    unique case (state_q)
      // Espera a start
      S_IDLE: begin
        busy_d = 1'b0;
        if (start) begin
          state_d     = S_CAPTURE;
        end
      end

      // Captura entradas y prepara conversión
      S_CAPTURE: begin
        busy_d      = 1'b1;
        base_addr_d = base_addr;
        min_width_d = min_width;
        zero_pad_d  = zero_pad;

        // Inicializa proceso de conversión
        val_d   = value;
        len_d   = '0;
        // Limpia el buffer de dígitos
        for (int i = 0; i < MAX_DIGITS; i++) begin
          digits_d[i] = '0;
        end

        state_d = S_EXTRACT;
      end

      // Extrae dígitos en base 10 (LSB→MSB): cada ciclo hace /10 y %10
      S_EXTRACT: begin
        // Caso especial: si value==0 y aún no tenemos dígitos, genera "0"
        if ((val_q == '0) && (len_q == '0)) begin
          digits_d[0] = 4'd0;
          len_d       = 1;
          // listos para preparar emisión
          state_d = S_PREP_EMIT;
        end else if (val_q != '0) begin
          // Extrae el siguiente dígito
          // Nota: /10 y %10 son constantes; Quartus los sintetiza (divisor por constante).
          logic [WIDTH-1:0] q10;
          logic [3:0]       r10;
          q10 = val_q / 10;
          r10 = val_q - q10*10;        // resto = v % 10 sin operador %
          digits_d[len_q] = r10[3:0];  // guardar siguiente dígito (LSB primero)
          len_d = len_q + 1;

          val_d = q10;

          // Si ya no queda, pasamos a preparar la emisión
          if (q10 == '0) begin
            state_d = S_PREP_EMIT;
          end
        end else begin
          // val==0 pero ya hay dígitos -> pasar a emitir
          state_d = S_PREP_EMIT;
        end
      end

      // Calcula padding y prepara índices para emitir MSB→LSB
      S_PREP_EMIT: begin
        // Cálculo de padding a la izquierda
        if (min_width_q > len_q) begin
          pad_left_d = min_width_q - len_q;
        end else begin
          pad_left_d = 8'd0;
        end

        // Índice de emisión: arrancamos desde el dígito más significativo
        // digits[] está en LSB->MSB, así que el MSB está en len-1
        emit_idx_d = (len_q == 0) ? 0 : (len_q - 1);

        // Posición de escritura relativa
        out_pos_d  = 16'd0;

        // Primers dirección de VRAM
        char_addr_d = base_addr_q;

        state_d = S_EMIT;
      end

      // Emite padding (si hay) y luego los dígitos (MSB->LSB)
      S_EMIT: begin
        // Un carácter por ciclo (pulso de WE)
        if (pad_left_q != 0) begin
          // Padding a la izquierda
          char_we_d   = 1'b1;
          char_addr_d = base_addr_q + out_pos_q;
          char_data_d = zero_pad_q ? 8'h30 /*'0'*/ : 8'h20 /*' '*/;

          pad_left_d  = pad_left_q - 1;
          out_pos_d   = out_pos_q + 1;
        end else if ((len_q != 0) && (emit_idx_q < MAX_DIGITS)) begin
          // Emite dígitos: del más significativo al menos
          char_we_d   = 1'b1;
          char_addr_d = base_addr_q + out_pos_q;
          char_data_d = 8'h30 + {4'b0, digits_q[emit_idx_q]}; // '0' + dígito

          out_pos_d   = out_pos_q + 1;

          if (emit_idx_q == 0) begin
            // último dígito
            state_d = S_DONE;
          end else begin
            emit_idx_d = emit_idx_q - 1;
          end
        end else begin
          // Nada que emitir -> DONE (por seguridad)
          state_d = S_DONE;
        end
      end

      // Pulso done y volver a IDLE
      S_DONE: begin
        done_d  = 1'b1;   // pulso 1 ciclo
        busy_d  = 1'b0;
        state_d = S_IDLE;
      end

      default: begin
        state_d = S_IDLE;
      end
    endcase
  end

endmodule
