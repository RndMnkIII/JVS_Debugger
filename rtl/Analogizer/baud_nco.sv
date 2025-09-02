// baud_nco.sv — CE fractional RATE_HZ (NCO 32-bit, jitter ≤ +-1 clk period)
module baud_nco #(
  parameter int unsigned F_CLK_HZ = 48_000_000,
  parameter int unsigned RATE_HZ  = 1_843_200  // p.ej. BAUD*OVERS
)(
  input  logic clk,
  input  logic rst,      // synchronous reset
  output logic tick      // one clk period pulse
);
  // STEP = round(RATE_HZ / F_CLK_HZ * 2^32)
  localparam longint unsigned STEP_L = ((longint'(RATE_HZ) << 32) + F_CLK_HZ/2) / F_CLK_HZ;
  localparam logic [31:0] STEP = logic'(STEP_L[31:0]);

  logic [31:0] acc;
  logic [32:0] sum;

  always_ff @(posedge clk) begin
    if (rst) begin
      acc  <= '0;
      tick <= 1'b0;
    end else begin
      sum  = {1'b0, acc} + {1'b0, STEP};
      acc  <= sum[31:0];
      tick <= sum[32]; // clk strobe
    end
  end
endmodule
