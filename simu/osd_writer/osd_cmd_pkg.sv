
// osd_cmd_pkg.sv — Estructura de comando OSD y constructores.

package osd_cmd_pkg;

  parameter int BASE_ADDR_W = 16;
  parameter int PAYLOAD_W   = 64;

  typedef enum logic [2:0] {
    CMD_STR  = 3'd0,
    CMD_UDEC = 3'd1,
    CMD_SDEC = 3'd2,
    CMD_HEX  = 3'd3,
    CMD_BIN  = 3'd4
  } osd_cmd_type_e;

  typedef struct packed {
    logic                    pending;
    osd_cmd_type_e           osd_cmd_type;
    logic [BASE_ADDR_W-1:0]  base_addr;
    logic [PAYLOAD_W-1:0]    payload;
  } osd_cmd_t;

  // Helpers
  function automatic osd_cmd_t make_cmd_str(
      input logic [BASE_ADDR_W-1:0] base_addr,
      input logic [31:0]            str_base_addr
  );
    osd_cmd_t c;
    c.pending   = 1'b1;
    c.osd_cmd_type = CMD_STR;
    c.base_addr = base_addr;
    c.payload   = '0;
    c.payload[31:0] = str_base_addr;
    return c;
  endfunction

  function automatic osd_cmd_t make_cmd_udec(
      input logic [BASE_ADDR_W-1:0] base_addr,
      input logic [31:0]            value,
      input logic [7:0]             min_width,
      input logic                   zero_pad
  );
    osd_cmd_t c;
    c.pending   = 1'b1;
    c.osd_cmd_type= CMD_UDEC;
    c.base_addr = base_addr;
    c.payload   = '0;
    c.payload[31:0]  = value;
    c.payload[39:32] = min_width;
    c.payload[40]    = zero_pad;
    return c;
  endfunction

  function automatic osd_cmd_t make_cmd_sdec(
      input logic [BASE_ADDR_W-1:0] base_addr,
      input logic [31:0]            value_signed,
      input logic [7:0]             min_width,
      input logic                   zero_pad
  );
    osd_cmd_t c;
    c.pending   = 1'b1;
    c.osd_cmd_type = CMD_SDEC;
    c.base_addr = base_addr;
    c.payload   = '0;
    c.payload[31:0]  = value_signed;
    c.payload[39:32] = min_width;
    c.payload[40]    = zero_pad;
    return c;
  endfunction

  function automatic osd_cmd_t make_cmd_hex(
      input logic [BASE_ADDR_W-1:0] base_addr,
      input logic [31:0]            value,
      input logic [7:0]             min_nibbles,
      input logic                   prefix_0x,
      input logic                   uppercase
  );
    osd_cmd_t c;
    c.pending   = 1'b1;
    c.osd_cmd_type= CMD_HEX;
    c.base_addr = base_addr;
    c.payload   = '0;
    c.payload[31:0]  = value;
    c.payload[39:32] = min_nibbles;
    c.payload[40]    = prefix_0x;
    c.payload[41]    = uppercase;
    return c;
  endfunction

  function automatic osd_cmd_t make_cmd_bin(
      input logic [BASE_ADDR_W-1:0] base_addr,
      input logic [31:0]            value,
      input logic                   prefix_0b,
      input logic                   group4
  );
    osd_cmd_t c;
    c.pending   = 1'b1;
    c.osd_cmd_type= CMD_BIN;
    c.base_addr = base_addr;
    c.payload   = '0;
    c.payload[31:0] = value;
    c.payload[40]   = prefix_0b;
    c.payload[41]   = group4;
    return c;
  endfunction

  function automatic osd_cmd_t clear_pending(input osd_cmd_t in);
    osd_cmd_t c = in; c.pending = 1'b0; return c;
  endfunction

endpackage
