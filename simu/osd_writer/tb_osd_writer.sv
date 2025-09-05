//Questasim:
//Optimize the design:
//vopt +acc tb_osd_writer -o tb_osd_writer_opt
//Load the design:
//vsim tb_osd_writer_opt
//do file.do
//run -all
`timescale 1ns/1ps
`default_nettype none

module tb_osd_writer;

  // --- Parámetros ---
  localparam int COLS       = 40;
  localparam int ROWS       = 30;
  localparam int WIDTH_BITS = 16;

  // --- Señales DUT ---
  logic clk, rst;
  logic        osd_writer_start_init;
  logic        osd_writer_clear_en;
  logic [7:0]  osd_writer_clear_char;
  logic [15:0] osd_writer_value1;
  logic [15:0] osd_writer_value2;

  logic        v_we;
  logic [15:0] v_wr_addr;
  logic [7:0]  v_wr_data;

  // --- Generación de reloj ---
  initial clk = 1'b0;
  always #5 clk = ~clk;   // periodo 10 ns → 100 MHz

  // --- Instancia del DUT ---
  osd_writer #(
    .COLS(COLS),
    .ROWS(ROWS),
    .WIDTH_BITS(WIDTH_BITS)
  ) dut (
    .clk,
    .rst,
    .osd_writer_start_init,
    .osd_writer_clear_en,
    .osd_writer_clear_char,
    .osd_writer_value1,
    .osd_writer_value2,
    .v_we,
    .v_wr_addr,
    .v_wr_data
  );

  // --- Estímulos ---
  initial begin
    // valores por defecto
    osd_writer_start_init = 1'b0;
    osd_writer_clear_en   = 1'b0;
    osd_writer_clear_char = " ";
    osd_writer_value1     = 16'h1234;
    osd_writer_value2     = 16'hABCD;

    // reset síncrono
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // esperar un poco
    repeat (10) @(posedge clk);

    // lanzar inicialización + clear
    osd_writer_clear_en   = 0;
    osd_writer_clear_char = " ";
    osd_writer_start_init = 1;
    @(posedge clk);
    osd_writer_start_init = 0;

    // esperar a que el DUT haga cosas
    repeat (500) @(posedge clk);

    // terminar
    $display("Fin de la simulación");
    $finish;
  end

endmodule