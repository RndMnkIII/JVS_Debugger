// uart_core.sv — wrapper module
module uart_core #(
  parameter int unsigned F_CLK_HZ = 48_000_000,
  parameter int unsigned BAUD     = 115_200,
  parameter int unsigned OVERS    = 16
)(
  input  logic clk,
  input  logic rst,
  input  logic i_rxd,
  output logic o_txd,

  // interfaz mínima para TX/RX
  input  logic       tx_valid,
  input  logic [7:0] tx_data,
  output logic       tx_ready,

  output logic       rx_valid,
  output logic [7:0] rx_data,
  input  logic       rx_ready,

  output logic framing_err,
  output logic parity_err
);
  import uart_pkg::*;

  uart_tx #(.F_CLK_HZ(F_CLK_HZ), .BAUD(BAUD), .OVERS(OVERS), .DATA_BITS(8), .STOP_BITS(1), .PAR(PAR_NONE))
  UTX(
    .clk(clk), .rst(rst),
    .i_tx_valid(tx_valid),
    .i_tx_data(tx_data),
    .o_tx_ready(tx_ready),
    .o_txd(o_txd),
    .o_busy()
  );

  uart_rx #(.F_CLK_HZ(F_CLK_HZ), .BAUD(BAUD), .OVERS(OVERS), .DATA_BITS(8), .STOP_BITS(1), .PAR(PAR_NONE))
  URX(
    .clk(clk), .rst(rst),
    .i_rxd(i_rxd),
    .o_rx_valid(rx_valid),
    .o_rx_data(rx_data),
    .i_rx_ready(rx_ready),
    .o_framing_err(framing_err),
    .o_parity_err(parity_err),
    .o_busy()
  );
endmodule
