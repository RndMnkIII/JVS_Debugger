// Project: OSD Overlay
// File: osd_overlay.sv
// Description: Overlay module for displaying OSD (On-Screen Display) characters
//              on a VGA screen. It uses a character RAM and a font ROM to
//              generate the pixel data for the OSD characters.
// Author: @RndMnkIII
// Date: 2025-05-09
// License: MIT
//
`default_nettype none
//import JVS_pkg::*;

module osd_top #(
    parameter int CLK_HZ = 48_000_000,
    parameter int COLS = 40,
    parameter int ROWS = 30,
    parameter int CHAR_RAM_SIZE = COLS * ROWS
)(
    input  logic         clk,
    input  logic         reset,
    input  logic         pixel_ce,
    input  logic [7:0]   R_in,
    input  logic [7:0]   G_in,
    input  logic [7:0]   B_in,
    input  logic         hsync_in,
    input  logic         vsync_in,
    input  logic         hblank,
    input  logic         vblank,
    output logic [7:0]   R_out,
    output logic [7:0]   G_out,
    output logic [7:0]   B_out,
    output logic         hsync_out,
    output logic         vsync_out,
    output logic [2:0]   hblank_out,
    output logic [2:0]   vblank_out,

    //memory write interface
    input logic [10:0] wr_addr,
    input logic [7:0]  wr_data,
    input logic        wr_en
);

  // RAM de caracteres compartida
  logic [10:0] char_rd_addr;
  logic [7:0]  char_code;

    char_ram_dualport #(
        .ADDR_WIDTH(11), //2048 posiciones (40x30 caracteres)
        .DATA_WIDTH(8),
        .INIT_FILE("JVS_RAM.mem")
    ) char_mem_inst (
        .clk(clk),
        .we_a(wr_en),
        .addr_a(wr_addr),
        .data_a(wr_data),
        .addr_b(char_rd_addr),
        .data_b(char_code)
    );

    logic [11:0] x_pix, y_pix;
    logic [11:0] width, height;
    logic        timing_ready;

    video_timing_tracker timing_inst (
        .clk(clk),
        .pixel_ce(pixel_ce),
        .hs(hsync_in),
        .vs(vsync_in),
        .hb(hblank),
        .vb(vblank),
        .x(x_pix),
        .y(y_pix),
        .width(width),
        .height(height),
        .ready(timing_ready)
    );

    logic [24:0] video_osd; //transparent color+RGB
    logic [7:0] R_d1, R_d2, R_d3, G_d1, G_d2, G_d3,B_d1, B_d2, B_d3;
    logic hsync_d1, hsync_d2, hsync_d3, vsync_d1, vsync_d2, vsync_d3;
    logic hblank_d1, hblank_d2, hblank_d3, vblank_d1, vblank_d2, vblank_d3;
    logic [9:0] x_d1, x_d2, y_d1, y_d2;
    logic osd_d1, osd_d2;
    logic osd_active;
    logic disp_dbg;

    always_ff @(posedge clk) begin
         if (pixel_ce) begin
            R_d1 <= R_in; R_d2 <= R_d1; R_d3 <= R_d2;
            G_d1 <= G_in; G_d2 <= G_d1; G_d3 <= G_d2;
            B_d1 <= B_in; B_d2 <= B_d1; B_d3 <= B_d2;
            hsync_d1 <= hsync_in; hsync_d2 <= hsync_d1; // hsync_d3 <= hsync_d2;
            vsync_d1 <= vsync_in; vsync_d2 <= vsync_d1; // vsync_d3 <= vsync_d2;
            hblank_d1 <= hblank; hblank_d2 <= hblank_d1;// hblank_d3 <= hblank_d2;
            vblank_d1 <= vblank; vblank_d2 <= vblank_d1;// vblank_d3 <= vblank_d2;
         end
    end

    osd_overlay_4bpp #(
        .CHAR_WIDTH(8), .CHAR_HEIGHT(8),
        .SCREEN_COLS(COLS), .SCREEN_ROWS(ROWS)
    ) osd_inst (
        .clk(clk),
        .reset(reset),
        .hblank(hblank),
        .vblank(vblank),
        .x(x_pix[9:0]),
        .y(y_pix[9:0]),
        .osd_active(osd_active),
        .video_out(video_osd),
        .addr_b(char_rd_addr),
        .char_code(char_code),
        .disp_dbg(disp_dbg)
    );

    assign osd_active = 1'b1; //always on for debug

    // Color del OSD (gris), por ejemplo: 0xA0
    localparam [7:0] OSD_GRAY = 8'hA0;

    // Peso: 3/4 fondo + 1/4 OSD → (background >> 2) + (OSD >> 2)
    logic [7:0] Rgrayout, Ggrayout, Bgrayout;
    assign Rgrayout = (R_d2 >> 1) + (OSD_GRAY >> 2);
    assign Ggrayout = (G_d2 >> 1) + (OSD_GRAY >> 2);
    assign Bgrayout = (B_d2 >> 1) + (OSD_GRAY >> 2);

    assign {R_out, G_out, B_out} = (video_osd[24] == 1'b0) ? video_osd[23:0] : (osd_active ? {Rgrayout,Ggrayout,Bgrayout} :{R_d2, G_d2, B_d2});
    assign hsync_out = hsync_d2;
    assign vsync_out = vsync_d2;
    assign hblank_out = hblank_d2;
    assign vblank_out = vblank_d2;

endmodule
