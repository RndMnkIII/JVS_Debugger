
// osd_textbuf.sv
// VRAM de caracteres: 1 puerto lectura (rd_addr) y 1 puerto escritura (wr_*)
//`default_nettype none

module osd_textbuf #(
  parameter int COLS = 40,
  parameter int ROWS = 20
) (
  input  logic               clk,
  // Puerto A (lectura, p.ej. rasterizador)
  input  logic        [15:0] rd_addr,
  output logic         [7:0] rd_data,
  // Puerto B (escritura desde formatters/dispatcher)
  input  logic               we,
  input  logic        [15:0] wr_addr,
  input  logic         [7:0] wr_data
);
  localparam int DEPTH = COLS*ROWS;
  logic [7:0] mem [0:DEPTH-1];

  assign rd_data = mem[rd_addr];

  always_ff @(posedge clk) begin
    if (we) mem[wr_addr] <= wr_data;
  end

endmodule
