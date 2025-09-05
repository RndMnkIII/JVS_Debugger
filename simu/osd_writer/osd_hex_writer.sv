
// osd_hex_writer.sv — Emite valor en hexadecimal, opcional '0x', uppercase y anchura mínima en nibbles.
//`default_nettype none

module osd_hex_writer #(
  parameter int WIDTH = 32
)(
  input  logic         clk,
  input  logic         rst,

  input  logic         start,
  output logic         busy,
  output logic         done,

  input  logic [15:0]  base_addr,
  input  logic         prefix_0x,
  input  logic         uppercase,
  input  logic  [7:0]  min_nibbles,   // 0=compacto, >0 fija anchura con padding '0'

  input  logic [WIDTH-1:0] value,

  output logic         char_we,
  output logic [15:0]  char_addr,
  output logic  [7:0]  char_data
);
  import osd_format_pkg::*;

  typedef enum logic [2:0] {IDLE, PFX0, PFKX, PREP, EMIT, DONE} state_t;
  state_t state;

  logic [15:0] cursor;
  int   msb_nib;
  int   idx;

  function automatic int msb_nibble(input logic [WIDTH-1:0] v);
    int n = (WIDTH+3)/4 - 1;
    int k;
    msb_nibble = 0;
    for (k = n; k > 0; k--) begin
      if (v[k*4 +: 4] != 4'd0) begin
        msb_nibble = k;
        return msb_nibble;
      end
    end
    msb_nibble = 0;
  endfunction

  assign char_addr = cursor;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state<=IDLE; busy<=0; done<=0; char_we<=0; cursor<='0; idx<=0; msb_nib<=0;
    end else begin
      char_we <= 1'b0; done <= 1'b0;

      case (state)
        IDLE: if (start) begin
          busy    <= 1'b1;
          cursor  <= base_addr;
          msb_nib <= msb_nibble(value);
          if (min_nibbles > 0 && msb_nib < (min_nibbles-1))
            msb_nib <= min_nibbles-1;
          idx     <= msb_nib;
          state   <= (prefix_0x ? PFX0 : PREP);
        end

        PFX0: begin
          char_we   <= 1'b1;
          char_data <= "0";
          cursor    <= cursor + 16'd1;
          state     <= PFKX;
        end

        PFKX: begin
          char_we   <= 1'b1;
          char_data <= (uppercase ? "X" : "x");
          cursor    <= cursor + 16'd1;
          state     <= PREP;
        end

        PREP: begin
          state <= EMIT;
        end

        EMIT: begin
          char_we   <= 1'b1;
          char_data <= hex2ascii(value[idx*4 +: 4], uppercase);
          cursor    <= cursor + 16'd1;
          if (idx == 0) state <= DONE;
          else idx <= idx - 1;
        end

        DONE: begin
          busy <= 1'b0; done <= 1'b1; state <= IDLE;
        end
      endcase
    end
  end

endmodule
