// ROM_snac_strings.sv
// - 21 stringz  × 32 fixed length = 672 bytes
`default_nettype none

module ROM_snac_strings #(
    parameter FILENAME = "snac_strings.mem"  // debe estar en el proyecto
)(
    input  logic               clk,
    input  logic [9:0]         addr,  
    output logic [7:0]         data
);

    localparam int STR_LEN    = 32;
    localparam int NUM_STR    = 21;
    localparam int MEM_BYTES  = STR_LEN * NUM_STR;
	 
    (* ramstyle = "M10K, no_rw_check" *)
    logic [7:0] mem [0:MEM_BYTES-1];

    initial begin
        $readmemh(FILENAME, mem);
    end

    // sinchronous read
    always_ff @(posedge clk) begin
        data <= mem[addr];
    end
endmodule
