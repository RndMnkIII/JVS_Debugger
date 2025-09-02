module video_sync_gen_320x240_6mhz (
  input  logic clk_pix,  // 6 MHz
  input  logic rst_n,
  output logic [8:0] xpos,  // 0..319
  output logic [7:0] ypos,  // 0..239
  output logic hblank, vblank, hsync, vsync
);
  video_sync_gen #(
    .H_TOTAL (384), .H_ACTIVE(320), .H_FP(8),  .H_SYNC(32), .H_BP(24),
    .V_TOTAL (262), .V_ACTIVE(240), .V_FP(4),  .V_SYNC(3),  .V_BP(15),
    .HSYNC_ACTIVE_LOW(1), .VSYNC_ACTIVE_LOW(1)
  ) u_gen (
    .clk_pix, .rst_n, .xpos, .ypos, .hblank, .vblank, .hsync, .vsync
  );
endmodule