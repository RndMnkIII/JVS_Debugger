
// osd_print_dispatcher.sv — Dispatcher que enruta comandos a los writers y multiplexa la VRAM.
//`default_nettype none

module osd_print_dispatcher #(
  parameter int WIDTH        = 32,
  parameter int FIFO_DEPTH   = 4,
  parameter int STR_ADDR_W   = 16,
  parameter int RD_LATENCY   = 1
)(
  input  logic                   clk,
  input  logic                   rst,

  // Entrada de comandos (push)
  input  logic                   cmd_valid,
  output logic                   cmd_ready,
  input  logic  [2:0]            cmd_type,
  input  logic [15:0]            base_addr,
  input  logic [WIDTH-1:0]       value,
  input  logic [STR_ADDR_W-1:0]  str_base_addr,
  input  logic  [7:0]            dec_min_width,
  input  logic                   dec_zero_pad,
  input  logic                   hex_prefix_0x,
  input  logic                   hex_uppercase,
  input  logic  [7:0]            hex_min_nibbles,
  input  logic                   bin_prefix_0b,
  input  logic                   bin_group4,

  // Salida a VRAM
  output logic                   char_we,
  output logic [15:0]            char_addr,
  output logic  [7:0]            char_data,

  // Puerto de lectura cadenas
  output logic [STR_ADDR_W-1:0]  str_rd_addr,
  output logic                   str_rd_en,
  input  logic  [7:0]            str_rd_data,

  // Estado
  output logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_level
);

  // FIFO de comandos
  localparam int CMDW = 3+16+WIDTH+STR_ADDR_W + 8+1 + 1+1+8 + 1+1;
  typedef logic [CMDW-1:0] cmd_t;

  function automatic cmd_t pack_cmd(
    input logic [2:0] t,
    input logic [15:0] ba,
    input logic [WIDTH-1:0] v,
    input logic [STR_ADDR_W-1:0] sa,
    input logic [7:0] dminw,
    input logic dzpad,
    input logic hx_pfx,
    input logic hx_uc,
    input logic [7:0] hx_min,
    input logic bn_pfx,
    input logic bn_g4
  );
    return {bn_g4, bn_pfx, hx_min, hx_uc, hx_pfx, dzpad, dminw, sa, v, ba, t};
  endfunction

  task automatic unpack_cmd(input cmd_t x,
    output logic [2:0] t,
    output logic [15:0] ba,
    output logic [WIDTH-1:0] v,
    output logic [STR_ADDR_W-1:0] sa,
    output logic [7:0] dminw,
    output logic dzpad,
    output logic hx_pfx,
    output logic hx_uc,
    output logic [7:0] hx_min,
    output logic bn_pfx,
    output logic bn_g4
  );
    {bn_g4, bn_pfx, hx_min, hx_uc, hx_pfx, dzpad, dminw, sa, v, ba, t} = x;
  endtask

  cmd_t mem [0:FIFO_DEPTH-1];
  logic [$clog2(FIFO_DEPTH)-1:0] wptr, rptr;
  logic [$clog2(FIFO_DEPTH+1)-1:0] count;

  // Mux VRAM + ROM control
  logic [2:0]            q_type;
  logic [15:0]           q_base_addr;
  logic [WIDTH-1:0]      q_value;
  logic [STR_ADDR_W-1:0] q_str_base;
  logic [7:0]            q_dec_minw;
  logic                  q_dec_zpad;
  logic                  q_hex_pfx, q_hex_uc;
  logic [7:0]            q_hex_min;
  logic                  q_bin_pfx, q_bin_g4;
  
  assign fifo_level = count;
  assign cmd_ready = (count != FIFO_DEPTH);

always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    wptr <= '0; 
  end else begin
    if (cmd_valid && cmd_ready) begin
		 mem[wptr] <= pack_cmd(cmd_type, base_addr, value, str_base_addr,
								dec_min_width, dec_zero_pad,
								hex_prefix_0x, hex_uppercase, hex_min_nibbles,
								bin_prefix_0b, bin_group4);
		 wptr <= (wptr == FIFO_DEPTH-1) ? '0 : (wptr + 1'b1);
    end
  end
