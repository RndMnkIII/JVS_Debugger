
// jvs_node_info_pkg.sv — Package defining the structure for JVS node information
package jvs_node_info_pkg;
  // Parameters inside a package
  parameter int MAX_JVS_NODES   = 2;
  parameter int NODE_NAME_SIZE  = 100;

	typedef struct {
		//logic [7:0] node_name [0:MAX_JVS_NODES-1][0:NODE_NAME_SIZE-1];
		logic [7:0] node_cmd_ver [0:MAX_JVS_NODES-1];    // Command version for each node
		logic [7:0] node_jvs_ver [0:MAX_JVS_NODES-1];    // JVS version for each node  
		logic [7:0] node_com_ver [0:MAX_JVS_NODES-1];    // Communication version for each node
	} jvs_node_info_t;
endpackage : jvs_node_info_pkg