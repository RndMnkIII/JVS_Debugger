
// osd_sdec_writer.sv — Decimal con signo, reutiliza el writer unsigned.
//`default_nettype none

module osd_sdec_writer #(
  parameter int WIDTH = 32
)(
  input  logic         clk,
  input  logic         rst,

  input  logic         start,
  output logic         busy,
  output logic         done,

  input  logic [15:0]  base_addr,

  input  logic  [7:0]  min_width,
  input  logic         zero_pad,

  input  logic signed [WIDTH-1:0] value,

  output logic         char_we,
  output logic [15:0]  char_addr,
  output logic  [7:0]  char_data
);

  typedef enum logic [1:0] {IDLE, WRITE_SIGN, RUN_UDEC, DONE} state_t;
  state_t state;

  logic [15:0] cursor;
  logic        neg;
  logic [WIDTH-1:0] abs_val;

  // Instancia unsigned
  logic u_start, u_busy, u_done;
  logic u_we;  logic [15:0] u_addr; logic [7:0] u_data;

  osd_udec_writer_seq #(.WIDTH(WIDTH)) udec_i (
    .clk, .rst,
    .start(u_start), .busy(u_busy), .done(u_done),
    .base_addr(cursor),
    .min_width(min_width), .zero_pad(zero_pad),
    .value(abs_val),
    .char_we(u_we), .char_addr(u_addr), .char_data(u_data)
  );

  // Mux de salida
  assign char_addr = (state == RUN_UDEC) ? u_addr : cursor;
  assign char_data = (state == WRITE_SIGN) ? "-" : u_data;
  assign char_we   = (state == WRITE_SIGN) ? 1'b1 : (state == RUN_UDEC ? u_we : 1'b0);

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state<=IDLE; busy<=0; done<=0; u_start<=0; cursor<='0;
    end else begin
      done    <= 1'b0; u_start <= 1'b0;

      case (state)
        IDLE: if (start) begin
          busy    <= 1'b1;
          cursor  <= base_addr;
          neg     <= value[WIDTH-1];
          abs_val <= value[WIDTH-1] ? (~value + 1'b1) : value;
          state   <= value[WIDTH-1] ? WRITE_SIGN : RUN_UDEC;
        end

        WRITE_SIGN: begin
          // Escribe '-' en este ciclo
          cursor <= cursor + 16'd1;
          state  <= RUN_UDEC;
        end

        RUN_UDEC: begin
          if (!u_busy && !u_done) u_start <= 1'b1;
          else if (u_done) state <= DONE;
        end

        DONE: begin
          busy <= 1'b0; done <= 1'b1; state <= IDLE;
        end
      endcase
    end
  end

endmodule
