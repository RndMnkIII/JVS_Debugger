
// rowcol_to_addr_pipe.sv — 2 etapas: mult + suma (el sintetizador decide DSP o lógica)
module rowcol_to_addr_pipe #(
  parameter int COLS   = 40,
  parameter int ADDR_W = 12
)(
  input  logic        clk,
  input  logic        rst,
  input  logic        valid_in,
  input  logic [15:0] row,
  input  logic [15:0] col,
  output logic        valid_out,
  output logic [ADDR_W-1:0] addr
);
  logic [ADDR_W-1:0] mult_s1; logic v1;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin mult_s1<='0; v1<=0; end
    else begin mult_s1 <= row * COLS; v1 <= valid_in; end
  end
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin addr<='0; valid_out<=0; end
    else begin addr <= mult_s1 + col; valid_out <= v1; end
  end
endmodule
