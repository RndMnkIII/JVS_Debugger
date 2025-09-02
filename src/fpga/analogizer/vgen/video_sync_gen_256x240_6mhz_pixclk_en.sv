module video_sync_gen_256x240_6mhz_pixclk_en (
  input  logic clk48, input logic rst,
  output logic pixel_clock_en,
  output logic [7:0] xpos, output logic [7:0] ypos,
  output logic hblank, vblank, hsync, vsync
);
  video_sync_gen_pixclk_en #(
    .H_TOTAL(384), .H_ACTIVE(256), .H_FP(16), .H_SYNC(32), .H_BP(80),
    .V_TOTAL(262), .V_ACTIVE(240), .V_FP(4),  .V_SYNC(3),  .V_BP(15),
    .HSYNC_ACTIVE_LOW(0), .VSYNC_ACTIVE_LOW(0)
  ) sync_gen (
    .clk48(clk48), 
    .rst(rst),
    .pixel_clock_en(pixel_clock_en),
    .xpos(xpos), 
    .ypos(ypos), 
    .hblank(hblank), 
    .vblank(vblank), 
    .hsync(hsync), 
    .vsync(vsync)
  );
endmodule