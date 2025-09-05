
// rowcol_to_addr_1c.sv — 1 ciclo combinacional (síntesis puede usar lógica o DSP a su criterio)
module rowcol_to_addr_1c #(
  parameter int COLS   = 40,
  parameter int ADDR_W = 12
)(
  input  logic [15:0] row,
  input  logic [15:0] col,
  output logic [ADDR_W-1:0] addr
);
  assign addr = (row * COLS) + col; // deja decidir al sintetizador (DSP o lógica)
endmodule
