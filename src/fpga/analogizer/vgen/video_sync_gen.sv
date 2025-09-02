module video_sync_gen #(
  // Totales
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

  // Polaridades (0 = activo en bajo)
  parameter bit HSYNC_ACTIVE_LOW   = 1'b1,
  parameter bit VSYNC_ACTIVE_LOW   = 1'b1
)(
  input  logic clk_pix,   // 6 MHz
  input  logic rst_n,

  output logic [$clog2(H_ACTIVE)-1:0] xpos,
  output logic [$clog2(V_ACTIVE)-1:0] ypos,
  output logic                        hblank,
  output logic                        vblank,
  output logic                        hsync,
  output logic                        vsync
);
  localparam int unsigned H_SYNC_BEG = H_ACTIVE + H_FP;
  localparam int unsigned H_SYNC_END = H_ACTIVE + H_FP + H_SYNC; // no inclusivo
  localparam int unsigned V_SYNC_BEG = V_ACTIVE + V_FP;
  localparam int unsigned V_SYNC_END = V_ACTIVE + V_FP + V_SYNC; // no inclusivo

  localparam int H_CNT_W = $clog2(H_TOTAL);
  localparam int V_CNT_W = $clog2(V_TOTAL);

  logic [H_CNT_W-1:0] hcnt;
  logic [V_CNT_W-1:0] vcnt;

  // Contadores H/V
  always_ff @(posedge clk_pix or negedge rst_n) begin
    if (!rst_n) begin
      hcnt <= '0;
      vcnt <= '0;
    end else begin
      if (hcnt == H_TOTAL-1) begin
        hcnt <= '0;
        if (vcnt == V_TOTAL-1) vcnt <= '0;
        else                   vcnt <= vcnt + 1'b1;
      end else begin
        hcnt <= hcnt + 1'b1;
      end
    end
  end

  // Blanking
  always_comb begin
    hblank = (hcnt >= H_ACTIVE);
    vblank = (vcnt >= V_ACTIVE);
  end

  // HSYNC / VSYNC (ventanas)
  logic hsync_int = (hcnt >= H_SYNC_BEG) && (hcnt < H_SYNC_END);
  logic vsync_int = (vcnt >= V_SYNC_BEG) && (vcnt < V_SYNC_END);

  always_comb begin
    // Activo en bajo por defecto
    hsync = HSYNC_ACTIVE_LOW ? ~hsync_int : hsync_int;
    vsync = VSYNC_ACTIVE_LOW ? ~vsync_int : vsync_int;
  end

  // Coordenadas visibles (0..ACTIVE-1), fuera = 0
  always_ff @(posedge clk_pix or negedge rst_n) begin
    if (!rst_n) begin
      xpos <= '0;
      ypos <= '0;
    end else begin
      if (!hblank && !vblank) begin
        xpos <= hcnt[$bits(xpos)-1:0]; // 0..H_ACTIVE-1
        ypos <= vcnt[$bits(ypos)-1:0]; // 0..V_ACTIVE-1
      end else begin
        xpos <= '0;
        // Solo resetea ypos al inicio de la línea activa para evitar glitchs
        if (hcnt == 0) begin
          if (vblank) ypos <= '0;
        end
      end
    end
  end
endmodule
