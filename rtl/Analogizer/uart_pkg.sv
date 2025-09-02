// uart_pkg.sv — utilities
package uart_pkg;
  typedef enum logic [1:0] {PAR_NONE=2'b00, PAR_EVEN=2'b01, PAR_ODD=2'b10} parity_t;

  function automatic logic majority3(input logic a,b,c);
    return (a & b) | (a & c) | (b & c);
  endfunction
endpackage
