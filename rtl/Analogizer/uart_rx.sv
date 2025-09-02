// uart_rx.sv — receiver with NCO + 16× oversampling (mostly 7/8/9)
module uart_rx #(
  parameter int unsigned F_CLK_HZ   = 48_000_000,
  parameter int unsigned BAUD       = 115_200,
  parameter int unsigned OVERS      = 16,
  parameter int unsigned DATA_BITS  = 8,
  parameter int unsigned STOP_BITS  = 1,
  parameter uart_pkg::parity_t PAR  = uart_pkg::PAR_NONE
)(
  input  logic clk,
  input  logic rst,

  input  logic i_rxd,

  output logic        o_rx_valid,
  output logic [7:0]  o_rx_data,     // LSB-first
  input  logic        i_rx_ready,    

  output logic        o_framing_err,
  output logic        o_parity_err,
  output logic        o_busy
);
  import uart_pkg::*;

  localparam int unsigned RATE_HZ = BAUD * OVERS;
  wire tick_ovs;
  baud_nco #(.F_CLK_HZ(F_CLK_HZ), .RATE_HZ(RATE_HZ)) nco(.clk(clk), .rst(rst), .tick(tick_ovs));

  // syncs RX with clk
  logic rxd_meta, rxd_sync, rxd_prev;
  always_ff @(posedge clk) begin
    rxd_meta <= i_rxd;
    rxd_sync <= rxd_meta;
    rxd_prev <= rxd_sync;
  end

  typedef enum logic [2:0] {R_IDLE,R_START,R_DATA,R_PAR,R_STOP} state_t;
  state_t st;

  logic [$clog2(OVERS)-1:0] sub;
  logic [$clog2(DATA_BITS):0] bit_idx;
  logic [DATA_BITS-1:0] shreg;
  logic s7,s8,s9;

  function automatic logic parity_calc(input logic [DATA_BITS-1:0] d);
    logic p = ^d;
    case (PAR)
      PAR_NONE: parity_calc = 1'b0;
      PAR_EVEN: parity_calc = ~p;
      PAR_ODD : parity_calc =  p;
      default : parity_calc = 1'b0;
    endcase
  endfunction

  assign o_busy = (st != R_IDLE);

  always_ff @(posedge clk) begin
    if (rst) begin
      o_rx_valid    <= 1'b0;
      o_framing_err <= 1'b0;
      o_parity_err  <= 1'b0;
    end else begin
      if (i_rx_ready) o_rx_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      st <= R_IDLE;
      sub <= '0;
      bit_idx <= '0;
      s7 <= 1'b1; s8 <= 1'b1; s9 <= 1'b1;
      o_framing_err <= 1'b0;
      o_parity_err  <= 1'b0;
    end else begin
      unique case (st)
        R_IDLE: begin
          if (rxd_prev && !rxd_sync) begin // start edge
            st  <= R_START;
            sub <= '0;
            s7 <= 1'b1; s8 <= 1'b1; s9 <= 1'b1;
            o_framing_err <= 1'b0;
            o_parity_err  <= 1'b0;
          end
        end

        default: if (tick_ovs) begin
          sub <= sub + 1'b1;

          if (sub == (OVERS/2 - 1)) s7 <= rxd_sync; // 7
          if (sub == (OVERS/2    )) s8 <= rxd_sync; // 8
          if (sub == (OVERS/2 + 1)) s9 <= rxd_sync; // 9

          if (sub == OVERS-1) begin
            logic centre = uart_pkg::majority3(s7,s8,s9);
            s7<=1'b1; s8<=1'b1; s9<=1'b1;
            sub <= '0;

            unique case (st)
              R_START: begin
                if (centre != 1'b0) st <= R_IDLE; // false start
                else begin
                  st <= R_DATA;
                  bit_idx <= 0;
                end
              end
              R_DATA: begin
                shreg[bit_idx] <= centre;
                if (bit_idx == DATA_BITS-1) begin
                  st <= (PAR==PAR_NONE) ? R_STOP : R_PAR;
                end else begin
                  bit_idx <= bit_idx + 1;
                end
              end
              R_PAR: begin
                o_parity_err <= (centre != parity_calc(shreg));
                st <= R_STOP;
              end
              R_STOP: begin
                if (centre != 1'b1) o_framing_err <= 1'b1;
                // (if STOP_BITS=2, the second stop bit occurs in the next bit period; we usually check the last center sample)
                o_rx_data  <= { {(8-DATA_BITS){1'b0}}, shreg };
                o_rx_valid <= 1'b1;
                st <= R_IDLE;
              end
            endcase
          end
        end
      endcase
    end
  end
endmodule
