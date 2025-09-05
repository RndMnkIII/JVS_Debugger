
// osd_format_pkg.sv
// Utilidades ASCII y helpers generales.

package osd_format_pkg;

  // Nibble (0..15) a ASCII ('0'..'9','A'..'F' o 'a'..'f')
  function automatic logic [7:0] hex2ascii(input logic [3:0] v, input logic uppercase);
    if (v < 10) hex2ascii = "0" + v;
    else        hex2ascii = (uppercase ? "A" : "a") + (v - 10);
  endfunction

  // Bit -> '0'/'1'
  function automatic logic [7:0] bit2ascii(input logic b);
    return b ? "1" : "0";
  endfunction

  // Dígito BCD (0..9) -> ASCII
  function automatic logic [7:0] bcd2ascii(input logic [3:0] d);
    return "0" + d;
  endfunction

  // Aproximación de nº de dígitos decimales para WIDTH bits: ceil(W*log10(2)) + margen
  function automatic int dec_digits_for_width(input int WIDTH);
    int d;
    d = ((WIDTH*30103)+99999)/100000; // ceil(W*0.30103)
    if (d < 1) d = 1;
    return d + 1;
  endfunction

endpackage
