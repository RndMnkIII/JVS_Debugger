
// jvs_node_info_pkg.sv — Package defining the structure for JVS node information
package jvs_node_info_pkg;
  parameter int MAX_JVS_NODES   = 2;
  parameter int NODE_NAME_SIZE  = 100;

	typedef struct {
		//logic [7:0] node_name [0:MAX_JVS_NODES-1][0:NODE_NAME_SIZE-1];
		logic [7:0] node_cmd_ver [0:MAX_JVS_NODES-1];    // Command version for each node
		logic [7:0] node_jvs_ver [0:MAX_JVS_NODES-1];    // JVS version for each node  
		logic [7:0] node_com_ver [0:MAX_JVS_NODES-1];    // Communication version for each node
	} jvs_node_info_t;

	// Nibble (0..15) a ASCII ('0'..'9','A'..'F' o 'a'..'f')
  function automatic logic [7:0] hex2ascii(input logic [3:0] v, input logic uppercase);
    if (v < 10) hex2ascii = "0" + v;
    else        hex2ascii = (uppercase ? "A" : "a") + (v - 10);
  endfunction
endpackage : jvs_node_info_pkg