end

  // Instancias writers
  // STR
  logic str_start, str_busy, str_done;
  logic str_we;  logic [15:0] str_addr; logic [7:0] str_data;
  logic [STR_ADDR_W-1:0] str_rd_addr_i; logic str_rd_en_i;

  osd_str_writer #(.RD_LATENCY(RD_LATENCY), .STR_ADDR_W(STR_ADDR_W)) u_str (
    .clk, .rst,
    .start(str_start), .busy(str_busy), .done(str_done),
    .base_addr(q_base_addr),
    .char_we(str_we), .char_addr(str_addr), .char_data(str_data),
    .str_base_addr(q_str_base),
    .str_rd_addr(str_rd_addr_i), .str_rd_en(str_rd_en_i), .str_rd_data(str_rd_data)
  );

  // UDEC
  logic udec_start, udec_busy, udec_done;
  logic udec_we;  logic [15:0] udec_addr; logic [7:0] udec_data;

  osd_udec_writer_seq #(.WIDTH(WIDTH)) u_udec (
    .clk, .rst,
    .start(udec_start), .busy(udec_busy), .done(udec_done),
    .base_addr(q_base_addr),
    .min_width(q_dec_minw), .zero_pad(q_dec_zpad),
    .value(q_value),
    .char_we(udec_we), .char_addr(udec_addr), .char_data(udec_data)
  );

  // SDEC
  logic sdec_start, sdec_busy, sdec_done;
  logic sdec_we;  logic [15:0] sdec_addr; logic [7:0] sdec_data;

  osd_sdec_writer #(.WIDTH(WIDTH)) u_sdec (
    .clk, .rst,
    .start(sdec_start), .busy(sdec_busy), .done(sdec_done),
    .base_addr(q_base_addr),
    .min_width(q_dec_minw), .zero_pad(q_dec_zpad),
    .value(q_value[WIDTH-1:0]),
    .char_we(sdec_we), .char_addr(sdec_addr), .char_data(sdec_data)
  );

  // HEX
  logic hex_start, hex_busy, hex_done;
  logic hex_we;  logic [15:0] hex_addr; logic [7:0] hex_data;

  osd_hex_writer #(.WIDTH(WIDTH)) u_hex (
    .clk, .rst,
    .start(hex_start), .busy(hex_busy), .done(hex_done),
    .base_addr(q_base_addr),
    .prefix_0x(q_hex_pfx), .uppercase(q_hex_uc), .min_nibbles(q_hex_min),
    .value(q_value),
    .char_we(hex_we), .char_addr(hex_addr), .char_data(hex_data)
  );

  // BIN
  logic bin_start, bin_busy, bin_done;
  logic bin_we;  logic [15:0] bin_addr; logic [7:0] bin_data;

  osd_bin_writer #(.WIDTH(WIDTH)) u_bin (
    .clk, .rst,
    .start(bin_start), .busy(bin_busy), .done(bin_done),
    .base_addr(q_base_addr),
    .prefix_0b(q_bin_pfx), .group4(q_bin_g4),
    .value(q_value),
    .char_we(bin_we), .char_addr(bin_addr), .char_data(bin_data)
  );

  // Multiplexado de escrituras
  always_comb begin
    char_we   = 1'b0; char_addr = '0; char_data = '0;
    str_rd_addr = '0; str_rd_en = 1'b0;
    unique case (q_type)
      3'd0: begin char_we=str_we;  char_addr=str_addr; char_data=str_data; str_rd_addr=str_rd_addr_i; str_rd_en=str_rd_en_i; end
      3'd1: begin char_we=udec_we; char_addr=udec_addr; char_data=udec_data; end
      3'd2: begin char_we=sdec_we; char_addr=sdec_addr; char_data=sdec_data; end
      3'd3: begin char_we=hex_we;  char_addr=hex_addr; char_data=hex_data; end
      3'd4: begin char_we=bin_we;  char_addr=bin_addr; char_data=bin_data; end
      default: ;
    endcase
  end

  // FSM de despacho
  typedef enum logic [1:0] {D_IDLE, D_FETCH, D_RUN, D_DONE} dstate_t;
  dstate_t dstate;
  logic do_wr;
  logic do_rd;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      dstate <= D_IDLE;
      str_start<=0; udec_start<=0; sdec_start<=0; hex_start<=0; bin_start<=0;
      q_type<='0; q_base_addr<='0; q_value<='0; q_str_base<='0; q_dec_minw<='0;
      q_dec_zpad<=0; q_hex_pfx<=0; q_hex_uc<=0; q_hex_min<='0; q_bin_pfx<=0; q_bin_g4<=0;
		  rptr   <= '0;
      count  <= '0; 
    end else begin
      str_start<=0; udec_start<=0; sdec_start<=0; hex_start<=0; bin_start<=0;
      do_wr <= (cmd_valid && cmd_ready);
      do_rd <= 1'b0;

      unique case (dstate)
        D_IDLE: begin
          if (count != 0) dstate <= D_FETCH;
        end

        D_FETCH: begin
          unpack_cmd(mem[rptr], q_type, q_base_addr, q_value, q_str_base,
                     q_dec_minw, q_dec_zpad, q_hex_pfx, q_hex_uc, q_hex_min, q_bin_pfx, q_bin_g4);
          rptr  <= (rptr == FIFO_DEPTH-1) ? '0 : rptr + 1'b1;
          do_rd  <= 1'b1;
          dstate<= D_RUN;
        end

        D_RUN: begin
          unique case (q_type)
            3'd0: if (!str_busy && !str_done) str_start <= 1'b1;
            3'd1: if (!udec_busy && !udec_done) udec_start <= 1'b1;
            3'd2: if (!sdec_busy && !sdec_done) sdec_start <= 1'b1;
            3'd3: if (!hex_busy  && !hex_done)  hex_start  <= 1'b1;
            3'd4: if (!bin_busy  && !bin_done)  bin_start  <= 1'b1;
            default: ;
          endcase

          if ((q_type==3'd0 && str_done) ||
              (q_type==3'd1 && udec_done)||
              (q_type==3'd2 && sdec_done)||
              (q_type==3'd3 && hex_done) ||
              (q_type==3'd4 && bin_done)) begin
            dstate <= D_DONE;
          end
        end

        D_DONE: begin
          dstate <= (count != 0) ? D_FETCH : D_IDLE;
        end
      endcase
		
      unique case ({do_wr, do_rd})
        2'b10: count <= count + 1'b1; // solo write
        2'b01: count <= count - 1'b1; // solo read
        default: /* sin cambio */ ;
      endcase
    end
  end

endmodule
