//RndMnkIII. 09/2025
// osd_writer.sv
// Interface to write to OSD character RAM buffer, with support for various data formats.

//`default_nettype none
module osd_writer #(
  parameter int COLS = 40,
  parameter int ROWS = 30,
  parameter int WIDTH_BITS = 16
)(
  input  logic clk,
  input  logic rst,

  input  logic        osd_writer_start_init,
  input  logic        osd_writer_clear_en,
  input  logic [7:0]  osd_writer_clear_char,
  input  logic [15:0] osd_writer_value1,
  input  logic [15:0] osd_writer_value2,

  // Video RAM buffer interface
  output logic v_we,
  output logic [15:0] v_wr_addr,
  output  logic [7:0] v_wr_data
);
  import osd_cmd_pkg::*;

  // VRAM
//   logic [15:0] v_rd_addr; logic [7:0] v_rd_data;
//   logic v_we; logic [15:0] v_wr_addr; logic [7:0] v_wr_data;

//   osd_textbuf #(.COLS(COLS), .ROWS(ROWS)) vram_i (
//     .clk, .rd_addr(v_rd_addr), .rd_data(v_rd_data),
//     .we(v_we), .wr_addr(v_wr_addr), .wr_data(v_wr_data)
//   );

  //assign v_rd_addr = '0; // demo

  // ROM de cadenas
  localparam int STR_ADDR_W = 16;
  logic [STR_ADDR_W-1:0] str_rd_addr;
  logic                  str_rd_en;
  logic [7:0]            str_rd_data;

  osd_demo_str_rom #(.ADDR_W(STR_ADDR_W)) rom_i (
    .clk, .en(str_rd_en), .addr(str_rd_addr), .data(str_rd_data)
  );

  // Dispatcher
  logic                   d_cmd_valid, d_cmd_ready;
  logic  [2:0]            d_cmd_type;
  logic [15:0]            d_base_addr;
  logic [WIDTH_BITS-1:0]  d_value;
  logic [STR_ADDR_W-1:0]  d_str_base_addr;
  logic  [7:0]            d_dec_minw;
  logic                   d_dec_zpad;
  logic                   d_hex_pfx, d_hex_uc;
  logic  [7:0]            d_hex_min_nibbles;
  logic                   d_bin_pfx, d_bin_g4;
  logic                   disp_we; logic [15:0] disp_addr; logic [7:0] disp_data;
  logic [$clog2(4+1)-1:0] disp_fifo_level;

  osd_print_dispatcher #(
    .WIDTH(WIDTH_BITS),
    .FIFO_DEPTH(4),
    .STR_ADDR_W(STR_ADDR_W),
    .RD_LATENCY(1)
  ) disp_i (
    .clk, .rst,
    .cmd_valid(d_cmd_valid), .cmd_ready(d_cmd_ready),
    .cmd_type(d_cmd_type), .base_addr(d_base_addr), .value(d_value),
    .str_base_addr(d_str_base_addr),
    .dec_min_width(d_dec_minw), .dec_zero_pad(d_dec_zpad),
    .hex_prefix_0x(d_hex_pfx), .hex_uppercase(d_hex_uc), .hex_min_nibbles(d_hex_min_nibbles),
    .bin_prefix_0b(d_bin_pfx), .bin_group4(d_bin_g4),
    .char_we(disp_we), .char_addr(disp_addr), .char_data(disp_data),
    .str_rd_addr(str_rd_addr), .str_rd_en(str_rd_en), .str_rd_data(str_rd_data),
    .fifo_level(disp_fifo_level)
  );

  // Batch enqueuer
  localparam int NUM_CMDS_MAX = 16;
  logic                                be_load_we;
  logic [$clog2(NUM_CMDS_MAX)-1:0]     be_load_addr;
  osd_cmd_t                            be_load_data;
  logic [$clog2(NUM_CMDS_MAX+1)-1:0]   be_seq_count;
  logic                                be_start;
  logic                                be_busy, be_done;

  osd_cmd_batch_enqueuer #(.WIDTH(WIDTH_BITS), .DEPTH(NUM_CMDS_MAX)) beq_i (
    .clk, .rst,
    .load_we(be_load_we), .load_addr(be_load_addr), .load_data(be_load_data),
    .seq_count(be_seq_count),
    .start(be_start), .busy(be_busy), .done(be_done),
    .cmd_valid(d_cmd_valid), .cmd_ready(d_cmd_ready),
    .cmd_type(d_cmd_type), .base_addr(d_base_addr), .value(d_value), .str_base_addr(d_str_base_addr),
    .dec_min_width(d_dec_minw), .dec_zero_pad(d_dec_zpad),
    .hex_prefix_0x(d_hex_pfx), .hex_uppercase(d_hex_uc), .hex_min_nibbles(d_hex_min_nibbles),
    .bin_prefix_0b(d_bin_pfx), .bin_group4(d_bin_g4)
  );

  // Init FSM dinámica
  logic init_busy, init_done;
  logic init_v_we; logic [15:0] init_v_addr; logic [7:0] init_v_data;

  // Stream de programación (productor de ejemplo)
  logic               p_valid, p_ready, p_last;
  osd_cmd_t           p_cmd;

  osd_init_fsm_dyn #(
    .COLS(COLS), .ROWS(ROWS), .NUM_CMDS_MAX(NUM_CMDS_MAX)
  ) init_i (
    .clk, .rst,
    .init_start(osd_writer_start_init), .init_busy(init_busy), .init_done(init_done),
    .clear_enable(osd_writer_clear_en), .clear_char(osd_writer_clear_char),
    .vram_we(init_v_we), .vram_addr(init_v_addr), .vram_data(init_v_data),
    .prog_valid(p_valid), .prog_ready(p_ready), .prog_cmd(p_cmd), .prog_last(p_last),
    .be_load_we(be_load_we), .be_load_addr(be_load_addr), .be_load_data(be_load_data),
    .be_seq_count(be_seq_count), .be_start(be_start), .be_busy(be_busy), .be_done(be_done)
  );

  // Mux escritura VRAM
  always_comb begin
    if (init_busy && osd_writer_clear_en && init_v_we) begin
      v_we = 1'b1; v_wr_addr = init_v_addr; v_wr_data = init_v_data;
    end else begin
      v_we = disp_we; v_wr_addr = disp_addr; v_wr_data = disp_data;
    end
  end

  // Productor de ejemplo: "V=" + udec + " " + hex + "\n"
  localparam logic [15:0] BA_VEQ  = COLS * 16 + 10; // 16'd0;
  localparam logic [15:0] BA_UDEC = COLS * 16 + 12; //16'd2;
  localparam logic [15:0] BA_SP   = COLS * 16 + 17; //16'd7;
  localparam logic [15:0] BA_HEX  = COLS * 16 + 18; //16'd8;
  localparam logic [15:0] BA_NL   = COLS * 16 + 16; //16'd16;

  localparam logic [31:0] STR_PTR_VEQ = 32'h0000_0100;
  localparam logic [31:0] STR_PTR_SP  = 32'h0000_0200;
  localparam logic [31:0] STR_PTR_NL  = 32'h0000_0210;

  typedef enum logic [2:0] {PS_IDLE, PS_C0, PS_C1, PS_C2, PS_C3, PS_C4, PS_DONE} prod_state_t;
  prod_state_t pstate;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      pstate <= PS_IDLE; p_valid <= 1'b0; p_last <= 1'b0; p_cmd <= '0;
    end else begin
      p_valid <= 1'b0; p_last <= 1'b0;
      case (pstate)
        PS_IDLE: if (osd_writer_start_init) pstate <= PS_C0;
        PS_C0: if (p_ready) begin
          p_cmd <= make_cmd_str(BA_VEQ, STR_PTR_VEQ); p_cmd.pending <= 1'b1; p_valid <= 1'b1; pstate <= PS_C1; end
        PS_C1: if (p_ready) begin
          p_cmd <= make_cmd_udec(BA_UDEC, osd_writer_value1, 8'd1, 1'b0); p_cmd.pending <= 1'b1; p_valid <= 1'b1; pstate <= PS_C2; end
        PS_C2: if (p_ready) begin
          p_cmd <= make_cmd_str(BA_SP, STR_PTR_SP); p_cmd.pending <= 1'b1; p_valid <= 1'b1; pstate <= PS_C3; end
        PS_C3: if (p_ready) begin
          p_cmd <= make_cmd_hex(BA_HEX, osd_writer_value1, 8'd8, 1'b1, 1'b1); p_cmd.pending <= 1'b1; p_valid <= 1'b1; pstate <= PS_C4; end
        PS_C4: if (p_ready) begin
          p_cmd <= make_cmd_str(BA_NL, STR_PTR_NL); p_cmd.pending <= 1'b1; p_valid <= 1'b1; p_last <= 1'b1; pstate <= PS_DONE; end
        PS_DONE: begin
          if (!osd_writer_start_init) pstate <= PS_IDLE;
        end
        default: pstate <= PS_IDLE;
      endcase
    end
  end

endmodule

// ROM de cadenas NUL-terminadas (latencia 1 ciclo)
module osd_demo_str_rom #(
  parameter int ADDR_W = 16
)(
  input  logic              clk,
  input  logic              en,
  input  logic [ADDR_W-1:0] addr,
  output logic [7:0]        data
);
  logic [7:0] q;
  always_comb begin
    q = 8'h00;
    unique case (addr)
      16'h0100: q = "V";
      16'h0101: q = "=";
      16'h0102: q = 8'h00;
      16'h0200: q = " ";
      16'h0201: q = 8'h00;
      16'h0210: q = "\n";
      16'h0211: q = 8'h00;
      default:  q = 8'h00;
    endcase
  end
  always_ff @(posedge clk) begin
    if (en) data <= q;
  end
endmodule
