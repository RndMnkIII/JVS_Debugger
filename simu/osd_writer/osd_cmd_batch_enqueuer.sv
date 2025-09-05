// osd_cmd_batch_enqueuer.sv — Carga una secuencia de comandos y los empuja al dispatcher.
//`default_nettype none

module osd_cmd_batch_enqueuer #(
  parameter int WIDTH = 32,
  parameter int DEPTH = 32
)(
  input  logic clk,
  input  logic rst,

  input  logic                         load_we,
  input  logic [$clog2(DEPTH)-1:0]     load_addr,
  input  osd_cmd_pkg::osd_cmd_t        load_data,

  input  logic [$clog2(DEPTH+1)-1:0]   seq_count,

  input  logic start,
  output logic busy,
  output logic done,

  output logic                         cmd_valid,
  input  logic                         cmd_ready,

  output logic  [2:0]                  cmd_type,
  output logic [15:0]                  base_addr,
  output logic [WIDTH-1:0]             value,
  output logic [osd_cmd_pkg::BASE_ADDR_W-1:0] str_base_addr,
  output logic  [7:0]                  dec_min_width,
  output logic                         dec_zero_pad,
  output logic                         hex_prefix_0x,
  output logic                         hex_uppercase,
  output logic  [7:0]                  hex_min_nibbles,
  output logic                         bin_prefix_0b,
  output logic                         bin_group4
);

  import osd_cmd_pkg::*;

  osd_cmd_t ram [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (load_we) ram[load_addr] <= load_data;
  end

  typedef enum logic [1:0] {S_IDLE, S_FETCH, S_PREP, S_SEND} state_t;
  state_t state;

  logic [$clog2(DEPTH)-1:0] idx;
  osd_cmd_t q;
  logic have_q;

  // Decode payload
  always_comb begin
    cmd_type        = 3'd0;
    base_addr       = '0;
    value           = '0;
    str_base_addr   = '0;
    dec_min_width   = 8'd0;
    dec_zero_pad    = 1'b0;
    hex_prefix_0x   = 1'b0;
    hex_uppercase   = 1'b0;
    hex_min_nibbles = 8'd0;
    bin_prefix_0b   = 1'b0;
    bin_group4      = 1'b0;

    if (have_q) begin
      cmd_type  = q.osd_cmd_type;
      base_addr = q.base_addr;
      unique case (q.osd_cmd_type)
        CMD_STR: begin str_base_addr = q.payload[31:0]; end
        CMD_UDEC, CMD_SDEC: begin
          value         = q.payload[31:0];
          dec_min_width = q.payload[39:32];
          dec_zero_pad  = q.payload[40];
        end
        CMD_HEX: begin
          value           = q.payload[31:0];
          hex_min_nibbles = q.payload[39:32];
          hex_prefix_0x   = q.payload[40];
          hex_uppercase   = q.payload[41];
        end
        CMD_BIN: begin
          value         = q.payload[31:0];
          bin_prefix_0b = q.payload[40];
          bin_group4    = q.payload[41];
        end
        default: ;
      endcase
    end
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state<=S_IDLE; idx<='0; have_q<=0; busy<=0; done<=0; cmd_valid<=0;
    end else begin
      done<=0; cmd_valid<=0;

      case (state)
        S_IDLE: if (start) begin busy<=1; idx<='0; state<=S_FETCH; end

        S_FETCH: begin
          if (idx >= seq_count) begin busy<=0; done<=1; state<=S_IDLE; end
          else begin q <= ram[idx]; have_q <= 1; state<=S_PREP; end
        end

        S_PREP: begin
          if (!q.pending) begin idx <= idx + 1; have_q<=0; state<=S_FETCH; end
          else state <= S_SEND;
        end

        S_SEND: begin
          cmd_valid <= 1'b1;
          if (cmd_ready) begin
            idx <= idx + 1; have_q<=0; state<=S_FETCH;
          end
        end
      endcase
    end
  end

endmodule
