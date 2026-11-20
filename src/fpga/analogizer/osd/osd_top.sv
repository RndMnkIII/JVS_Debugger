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
    input logic        wr_en,

    //gun interface, one crosshair per player (P1..P4): player p at [p] / [p*12 +: 12]
    input logic [3:0]  gun_trigger,
    input logic [47:0] gun_x,
    input logic [47:0] gun_y,
    input logic [3:0]  gun_enable,   // draw the crosshair of the player (gun players only)
    
    //gpio output value for recoil display
    input logic [7:0] gpio_output_value,
    
    //snac io signals for display
    input logic snac_io3,
    input logic snac_in7,
    //JVS line activity (stretched pulses) for the TX/RX indicators
    input logic jvs_tx_activity,
    input logic jvs_rx_activity,

    //analog display: X/Y gauges (rows 26/27) and X/Y target (cols 33..38, rows 22..27)
    input logic        ana_has_x,
    input logic        ana_has_y,
    input logic [15:0] ana_x,
    input logic [15:0] ana_y
);

    //-------------------------------------------------------------------------
    // Analog overlay geometry (pixels, 8x8 character cells)
    //-------------------------------------------------------------------------
    localparam int GAUGE_X0  = 48;            // col 6
    localparam int GAUGE_X1  = 207;           // col 25 (160 px wide)
    localparam int GAUGE_XC  = 127;           // gauge center
    localparam int GAUGE_Y_X = 208;           // row 26: X gauge
    localparam int GAUGE_Y_Y = 216;           // row 27: Y gauge
    localparam int TGT_X0    = 264;           // col 33
    localparam int TGT_X1    = 311;           // col 38 (48 px)
    localparam int TGT_Y0    = 176;           // row 22
    localparam int TGT_Y1    = 223;           // row 27 (48 px)
    localparam int TGT_XC    = 288;
    localparam int TGT_YC    = 200;

    localparam logic [23:0] COL_TRACK  = 24'h5A6270;
    localparam logic [23:0] COL_CENTER = 24'h9474FF;
    localparam logic [23:0] COL_CURSOR = 24'hFFC300;
    localparam logic [23:0] COL_FRAME  = 24'h2EA8FF;
    localparam logic [23:0] COL_AXIS   = 24'h806000;

    // Cursor positions (registered): gauge = x0 + v*160/65536, target = x0 + v*48/65536
    // Values are sampled once per frame (during vblank) so that a value change
    // in the middle of the frame does not tear the gauges / target.
    logic [11:0] gauge_cx, gauge_cy, tgt_px, tgt_py;
    logic        ana_has_x_r, ana_has_y_r;
    always_ff @(posedge clk) begin
        if (vblank) begin
            gauge_cx    <= 12'(GAUGE_X0) + 12'((20'(ana_x) * 20'd10) >> 12);
            gauge_cy    <= 12'(GAUGE_X0) + 12'((20'(ana_y) * 20'd10) >> 12);
            tgt_px      <= 12'(TGT_X0)   + 12'((18'(ana_x) * 18'd3)  >> 12);
            tgt_py      <= 12'(TGT_Y0)   + 12'((18'(ana_y) * 18'd3)  >> 12);
            ana_has_x_r <= ana_has_x;
            ana_has_y_r <= ana_has_y;
        end
    end

    // Returns 1 and a color when (x,y) is on a gauge drawn on the cell row starting at y0
    function automatic logic gauge_pix(input logic [11:0] x, input logic [11:0] y, input int y0,
                                       input logic [11:0] cur, output logic [23:0] col);
        gauge_pix = 1'b0;
        col = COL_TRACK;
        if (x >= GAUGE_X0 && x <= GAUGE_X1 && y >= y0 && y < y0 + 8) begin
            if (x + 1 >= cur && x <= cur + 1) begin
                gauge_pix = 1'b1; col = COL_CURSOR;                      // cursor (3 px)
            end else if ((x == GAUGE_XC || x == GAUGE_XC + 1) && y > y0 && y < y0 + 7) begin
                gauge_pix = 1'b1; col = COL_CENTER;                      // center tick
            end else if ((x == GAUGE_X0 || x == GAUGE_X1) && y > y0 && y < y0 + 7) begin
                gauge_pix = 1'b1; col = COL_TRACK;                       // end caps
            end else if (y == y0 + 3 || y == y0 + 4) begin
                gauge_pix = 1'b1; col = COL_TRACK;                       // track
            end
        end
    endfunction

    // X/Y target: frame, dotted center axes, X/Y decomposition lines and dot
    function automatic logic target_pix(input logic [11:0] x, input logic [11:0] y,
                                        input logic [11:0] px, input logic [11:0] py,
                                        output logic [23:0] col);
        target_pix = 1'b0;
        col = COL_FRAME;
        if (x >= TGT_X0 && x <= TGT_X1 && y >= TGT_Y0 && y <= TGT_Y1) begin
            if (x + 1 >= px && x <= px + 1 && y + 1 >= py && y <= py + 1) begin
                target_pix = 1'b1; col = COL_CURSOR;                     // position dot (3x3)
            end else if (x == TGT_X0 || x == TGT_X1 || y == TGT_Y0 || y == TGT_Y1) begin
                target_pix = 1'b1; col = COL_FRAME;                      // frame
            end else if (x == px || y == py) begin
                target_pix = 1'b1; col = COL_AXIS;                       // X / Y decomposition
            end else if ((x == TGT_XC && !y[0]) || (y == TGT_YC && !x[0])) begin
                target_pix = 1'b1; col = COL_TRACK;                      // dotted center axes
            end
        end
    endfunction

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

    //assign {R_out, G_out, B_out} = (video_osd[24] == 1'b0) ? video_osd[23:0] : (osd_active ? {Rgrayout,Ggrayout,Bgrayout} :{R_d2, G_d2, B_d2});
    // assign hsync_out = hsync_d2;
    // assign vsync_out = vsync_d2;
    // assign hblank_out = hblank_d2;
    // assign vblank_out = vblank_d2;

    //cross drawing helper function
    function automatic logic is_around (
        input logic [11:0] val,      // value to check
        input logic [11:0] reference,      // reference value
        input logic [11:0] tol,      // tolerance
        input logic [11:0] max_val   // max value to avoid overflow
    );
        logic [11:0] lower, upper;
        logic [12:0] sum_w;          // for overflow en ref+tol

        begin
            // saturated lower limit
            if (reference < tol)
                lower = 12'd0;
            else
                lower = reference - tol;

            // saturated upper limit
            sum_w = {1'b0, reference} + {1'b0, tol};
            if (sum_w[12] || (sum_w[11:0] > max_val))
                upper = max_val;
            else
                upper = sum_w[11:0];

            // Result: true if val is within [lower, upper]
            return (val >= lower) && (val <= upper);
        end
    endfunction

    logic [3:0]  hit_x, hit_y, gun_trigger_d;
    logic [11:0] gun_xr [4], gun_yr [4];
    logic [11:0] x_pixr, y_pixr;   // <-- 12 bits
    // crosshair color of each player (red while its trigger is pressed)
    localparam logic [23:0] GUN_COL [4] = '{24'h00FF00,    // P1 green
                                           24'h00C0FF,    // P2 cyan
                                           24'hFFD000,    // P3 yellow
                                           24'hFF40FF};   // P4 magenta
    logic        cross_hit;
    logic [23:0] cross_col;
    always_comb begin
        cross_hit = 1'b0;
        cross_col = 24'h000000;
        for (int p = 3; p >= 0; p--)            // P1 drawn on top
            if (gun_enable[p] && ((hit_x[p] && y_pixr == gun_yr[p]) || (hit_y[p] && x_pixr == gun_xr[p]))) begin
                cross_hit = 1'b1;
                cross_col = gun_trigger_d[p] ? 24'hFF0000 : GUN_COL[p];
            end
    end
    localparam int GUN_CROSS_SIZE = 4;

    //-------------------------------------------------------------------------
    // Status indicators, row 11: "o SETUP   o LINK   o TX   o RX   o OUT"
    // (labels in JVS_RAM.mem, circles drawn here so they update in real time)
    // Filled circle = active, gray ring = inactive. SETUP / LINK follow the adapter LEDs
    // (lit when the open collector comparator output IN7 / IO3 is low).
    //-------------------------------------------------------------------------
    localparam int IND_Y0 = 88;                              // row 11
    localparam int IND_N  = 5;
    localparam int IND_X0 [IND_N] = '{16, 88, 152, 200, 248}; // cols 2, 11, 19, 25, 31
    localparam logic [23:0] IND_COL [IND_N] = '{24'hFF8000,   // SETUP orange
                                                24'h40FF40,   // LINK  green
                                                24'hFFC300,   // TX    yellow
                                                24'h00E5FF,   // RX    cyan
                                                24'hFF4040};  // OUT   red
    localparam logic [6:0] RING [7] = '{7'b0011100, 7'b0100010, 7'b1000001, 7'b1000001,
                                        7'b1000001, 7'b0100010, 7'b0011100};
    localparam logic [6:0] DISK [7] = '{7'b0011100, 7'b0111110, 7'b1111111, 7'b1111111,
                                        7'b1111111, 7'b0111110, 7'b0011100};
    logic [IND_N-1:0] ind_active;
    logic             ind_hit;
    logic [23:0]      ind_col;
    always_comb begin
        logic [11:0] lx, ly;
        ind_active = {gpio_output_value != 8'h00, jvs_rx_activity, jvs_tx_activity, ~snac_io3, ~snac_in7};
        ind_hit = 1'b0;
        ind_col = 24'h5A6270;
        ly = y_pixr - 12'(IND_Y0);
        if (y_pixr >= IND_Y0 && y_pixr < IND_Y0 + 7) begin
            for (int i = 0; i < IND_N; i++) begin
                lx = x_pixr - 12'(IND_X0[i]);
                if (x_pixr >= IND_X0[i] && x_pixr < IND_X0[i] + 7) begin
                    if (ind_active[i] ? DISK[ly][6 - lx] : RING[ly][6 - lx]) begin
                        ind_hit = 1'b1;
                        ind_col = ind_active[i] ? IND_COL[i] : 24'h5A6270;
                    end
                end
            end
        end
    end

    // Double border around the recoil mode gun icon (4 x 2 cells at row 4, col 29 of the JVS
    // debugger OSD): the target to shoot to toggle single / automatic recoil
    localparam int ICON_X0 = 29*8, ICON_X1 = 29*8 + 31, ICON_Y0 = 4*8, ICON_Y1 = 4*8 + 15;
    function automatic logic on_rect(input logic [11:0] x, y, input int l, t, r, b);
        on_rect = (((x == l) || (x == r)) && (y >= t) && (y <= b)) ||
                  (((y == t) || (y == b)) && (x >= l) && (x <= r));
    endfunction
    wire icon_border = on_rect(x_pixr, y_pixr, ICON_X0 - 3, ICON_Y0 - 3, ICON_X1 + 3, ICON_Y1 + 3) ||
                       on_rect(x_pixr, y_pixr, ICON_X0 - 5, ICON_Y0 - 5, ICON_X1 + 5, ICON_Y1 + 5);

    logic        gauge_hit_x, gauge_hit_y, target_hit;
    logic [23:0] gauge_col_x, gauge_col_y, target_col;
    always_comb begin
        gauge_hit_x = gauge_pix(x_pixr, y_pixr, GAUGE_Y_X, gauge_cx, gauge_col_x);
        gauge_hit_y = gauge_pix(x_pixr, y_pixr, GAUGE_Y_Y, gauge_cy, gauge_col_y);
        target_hit  = target_pix(x_pixr, y_pixr, tgt_px, tgt_py, target_col);
    end

    always_ff @(posedge clk) begin
        if(pixel_ce) begin
            for (int p = 0; p < 4; p++) begin
                hit_x[p]  <= is_around(x_pix, gun_x[p*12 +: 12], GUN_CROSS_SIZE, 319);
                hit_y[p]  <= is_around(y_pix, gun_y[p*12 +: 12], GUN_CROSS_SIZE, 239);
                gun_xr[p] <= gun_x[p*12 +: 12];
                gun_yr[p] <= gun_y[p*12 +: 12];
            end
            x_pixr <= x_pix;
            y_pixr <= y_pix;
            gun_trigger_d <= gun_trigger;


            // Status indicators (SETUP, LINK, TX, RX, OUT) on row 11
            if (ind_hit) begin
                {R_out, G_out, B_out} <= ind_col;
            end
            // Analog X / Y gauges and X/Y target
            else if (ana_has_x_r && gauge_hit_x) begin
                {R_out, G_out, B_out} <= gauge_col_x;
            end
            else if (ana_has_y_r && gauge_hit_y) begin
                {R_out, G_out, B_out} <= gauge_col_y;
            end
            else if (ana_has_x_r && ana_has_y_r && target_hit) begin
                {R_out, G_out, B_out} <= target_col;
            end
            //if((hit_x && !hit_y) || (!hit_x && hit_y)) begin //crosslines
            else if (cross_hit) begin                  // gun crosshairs, one color per player
                {R_out, G_out, B_out} <= cross_col;
            end
            else if (osd_active && icon_border) begin
                {R_out, G_out, B_out} <= COL_FRAME;
            end
            else
                {R_out, G_out, B_out} <= (video_osd[24] == 1'b0) ? video_osd[23:0] : (osd_active ? {Rgrayout,Ggrayout,Bgrayout} :{R_d2, G_d2, B_d2});

            hsync_out  <= hsync_d2;
            vsync_out  <= vsync_d2;
            hblank_out <= hblank_d2;
            vblank_out <= vblank_d2;
        end
    end
endmodule
