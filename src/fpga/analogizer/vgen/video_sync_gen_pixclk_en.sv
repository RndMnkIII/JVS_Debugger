
// Project: JVS Debugger
// File: video_sync_gen_pixclk_en.sv
// Description: parametizable video sync generator for 240p 15KHz like video output
// Author: @RndMnkIII
// Date: 2025-09-01
// License: MIT
//
`default_nettype none

module video_sync_gen_pixclk_en #(
  // Totales y visibles
  parameter int unsigned H_TOTAL   = 384,
  parameter int unsigned H_ACTIVE  = 256,
  parameter int unsigned H_FP      = 16,
  parameter int unsigned H_SYNC    = 32,
  parameter int unsigned H_BP      = H_TOTAL - H_ACTIVE - H_FP - H_SYNC,

  parameter int unsigned V_TOTAL   = 262,
  parameter int unsigned V_ACTIVE  = 240,
  parameter int unsigned V_FP      = 4,
  parameter int unsigned V_SYNC    = 3,
  parameter int unsigned V_BP      = V_TOTAL - V_ACTIVE - V_FP - V_SYNC,

  // Polaridades (1 = activo en bajo)
  parameter bit HSYNC_ACTIVE_LOW   = 1'b1,
  parameter bit VSYNC_ACTIVE_LOW   = 1'b1
)(
  input  logic clk48,   // 48 MHz master
  input  logic rst,

  // Strobe de 6 MHz (1 ciclo a 48 MHz cada 8 ciclos)
  output logic pixel_clock_en,

  // Señales de vídeo
  output logic [$clog2(H_ACTIVE)-1:0] xpos,
  output logic [$clog2(V_ACTIVE)-1:0] ypos,
  output logic                        hblank,
  output logic                        vblank,
  output logic                        hsync,
  output logic                        vsync
);
  // -------- divisor 48 -> 6 MHz (strobe) --------
  logic [2:0] div8;
  always_ff @(posedge clk48 or posedge rst) begin
    if (rst) begin
      div8           <= '0;
      pixel_clock_en <= 1'b0;
    end else begin
      div8           <= div8 + 3'd1;
      pixel_clock_en <= (div8 == 3'd7);  // pulso 1 ciclo (48 MHz) cada 8 → 6 MHz
    end
  end

  // -------- contadores H/V (avanzan solo con pixel_clock_en) --------
  localparam int H_CNT_W = $clog2(H_TOTAL);
  localparam int V_CNT_W = $clog2(V_TOTAL);

  logic [H_CNT_W-1:0] hcnt;
  logic [V_CNT_W-1:0] vcnt;

  always_ff @(posedge clk48 or posedge rst) begin
    if (rst) begin
      hcnt <= '0;
      vcnt <= '0;
    end else if (pixel_clock_en) begin
      if (hcnt == H_TOTAL-1) begin
        hcnt <= '0;
        vcnt <= (vcnt == V_TOTAL-1) ? '0 : vcnt + 1'b1;
      end else begin
        hcnt <= hcnt + 1'b1;
      end
    end
  end

  // Ventanas de sync
  localparam int unsigned H_SYNC_BEG = H_ACTIVE + H_FP;
  localparam int unsigned H_SYNC_END = H_ACTIVE + H_FP + H_SYNC;
  localparam int unsigned V_SYNC_BEG = V_ACTIVE + V_FP;
  localparam int unsigned V_SYNC_END = V_ACTIVE + V_FP + V_SYNC;

  wire hsync_int = (hcnt >= H_SYNC_BEG) && (hcnt < H_SYNC_END);
  wire vsync_int = (vcnt >= V_SYNC_BEG) && (vcnt < V_SYNC_END);

  // Salidas registradas solo en tick de 6 MHz
  always_ff @(posedge clk48 or posedge rst) begin
    if (rst) begin
      hblank <= 1'b1;
      vblank <= 1'b1;
      hsync  <= HSYNC_ACTIVE_LOW ? 1'b1 : 1'b0;
      vsync  <= VSYNC_ACTIVE_LOW ? 1'b1 : 1'b0;
      xpos   <= '0;
      ypos   <= '0;
    end else if (pixel_clock_en) begin
      hblank <= (hcnt >= H_ACTIVE);
      vblank <= (vcnt >= V_ACTIVE);
      hsync  <= HSYNC_ACTIVE_LOW ? ~hsync_int : hsync_int;
      vsync  <= VSYNC_ACTIVE_LOW ? ~vsync_int : vsync_int;

      if (!hblank && !vblank) begin
        xpos <= xpos + 1'b1; //hcnt[$bits(xpos)-1:0];
        ypos <= ypos + 1'b1; //vcnt[$bits(ypos)-1:0];
      end else begin
        xpos <= '0;
        if (hcnt == 0 && vblank) ypos <= '0;
      end
    end
  end
endmodule
