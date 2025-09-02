// uart_tx.sv — transmitter with internal NCO (uses only 1 out of every OVERS ticks)
module uart_tx #(
  parameter int unsigned F_CLK_HZ   = 48_000_000,
  parameter int unsigned BAUD       = 115_200,
  parameter int unsigned OVERS      = 16,          // ticks per bit
  parameter int unsigned DATA_BITS  = 8,
  parameter int unsigned STOP_BITS  = 1,           // 1 o 2
  parameter uart_pkg::parity_t PAR  = uart_pkg::PAR_NONE
)(
  input  logic clk,
  input  logic rst,

  input  logic        i_tx_valid,
  input  logic [7:0]  i_tx_data,     
  output logic        o_tx_ready,

  output logic        o_txd,
  output logic        o_busy
);
  import uart_pkg::*;

  localparam int unsigned RATE_HZ = BAUD * OVERS;
  wire tick_ovs;
  baud_nco #(.F_CLK_HZ(F_CLK_HZ), .RATE_HZ(RATE_HZ)) nco(.clk(clk), .rst(rst), .tick(tick_ovs));

  typedef enum logic [2:0] {S_IDLE,S_START,S_DATA,S_PAR,S_STOP} state_t;
  state_t st;

  logic [$clog2(OVERS)-1:0] sub;
  logic [$clog2(DATA_BITS):0] bit_idx;
  logic [DATA_BITS-1:0] shreg;
  logic parity_bit;
  logic [1:0] stop_cnt;

  function automatic logic calc_parity(input logic [DATA_BITS-1:0] d);
    logic p = ^d;
    case (PAR)
      PAR_NONE: calc_parity = 1'b0;
      PAR_EVEN: calc_parity = ~p;
      PAR_ODD : calc_parity =  p;
      default : calc_parity = 1'b0;
    endcase
  endfunction

  assign o_tx_ready = (st==S_IDLE);
  assign o_busy     = (st!=S_IDLE);

  always_ff @(posedge clk) begin
    if (rst) begin
      st      <= S_IDLE;
      o_txd   <= 1'b1;
      sub     <= '0;
      bit_idx <= '0;
      stop_cnt<= '0;
    end else begin
      if (st==S_IDLE) begin
        o_txd <= 1'b1;
        if (i_tx_valid) begin
          shreg      <= i_tx_data[DATA_BITS-1:0];
          parity_bit <= calc_parity(i_tx_data[DATA_BITS-1:0]);
          st         <= S_START;
          sub        <= '0;
          o_txd      <= 1'b0; // start
        end
      end else if (tick_ovs) begin
        sub <= sub + 1'b1;
        if (sub == OVERS-1) begin
          sub <= '0;
          unique case (st)
            S_START: begin
              st      <= S_DATA;
              o_txd   <= shreg[0];
              bit_idx <= 1;
            end
            S_DATA: begin
              if (bit_idx < DATA_BITS) begin
                o_txd   <= shreg[bit_idx];
                bit_idx <= bit_idx + 1;
              end else begin
                if (PAR==PAR_NONE) begin
                  st      <= S_STOP;
                  o_txd   <= 1'b1;
                  stop_cnt<= 1;
                end else begin
                  st    <= S_PAR;
                  o_txd <= parity_bit;
                end
              end
            end
            S_PAR: begin
              st      <= S_STOP;
              o_txd   <= 1'b1;
              stop_cnt<= 1;
            end
            S_STOP: begin
              if (stop_cnt < STOP_BITS) begin
                stop_cnt <= stop_cnt + 1;
                o_txd    <= 1'b1;
              end else begin
                st <= S_IDLE;
                o_txd <= 1'b1;
              end
            end
          endcase
        end
      end
    end
  end
endmodule
