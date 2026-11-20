//This module encapsulates all Analogizer adapter signals
// Original work by @RndMnkIII. 
// Date: 05/2024 
// Releases: 
// * 1.0 05/2024    Initial RGBS output mode
// * 1.1            Added SOG modes: RGsB, YPbPt
// * 1.2            Added Mike Simon Y/C module, Scandoubler SVGA Mist module.     
// * 1.3 11/02/2025 Added Bridge interface to directly access to the Analogizer settings, now returns the settings. Added NES SNAC Zapper support.

// *** Analogizer R.3 adapter ***
// * WHEN SOG SWITCH IS IN ON POSITION, OUTPUTS CSYNC ON G CHANNEL
// # WHEN YPbPr VIDEO OUTPUT IS SELECTED, Y->G, Pr->R, Pb->B
//Pin mappings:                                               VGA CONNECTOR                                                                                          USB3 TYPE A FEMALE CONNECTOR (SNAC)
//                        ______________________________________________________________________________________________________________________________________________________________________________________________________  
//                       /                              VS  HS          R#  G*# B#                                                                  1      2       3       4      5       6       7       8       9              \
//                       |                              |   |           |   |   |                                                                 VBUS   D-      D+      GND     RX-     RX+     GND_D   TX-     TX+             |
//FUNCTION:              |                              |   |           |   |   |                                                                 +5V    OUT1    OUT2    GND     IO3     IN4     IO5     IO6     IN7             |
//                       |  A                           |   |           |   |   |                                                                          ^       ^              ^       |       ^       ^       |              |
//                       |  N             SOG           |   |           |   |   |                                                                          |       |              V       V       V       V       V              |
//                       |  A           -------         |   |           |   |   |                                                                                                                                                |
//                       |  O    OFF   |   S   |--GND   |   |         +------------+                                                                                                                                             |
//                       |  L          |   W   |        |   |   SYNC  |            |                                                                                                                                             |
//  PIN DIR:             |  G          |   I   +--------------------->|            |---------------------------------------------------------------------------------------------------------+                                   |
//  ^ OUTPUT             |  I          |   T   |        |   |         |  RGB DAC   |                                                                                                         |                                   |
//  V INPUT              |  Z          |   C   |        |   |         |            |===================================================================++                                    |                                   |
//                       |  E    ON ===|   H   |--------+   |         +------------+                                                                   ||                                    |                                   |
//                       |  R           -------         |   |            ||  |   | /BLANK                                                              ||                                    |                                   |
//                       |                              |   +--------+   ||  |   +------------------------------------------------------------------+  ||                                    |                                   |
//                       |  R                           +------+     |   ||  +===============================++                                     |  ||                                    |                                   |
//                       |  3                                  |     |   ||                                  ||                                     |  ||                                    |                                   |
//                       |     CONF.B        IO5V       ---    |     |   \\================================  \\================================     |  \\================================   VID               IO3^  IO6^         |
//                       |     CONF.A   IN4  ---  IN7   IO3V   VS    HS    R0    R1    R2    R3    R4    R5    G0    G1    G2    G3    G4    G5   /BLK   B0    B1    B2    B3    B4    B5   CLK  OUT1   OUT2  IO5^  IO6V         |
//                       |      __3.3V__ |___ | __ |_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____^__GND__    |
//POCKET                 |     /         V    V    V     V     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     ^     V       \   |
//CARTRIDGE PIN #:       \____|     1    2    3    4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19    20    21    22    23    24    25    26    27    28    29    30    31   32  |___/
//                             \_________|____|____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_______/    
//Pocket Pin Name:                       |    |    |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank0[7] --------------------+    |    |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank0[6] -------------------------+    |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank0[5] ------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank0[4] ------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank3[0] ------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank3[1] ------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank3[2] ------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank3[3] ------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank3[4] ------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank3[5] ------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank3[6] ------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank3[7] ------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//------------------                                                                                           |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank2[0] ------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank2[1] ------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank2[2] ------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank2[3] ------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank2[4] ------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank2[5] ------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank2[6] ------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank2[7] ------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |     |            
//------------------                                                                                                                                           |     |     |     |     |     |     |     |     |     |            
//cart_tran_bank1[0] ------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |     |            
//cart_tran_bank1[1] ------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |     |            
//cart_tran_bank1[2] ------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |     |            
//cart_tran_bank1[3] ------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |     |            
//cart_tran_bank1[4] ------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |     |            
//cart_tran_bank1[5] ------------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |     |            
//cart_tran_bank1[6] ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |     |            
//cart_tran_bank1[7] ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |     |            
//cart_tran_pin30    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+     |            
//cart_tran_pin31    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+             

//Use: set_global_assignment -name VERILOG_MACRO "USE_DUMMY_JVS_DATA=1" 
//in project .qsf to use dummy data for simulation without JVS device
`default_nettype none
`timescale 1ns / 1ps

import jvs_node_info_pkg::*;

