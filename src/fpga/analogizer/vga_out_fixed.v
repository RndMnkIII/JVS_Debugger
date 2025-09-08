module vga_out_fixed
(
    input  wire        clk,
    input  wire        ypbpr_en,

    input  wire        hsync,
    input  wire        vsync,
    input  wire        csync,
    input  wire        de,

    input  wire [23:0] din,
    output wire [23:0] dout,

    output reg         hsync_o,
    output reg         vsync_o,
    output reg         csync_o,
    output reg         de_o
);

wire [7:0] red   = din[23:16];
wire [7:0] green = din[15:8];
wire [7:0] blue  = din[7:0];

// http://marsee101.blog19.fc2.com/blog-entry-2311.html


// Y  =       0.301*R + 0.586*G + 0.113*B (Y  =  0.299*R + 0.587*G + 0.114*B)
// Pb = 128 - 0.168*R - 0.332*G + 0.500*B (Pb = -0.169*R - 0.331*G + 0.500*B)
// Pr = 128 + 0.500*R - 0.418*G - 0.082*B (Pr =  0.500*R - 0.419*G - 0.081*B)

reg  [7:0] y, pb, pr;
reg [23:0] rgb;

// [ADD] Pipeline extra para Y/Pb/Pr (igualar latencia a 2 ciclos)
reg [7:0] y_d1,  y_d2;
reg [7:0] pb_d1, pb_d2;
reg [7:0] pr_d1, pr_d2;

// [ADD] Niveles 8-bit para blank/sync en YPbPr
localparam [7:0] Y_BLACK_8 = 8'd109;  // ~0.3 V (negro) con F.S.=0.7 Vpp
localparam [7:0] C_MID_8   = 8'd128;  // centro (0) para Pb/Pr

// [ADD] Salidas 8-bit tras “override” por fases
reg [7:0] y8_out, pb8_out, pr8_out;

always @(posedge clk) begin
    // --- Cálculo RGB->YPbPr (original) ---
    reg [18:0] y_1r, pb_1r, pr_1r;
    reg [18:0] y_1g, pb_1g, pr_1g;
    reg [18:0] y_1b, pb_1b, pr_1b;
    reg [18:0] y_2, pb_2, pr_2;
    reg [23:0] din1, din2;
    reg hsync2, vsync2, csync2, de2;
    reg hsync1, vsync1, csync1, de1;

    y_1r  <= {red,   6'd0} + {red,   3'd0} + {red,   2'd0} + red;
    pb_1r <= 19'd32768 - ({red,   5'd0} + {red,   3'd0} + {red,   1'd0});
    pr_1r <= 19'd32768 + {red,   7'd0};

    y_1g  <= {green, 7'd0} + {green, 4'd0} + {green, 2'd0} + {green, 1'd0};
    pb_1g <= {green, 6'd0} + {green, 4'd0} + {green, 2'd0} + green;
    pr_1g <= {green, 6'd0} + {green, 5'd0} + {green, 3'd0} + {green, 1'd0};

    y_1b  <= {blue,  4'd0} + {blue,  3'd0} + {blue,  2'd0} + blue;
    pb_1b <= {blue,  7'd0};
    pr_1b <= {blue,  4'd0} + {blue,  2'd0} + blue;

    y_2  <= y_1r  + y_1g  + y_1b;
    pb_2 <= pb_1r - pb_1g + pb_1b;
    pr_2 <= pr_1r - pr_1g - pr_1b;

    y  <=  y_2[18] ? 8'd0   : y_2[16] ? 8'd255 : y_2[15:8];
    pb <= pb_2[18] ? 8'd0   : pb_2[16] ? 8'd255 : pb_2[15:8];
    pr <= pr_2[18] ? 8'd0   : pr_2[16] ? 8'd255 : pr_2[15:8];

    // Salidas de sincronía y DE a 2 ciclos (original)
    hsync_o <= hsync2; hsync2 <= hsync1; hsync1 <= hsync;
    vsync_o <= vsync2; vsync2 <= vsync1; vsync1 <= vsync;
    csync_o <= csync2; csync2 <= csync1; csync1 <= csync;
    de_o    <= de2;    de2    <= de1;    de1    <= de;

    // Pipeline de RGB de entrada (original)
    rgb <= din2; din2 <= din1; din1 <= din;

    // [ADD] Pipeline a 2 ciclos para Y/Pb/Pr (alineación con *_o y rgb)
    y_d1  <= y;    y_d2  <= y_d1;
    pb_d1 <= pb;   pb_d2 <= pb_d1;
    pr_d1 <= pr;   pr_d2 <= pr_d1;

    // [ADD] Override por fases usando señales alineadas (etapa 2)
    // Usamos de2/csync2 (alineadas). Asumimos csync activo-bajo: pulso cuando csync2==0.
    if (de2) begin
        // Vídeo activo: deja pasar Y/Pb/Pr tal cual (8 bits)
        y8_out  <= y_d2;
        pb8_out <= pb_d2;
        pr8_out <= pr_d2;
    end else if (~csync2) begin
        // Pulso de sync: Y en NEGRO (el ADV7123 insertará el tip con su pin SYNC).
        // Pb/Pr centrados (0).
        y8_out  <= Y_BLACK_8;
        pb8_out <= C_MID_8;
        pr8_out <= C_MID_8;
    end else begin
        // Blanking (porches sin sync): Y negro y Pb/Pr centrados.
        y8_out  <= Y_BLACK_8;
        pb8_out <= C_MID_8;
        pr8_out <= C_MID_8;
    end
end

// [MOD] Salida: YPbPr en 8b (Pr,Y,Pb) o RGB original
assign dout = ypbpr_en ? {pr8_out, y8_out, pb8_out} : rgb;

endmodule
