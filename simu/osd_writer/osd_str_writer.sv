
// osd_str_writer.sv
// Escribe una cadena NUL-terminada desde una ROM/RAM externa a la VRAM de caracteres.
//`default_nettype none

module osd_str_writer #(
  parameter int RD_LATENCY = 1,
  parameter int STR_ADDR_W = 16
) (
  input  logic               clk,
  input  logic               rst,

  input  logic               start,
  output logic               busy,
  output logic               done,

  input  logic        [15:0] base_addr,

  // Salida a VRAM
  output logic               char_we,
  output logic        [15:0] char_addr,
  output logic         [7:0] char_data,

  // Puerto de lectura de la memoria de cadenas
  input  logic [STR_ADDR_W-1:0] str_base_addr,
  output logic [STR_ADDR_W-1:0] str_rd_addr,
  output logic               str_rd_en,
  input  logic         [7:0] str_rd_data
);

  typedef enum logic [1:0] {IDLE, REQ, WAIT, WRITE} state_t;
  state_t state;

  logic [STR_ADDR_W-1:0] p;
  logic [15:0]           cursor;
  logic [7:0]            byte_q;
  logic [$clog2(RD_LATENCY+1)-1:0] wait_cnt;

  assign char_addr = cursor;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE; busy <= 1'b0; done <= 1'b0;
      char_we <= 1'b0; str_rd_en <= 1'b0; str_rd_addr <= '0;
      p <= '0; cursor <= '0; byte_q <= 8'h00; wait_cnt <= '0;
    end else begin
      char_we <= 1'b0; str_rd_en <= 1'b0; done <= 1'b0;

      case (state)
        IDLE: if (start) begin
          busy   <= 1'b1;
          p      <= str_base_addr;
          cursor <= base_addr;
          state  <= REQ;
        end

        REQ: begin
          str_rd_en   <= 1'b1;
          str_rd_addr <= p;
          wait_cnt    <= RD_LATENCY[$bits(wait_cnt)-1:0];
          state       <= WAIT;
        end

        WAIT: begin
          if (wait_cnt != 0) wait_cnt <= wait_cnt - 1;
          else begin
            byte_q <= str_rd_data;
            state  <= WRITE;
          end
        end

        WRITE: begin
          if (byte_q == 8'h00) begin
            busy <= 1'b0; done <= 1'b1; state <= IDLE;
          end else begin
            char_we   <= 1'b1;
            char_data <= byte_q;
            cursor    <= cursor + 16'd1;
            p         <= p + 1;
            state     <= REQ;
          end
        end
      endcase
    end
  end

endmodule
