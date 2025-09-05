
// osd_init_fsm_dyn.sv — Inicialización dinámica: limpia VRAM (opcional), recibe comandos por streaming y arranca el batch.
//`default_nettype none

module osd_init_fsm_dyn #(
  parameter int COLS = 40,
  parameter int ROWS = 20,
  parameter int NUM_CMDS_MAX = 64
)(
  input  logic clk,
  input  logic rst,

  input  logic init_start,
  output logic init_busy,
  output logic init_done,

  input  logic        clear_enable,
  input  logic [7:0]  clear_char,

  // Escritura a VRAM (durante clear)
  output logic        vram_we,
  output logic [15:0] vram_addr,
  output logic [7:0]  vram_data,

  // Stream de programación
  input  logic                         prog_valid,
  output logic                         prog_ready,
  input  osd_cmd_pkg::osd_cmd_t        prog_cmd,
  input  logic                         prog_last,

  // Hacia el batch enqueuer
  output logic                                be_load_we,
  output logic [$clog2(NUM_CMDS_MAX)-1:0]     be_load_addr,
  output osd_cmd_pkg::osd_cmd_t               be_load_data,
  output logic [$clog2(NUM_CMDS_MAX+1)-1:0]   be_seq_count,
  output logic                                be_start,
  input  logic                                be_busy,
  input  logic                                be_done
);

  localparam int DEPTH = COLS*ROWS;

  typedef enum logic [2:0] {S_IDLE, S_CLEAR, S_LOAD_WAIT, S_LOAD_ACCEPT, S_START, S_WAIT, S_DONE} state_t;
  state_t state;

  logic [15:0] clr_idx;
  logic [$clog2(NUM_CMDS_MAX+1)-1:0] cmd_count;
  logic [$clog2(NUM_CMDS_MAX+1)-1:0] seq_count_latched;

  // --------------------------------------------------------------------------
  // COMBINACIONAL: TODAS las salidas se conducen SOLO aquí según el estado
  // --------------------------------------------------------------------------
  always_comb begin
    // Handshake de init
    init_busy  = (state != S_IDLE) && (state != S_DONE);
    init_done  = (state == S_DONE);

    // VRAM defaults (dirección útil para clear)
    vram_we    = 1'b0;
    vram_addr  = clr_idx;
    vram_data  = clear_char;

    // Streaming defaults
    prog_ready = 1'b0;

    // Enqueuer defaults
    be_load_we   = 1'b0;
    be_load_addr = cmd_count[$clog2(NUM_CMDS_MAX)-1:0];
    be_load_data = prog_cmd;
    be_seq_count = cmd_count;
    be_start     = 1'b0;

    unique case (state)
      // Limpieza VRAM: un write por ciclo
      S_CLEAR: begin
        vram_we   = 1'b1;
        vram_addr = clr_idx;
        vram_data = clear_char;
      end

      // Acepta un comando y lo escribe (pulso de un ciclo)
      S_LOAD_ACCEPT: begin
        be_load_we   = 1'b1;
        be_load_addr = cmd_count[$clog2(NUM_CMDS_MAX)-1:0];
        be_load_data = prog_cmd;
        prog_ready   = 1'b1;
      end

      // Inicio del batch (pulso start y cuenta latcheada)
      S_START: begin
        be_seq_count = cmd_count;
        be_start     = 1'b1;
      end

      // Mientras el enqueuer trabaja, mantener el recuento latcheado
      S_WAIT: begin
        be_seq_count = seq_count_latched;
      end

      default: ;
    endcase
  end

  // --------------------------------------------------------------------------
  // SECUENCIAL: SOLO estado y contadores (ninguna salida aquí)
  // --------------------------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state             <= S_IDLE;
      clr_idx           <= 16'd0;
      cmd_count         <= '0;
      seq_count_latched <= '0;
    end else begin
      unique case (state)
        S_IDLE: begin
          if (init_start) begin
            cmd_count <= '0;
            clr_idx   <= 16'd0;
            state     <= clear_enable ? S_CLEAR : S_LOAD_WAIT;
          end
        end

        S_CLEAR: begin
          if (clr_idx == DEPTH-1) begin
            state <= S_LOAD_WAIT;
          end else begin
            clr_idx <= clr_idx + 16'd1;
          end
        end

        // Espera a tener comando válido y hueco
        S_LOAD_WAIT: begin
          if (prog_valid && (cmd_count < NUM_CMDS_MAX)) begin
            state <= S_LOAD_ACCEPT;
          end
        end

        // Aceptación y avance de punteros
        S_LOAD_ACCEPT: begin
          cmd_count <= cmd_count + 1'b1;
          state     <= prog_last ? S_START : S_LOAD_WAIT;
        end

        // Arranca el encolado (latch de la longitud)
        S_START: begin
          seq_count_latched <= cmd_count;
          state             <= S_WAIT;
        end

        // Espera fin del encolado externo
        S_WAIT: begin
          if (be_done) state <= S_DONE;
        end

        // Fin: volver a IDLE cuando suelte init_start
        S_DONE: begin
          if (!init_start) state <= S_IDLE;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