module openFPGA_Pocket_Analogizer #(parameter MASTER_CLK_FREQ=50_000_000, parameter LINE_LENGTH, parameter ADDRESS_ANALOGIZER_CONFIG=8'hF7) (
	input  wire clk_74a,
	input  wire i_clk,
	input  wire i_rst_apf, //active High
    input  wire i_rst_core,//active High
	input  wire i_ena,

	//Video interface
	input  wire video_clk,
	input  wire [7:0] R,
	input  wire [7:0] G,
	input  wire [7:0] B,
	input  wire Hblank,
	input  wire Vblank,
	input  wire Hsync,
	input  wire Vsync,

	//OSD out
	output  wire [7:0] OSD_out_R,
	output  wire [7:0] OSD_out_G,
	output  wire [7:0] OSD_out_B,
	output  wire OSD_out_Hblank,
	output  wire OSD_out_Vblank,
	output  wire OSD_out_Hsync,
	output  wire OSD_out_Vsync,

	//openFPGA Bridge interface
	input wire bridge_endian_little,
	input  wire [31:0] bridge_addr,
	input  wire        bridge_rd,
	output reg  [31:0] analogizer_bridge_rd_data,
	input  wire        bridge_wr,
	input  wire [31:0] bridge_wr_data,

	//Analogizer settings
	output wire [4:0] snac_game_cont_type_out,
	output wire [3:0] snac_cont_assignment_out,
	output wire [3:0] analogizer_video_type_out,
	output wire [2:0] SC_fx_out,
	output wire pocket_blank_screen_out,
	output wire analogizer_out,
	//Pocket controller 1 keys (clk_74a domain): D-pad left/right selects the displayed JVS node
	input  wire [15:0] pocket_cont1_key,
	//JVS bus dump (jvs_dump.bin): bridge read port and control, all in the clk_74a domain
	input  wire [14:0] jvs_dump_rd_addr,      // word address (128 KB buffer)
	output wire [31:0] jvs_dump_rd_data,
	input  wire        jvs_dump_hold,         // freeze the capture while the APF reads it
	input  wire        jvs_dump_restart_tgl,  // toggle: clear and restart the capture
	output wire [15:0] jvs_dump_entries,      // number of entries (stable while held)
	output wire        jvs_dump_full,         // capture buffer full (clk_sys domain, sync in core_top)
	input  wire        jvs_dump_ring,         // init capture saved: keep the last seconds (ring)
	input  wire        jvs_sniff_ring,        // sniffer init capture saved: keep the last seconds (ring)
	input  wire [1:0]  jvs_dump_status,       // 0 capture, 1 saving, 2 saved, 3 error
	input  wire [2:0]  jvs_dump_err,          // APF result code (7 = no answer)
	output wire        jvs_sniffer_mode,      // sniffer mode on (clk_sys domain, sync in core_top)

	//Video Y/C Encoder interface
	input  wire [39:0] CHROMA_PHASE_INC,
	input wire  [26:0] COLORBURST_RANGE,
	input  wire [4:0] CHROMA_ADD,
	input  wire [4:0] CHROMA_MUL,
	input  wire PALFLAG,
	//Video SVGA Scandoubler interface
	input  wire ce_pix,
	input  wire scandoubler, //logic for disable/enable the scandoubler
	//SNAC interface
    output wire [15:0] p1_btn_state,
	output wire [31:0] p1_joy_state,
    output wire [15:0] p2_btn_state,
	output wire [31:0] p2_joy_state,
    output wire [15:0] p3_btn_state,
	output wire [31:0] p3_joy_state,
    output wire [15:0] p4_btn_state,
	output wire [31:0] p4_joy_state,
	//PSX rumble interface joy1, joy2
    input [1:0] i_VIB_SW1,  //  Vibration SW  VIB_SW[0] Small Moter OFF 0:ON  1:
                                //VIB_SW[1] Bic Moter   OFF 0:ON  1(Dualshook Only)
	input [7:0] i_VIB_DAT1,  //  Vibration(Bic Moter)Data   8'H00-8'HFF (Dualshook Only)
    input [1:0] i_VIB_SW2,
	input [7:0] i_VIB_DAT2, 
	// 
	output wire busy, 
	//Pocket Analogizer IO interface to the cartridge port
	inout   wire    [7:0]   cart_tran_bank2,
	output  wire            cart_tran_bank2_dir,
	inout   wire    [7:0]   cart_tran_bank3,
	output  wire            cart_tran_bank3_dir,
	inout   wire    [7:0]   cart_tran_bank1,
	output  wire            cart_tran_bank1_dir,
	inout   wire    [7:4]   cart_tran_bank0,
	output  wire            cart_tran_bank0_dir,
	inout   wire            cart_tran_pin30,
	output  wire            cart_tran_pin30_dir,
	output  wire            cart_pin30_pwroff_reset,
	inout   wire            cart_tran_pin31,
	output  wire            cart_tran_pin31_dir,
    //debug
	output wire [3:0] DBG_TX,
    output wire o_stb
);
	//Configuration file dat
	//reg [31:0] analogizer_bridge_rd_data;
	reg  [31:0] analogizer_config = 0;
	wire [31:0] analogizer_config_s;
	reg  [31:0] config_mem [16]; //configuration memory
	
	synch_3 #(.WIDTH(32)) analogizer_sync({i_busyr,analogizer_config[30:0]}, analogizer_config_s, i_clk);

	wire [31:0] memory_out;
	reg [3:0] word_cnt;
	reg i_busyr;

	// handle memory mapped I/O from pocket
	always @(posedge clk_74a) begin
		if(i_rst_apf) begin
			i_busyr <= 1'b1;
		end
		else begin
			i_busyr <= 1'b0;
		end
	end

	// jvs_vendor.bin data slot (JVS vendor init table, see openFPGA_Pocket_Analogizer_SNAC):
	// written into the SNAC table as loaded, first file byte of each word in [31:24]
	localparam [7:0] ADDRESS_JVS_VENDOR = 8'h50;
	wire        jvs_vendor_wr = bridge_wr && (bridge_addr[31:24] == ADDRESS_JVS_VENDOR);
	wire [31:0] jvs_vendor_wr_data = bridge_endian_little ?
	            {bridge_wr_data[7:0], bridge_wr_data[15:8], bridge_wr_data[23:16], bridge_wr_data[31:24]} : bridge_wr_data;

	always @(posedge clk_74a) begin
		if(bridge_wr) begin
			case(bridge_addr[31:24])
			ADDRESS_ANALOGIZER_CONFIG: begin
				if (bridge_addr[3:0] == 4'h0) begin
					word_cnt <= 4'h1;
					analogizer_config <= bridge_endian_little ? bridge_wr_data  : {bridge_wr_data[7:0],bridge_wr_data[15:8],bridge_wr_data[23:16],bridge_wr_data[31:24]}; 
				end
				else begin
					word_cnt <= word_cnt + 4'h1;
					config_mem[bridge_addr[3:0]] <= bridge_endian_little ? bridge_wr_data  : {bridge_wr_data[7:0],bridge_wr_data[15:8],bridge_wr_data[23:16],bridge_wr_data[31:24]}; 
				end
			end
			endcase
		end
		if(bridge_rd) begin
			case(bridge_addr[31:24])
			ADDRESS_ANALOGIZER_CONFIG: begin
				if (bridge_addr[3:0] == 4'h0) analogizer_bridge_rd_data <= bridge_endian_little ?  analogizer_config_s : {analogizer_config_s[7:0],analogizer_config_s[15:8],analogizer_config_s[23:16],analogizer_config_s[31:24]}; //invert byte order to writeback to the Sav folders
				else analogizer_bridge_rd_data <= bridge_endian_little ? config_mem[bridge_addr[3:0]] : {memory_out[7:0],memory_out[15:8],memory_out[23:16],memory_out[31:24]};
			end
			endcase
		end
	end
	assign memory_out = config_mem[bridge_addr[3:0]];
	assign busy = i_busyrr;
	reg i_busyrr;

  always @(posedge i_clk) begin
    snac_game_cont_type   <= analogizer_config_s[4:0];
    snac_cont_assignment  <= analogizer_config_s[9:6];
    analogizer_video_type <= analogizer_config_s[13:10];	
	pocket_blank_screen   <= analogizer_config_s[14];
    analogizer_out2	  <= analogizer_config_s[15];
	i_busyrr		      <= analogizer_config_s[31];
  end


  wire conf_AB;
  reg conf_AB_r;

  always @(posedge i_clk) begin
	case(snac_game_cont_type)
		5'd0, 5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd6, 5'd7, 5'd8, 5'd9, 5'd10, 5'd11, 5'd12, 5'd13, 5'd14, 5'd15, 5'd20: conf_AB_r <= 1'b0; //Conf A	
		default: conf_AB_r <= 1'b1; //Conf B
	endcase
  end
  assign conf_AB = conf_AB_r;


  //0 disable, 1 scanlines 25%, 2 scanlines 50%, 3 scanlines 75%, 4 hq2x
  always @(posedge i_clk) begin
	if(analogizer_video_type >= 4'd5) SC_fx <= analogizer_video_type - 4'd5;
end

reg       analogizer_ena;
reg [3:0] analogizer_video_type;
reg [4:0] snac_game_cont_type;
reg [3:0] snac_cont_assignment;
reg [2:0] SC_fx;
reg       pocket_blank_screen;
reg       analogizer_out2;

assign analogizer_video_type_out = analogizer_video_type;
assign snac_game_cont_type_out   = snac_game_cont_type;
assign snac_cont_assignment_out  = snac_cont_assignment;
assign SC_fx_out                 = SC_fx;
assign pocket_blank_screen_out   = pocket_blank_screen;
assign analogizer_out        = analogizer_out2;
//------------------------------------------------------------------------

	wire [7:4] CART_BK0_OUT ;
    wire [7:4] CART_BK0_IN ;
    wire CART_BK0_DIR ; 
    wire [7:6] CART_BK1_OUT_P76 ;
    wire CART_PIN30_OUT ;
    wire CART_PIN30_IN ;
    wire CART_PIN30_DIR ; 
    wire CART_PIN31_OUT ;
    wire CART_PIN31_IN ;
    wire CART_PIN31_DIR ;

    logic jvs_data_ready;
	jvs_node_info_t jvs_nodes;
	jvs_bus_state_t jvs_bus_state;
    logic [7:0] node_name_rd_data;
    logic [7:0] node_name_rd_addr;
    
	// generic snac gun support
    wire snac_gun_trigger;
    wire [11:0] snac_gun_x;
    wire [11:0] snac_gun_y;
    wire [7:0] gpio_output_value;
    wire snac_io3, snac_in7;
    wire jvs_tx_activity, jvs_rx_activity;
    logic [15:0] dout_test = 16'h0000;       // digital output test value (Pocket A), see below
    logic [15:0] aout_test = 16'h0000;       // analog output test value (Pocket X), see below
    logic [3:0] osd_node_sel = 4'd0;         // node index shown in the OSD (0 = first node), see below
    wire  [3:0] p_trigger;                   // gun triggers of P1..P4 (SNAC, JVS profile masks)
    wire  [11:0] p2_gun_x, p2_gun_y, p3_gun_x, p3_gun_y, p4_gun_x, p4_gun_y;  // P2..P4 gun positions
    wire  [3:0]  p_gun_defined;              // gun players (trigger mask in the JVS profile)
    logic [3:0] p_recoil = 4'b0000;          // recoil of P1..P4 (pulses generated below)
    logic       recoil_auto = 1'b0;          // recoil mode (Pocket Y button): 0 single, 1 automatic
    logic jvs_sniffer = 1'b0;                // sniffer mode (Pocket Select button), see below
    assign jvs_sniffer_mode = jvs_sniffer;   // core_top: sniffer captures go to jvs_sniff.bin
    wire jvs_tx_line, jvs_rx_line, jvs_dir_line;
    wire [jvs_node_info_pkg::MAX_JVS_NODES*128-1:0] jvs_node_analog;
    wire [4*16-1:0] jvs_coin_status;

	openFPGA_Pocket_Analogizer_SNAC #(.MASTER_CLK_FREQ(MASTER_CLK_FREQ)) snac
	(
		.i_clk(i_clk),
		.i_rst(i_rst_apf),
		.conf_AB(conf_AB),              //0 conf. A(default), 1 conf. B (see graph above)
		.game_cont_type(snac_game_cont_type), //0-15 Conf. A, 16-31 Conf. B
		//.game_cont_sample_rate(game_cont_sample_rate), //0 compatibility mode (slowest), 1 normal mode, 2 fast mode, 3 superfast mode
		.p1_btn_state(p1_btn_state),
		.p1_joy_state(p1_joy_state),
		.p2_btn_state(p2_btn_state),
		.p2_joy_state(p2_joy_state),
		.p3_btn_state(p3_btn_state),
		.p3_joy_state(p3_joy_state),
		.p4_btn_state(p4_btn_state),
		.p4_joy_state(p4_joy_state),
		.i_VIB_SW1(i_VIB_SW1), .i_VIB_DAT1(i_VIB_DAT1), .i_VIB_SW2(i_VIB_SW2), .i_VIB_DAT2(i_VIB_DAT2), 
		.busy(),    
		//SNAC Pocket cartridge port interface (see graph above)   
		.CART_BK0_OUT(CART_BK0_OUT),
		.CART_BK0_IN(CART_BK0_IN),
		.CART_BK0_DIR(CART_BK0_DIR), 
		.CART_BK1_OUT_P76(CART_BK1_OUT_P76),
		.CART_PIN30_OUT(CART_PIN30_OUT),
		.CART_PIN30_IN(CART_PIN30_IN),
		.CART_PIN30_DIR(CART_PIN30_DIR), 
		.CART_PIN31_OUT(CART_PIN31_OUT),
		.CART_PIN31_IN(CART_PIN31_IN),
		.CART_PIN31_DIR(CART_PIN31_DIR),
		//debug
		.DBG_TX(DBG_TX),
    	.o_stb(o_stb),
		//JVS node info
		.jvs_data_ready(jvs_data_ready),
        .jvs_nodes(jvs_nodes),
        .jvs_bus_state(jvs_bus_state),
        .node_name_rd_data(node_name_rd_data),
        .node_name_rd_addr(node_name_rd_addr),
        // JVS vendor init table (jvs_vendor.bin data slot)
        .clk_74a(clk_74a),
        .vendor_wr(jvs_vendor_wr),
        .vendor_wr_addr(bridge_addr[7:2]),
        .vendor_wr_data(jvs_vendor_wr_data),
        // generic snac gun support
        .snac_gun_trigger(snac_gun_trigger),
        .snac_gun_x(snac_gun_x),
        .snac_gun_y(snac_gun_y),
        
        // GPIO output value
        .gpio_output_value(gpio_output_value),
        .dout_test(dout_test),
        .aout_test(aout_test),
        .output_node_sel(osd_node_sel),         // OUTPUT1 / ANLOUT sent to the selected node only
        // gun triggers in, recoil out (the SNAC maps them with the JVS profile)
        .p2_gun_x(p2_gun_x), .p2_gun_y(p2_gun_y),
        .p3_gun_x(p3_gun_x), .p3_gun_y(p3_gun_y),
        .p4_gun_x(p4_gun_x), .p4_gun_y(p4_gun_y),
        .p_gun_defined(p_gun_defined),
        .p1_trigger(p_trigger[0]), .p2_trigger(p_trigger[1]),
        .p3_trigger(p_trigger[2]), .p4_trigger(p_trigger[3]),
        .p1_recoil(p_recoil[0]),   .p2_recoil(p_recoil[1]),
        .p3_recoil(p_recoil[2]),   .p4_recoil(p_recoil[3]),
        .jvs_sniffer(jvs_sniffer),

        // Raw analog channels (OSD gauges / X-Y target)
        .jvs_node_analog(jvs_node_analog),
        .jvs_coin_status(jvs_coin_status),
        
        // SNAC IO signals
        .snac_io3(snac_io3),
        .snac_in7(snac_in7),
        .jvs_tx_activity(jvs_tx_activity),
        .jvs_rx_activity(jvs_rx_activity),
        .jvs_tx_line(jvs_tx_line),
        .jvs_rx_line(jvs_rx_line),
        .jvs_dir_line(jvs_dir_line)
	); 

	//=========================================================================
	// JVS bus logger (dumped to jvs_dump.bin with the Pocket Start button, see core_top)
	//=========================================================================
	//-------------------------------------------------------------------------
	// Sniffer mode (Pocket Select button, toggle): controller off, RS485 driver disabled,
	// the logger records the whole bus traffic (host requests and board answers come
	// on the receive line). Like the normal mode, the first capture starts on the first
	// E0 seen on the bus and is saved automatically when full (jvs_sniff_init.bin), then
	// the logger keeps the last seconds (ring buffer) and Start saves them (jvs_sniff.bin).
	//-------------------------------------------------------------------------
	logic [1:0] btn_sel_s;
	logic       btn_sel_d;
	logic       jvs_sniffer_prev = 1'b0;
	wire        jvs_sniffer_changed = (jvs_sniffer != jvs_sniffer_prev);
	always @(posedge i_clk) begin
		btn_sel_s <= {btn_sel_s[0], pocket_cont1_key[14]};
		btn_sel_d <= btn_sel_s[1];
		if (btn_sel_s[1] && !btn_sel_d)
			jvs_sniffer <= ~jvs_sniffer;
	end

	// The controller is off in sniffer mode (no jvs_data_ready): refresh the OSD at ~10 Hz
	// so that the capture counter keeps moving
	logic [$clog2(MASTER_CLK_FREQ/10+1)-1:0] sniff_tick_cnt = '0;
	logic sniff_tick = 1'b0;
	always @(posedge i_clk) begin
		sniff_tick <= 1'b0;
		if (!jvs_sniffer) sniff_tick_cnt <= '0;
		else if (sniff_tick_cnt == MASTER_CLK_FREQ/10) begin sniff_tick_cnt <= '0; sniff_tick <= 1'b1; end
		else sniff_tick_cnt <= sniff_tick_cnt + 1'b1;
	end

	logic [1:0] dump_hold_s;
	logic [2:0] dump_restart_s;
	logic [1:0] dump_ring_s, sniff_ring_s;
	always @(posedge i_clk) begin
		dump_ring_s  <= {dump_ring_s[0],  jvs_dump_ring};
		sniff_ring_s <= {sniff_ring_s[0], jvs_sniff_ring};
	end
	wire logger_ring = jvs_sniffer ? sniff_ring_s[1] : dump_ring_s[1];
	wire logger_waiting;
	always @(posedge i_clk) begin
		dump_hold_s    <= {dump_hold_s[0], jvs_dump_hold};
		dump_restart_s <= {dump_restart_s[1:0], jvs_dump_restart_tgl};
	end
	jvs_bus_logger #(.CLK_FREQ(MASTER_CLK_FREQ), .WORDS(32768)) jvs_logger (
		.clk(i_clk),
		.enable(snac_game_cont_type == 5'd20),   // GC_JVS
		.restart((dump_restart_s[2] ^ dump_restart_s[1]) || jvs_sniffer_changed),
		.hold(dump_hold_s[1]),
		.ring(logger_ring),
		.sync_start(jvs_sniffer),                // sniffer: start on the first E0
		.tx_line(jvs_tx_line),
		.rx_line(jvs_rx_line),
		.dir(jvs_dir_line),
		.setup_n(snac_in7),
		.link_n(snac_io3),
		.entry_count(jvs_dump_entries),
		.full(jvs_dump_full),
		.waiting(logger_waiting),
		.rd_clk(clk_74a),
		.rd_addr(jvs_dump_rd_addr),
		.rd_data(jvs_dump_rd_data)
	);

	//=========================================================================
	//------- START Process JVS data and copy strings to OSD memory -----------
	//=========================================================================
	logic jvs_data_ready_prev;
	logic do_proc = 1'b0;
	logic [5:0] btn_cnt = 6'd0;
	logic [3:0] hex_nibble;
	logic [7:0] STR_byte;
	logic [10:0] next_OSD_wr_addr;
	logic [7:0] buttons_decimal; // Decimal value of buttons for display
	logic [7:0] analog_bits_decimal; // Decimal value of analog bits for display

	localparam JVS_BUS_STATE_POS = 482;      // Row 12, Col 2 - "STATE: <bus state>" (empty line above SNAC)
	localparam JVS_BUS_STATE_LEN = 19;       // "STATE: " + 12 chars
	localparam SNAC_DEVICE_STR_POS = 528;
	localparam JVS_NODE_NUMBER_POS = 568;
	localparam JVS_NODE_BRAND_POS = 608;     // Row 15, Col 8 - Position after "BRAND:" colon
	localparam JVS_NODE_MODEL_POS = 648;     // Row 16, Col 8 - Position after "MODEL:" colon (shifted 1 left)
	localparam JVS_NODE_NAME_LAST1_POS = JVS_NODE_BRAND_POS + 29 - 1;   // End of BRAND line
	localparam JVS_NODE_NAME_LAST2_POS = JVS_NODE_MODEL_POS + 30 - 1;   // End of MODEL line (+1)
	localparam JVS_NODE_NAME_LAST3_POS = JVS_NODE_NAME_LAST2_POS + 40;   // Next line for MODEL overflow
	localparam JVS_NODE_CMD_POS = 770;  // Row 19, Col 10 - Position after "CMD VER:" colon (with space from border)
	localparam JVS_NODE_JVS_POS = 810;  // Row 20, Col 10 - Position after "JVS VER:" colon (with space from border)
	localparam JVS_NODE_COM_POS = 850;  // Row 21, Col 10 - Position after "COM VER:" colon (with space from border)
	localparam JVS_NODE_COUNT_POS = 854; // Row 21, Col 14 - Position after "COM VER:" for node count display
	// New positions for capability information - aligned colons at column 25
	localparam JVS_NODE_PLAYERS_POS = 774;   // Row 19, Col 14 - SWITCH label start (shifted 1 left)
	localparam JVS_NODE_ANALOG_POS = 821;    // Row 20, Col 21 - Position after ANALOG: colon (after space adjustment)
	localparam JVS_NODE_FEATURES_POS = 864;  // Row 21, Col 24 - Position after Features: colon (after space adjustment)
	localparam JVS_PLAYER_ROW_POS = 882;  // Row 22, Col 2 - first player row (one row per player, rows 22..25)
	localparam PLAYER_ROW_LEN = 21;       // "P1 UDLR SC 1234567890" (analog values are in the ANALOG block)
	localparam JVS_ANALOG_ROW_POS = 1042; // Row 26, Col 2 - analog X gauge row, then Y gauge (row 27) and pair info (row 28)
	localparam ANALOG_ROW_LEN = 29;
	localparam JVS_COIN_ROW_POS = 722;    // Row 18, Col 2 - coin slots of the selected node
	localparam COIN_ROW_LEN = 37;
	localparam JVS_DOUT_POS = 580;        // Row 14, Col 20 - "DOUT:xxxx" digital output test value
	localparam DOUT_ROW_LEN = 19;         // "DOUT:xxxx AOUT:xxxx"
	localparam JVS_RECOIL_POS = 402;      // Row 10, Col 2 - gun recoil mode (Pocket Y button)
	localparam RECOIL_ROW_LEN = 21;       // "RECOIL:SINGLE" + 8 gun icon cells
	localparam JVS_DUMP_STATUS_POS = 502; // Row 12, Col 22 - bus dump status
	localparam DUMP_ROW_LEN = 16;         // "COIN 1:0000x 2:0000x 3:0000x 4:0000x"

	// Assign string for snac_game_cont_type
	parameter int SNAC_ROM_STR_LEN = 32; //stringz
	logic [9:0] SNAC_ROM_addr; 
	logic [7:0] SNAC_ROM_data;
	

	ROM_snac_strings #(
	.FILENAME("snac_strings.mem")
	) u_rom (
	.clk (i_clk),
	.addr(SNAC_ROM_addr),
	.data(SNAC_ROM_data)
	);

	//State machine to copy JVS node name and SNAC device name to OSD memory
	enum int unsigned {

		INIT_JVS_STR   = 0, 
		COPY_NODEID_VER1= 1,
		READ_JVS_STR   = 2, 
		WRITE_BRAND_STR  = 3,
		SEARCH_SEMICOLON = 4,
		INIT_MODEL_STR = 5,
		READ_MODEL_STR = 6, 
		WRITE_MODEL_STR = 7,
		INIT_SNAC_STR  = 8,
		WAIT1_SNAC_STR = 9,
		READ_SNAC_STR  = 10,
		WRITE_SNAC_STR = 11,
		COPY_CMD_VER1  = 12, 
		COPY_CMD_VER2  = 13, 
		COPY_JVS_VER1  = 14, 
		COPY_JVS_VER2  = 15, 
		COPY_COM_VER1  = 16, 
		COPY_COM_VER2  = 17,
		WRITE_INPUTS_PLAYERS = 18,
		WRITE_INPUTS_P = 19,
		WRITE_INPUTS_BUTTONS_TENS = 20,
		WRITE_INPUTS_BUTTONS_UNITS = 21,
		WRITE_INPUTS_B = 22,
		WRITE_ANALOG_INFO = 23,
		WRITE_ANALOG_CH = 24,
		WRITE_ANALOG_H = 25,
		WRITE_ANALOG_BITS_TENS = 26,
		WRITE_ANALOG_BITS_UNITS = 27,
		WRITE_ANALOG_B = 28,
		WRITE_COIN_INFO = 29,
		WRITE_FEATURES_R = 30,
		WRITE_FEATURES_K = 31,
		WRITE_FEATURES_S = 32,
		WRITE_FEATURES_D = 33,
		WRITE_FEATURES_A = 34,
		WRITE_FEATURES_C = 35,
		WRITE_FEATURES_M = 36,
		WRITE_FEATURES_T = 37,
		WRITE_FEATURES_B = 38,
		WRITE_NODE_COUNT = 39,
		PLAYER_ROWS    = 40,
		EOS            = 48,
		WRITE_BUS_STATE = 49,
		CLEAR_NAMES    = 50,
		WAIT_JVS_STR   = 51,
		WRITE_NODE_SLASH = 52,
		ANALOG_ROWS    = 53,
		COIN_ROW       = 54,
		DOUT_ROW       = 55,
		DUMP_ROW       = 56,
		RECOIL_ROW     = 57
	} jvs_name_copy_state;

	// OSD text for the JVS bus state line: "STATE: XXXXXXXXXXXX"
	// node_count = nodes already configured, so the node being addressed is node_count+1
	function automatic logic [7:0] bus_state_char(input jvs_bus_state_t st, input logic [7:0] node_count, input logic [4:0] idx, input logic sniffer);
		logic [12*8-1:0] txt;
		logic [7*8-1:0] lbl;
		lbl = "STATE: ";
		case (sniffer ? JVS_ERROR : st)
			JVS_NO_DEVICE:  txt = "NO DEVICE   ";
			JVS_ADDRESSING: txt = (node_count == 8'd0) ? "INITIALIZING" : {"ADDR NODE ", 8'h30 + node_count[3:0] + 8'd1, " "};
			JVS_INIT:       txt = "IDENTIFYING ";
			JVS_READY:      txt = "READY       ";
			JVS_ERROR:      txt = sniffer ? "SNIFFER     " : "NO ANSWER   ";
			JVS_LINK_LOST:  txt = "LINK LOST   ";
			default:        txt = "?           ";
		endcase
		if (idx < 5'd7)
			bus_state_char = lbl[8*(6 - idx) +: 8];
		else
			bus_state_char = txt[8*(11 - (idx - 5'd7)) +: 8];
	endfunction

	// Refresh the OSD when the bus state changes (no jvs_data_ready pulse
	// is generated while no device is plugged or during init)
	jvs_bus_state_t jvs_bus_state_prev;
	wire jvs_bus_state_changed = (jvs_bus_state != jvs_bus_state_prev);

	//-------------------------------------------------------------------------
	// Displayed node selection with the Pocket D-pad (left = previous, right = next)
	//-------------------------------------------------------------------------
	logic [1:0] dpad_left_s, dpad_right_s;   // synchronizers (clk_74a -> i_clk)
	logic       dpad_left_d, dpad_right_d;   // edge detection
	logic [3:0] osd_node_sel_prev = 4'd0;
	wire  [7:0] osd_node_max = (jvs_nodes.node_count > jvs_node_info_pkg::MAX_JVS_NODES) ?
	                           jvs_node_info_pkg::MAX_JVS_NODES : jvs_nodes.node_count;
	wire        osd_node_changed = (osd_node_sel != osd_node_sel_prev);

	always @(posedge i_clk) begin
		dpad_left_s  <= {dpad_left_s[0],  pocket_cont1_key[2]};
		dpad_right_s <= {dpad_right_s[0], pocket_cont1_key[3]};
		dpad_left_d  <= dpad_left_s[1];
		dpad_right_d <= dpad_right_s[1];

		if (osd_node_max <= 8'd1) begin
			osd_node_sel <= 4'd0;                                 // 0 or 1 node: nothing to select
		end else if (osd_node_sel >= osd_node_max) begin
			osd_node_sel <= 4'd0;                                 // node count shrank (re-init)
		end else if (dpad_right_s[1] && !dpad_right_d) begin
			osd_node_sel <= (osd_node_sel == osd_node_max - 1) ? 4'd0 : osd_node_sel + 4'd1;
		end else if (dpad_left_s[1] && !dpad_left_d) begin
			osd_node_sel <= (osd_node_sel == 4'd0) ? osd_node_max[3:0] - 4'd1 : osd_node_sel - 4'd1;
		end
	end

	//-------------------------------------------------------------------------
	// Bus dump status (row 12, col 22): "DUMP:REC  0123" / "DUMP:FULL 0FFE" /
	// "DUMP:SAVING" / "DUMP:SAVED OK" / "DUMP:ERR n ..." (entry count in hex)
	//-------------------------------------------------------------------------
	logic [1:0] dump_status_s1, dump_status_s2, dump_status_prev;
	logic [2:0] dump_err_s1, dump_err_s2;
	always @(posedge i_clk) begin
		dump_status_s1 <= jvs_dump_status; dump_status_s2 <= dump_status_s1;
		dump_err_s1    <= jvs_dump_err;    dump_err_s2    <= dump_err_s1;
	end
	wire dump_status_changed = (dump_status_s2 != dump_status_prev);
	localparam int DUMP_MAX_ENTRIES = (32768 - 8) / 2;

	function automatic logic [7:0] dump_row_char(input logic [3:0] col, input logic [1:0] st,
	                                              input logic [2:0] err, input logic [15:0] n, input logic sniffer,
	                                              input logic ring, input logic waiting);
		logic [16*8-1:0] txt;
		case (st)
			2'd1:    txt = "DUMP:SAVING     ";
			2'd2:    case (err)
			             3'd1:    txt = "DUMP:SAVED INIT ";
			             3'd2:    txt = "DUMP:SAVED SNIF ";
			             3'd3:    txt = "DUMP:SAVED SINI ";
			             default: txt = "DUMP:SAVED DUMP ";
			         endcase
			2'd3:    case (err)
			             3'd1:    txt = "DUMP:ERR NO SLOT";
			             3'd2:    txt = "DUMP:ERR RANGE  ";
			             3'd7:    txt = "DUMP:ERR TIMEOUT";
			             default: txt = {"DUMP:ERR ", 8'h30 + err, "      "};
			         endcase
			default: txt = (sniffer && waiting) ? "DUMP:WAIT E0    " :
			               {sniffer ? (ring ? "DUMP:SNIF " : "DUMP:SINI ") : ring ? "DUMP:LAST " : (n >= DUMP_MAX_ENTRIES) ? "DUMP:FULL " : "DUMP:REC  ",
			                hex2ascii(n[15:12], 1'b1), hex2ascii(n[11:8], 1'b1),
			                hex2ascii(n[7:4], 1'b1),   hex2ascii(n[3:0], 1'b1), "  "};
		endcase
		dump_row_char = txt[8*(15 - col) +: 8];
	endfunction

	//-------------------------------------------------------------------------
	// Digital output test (Pocket A button): when the selected node declares digital
	// outputs (feature D), each press doubles the value sent with OUTPUT1 (32):
	// 0 -> 1 -> 2 -> 4 ... -> 0x8000 -> 0 (bit 7 of the low byte = output 1)
	//-------------------------------------------------------------------------
	logic [1:0]  btn_a_s;
	logic        btn_a_d;
	logic [15:0] dout_test_prev = 16'h0000;
	wire         dout_test_changed = (dout_test != dout_test_prev);
	wire         node_has_dout = (jvs_nodes.node_digital_outputs[osd_node_sel] != 8'd0);

	// Analog output test (Pocket X button): when the selected node declares analog outputs
	// (feature A), each press steps the value sent on every ANLOUT (33) channel:
	// 0000 -> 2000 -> 4000 ... -> E000 -> FFFF -> 0000 (e.g. lamp intensity)
	logic [1:0]  btn_x_s;
	logic        btn_x_d;
	logic [15:0] aout_test_prev = 16'h0000;
	wire         aout_test_changed = (aout_test != aout_test_prev);
	wire         node_has_aout = (jvs_nodes.node_analog_output_channels[osd_node_sel] != 4'd0);
	always @(posedge i_clk) begin
		btn_x_s <= {btn_x_s[0], pocket_cont1_key[6]};
		btn_x_d <= btn_x_s[1];
		if (jvs_bus_state != JVS_READY)
			aout_test <= 16'h0000;
		else if (btn_x_s[1] && !btn_x_d && node_has_aout)
			aout_test <= (aout_test == 16'hFFFF) ? 16'h0000 :
			             (aout_test == 16'hE000) ? 16'hFFFF : aout_test + 16'h2000;
	end
	always @(posedge i_clk) begin
		btn_a_s <= {btn_a_s[0], pocket_cont1_key[4]};
		btn_a_d <= btn_a_s[1];
		if (jvs_bus_state != JVS_READY)
			dout_test <= 16'h0000;                         // back to 0 on re-init / link loss
		else if (btn_a_s[1] && !btn_a_d && node_has_dout)
			dout_test <= (dout_test == 16'h0000) ? 16'h0001 : (dout_test << 1);
	end

	//-------------------------------------------------------------------------
	// Gun recoil of each player, from its trigger (SNAC p_trigger, JVS profile masks):
	//  - single (default): one 50 ms pulse per trigger press, as the Time Crisis 4 host
	//  - automatic: while the trigger is held, 50 ms on / 150 ms off (5 shots per second)
	// Pocket Y button toggles the mode, and so does a P1 shot on the gun icon at the right of
	// the JVS logo (pistol = single, machine gun = automatic)
	//-------------------------------------------------------------------------
	localparam int RECOIL_PULSE = MASTER_CLK_FREQ / 20;            // 50 ms on
	// automatic mode: 150 ms off between shots so that the solenoid has time to come back
	// (50 ms off was too short on Time Crisis 4): one shot every 200 ms, 5 shots per second
	localparam int RECOIL_PERIOD = 4 * RECOIL_PULSE;
	logic [1:0] btn_y_s;
	logic       btn_y_d;
	logic       recoil_auto_prev = 1'b0;
	// gun icon (4 x 2 cells at row 4, col 29, double border drawn by osd_top): shot = trigger of
	// a gun player pressed with its crosshair inside the outer border
	localparam int RECOIL_ICON_COL = 29, RECOIL_ICON_ROW = 4;
	function automatic logic on_recoil_icon(input logic [11:0] x, y);
		on_recoil_icon = (x >= RECOIL_ICON_COL*8 - 5) && (x <= RECOIL_ICON_COL*8 + 31 + 5) &&
		                 (y >= RECOIL_ICON_ROW*8 - 5) && (y <= RECOIL_ICON_ROW*8 + 15 + 5);
	endfunction
	// crosshairs: P1 also for single player / screen position boards (legacy), P2..P4 when the
	// JVS profile defines their trigger
	wire [3:0]  gun_shown = {p_gun_defined[3:1],
	                         p_gun_defined[0] || jvs_nodes.node_players[0] == 4'd1 || jvs_nodes.node_has_screen_pos[0]};
	wire [47:0] gun_x_all = {p4_gun_x, p3_gun_x, p2_gun_x, snac_gun_x};
	wire [47:0] gun_y_all = {p4_gun_y, p3_gun_y, p2_gun_y, snac_gun_y};
	wire [3:0]  gun_trig_all = {p_trigger[3:1], p_trigger[0] | snac_gun_trigger};
	logic [3:0] gun_trig_d = 4'b0000;
	always @(posedge i_clk) gun_trig_d <= gun_trig_all;
	logic recoil_icon_shot;
	always_comb begin
		recoil_icon_shot = 1'b0;
		for (int p = 0; p < 4; p++)
			if (gun_shown[p] && gun_trig_all[p] && !gun_trig_d[p] &&
			    on_recoil_icon(gun_x_all[p*12 +: 12], gun_y_all[p*12 +: 12]))
				recoil_icon_shot = 1'b1;
	end
	wire        recoil_auto_changed = (recoil_auto != recoil_auto_prev);
	always @(posedge i_clk) begin
		btn_y_s <= {btn_y_s[0], pocket_cont1_key[7]};
		btn_y_d <= btn_y_s[1];
		if ((btn_y_s[1] && !btn_y_d) || recoil_icon_shot) recoil_auto <= ~recoil_auto;
	end
	logic [3:0] p_trigger_d = 4'b0000;
	logic [$clog2(RECOIL_PERIOD+1)-1:0] recoil_cnt [4];
	always @(posedge i_clk) begin
		p_trigger_d <= p_trigger;
		for (int p = 0; p < 4; p++) begin
			if (p_trigger[p] && !p_trigger_d[p]) begin         // trigger pressed: first shot
				p_recoil[p]   <= 1'b1;
				recoil_cnt[p] <= '0;
			end else if (recoil_cnt[p] < RECOIL_PULSE - 1) begin
				recoil_cnt[p] <= recoil_cnt[p] + 1'b1;          // pulse on
			end else if (recoil_auto && p_trigger[p]) begin
				// automatic: off for 50 ms, then the next shot while the trigger is held
				p_recoil[p] <= 1'b0;
				recoil_cnt[p] <= (recoil_cnt[p] >= RECOIL_PERIOD - 1) ? '0 : recoil_cnt[p] + 1'b1;
				if (recoil_cnt[p] >= RECOIL_PERIOD - 1) p_recoil[p] <= 1'b1;
			end else begin
				p_recoil[p] <= 1'b0;                              // single shot done / released
			end
		end
	end

	// "RECOIL:SINGLE" / "RECOIL:AUTO" (row 10), then the gun icon (8 cells, glyphs of
	// font_JVS_color_trans.mem): pistol in single mode, machine gun in automatic mode
	function automatic logic [7:0] recoil_row_char(input logic [4:0] idx, input logic auto_mode);
		logic [13*8-1:0] txt;
		logic [8*8-1:0]  pistol, mgun;
		txt    = auto_mode ? "RECOIL:AUTO  " : "RECOIL:SINGLE";
		pistol = 64'hA0A1AFB0_B1B2BFC0;
		mgun   = 64'hC1C2CFD0_D1D2DFE0;
		if (idx < 5'd13) recoil_row_char = txt[8*(12 - idx) +: 8];
		else             recoil_row_char = auto_mode ? mgun[8*(20 - idx) +: 8] : pistol[8*(20 - idx) +: 8];
	endfunction
	function automatic logic [10:0] recoil_row_addr(input logic [4:0] idx);
		logic [2:0] k;
		k = idx - 5'd13;
		if (idx < 5'd13) recoil_row_addr = JVS_RECOIL_POS + idx;
		else             recoil_row_addr = RECOIL_ICON_ROW*40 + RECOIL_ICON_COL + (k[2] ? 40 : 0) + k[1:0];
	endfunction

	// "DOUT:xxxx AOUT:xxxx" on the NODE# row (each part only when the node has such outputs)
	function automatic logic [7:0] dout_row_char(input logic [4:0] col, input logic has_d, input logic [15:0] d,
	                                              input logic has_a, input logic [15:0] a);
		logic        has;
		logic [15:0] v;
		logic [3:0]  c;
		logic [7:0]  k;
		has = (col < 5'd10) ? has_d : has_a;
		v   = (col < 5'd10) ? d : a;
		k   = (col < 5'd10) ? "D" : "A";
		c   = (col < 5'd10) ? col[3:0] : col - 5'd10;
		dout_row_char = 8'h20;
		if (has) begin
			case (c)
				4'd0: dout_row_char = k;
				4'd1: dout_row_char = "O";
				4'd2: dout_row_char = "U";
				4'd3: dout_row_char = "T";
				4'd4: dout_row_char = ":";
				4'd5: dout_row_char = hex2ascii(v[15:12], 1'b1);
				4'd6: dout_row_char = hex2ascii(v[11:8],  1'b1);
				4'd7: dout_row_char = hex2ascii(v[7:4],   1'b1);
				4'd8: dout_row_char = hex2ascii(v[3:0],   1'b1);
				default: dout_row_char = 8'h20;
			endcase
		end
	endfunction

	//-------------------------------------------------------------------------
	// Analog pair selection with the Pocket D-pad (up = previous, down = next)
	// Pair p shows X = CH(2p+1) and Y = CH(2p+2) of the selected node
	//-------------------------------------------------------------------------
	logic [1:0] dpad_up_s, dpad_down_s;
	logic       dpad_up_d, dpad_down_d;
	logic [1:0] ana_pair_sel = 2'd0;
	logic [1:0] ana_pair_sel_prev = 2'd0;
	wire  [3:0] ana_channels = (jvs_nodes.node_analog_channels[osd_node_sel] > 4'd8) ? 4'd8 :
	                           jvs_nodes.node_analog_channels[osd_node_sel];
	wire  [2:0] ana_pairs = (ana_channels + 4'd1) >> 1;           // 0..4
	wire        ana_pair_changed = (ana_pair_sel != ana_pair_sel_prev);

	always @(posedge i_clk) begin
		dpad_up_s   <= {dpad_up_s[0],   pocket_cont1_key[0]};
		dpad_down_s <= {dpad_down_s[0], pocket_cont1_key[1]};
		dpad_up_d   <= dpad_up_s[1];
		dpad_down_d <= dpad_down_s[1];

		if (ana_pairs <= 3'd1 || osd_node_changed) begin
			ana_pair_sel <= 2'd0;
		end else if (ana_pair_sel >= ana_pairs) begin
			ana_pair_sel <= 2'd0;
		end else if (dpad_down_s[1] && !dpad_down_d) begin
			ana_pair_sel <= (ana_pair_sel == ana_pairs - 3'd1) ? 2'd0 : ana_pair_sel + 2'd1;
		end else if (dpad_up_s[1] && !dpad_up_d) begin
			ana_pair_sel <= (ana_pair_sel == 2'd0) ? ana_pairs[1:0] - 2'd1 : ana_pair_sel - 2'd1;
		end
	end

	// Per node analog storage from jvs_ctrl: node n channel c at [(n*8 + c)*16 +: 16]
	wire [2:0]  ana_x_ch = {ana_pair_sel, 1'b0};                 // node local channel index (CH0..)
	wire [2:0]  ana_y_ch = {ana_pair_sel, 1'b1};
	wire [7:0]  ana_node_base = osd_node_sel * 8;
	wire [15:0] ana_x = jvs_node_analog[(ana_node_base + ana_x_ch) * 16 +: 16];
	wire [15:0] ana_y = jvs_node_analog[(ana_node_base + ana_y_ch) * 16 +: 16];
	wire        ana_has_x = (ana_channels != 4'd0);
	wire        ana_has_y = ({1'b0, ana_y_ch} < ana_channels);

	// Analog rows (rows 26..28, columns 0..30 from col 2):
	//   "CH1 [ X gauge drawn by osd_top  ] 8000"
	//   "CH2 [ Y gauge drawn by osd_top  ] 8000"
	//   "ANALOG P1 [1/2]"            or "NO ANALOG INPUT"
	function automatic logic [7:0] analog_row_char(input logic [1:0] row, input logic [4:0] col,
	                                                input logic has_x, input logic has_y,
	                                                input logic [2:0] x_ch, input logic [2:0] y_ch,
	                                                input logic [15:0] x, input logic [15:0] y,
	                                                input logic [1:0] pair, input logic [2:0] pairs);
		logic        has;
		logic [2:0]  ch;
		logic [15:0] v;
		logic [15*8-1:0] txt;
		analog_row_char = 8'h20;
		has = (row == 2'd0) ? has_x : has_y;
		ch  = (row == 2'd0) ? x_ch  : y_ch;
		v   = (row == 2'd0) ? x     : y;
		if (row == 2'd2) begin
			txt = has_x ? {"ANALOG P", 8'h31 + pair, " [", 8'h31 + pair, "/", 8'h30 + pairs, "]"} : "NO ANALOG INPUT";
			if (col < 5'd15) analog_row_char = txt[8*(14 - col) +: 8];
		end else if (has) begin
			case (col)
				5'd0:  analog_row_char = "C";
				5'd1:  analog_row_char = "H";
				5'd2:  analog_row_char = 8'h30 + ch;          // channels numbered from CH0
				5'd25: analog_row_char = hex2ascii(v[15:12], 1'b1);
				5'd26: analog_row_char = hex2ascii(v[11:8],  1'b1);
				5'd27: analog_row_char = hex2ascii(v[7:4],   1'b1);
				5'd28: analog_row_char = hex2ascii(v[3:0],   1'b1);
				default: analog_row_char = 8'h20;
			endcase
		end
	endfunction

	//-------------------------------------------------------------------------
	// Coin slots of the selected node (row 18)
	//   "COIN 1:0012  2:0003J ..." counter in decimal, condition letter:
	//   ' ' normal, 'J' jam, 'D' disconnected, 'B' busy
	//-------------------------------------------------------------------------
	logic [3:0] node_first_coin;
	always_comb begin
		node_first_coin = 4'd0;
		for (int n = 0; n < jvs_node_info_pkg::MAX_JVS_NODES; n++)
			if (n < osd_node_sel)
				node_first_coin = node_first_coin + jvs_nodes.node_coin_slots[n];
	end

	// Decimal conversion of the 4 global coin counters, done sequentially by repeated
	// subtraction (a combinational /1000 /100 /10 does not meet timing). Each slot takes
	// at most ~30 cycles, the 4 digits of slot s are at coin_bcd[s*16 +: 16].
	logic [4*16-1:0] coin_bcd = '0;
	logic [1:0]  bcd_slot = 2'd0;
	logic [1:0]  bcd_phase = 2'd0;      // 0: thousands, 1: hundreds, 2: tens, 3: store
	logic [13:0] bcd_val = '0;
	logic [3:0]  bcd_d3, bcd_d2, bcd_d1;
	always @(posedge i_clk) begin
		case (bcd_phase)
			2'd0: if (bcd_val >= 14'd1000) begin bcd_val <= bcd_val - 14'd1000; bcd_d3 <= bcd_d3 + 4'd1; end
			      else bcd_phase <= 2'd1;
			2'd1: if (bcd_val >= 14'd100)  begin bcd_val <= bcd_val - 14'd100;  bcd_d2 <= bcd_d2 + 4'd1; end
			      else bcd_phase <= 2'd2;
			2'd2: if (bcd_val >= 14'd10)   begin bcd_val <= bcd_val - 14'd10;   bcd_d1 <= bcd_d1 + 4'd1; end
			      else bcd_phase <= 2'd3;
			2'd3: begin
				coin_bcd[bcd_slot * 16 +: 16] <= {bcd_d3, bcd_d2, bcd_d1, bcd_val[3:0]};
				// Load the next slot (counter capped to 9999)
				bcd_slot  <= bcd_slot + 2'd1;
				bcd_val   <= (jvs_coin_status[(bcd_slot + 2'd1) * 16 +: 14] > 14'd9999) ? 14'd9999 :
				             jvs_coin_status[(bcd_slot + 2'd1) * 16 +: 14];
				{bcd_d3, bcd_d2, bcd_d1} <= '0;
				bcd_phase <= 2'd0;
			end
		endcase
	end

	function automatic logic [7:0] coin_row_char(input logic [5:0] col, input logic [3:0] slots,
	                                              input logic [3:0] first, input logic [63:0] status,
	                                              input logic [63:0] bcd);
		logic [2:0]  slot;
		logic [2:0]  pos;
		logic [3:0]  g;
		logic [15:0] st;
		logic [15:0] dg;
		logic [7:0]  cond_chr;
		logic [15*8-1:0] none_txt;
		coin_row_char = 8'h20;
		none_txt = "COIN: NO SLOT  ";
		if (slots == 4'd0) begin
			if (col < 6'd15) coin_row_char = none_txt[8*(14 - col) +: 8];
		end else if (col < 6'd4) begin
			coin_row_char = (col == 6'd0) ? "C" : (col == 6'd1) ? "O" : (col == 6'd2) ? "I" : "N";
		end else if (col >= 6'd5) begin
			slot = (col - 6'd5) >> 3;
			pos  = (col - 6'd5) & 6'd7;
			g    = first + slot;
			if (slot < slots && g < 4'd4) begin
				st  = status[g[1:0] * 16 +: 16];
				dg  = bcd[g[1:0] * 16 +: 16];
				case (st[15:14])
					2'd1:    cond_chr = "J";
					2'd2:    cond_chr = "D";
					2'd3:    cond_chr = "B";
					default: cond_chr = " ";
				endcase
				case (pos)
					3'd0: coin_row_char = 8'h31 + slot;
					3'd1: coin_row_char = ":";
					3'd2: coin_row_char = 8'h30 + dg[15:12];
					3'd3: coin_row_char = 8'h30 + dg[11:8];
					3'd4: coin_row_char = 8'h30 + dg[7:4];
					3'd5: coin_row_char = 8'h30 + dg[3:0];
					3'd6: coin_row_char = cond_chr;
					default: coin_row_char = 8'h20;
				endcase
			end
		end
	endfunction

	//-------------------------------------------------------------------------
	// Player rows of the selected node
	//-------------------------------------------------------------------------
	// Players are numbered globally across the chain: the selected node's first
	// player is the sum of the players of the nodes before it.
	logic [1:0] player_slot = 2'd0;          // local player row being written (0..3)
	logic [3:0] node_first_player;
	always_comb begin
		node_first_player = 4'd0;
		for (int n = 0; n < jvs_node_info_pkg::MAX_JVS_NODES; n++)
			if (n < osd_node_sel)
				node_first_player = node_first_player + jvs_nodes.node_players[n];
	end
	wire [3:0]  player_global = node_first_player + player_slot;
	wire        player_slot_active = (player_slot < jvs_nodes.node_players[osd_node_sel]) && (player_global < 4'd4);
	logic [15:0] player_btn;
	logic [31:0] player_joy;
	always_comb begin
		case (player_global[1:0])
			2'd0: begin player_btn = p1_btn_state; player_joy = p1_joy_state; end
			2'd1: begin player_btn = p2_btn_state; player_joy = p2_joy_state; end
			2'd2: begin player_btn = p3_btn_state; player_joy = p3_joy_state; end
			default: begin player_btn = p4_btn_state; player_joy = p4_joy_state; end
		endcase
	end

	// Input glyphs in the OSD font: 0x80+k released (gray), 0xF0+k pressed (yellow)
	// k: 0=Up 1=Down 2=Left 3=Right 4=Start 5=Coin 6..15=push buttons 1..10
	function automatic logic [7:0] input_glyph(input logic [3:0] k, input logic pressed);
		input_glyph = (pressed ? 8'hF0 : 8'h80) + k;
	endfunction

	// Player row: "P1 UDLR SC 1234567890" (columns 0..20)
	// btn bits: [0]Up [1]Down [2]Left [3]Right [4..13]push1..10 [14]Coin [15]Start
	function automatic logic [7:0] player_row_char(input logic active, input logic [1:0] slot,
	                                                input logic [15:0] btn, input logic [31:0] joy,
	                                                input logic has_analog, input logic [4:0] col);
		player_row_char = 8'h20;
		if (active) begin
			case (col)
				5'd0:  player_row_char = "P";
				5'd1:  player_row_char = "1" + slot;
				5'd3, 5'd4, 5'd5, 5'd6:
				       player_row_char = input_glyph(col - 5'd3, btn[col - 5'd3]);
				5'd8:  player_row_char = input_glyph(4'd4, btn[15]);
				5'd9:  player_row_char = input_glyph(4'd5, btn[14]);
				5'd11, 5'd12, 5'd13, 5'd14, 5'd15, 5'd16, 5'd17, 5'd18, 5'd19, 5'd20:
				       player_row_char = input_glyph(col - 5'd5, btn[col - 5'd7]);
				default: player_row_char = 8'h20;
			endcase
		end
	endfunction

	// Base address of the selected node name in the controller name BRAM
	wire [7:0] osd_node_name_base = osd_node_sel * jvs_node_info_pkg::NODE_NAME_SIZE;

	// BRAND / MODEL fields are only written up to the string terminator: blank
	// them first when the displayed node (or the bus state) changes
	logic       clear_names_req = 1'b0;
	logic [10:0] clear_addr;
	logic [1:0]  name_wait_cnt;
	function automatic logic is_name_field(input logic [10:0] a);
		is_name_field = (a >= JVS_NODE_BRAND_POS && a < JVS_NODE_NAME_LAST1_POS) ||
		                (a >= JVS_NODE_MODEL_POS && a <= JVS_NODE_NAME_LAST2_POS) ||
		                (a >= JVS_NODE_NAME_LAST2_POS + 11 && a < JVS_NODE_NAME_LAST3_POS);
	endfunction

	// Variables for BRAND/MODEL parsing
	logic [7:0] semicolon_addr;  // Address where semicolon was found
	logic semicolon_found;       // Flag indicating semicolon was found

	// Nibble (0..15) a ASCII ('0'..'9','A'..'F' o 'a'..'f')
	function automatic logic [7:0] hex2ascii(input logic [3:0] v, input logic uppercase);
		if (v < 10) hex2ascii = "0" + v;
		else        hex2ascii = (uppercase ? "A" : "a") + (v - 10);
	endfunction

	always @(posedge i_clk) begin
//see comments in JVS_Debugger.qsf under [JVS project settings]
		`ifdef USE_DUMMY_JVS_DATA
		jvs_data_ready_prev <= OSD_VS;
		`else
		jvs_data_ready_prev <= jvs_data_ready;
		`endif
		jvs_bus_state_prev <= jvs_bus_state;
		osd_node_sel_prev <= osd_node_sel;
		dout_test_prev <= dout_test;
		aout_test_prev <= aout_test;
		recoil_auto_prev <= recoil_auto;
		dump_status_prev <= dump_status_s2;
		jvs_sniffer_prev <= jvs_sniffer;
		ana_pair_sel_prev <= ana_pair_sel;
		if (jvs_bus_state_changed || osd_node_changed)
			clear_names_req <= 1'b1;

		`ifdef USE_DUMMY_JVS_DATA
	    if ((!jvs_data_ready_prev && OSD_VS) || osd_node_changed || ana_pair_changed)
		`else
		if ((!jvs_data_ready_prev && jvs_data_ready) || jvs_bus_state_changed || osd_node_changed || ana_pair_changed || dout_test_changed || aout_test_changed || recoil_auto_changed || dump_status_changed || jvs_sniffer_changed || sniff_tick)
		`endif
		begin
			jvs_name_copy_state <= CLEAR_NAMES;
			clear_addr <= JVS_NODE_BRAND_POS;
			do_proc <= 1'b1;
		end else if (do_proc) begin
			case (jvs_name_copy_state)
				CLEAR_NAMES: begin
					// Blank BRAND/MODEL fields (only when requested)
					if (clear_names_req && clear_addr < JVS_NODE_NAME_LAST3_POS) begin
						OSD_wr_en   <= is_name_field(clear_addr);
						OSD_wr_addr <= clear_addr;
						OSD_wr_data <= 8'h20; // ' '
						clear_addr  <= clear_addr + 11'd1;
					end else begin
						OSD_wr_en <= 1'b0;
						clear_names_req <= 1'b0;
						jvs_name_copy_state <= INIT_JVS_STR;
					end
				end
				INIT_JVS_STR: begin
					node_name_rd_addr <= osd_node_name_base; // Selected node name: node_index * NODE_NAME_SIZE
					next_OSD_wr_addr <= JVS_NODE_BRAND_POS;  // Start with BRAND
					semicolon_found <= 1'b0;  // Reset semicolon flag
					semicolon_addr <= 0;   // Reset semicolon address using proper width
					OSD_wr_en <= 1'b0;	//disable write
					name_wait_cnt <= 2'd2;
					jvs_name_copy_state <= WAIT_JVS_STR;
				end
				WAIT_JVS_STR: begin
					// Name BRAM read latency after the base address change
					if (name_wait_cnt == 2'd0)
						jvs_name_copy_state <= READ_JVS_STR;
					else
						name_wait_cnt <= name_wait_cnt - 2'd1;
				end
				READ_JVS_STR: begin
					OSD_wr_en <= 1'b0;	//disable write
					STR_byte <= node_name_rd_data;
					node_name_rd_addr <= node_name_rd_addr + 1'b1; //increment read address for next byte
					jvs_name_copy_state <= WRITE_BRAND_STR;
				end

				// WAIT1_JVS_STR: begin
				// 	jvs_name_copy_state <= WRITE_JVS_STR;
				// end

				WRITE_BRAND_STR: begin
					if((STR_byte != 8'h00) && (next_OSD_wr_addr < JVS_NODE_NAME_LAST1_POS)) begin
						if (STR_byte == 8'h3B) begin // Semicolon found (';' = 0x3B)
							semicolon_found <= 1'b1;
							semicolon_addr <= node_name_rd_addr - 1'b1; // Save position after semicolon
							jvs_name_copy_state <= INIT_MODEL_STR;
						end else begin
							//write brand character
							OSD_wr_en <= 1'b1; //enable write
							OSD_wr_data <= STR_byte;
							OSD_wr_addr <= next_OSD_wr_addr;
							next_OSD_wr_addr <= next_OSD_wr_addr + 11'd1;	 //increment write address for next byte
							jvs_name_copy_state <= READ_JVS_STR;
						end
					end else begin
						// End of string or max BRAND size reached
						OSD_wr_en <= 1'b0;	//disable write
						jvs_name_copy_state <= INIT_SNAC_STR;
					end
				end

				INIT_MODEL_STR: begin
					next_OSD_wr_addr <= JVS_NODE_MODEL_POS;  // Switch to MODEL position
					OSD_wr_en <= 1'b0;	//disable write
					jvs_name_copy_state <= READ_MODEL_STR;
				end

				READ_MODEL_STR: begin
					OSD_wr_en <= 1'b0;	//disable write
					STR_byte <= node_name_rd_data;
					node_name_rd_addr <= node_name_rd_addr + 1'b1; //increment read address for next byte
					jvs_name_copy_state <= WRITE_MODEL_STR;
				end

				WRITE_MODEL_STR: begin
					if((STR_byte != 8'h00) && (next_OSD_wr_addr < JVS_NODE_NAME_LAST3_POS)) begin
						//write model character
						OSD_wr_en <= 1'b1; //enable write
						OSD_wr_data <= STR_byte;
						OSD_wr_addr <= next_OSD_wr_addr;
						next_OSD_wr_addr <=(next_OSD_wr_addr == JVS_NODE_NAME_LAST2_POS) ? next_OSD_wr_addr + 11'd11 : next_OSD_wr_addr + 11'd1; //jump to next line if needed
						jvs_name_copy_state <= READ_MODEL_STR;
					end else begin
						// End of string or max MODEL size reached
						OSD_wr_en <= 1'b0;	//disable write
						jvs_name_copy_state <= INIT_SNAC_STR;
					end
				end

				INIT_SNAC_STR: begin
					SNAC_ROM_addr <= snac_game_cont_type * SNAC_ROM_STR_LEN; //set initial read address
					next_OSD_wr_addr <= SNAC_DEVICE_STR_POS;
					OSD_wr_en <= 1'b0;	//disable write
					jvs_name_copy_state <= WAIT1_SNAC_STR;
				end
				
				//let ROM one cycle to retrieve data
				WAIT1_SNAC_STR: begin
					jvs_name_copy_state <= READ_SNAC_STR;
				end

				READ_SNAC_STR: begin
					OSD_wr_en <= 1'b0;	//disable write
					STR_byte <= SNAC_ROM_data;
					SNAC_ROM_addr <= SNAC_ROM_addr + 10'd1; //increment read address for next byte
					jvs_name_copy_state <= WRITE_SNAC_STR;
				end

				WRITE_SNAC_STR: begin
					if((STR_byte != 8'h00) && (next_OSD_wr_addr < SNAC_DEVICE_STR_POS + SNAC_ROM_STR_LEN)) begin
						//end of string or max size reached
						OSD_wr_en <= 1'b1; //enable write
						OSD_wr_data <= STR_byte;
						OSD_wr_addr <= next_OSD_wr_addr;
						next_OSD_wr_addr <= next_OSD_wr_addr  + 11'd1; //increment write address for next byte
						jvs_name_copy_state <= READ_SNAC_STR;
					end else begin
						OSD_wr_en <= 1'b0;	//disable write
						jvs_name_copy_state <= COPY_NODEID_VER1;
					end
				end
				COPY_NODEID_VER1: begin
					jvs_name_copy_state <= WRITE_NODE_SLASH;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_NUMBER_POS;
					OSD_wr_data <= 8'h30 + osd_node_sel + 8'd1; // Node position in the chain (= JVS address), 1-based
				end

				WRITE_NODE_SLASH: begin
					jvs_name_copy_state <= WRITE_NODE_COUNT;
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_NUMBER_POS + 11'd1;
					OSD_wr_data <= "/";
				end

				WRITE_NODE_COUNT: begin
					jvs_name_copy_state <= COPY_CMD_VER1;
					//write node_count after node ID (format: "NODE# 1/2" where 2 is node_count)
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_NUMBER_POS + 11'd2; // After "NODE# X/"
					OSD_wr_data <= 8'h30 + jvs_nodes.node_count[3:0]; // node_count as ASCII digit
				end

				COPY_CMD_VER1: begin
					jvs_name_copy_state <= COPY_CMD_VER2;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_CMD_POS;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_cmd_ver[osd_node_sel][7:4]; //LS nibble
				end

				COPY_CMD_VER2: begin
					jvs_name_copy_state <= COPY_JVS_VER1;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_CMD_POS + 11'd1;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_cmd_ver[osd_node_sel][3:0]; //MS nibble
				end
				COPY_JVS_VER1: begin
					jvs_name_copy_state <= COPY_JVS_VER2;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_JVS_POS;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_jvs_ver[osd_node_sel][7:4]; //LS nibble
				end

				COPY_JVS_VER2: begin
					jvs_name_copy_state <= COPY_COM_VER1;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_JVS_POS + 11'd1;
					OSD_wr_data <= 8'h30 +jvs_nodes.node_jvs_ver[osd_node_sel][3:0]; //MS nibble
				end
				
				COPY_COM_VER1: begin
					jvs_name_copy_state <= COPY_COM_VER2;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_COM_POS;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_com_ver[osd_node_sel][7:4]; //LS nibble
				end

				COPY_COM_VER2: begin
					jvs_name_copy_state <= WRITE_INPUTS_PLAYERS;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_COM_POS + 11'd1;
					OSD_wr_data <= 8'h30 +jvs_nodes.node_com_ver[osd_node_sel][3:0]; //MS nibble
				end

				WRITE_INPUTS_PLAYERS: begin
					jvs_name_copy_state <= WRITE_INPUTS_P;
					//write number of players
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd7; // After "SWITCH:" for players in compact format
					OSD_wr_data <= 8'h30 + jvs_nodes.node_players[osd_node_sel][3:0]; // Convert to ASCII digit
				end

				WRITE_INPUTS_P: begin
					jvs_name_copy_state <= WRITE_INPUTS_BUTTONS_TENS;
					//write "P" and calculate decimal value
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd8; // 'P' in compact format
					OSD_wr_data <= 8'h50; // 'P'
					// Convert hex to decimal for display
					buttons_decimal <= jvs_nodes.node_buttons[osd_node_sel];
				end

				WRITE_INPUTS_BUTTONS_TENS: begin
					jvs_name_copy_state <= WRITE_INPUTS_BUTTONS_UNITS;
					//write tens digit only if >= 10 (skip completely for single digits)
					if (buttons_decimal >= 8'd10) begin
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd9; // buttons tens digit
						OSD_wr_data <= 8'h30 + (buttons_decimal / 8'd10); // Tens digit
					end else begin
						// Skip writing tens digit for single digit numbers
						OSD_wr_en <= 1'b0; // No write operation
					end
				end

				WRITE_INPUTS_BUTTONS_UNITS: begin
					jvs_name_copy_state <= WRITE_INPUTS_B;
					//write units digit
					OSD_wr_en <= 1'b1;
					if (buttons_decimal >= 8'd10) begin
						OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd10; // buttons units after tens digit
					end else begin
						OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd9;  // buttons units direct after 'P'
					end
					OSD_wr_data <= 8'h30 + (buttons_decimal % 8'd10); // Units digit
				end

				WRITE_INPUTS_B: begin
					jvs_name_copy_state <= WRITE_ANALOG_INFO;
					//write "b" after buttons digits (position depends on number of digits)
					OSD_wr_en <= 1'b1;
					if (buttons_decimal >= 8'd10) begin
						OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd11; // 'b' after 2 digits (2P13b)
					end else begin
						OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd10; // 'b' after 1 digit (2P8b)
					end
					OSD_wr_data <= 8'h62; // 'b' (lowercase)
				end

				WRITE_ANALOG_INFO: begin
					jvs_name_copy_state <= WRITE_ANALOG_CH;
					//write number of analog channels to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_ANALOG_POS;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_analog_channels[osd_node_sel][3:0]; // Convert to ASCII digit
				end

				WRITE_ANALOG_CH: begin
					jvs_name_copy_state <= WRITE_ANALOG_H;
					//write "C" for channels
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_ANALOG_POS + 11'd1;
					OSD_wr_data <= 8'h43; // 'C'
				end

				WRITE_ANALOG_H: begin
					//write "h" for channels and calculate bits decimal value
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_ANALOG_POS + 11'd2;
					OSD_wr_data <= 8'h68; // 'h'
					// Convert hex to decimal for display, check for unknown resolution
					if (jvs_nodes.node_analog_bits[osd_node_sel] == 8'd0) begin
						// Resolution unknown, skip to write '?' 
						jvs_name_copy_state <= WRITE_ANALOG_B;
						analog_bits_decimal <= 8'd0; // Special case for unknown
					end else begin
						jvs_name_copy_state <= WRITE_ANALOG_BITS_TENS;
						analog_bits_decimal <= (jvs_nodes.node_analog_bits[osd_node_sel] > 8'd99) ? 8'd99 : jvs_nodes.node_analog_bits[osd_node_sel];
					end
				end

				WRITE_ANALOG_BITS_TENS: begin
					jvs_name_copy_state <= WRITE_ANALOG_BITS_UNITS;
					//write tens digit of analog bits
					if (analog_bits_decimal >= 8'd10) begin
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_NODE_ANALOG_POS + 11'd3;
						OSD_wr_data <= 8'h30 + (analog_bits_decimal / 8'd10); // Tens digit
					end else begin
						// Skip tens digit for single digit values
						jvs_name_copy_state <= WRITE_ANALOG_BITS_UNITS;
					end
				end

				WRITE_ANALOG_BITS_UNITS: begin
					jvs_name_copy_state <= WRITE_ANALOG_B;
					//write units digit of analog bits
					OSD_wr_en <= 1'b1;
					if (analog_bits_decimal >= 8'd10) begin
						OSD_wr_addr <= JVS_NODE_ANALOG_POS + 11'd4;
					end else begin
						OSD_wr_addr <= JVS_NODE_ANALOG_POS + 11'd3; // Single digit, no space for tens
					end
					OSD_wr_data <= 8'h30 + (analog_bits_decimal % 8'd10); // Units digit
				end

				WRITE_ANALOG_B: begin
					jvs_name_copy_state <= WRITE_COIN_INFO;
					if (analog_bits_decimal == 8'd0) begin
						// Unknown resolution, don't write anything more (just "8Ch")
						OSD_wr_en <= 1'b0; // No write operation
					end else begin
						//write "b" for bits after the number
						OSD_wr_en <= 1'b1;
						if (analog_bits_decimal >= 8'd10) begin
							OSD_wr_addr <= JVS_NODE_ANALOG_POS + 11'd5; // After 2 digits
						end else begin
							OSD_wr_addr <= JVS_NODE_ANALOG_POS + 11'd4; // After 1 digit
						end
						OSD_wr_data <= 8'h62; // 'b'
					end
				end

				WRITE_COIN_INFO: begin
					jvs_name_copy_state <= WRITE_FEATURES_R;
					//write number of coin slots after "COIN:" label on SWITCH line
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd18; // After "COIN:" label in compact format
					OSD_wr_data <= 8'h30 + jvs_nodes.node_coin_slots[osd_node_sel][3:0]; // Convert to ASCII digit
				end

				WRITE_FEATURES_R: begin
					jvs_name_copy_state <= WRITE_FEATURES_K;
					//write 'R' if rotary encoders available (0x04), space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS;
					OSD_wr_data <= (jvs_nodes.node_rotary_channels[osd_node_sel] > 0) ? 8'h52 : 8'h20; // 'R' or space
				end

				WRITE_FEATURES_K: begin
					jvs_name_copy_state <= WRITE_FEATURES_S;
					//write 'K' if keycode input available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd1;
					OSD_wr_data <= jvs_nodes.node_has_keycode_input[osd_node_sel] ? 8'h4B : 8'h20; // 'K' or space
				end

				WRITE_FEATURES_S: begin
					jvs_name_copy_state <= WRITE_FEATURES_D;
					//write 'S' if screen position available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd2;
					OSD_wr_data <= jvs_nodes.node_has_screen_pos[osd_node_sel] ? 8'h53 : 8'h20; // 'S' or space
				end

				WRITE_FEATURES_D: begin
					jvs_name_copy_state <= WRITE_FEATURES_A;
					//write 'D' if digital outputs available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd3;
					OSD_wr_data <= (jvs_nodes.node_digital_outputs[osd_node_sel] > 0) ? 8'h44 : 8'h20; // 'D' or space
				end

				WRITE_FEATURES_A: begin
					jvs_name_copy_state <= WRITE_FEATURES_C;
					//write 'A' if analog outputs available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd4;
					OSD_wr_data <= (jvs_nodes.node_analog_output_channels[osd_node_sel] > 0) ? 8'h41 : 8'h20; // 'A' or space
				end

				WRITE_FEATURES_C: begin
					jvs_name_copy_state <= WRITE_FEATURES_M;
					//write 'C' if card system available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd5;
					OSD_wr_data <= (jvs_nodes.node_card_system_slots[osd_node_sel] > 0) ? 8'h43 : 8'h20; // 'C' or space
				end

				WRITE_FEATURES_M: begin
					jvs_name_copy_state <= WRITE_FEATURES_T;
					//write 'M' if medal hopper available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd6;
					OSD_wr_data <= (jvs_nodes.node_medal_hopper_channels[osd_node_sel] > 0) ? 8'h4D : 8'h20; // 'M' or space
				end

				WRITE_FEATURES_T: begin
					jvs_name_copy_state <= WRITE_FEATURES_B;
					//write 'T' if text display available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd7;
					OSD_wr_data <= jvs_nodes.node_has_char_display[osd_node_sel] ? 8'h54 : 8'h20; // 'T' or space
				end

				WRITE_FEATURES_B: begin
					jvs_name_copy_state <= PLAYER_ROWS;
					btn_cnt <= 6'd0;
					player_slot <= 2'd0;
					//write 'B' if backup available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd8;
					OSD_wr_data <= jvs_nodes.node_has_backup[osd_node_sel] ? 8'h42 : 8'h20; // 'B' or space
				end

				// One row per player of the selected node:
				// "P1 <U><D><L><R> <S><C> <1>..<0> XXXX YYYY"
				PLAYER_ROWS: begin
					if (btn_cnt < PLAYER_ROW_LEN) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_PLAYER_ROW_POS + player_slot * 11'd40 + btn_cnt;
						OSD_wr_data <= player_row_char(player_slot_active, player_slot, player_btn, player_joy,
						                               jvs_nodes.node_analog_channels[osd_node_sel] != 4'd0, btn_cnt[4:0]);
					end else begin
						OSD_wr_en <= 1'b0;
						btn_cnt <= 6'd0;
						if (player_slot == 2'd3) begin
							player_slot <= 2'd0;
							jvs_name_copy_state <= ANALOG_ROWS;
						end else begin
							player_slot <= player_slot + 2'd1;
						end
					end
				end

				// Analog rows: X gauge, Y gauge (bars drawn by osd_top), pair info
				ANALOG_ROWS: begin
					if (btn_cnt < ANALOG_ROW_LEN) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_ANALOG_ROW_POS + player_slot * 11'd40 + btn_cnt;
						OSD_wr_data <= analog_row_char(player_slot, btn_cnt[4:0], ana_has_x, ana_has_y,
						                               ana_x_ch, ana_y_ch, ana_x, ana_y, ana_pair_sel, ana_pairs);
					end else begin
						OSD_wr_en <= 1'b0;
						btn_cnt <= 6'd0;
						if (player_slot == 2'd2) begin
							player_slot <= 2'd0;
							jvs_name_copy_state <= DOUT_ROW;
						end else begin
							player_slot <= player_slot + 2'd1;
						end
					end
				end

				// Digital output test value (NODE# row)
				DOUT_ROW: begin
					if (btn_cnt < DOUT_ROW_LEN) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_DOUT_POS + btn_cnt;
						OSD_wr_data <= dout_row_char(btn_cnt[4:0], node_has_dout, dout_test, node_has_aout, aout_test);
					end else begin
						OSD_wr_en <= 1'b0;
						btn_cnt <= 6'd0;
						jvs_name_copy_state <= RECOIL_ROW;
					end
				end

				// Gun recoil mode (row 10)
				RECOIL_ROW: begin
					if (btn_cnt < RECOIL_ROW_LEN) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= recoil_row_addr(btn_cnt[4:0]);
						OSD_wr_data <= recoil_row_char(btn_cnt[4:0], recoil_auto);
					end else begin
						OSD_wr_en <= 1'b0;
						btn_cnt <= 6'd0;
						jvs_name_copy_state <= DUMP_ROW;
					end
				end

				// Bus dump status (row 12)
				DUMP_ROW: begin
					if (btn_cnt < DUMP_ROW_LEN) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_DUMP_STATUS_POS + btn_cnt;
						OSD_wr_data <= dump_row_char(btn_cnt[3:0], dump_status_s2, dump_err_s2, jvs_dump_entries, jvs_sniffer, logger_ring, logger_waiting);
					end else begin
						OSD_wr_en <= 1'b0;
						btn_cnt <= 6'd0;
						jvs_name_copy_state <= COIN_ROW;
					end
				end

				// Coin slots of the selected node (row 18)
				COIN_ROW: begin
					if (btn_cnt < COIN_ROW_LEN) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_COIN_ROW_POS + btn_cnt;
						OSD_wr_data <= coin_row_char(btn_cnt, jvs_nodes.node_coin_slots[osd_node_sel],
						                             node_first_coin, jvs_coin_status, coin_bcd);
					end else begin
						OSD_wr_en <= 1'b0;
						btn_cnt <= 6'd0;
						jvs_name_copy_state <= WRITE_BUS_STATE;
					end
				end

				WRITE_BUS_STATE: begin
					if (btn_cnt < JVS_BUS_STATE_LEN) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_BUS_STATE_POS + btn_cnt;
						OSD_wr_data <= bus_state_char(jvs_bus_state, jvs_nodes.node_count, btn_cnt[4:0], jvs_sniffer);
					end else begin
						OSD_wr_en <= 1'b0;
						jvs_name_copy_state <= EOS;
					end
				end

				EOS: begin
						OSD_wr_addr <= 11'd0;
						OSD_wr_data <= 8'd0;
						node_name_rd_addr <= 0;
						SNAC_ROM_addr <= 10'd0;
						btn_cnt <= 6'd0;
						do_proc <= 1'b0;
				end
			endcase
		end	
	end
	//=========================================================================
	//------- END Process JVS data and copy strings to OSD memory -----------
	//=========================================================================

//---------------------------------------------------------------------
// Debug OSD
//---------------------------------------------------------------------
    logic [7:0] OSD_R, OSD_G, OSD_B;
    logic OSD_HS, OSD_VS, OSD_HB, OSD_VB;

	logic [10:0] OSD_wr_addr;
    logic [7:0]  OSD_wr_data;
    logic        OSD_wr_en=1'b0;

   osd_top #(
   	.CLK_HZ(MASTER_CLK_FREQ),
   	.COLS(40),
		.ROWS(30)
   ) osd_debug_inst (
       .clk(i_clk),
       .reset(i_rst_core),
       .pixel_ce(ce_pix),
       .R_in(R),
       .G_in(G),
       .B_in(B),
       .hsync_in(Hsync),
       .vsync_in(Vsync),
       .hblank(Hblank),
       .vblank(Vblank),
       .R_out(OSD_R),
       .G_out(OSD_G),
       .B_out(OSD_B),
       .hsync_out(OSD_HS),
       .vsync_out(OSD_VS),
       .hblank_out(OSD_HB),
       .vblank_out(OSD_VB),
		//memory write interface
		.wr_en(OSD_wr_en),
		.wr_addr(OSD_wr_addr),
		.wr_data(OSD_wr_data),
		// Wire gun to snac module
		.gun_trigger(gun_trig_all),
    	.gun_x(gun_x_all),
    	.gun_y(gun_y_all),
    	// Crosshair only for light gun boards (single player or screen position input):
    	// on other boards the "gun" position is just the P1 stick and drew an artifact
    	.gun_enable(gun_shown),
    	
    	// Wire GPIO output value for recoil display
    	.gpio_output_value(gpio_output_value),
    	
    	// Wire SNAC IO signals for display
    	.snac_io3(snac_io3),
    	.snac_in7(snac_in7),
    	.jvs_tx_activity(jvs_tx_activity),
    	.jvs_rx_activity(jvs_rx_activity),

    	// Analog gauges / X-Y target (selected node, selected pair)
    	.ana_has_x(ana_has_x),
    	.ana_has_y(ana_has_y),
    	.ana_x(ana_x),
    	.ana_y(ana_y)
   );

   assign OSD_out_R =OSD_R;
   assign OSD_out_G =OSD_G;
   assign OSD_out_B =OSD_B;
   assign OSD_out_Hsync =OSD_HS;
   assign OSD_out_Vsync =OSD_VS;
   assign OSD_out_Hblank=OSD_HB;
   assign OSD_out_Vblank=OSD_VB;


//---------------------------------------------------------------------
// Fix video
//---------------------------------------------------------------------
wire  ANALOGIZER_DE = ~(OSD_HB || OSD_VB);
wire ANALOGIZER_CSYNC = ~^{OSD_HS, OSD_VS};

wire hs_fix,vs_fix;
sync_fix sync_h(i_clk, OSD_HS, hs_fix);
sync_fix sync_v(i_clk, OSD_VS, vs_fix);

reg [7:0] R_fix,G_fix,B_fix;

reg CE,HS,VS,HBL,VBL;
always @(posedge i_clk) begin
	reg old_ce;
	old_ce <= ce_pix;
	CE <= 0;
	if(~old_ce & ce_pix) begin
		CE <= 1;
		HS <= hs_fix;
		// if(~HS & hs_fix) VS <= vs_fix;
		//FIX ONLY FOR XAIN'D SLEENA
		VS <= vs_fix;

		{R_fix,G_fix,B_fix} <= {OSD_R,OSD_G,OSD_B};
		HBL <= OSD_HB;
		// if(HBL & ~Hblank) VBL <= Vblank;
		//FIX ONLY FOR XAIN'D SLEENA
		VBL <= OSD_VB;
	end
end
//---------------------------------------------------------------------------

	//Choose type of analog video type of signal
	reg [5:0] Rout, Gout, Bout ;
	reg HsyncOut, VsyncOut, BLANKnOut ;
	wire [7:0] Yout, PrOut, PbOut ;
	wire [7:0] R_Sd, G_Sd, B_Sd ;
	wire Hsync_Sd, Vsync_Sd ;
	wire Hblank_Sd, Vblank_Sd ;
	wire BLANKn_SD = ~(Hblank_Sd || Vblank_Sd) ;

	always @(*) begin
		case(analogizer_video_type)
			4'h0: begin //RGBS
				Rout = R_fix[7:2]&{6{ANALOGIZER_DE}};
				Gout = G_fix[7:2]&{6{ANALOGIZER_DE}};
				Bout = B_fix[7:2]&{6{ANALOGIZER_DE}};
				HsyncOut = ANALOGIZER_CSYNC;
				VsyncOut = 1'b1;
				BLANKnOut = ANALOGIZER_DE;
			end
			4'h3, 4'h4: begin// Y/C Modes works for Analogizer R1, R2 Adapters
				Rout = yc_o[23:18];
				Gout = yc_o[15:10];
				Bout = yc_o[7:2];
				HsyncOut = yc_cs;
				VsyncOut = 1'b1;
				BLANKnOut = 1'b1;
			end
			4'h1: begin //RGsB
				Rout = R_fix[7:2]&{6{ANALOGIZER_DE}};
				Gout = G_fix[7:2]&{6{ANALOGIZER_DE}};
				Bout = B_fix[7:2]&{6{ANALOGIZER_DE}};
				HsyncOut = 1'b1;
				VsyncOut = ANALOGIZER_CSYNC; //to DAC SYNC pin, SWITCH SOG ON
				BLANKnOut = ANALOGIZER_DE;
			end
			4'h2: begin //YPbPr
				Rout = PrOut[7:2];
				Gout = Yout[7:2];
				Bout = PbOut[7:2];
				HsyncOut = 1'b1;
				VsyncOut = YPbPr_sync; //to DAC SYNC pin, SWITCH SOG ON
				BLANKnOut = 1'b1; //ADV7123 needs this
			end
			4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin //Scandoubler modes
				Rout = vga_data_sl[23:18]; //R_Sd[7:2];
				Gout = vga_data_sl[15:10]; //G_Sd[7:2];
				Bout = vga_data_sl[7:2]; //B_Sd[7:2];
				HsyncOut = vga_hs_sl; //Hsync_Sd;
				VsyncOut = vga_vs_sl; //Vsync_Sd;
				BLANKnOut = 1'b1;
			end
			default: begin
				Rout = 6'h0;
				Gout = 6'h0;
				Bout = 6'h0;
				HsyncOut = HS;
				VsyncOut = 1'b1;
				BLANKnOut = ANALOGIZER_DE;
			end
		endcase
	end

	wire YPbPr_sync, YPbPr_blank;
	vga_out_fixed ybpr_video
	(
		.clk(video_clk),
		.ypbpr_en(1'b1),
		.csync(ANALOGIZER_CSYNC),
		.de(ANALOGIZER_DE),
		.din({R_fix[7:0],G_fix[7:0],B_fix[7:0]}), //24 bits input
		.dout({PrOut,Yout,PbOut}), //24 bits output
		.csync_o(YPbPr_sync),
		.de_o(YPbPr_blank)
	);

	wire [23:0] yc_o ;
	//wire yc_hs, yc_vs, 
	wire yc_cs ;

	yc_out_legacy yc_out
	(
		.clk(i_clk),
		.PAL_EN(PALFLAG),
		.PHASE_INC(CHROMA_PHASE_INC),
		.COLORBURST_RANGE(COLORBURST_RANGE),
		.MULFLAG(CHROMA_MUL),
		.CHRADD(CHROMA_ADD),
		.CHRMUL(CHROMA_MUL),	
		.hsync(HS),
		.vsync(VS),
		.csync(ANALOGIZER_CSYNC),
		.dout(yc_o),
		.din({R_fix, G_fix, B_fix}), //24bits input
		.hsync_o(),
		.vsync_o(),
		.csync_o(yc_cs) //24bits output
	);

	wire ce_pix_Sd ;
	scandoubler_2 #(.LENGTH(LINE_LENGTH), .HALF_DEPTH(0)) sd
	(
		.clk_vid(i_clk),
		.hq2x(SC_fx[2]),

		.ce_pix(CE),
		.hs_in(HS),
		.vs_in(VS),
		.hb_in(HBL),
		.vb_in(VBL),
		.r_in({R_fix[7:0]&{8{ANALOGIZER_DE}}}),
		.g_in({G_fix[7:0]&{8{ANALOGIZER_DE}}}),
		.b_in({B_fix[7:0]&{8{ANALOGIZER_DE}}}),

		.ce_pix_out(ce_pix_Sd),
		.hs_out(Hsync_Sd),
		.vs_out(Vsync_Sd),
		.hb_out(Hblank_Sd),
		.vb_out(Vblank_Sd),
		.r_out(R_Sd),
		.g_out(G_Sd),
		.b_out(B_Sd)
	);

	reg Hsync_SL, Vsync_SL, Hblank_SL, Vblank_SL ;
	reg [7:0] R_SL, G_SL, B_SL ;
	reg CE_PIX_SL, DE_SL ;

	always @(posedge video_clk) begin
		Hsync_SL <= (scandoubler) ? Hsync_Sd : HS;
		Vsync_SL <= (scandoubler) ? Vsync_Sd : VS;
		Hblank_SL <= (scandoubler) ? Hblank_Sd : HBL;
		Vblank_SL <= (scandoubler) ? Vblank_Sd : VBL;
		R_SL <= (scandoubler) ? R_Sd    : {R_fix[7:0]&{8{ANALOGIZER_DE}}};
		G_SL <= (scandoubler) ? G_Sd    : {G_fix[7:0]&{8{ANALOGIZER_DE}}};
		B_SL <= (scandoubler) ? B_Sd    : {B_fix[7:0]&{8{ANALOGIZER_DE}}};
		CE_PIX_SL <= (scandoubler) ? ce_pix_Sd : CE;
		DE_SL <= ANALOGIZER_DE;
	end


wire [23:0] vga_data_sl ;
wire        vga_vs_sl, vga_hs_sl ;
scanlines_analogizer #(0) VGA_scanlines
(
	.clk(video_clk),

	.scanlines(SC_fx[1:0]),
	//.din(de_emu ? {R_SL, G_SL,B_SL} : 24'd0),
	.din({R_SL, G_SL,B_SL}),
	.hs_in(Hsync_SL),
	.vs_in(Vsync_SL),
	.de_in(DE_SL),
	.ce_in(CE_PIX_SL),

	.dout(vga_data_sl),
	.hs_out(vga_hs_sl),
	.vs_out(vga_vs_sl),
	.de_out(),
	.ce_out()
);


	//infer tri-state buffers for cartridge data signals
	//BK0
	assign cart_tran_bank0         = i_rst_apf | ~i_ena ? 4'hf : ((CART_BK0_DIR) ? CART_BK0_OUT : 4'hZ);     //on reset state set ouput value to 4'hf
	assign cart_tran_bank0_dir     = i_rst_apf | ~i_ena ? 1'b1 : CART_BK0_DIR;                              //on reset state set pin dir to output
	assign CART_BK0_IN             = cart_tran_bank0;
	//BK3
	assign cart_tran_bank3         = i_rst_apf | ~i_ena ? 8'hzz : {Rout[5:0],HsyncOut,VsyncOut};                          //on reset state set ouput value to 8'hZ
	assign cart_tran_bank3_dir     = i_rst_apf | ~i_ena ? 1'b0  : 1'b1;                                     //on reset state set pin dir to input
	//BK2
	assign cart_tran_bank2         = i_rst_apf | ~i_ena ? 8'hzz : {Bout[0],BLANKnOut,Gout[5:0]};                          //on reset state set ouput value to 8'hZ
	assign cart_tran_bank2_dir     = i_rst_apf | ~i_ena ? 1'b0  : 1'b1;                                     //on reset state set pin dir to input
	//BK1
	assign cart_tran_bank1         = i_rst_apf | ~i_ena ? 8'hzz : {CART_BK1_OUT_P76,video_clk,Bout[5:1]};      //on reset state set ouput value to 8'hZ
	assign cart_tran_bank1_dir     = i_rst_apf | ~i_ena ? 1'b0  : 1'b1;                                     //on reset state set pin dir to input
	//PIN30
	assign cart_tran_pin30         = i_rst_apf | ~i_ena ? 1'bz : ((CART_PIN30_DIR) ? CART_PIN30_OUT : 1'bZ); //on reset state set ouput value to 4'hf
	assign cart_tran_pin30_dir     = i_rst_apf | ~i_ena ? 1'b0 : CART_PIN30_DIR;                              //on reset state set pin dir to output
	assign CART_PIN30_IN           = cart_tran_pin30;
	assign cart_pin30_pwroff_reset = i_rst_apf | ~i_ena ? 1'b0 : 1'b1;                                      //1'b1 (GPIO USE)
	//PIN31
	assign cart_tran_pin31         = i_rst_apf | ~i_ena ? 1'bz : ((CART_PIN31_DIR) ? CART_PIN31_OUT : 1'bZ); //on reset state set ouput value to 4'hf
	assign cart_tran_pin31_dir     = i_rst_apf | ~i_ena ? 1'b0 : CART_PIN31_DIR;                            //on reset state set pin dir to input
	assign CART_PIN31_IN           = cart_tran_pin31;
endmodule

module sync_fix
(
	input clk,
	
	input sync_in,
	output sync_out
);

assign sync_out = sync_in ^ pol;

reg pol;
always @(posedge clk) begin
	reg [31:0] cnt;
	reg s1,s2;

	s1 <= sync_in;
	s2 <= s1;
	cnt <= s2 ? (cnt - 1) : (cnt + 1);

	if(~s2 & s1) begin
		cnt <= 0;
		pol <= cnt[31];
	end
end
endmodule