
// osd_bin_writer.sv — Emite valor en binario, opcional '0b' y agrupación cada 4 bits.
//`default_nettype none

module osd_bin_writer #(
  parameter int WIDTH = 32
)(
  input  logic         clk,
  input  logic         rst,

  input  logic         start,
  output logic         busy,
  output logic         done,

  input  logic [15:0]  base_addr,
  input  logic         prefix_0b,
  input  logic         group4,

  input  logic [WIDTH-1:0] value,

  output logic         char_we,
  output logic [15:0]  char_addr,
  output logic  [7:0]  char_data
);
  import osd_format_pkg::*;

  typedef enum logic [2:0] {IDLE, PFX0, PFXb, EMIT, DONE} state_t;
  state_t state;

  logic [15:0] cursor;
  int idx;
  int gcnt;

  assign char_addr = cursor;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state<=IDLE; busy<=0; done<=0; char_we<=0; cursor<='0; idx<=0; gcnt<=0;
    end else begin
      char_we <= 1'b0; done <= 1'b0;

      case (state)
        IDLE: if (start) begin
          busy   <= 1'b1;
          cursor <= base_addr;
          idx    <= WIDTH-1;
          gcnt   <= 0;
          state  <= prefix_0b ? PFX0 : EMIT;
        end

        PFX0: begin
          char_we   <= 1'b1;
          char_data <= "0";
          cursor    <= cursor + 16'd1;
          state     <= PFXb;
        end

        PFXb: begin
          char_we   <= 1'b1;
          char_data <= "b";
          cursor    <= cursor + 16'd1;
          state     <= EMIT;
        end

        EMIT: begin
          if (group4 && gcnt == 4) begin
            char_we   <= 1'b1;
            char_data <= " ";
            cursor    <= cursor + 16'd1;
            gcnt      <= 0;
          end else begin
            char_we   <= 1'b1;
            char_data <= bit2ascii(value[idx]);
            cursor    <= cursor + 16'd1;

            gcnt <= gcnt + 1;
            if (idx == 0) state <= DONE;
            else idx <= idx - 1;
          end
        end

        DONE: begin
          busy <= 1'b0; done <= 1'b1; state <= IDLE;
        end
      endcase
    end
  end

endmodule
