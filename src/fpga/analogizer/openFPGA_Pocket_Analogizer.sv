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
	output wire analogizer_osd_out,

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
    output wire [15:0] p4_btn_state,
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
    analogizer_osd_out2	  <= analogizer_config_s[15];
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
reg       analogizer_osd_out2;

assign analogizer_video_type_out = analogizer_video_type;
assign snac_game_cont_type_out   = snac_game_cont_type;
assign snac_cont_assignment_out  = snac_cont_assignment;
assign SC_fx_out                 = SC_fx;
assign pocket_blank_screen_out   = pocket_blank_screen;
assign analogizer_osd_out        = analogizer_osd_out2;
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
    logic [7:0] node_name_rd_data;
    logic [6:0] node_name_rd_addr;

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
		.p4_btn_state(p4_btn_state),
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
        .node_name_rd_data(node_name_rd_data),
        .node_name_rd_addr(node_name_rd_addr)
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

	localparam SNAC_DEVICE_STR_POS = 528;
	localparam JVS_NODE_NUMBER_POS = 568;
	localparam JVS_NODE_BRAND_POS = 608;     // Row 15, Col 8 - Position after "BRAND:" colon (shifted 1 left)
	localparam JVS_NODE_MODEL_POS = 648;     // Row 16, Col 8 - Position after "MODEL:" colon (shifted 1 left)
	localparam JVS_NODE_NAME_LAST1_POS = JVS_NODE_BRAND_POS + 29 - 1;   // End of BRAND line
	localparam JVS_NODE_NAME_LAST2_POS = JVS_NODE_MODEL_POS + 30 - 1;   // End of MODEL line (+1)
	localparam JVS_NODE_NAME_LAST3_POS = JVS_NODE_NAME_LAST2_POS + 40;   // Next line for MODEL overflow
	localparam JVS_NODE_CMD_POS = 770;  // Row 19, Col 10 - Position after "CMD VER:" colon (with space from border)
	localparam JVS_NODE_JVS_POS = 810;  // Row 20, Col 10 - Position after "JVS VER:" colon (with space from border)
	localparam JVS_NODE_COM_POS = 850;  // Row 21, Col 10 - Position after "COM VER:" colon (with space from border)
	// New positions for capability information - aligned colons at column 25
	localparam JVS_NODE_PLAYERS_POS = 774;   // Row 19, Col 14 - SWITCH label start (shifted 1 left)
	localparam JVS_NODE_ANALOG_POS = 821;    // Row 20, Col 21 - Position after ANALOG: colon (after space adjustment)
	localparam JVS_NODE_FEATURES_POS = 864;  // Row 21, Col 24 - Position after Features: colon (after space adjustment)
	localparam JVS_P1_BTN_POS = 891;  // Row 22, Col 11 - Position after "P1 BTN :" colon (moved closer to border)
	localparam JVS_P1_JOY_POS = 930;
	localparam JVS_P2_BTN_POS = 971;  // Row 24, Col 11 - Position after "P2 BTN :" colon (moved closer to border)
	localparam JVS_P2_JOY_POS = 1010;

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
		P1_BTN         = 39,
		P1_JOY         = 40,
		P2_BTN         = 41,
		P2_JOY         = 42,
		EOS            = 43
	} jvs_name_copy_state;

	// Variables for BRAND/MODEL parsing
	logic [6:0] semicolon_addr;  // Address where semicolon was found
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

		`ifdef USE_DUMMY_JVS_DATA
	    if (!jvs_data_ready_prev && OSD_VS)
		`else 
		if (!jvs_data_ready_prev && jvs_data_ready)
		`endif
		begin
			jvs_name_copy_state <= INIT_JVS_STR;
			do_proc <= 1'b1;
		end else if (do_proc) begin
			case (jvs_name_copy_state)
				INIT_JVS_STR: begin
					node_name_rd_addr <= 7'h0; //set initial read address
					next_OSD_wr_addr <= JVS_NODE_BRAND_POS;  // Start with BRAND
					semicolon_found <= 1'b0;  // Reset semicolon flag
					semicolon_addr <= 7'h0;   // Reset semicolon address
					OSD_wr_en <= 1'b0;	//disable write
					jvs_name_copy_state <=READ_JVS_STR;
				end
				READ_JVS_STR: begin
					OSD_wr_en <= 1'b0;	//disable write
					STR_byte <= node_name_rd_data;
					node_name_rd_addr <= node_name_rd_addr + 7'd1; //increment read address for next byte
					jvs_name_copy_state <= WRITE_BRAND_STR;
				end

				// WAIT1_JVS_STR: begin
				// 	jvs_name_copy_state <= WRITE_JVS_STR;
				// end

				WRITE_BRAND_STR: begin
					if((STR_byte != 8'h00) && (next_OSD_wr_addr < JVS_NODE_NAME_LAST1_POS)) begin
						if (STR_byte == 8'h3B) begin // Semicolon found (';' = 0x3B)
							semicolon_found <= 1'b1;
							semicolon_addr <= node_name_rd_addr - 7'd1; // Save position after semicolon
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
					node_name_rd_addr <= node_name_rd_addr + 7'd1; //increment read address for next byte
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
					jvs_name_copy_state <= COPY_CMD_VER1;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_NUMBER_POS;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_id[0][3:0]; //LS nibble
				end

				COPY_CMD_VER1: begin
					jvs_name_copy_state <= COPY_CMD_VER2;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_CMD_POS;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_cmd_ver[0][7:4]; //LS nibble
				end

				COPY_CMD_VER2: begin
					jvs_name_copy_state <= COPY_JVS_VER1;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_CMD_POS + 11'd1;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_cmd_ver[0][3:0]; //MS nibble
				end
				COPY_JVS_VER1: begin
					jvs_name_copy_state <= COPY_JVS_VER2;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_JVS_POS;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_jvs_ver[0][7:4]; //LS nibble
				end

				COPY_JVS_VER2: begin
					jvs_name_copy_state <= COPY_COM_VER1;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_JVS_POS + 11'd1;
					OSD_wr_data <= 8'h30 +jvs_nodes.node_jvs_ver[0][3:0]; //MS nibble
				end
				
				COPY_COM_VER1: begin
					jvs_name_copy_state <= COPY_COM_VER2;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_COM_POS;
					OSD_wr_data <= 8'h30 + jvs_nodes.node_com_ver[0][7:4]; //LS nibble
				end

				COPY_COM_VER2: begin
					jvs_name_copy_state <= WRITE_INPUTS_PLAYERS;
					//write byte to OSD memory
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_COM_POS + 11'd1;
					OSD_wr_data <= 8'h30 +jvs_nodes.node_com_ver[0][3:0]; //MS nibble
				end

				WRITE_INPUTS_PLAYERS: begin
					jvs_name_copy_state <= WRITE_INPUTS_P;
					//write number of players
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd7; // After "SWITCH:" for players in compact format
					OSD_wr_data <= 8'h30 + jvs_nodes.node_players[0][3:0]; // Convert to ASCII digit
				end

				WRITE_INPUTS_P: begin
					jvs_name_copy_state <= WRITE_INPUTS_BUTTONS_TENS;
					//write "P" and calculate decimal value
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_PLAYERS_POS + 11'd8; // 'P' in compact format
					OSD_wr_data <= 8'h50; // 'P'
					// Convert hex to decimal for display
					buttons_decimal <= jvs_nodes.node_buttons[0];
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
					OSD_wr_data <= 8'h30 + jvs_nodes.node_analog_channels[0][3:0]; // Convert to ASCII digit
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
					if (jvs_nodes.node_analog_bits[0] == 8'd0) begin
						// Resolution unknown, skip to write '?' 
						jvs_name_copy_state <= WRITE_ANALOG_B;
						analog_bits_decimal <= 8'd0; // Special case for unknown
					end else begin
						jvs_name_copy_state <= WRITE_ANALOG_BITS_TENS;
						analog_bits_decimal <= (jvs_nodes.node_analog_bits[0] > 8'd99) ? 8'd99 : jvs_nodes.node_analog_bits[0];
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
					OSD_wr_data <= 8'h30 + jvs_nodes.node_coin_slots[0][3:0]; // Convert to ASCII digit
				end

				WRITE_FEATURES_R: begin
					jvs_name_copy_state <= WRITE_FEATURES_K;
					//write 'R' if rotary encoders available (0x04), space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS;
					OSD_wr_data <= (jvs_nodes.node_rotary_channels[0] > 0) ? 8'h52 : 8'h20; // 'R' or space
				end

				WRITE_FEATURES_K: begin
					jvs_name_copy_state <= WRITE_FEATURES_S;
					//write 'K' if keycode input available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd1;
					OSD_wr_data <= jvs_nodes.node_has_keycode_input[0] ? 8'h4B : 8'h20; // 'K' or space
				end

				WRITE_FEATURES_S: begin
					jvs_name_copy_state <= WRITE_FEATURES_D;
					//write 'S' if screen position available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd2;
					OSD_wr_data <= jvs_nodes.node_has_screen_pos[0] ? 8'h53 : 8'h20; // 'S' or space
				end

				WRITE_FEATURES_D: begin
					jvs_name_copy_state <= WRITE_FEATURES_A;
					//write 'D' if digital outputs available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd3;
					OSD_wr_data <= (jvs_nodes.node_digital_outputs[0] > 0) ? 8'h44 : 8'h20; // 'D' or space
				end

				WRITE_FEATURES_A: begin
					jvs_name_copy_state <= WRITE_FEATURES_C;
					//write 'A' if analog outputs available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd4;
					OSD_wr_data <= (jvs_nodes.node_analog_output_channels[0] > 0) ? 8'h41 : 8'h20; // 'A' or space
				end

				WRITE_FEATURES_C: begin
					jvs_name_copy_state <= WRITE_FEATURES_M;
					//write 'C' if card system available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd5;
					OSD_wr_data <= (jvs_nodes.node_card_system_slots[0] > 0) ? 8'h43 : 8'h20; // 'C' or space
				end

				WRITE_FEATURES_M: begin
					jvs_name_copy_state <= WRITE_FEATURES_T;
					//write 'M' if medal hopper available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd6;
					OSD_wr_data <= (jvs_nodes.node_medal_hopper_channels[0] > 0) ? 8'h4D : 8'h20; // 'M' or space
				end

				WRITE_FEATURES_T: begin
					jvs_name_copy_state <= WRITE_FEATURES_B;
					//write 'T' if text display available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd7;
					OSD_wr_data <= jvs_nodes.node_has_char_display[0] ? 8'h54 : 8'h20; // 'T' or space
				end

				WRITE_FEATURES_B: begin
					jvs_name_copy_state <= P1_BTN;
					//write 'B' if backup available, space otherwise
					OSD_wr_en <= 1'b1;
					OSD_wr_addr <= JVS_NODE_FEATURES_POS + 11'd8;
					OSD_wr_data <= jvs_nodes.node_has_backup[0] ? 8'h42 : 8'h20; // 'B' or space
				end

				P1_BTN: begin
					if (btn_cnt < 6'd16) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_P1_BTN_POS + btn_cnt; //set start of destination address;		
						OSD_wr_data <= (p1_btn_state[15-btn_cnt]) ? "1" : "0";
					end else begin
						btn_cnt <= 6'd0;
						jvs_name_copy_state <= P2_BTN;
					end
				end

				P2_BTN: begin
					if (btn_cnt < 6'd16) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_P2_BTN_POS + btn_cnt; //set start of destination address;		
						OSD_wr_data <= (p2_btn_state[15-btn_cnt]) ? "1" : "0";
					end else begin
						btn_cnt <= 6'd0;
						jvs_name_copy_state <= P1_JOY;
					end
				end

				P1_JOY: begin
					if (btn_cnt < 6'd8) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_P1_JOY_POS + btn_cnt; //set start of destination address;
						case(btn_cnt[2:0])
							3'd0: OSD_wr_data <= hex2ascii(p1_joy_state[31:28], 1'b1);
							3'd1: OSD_wr_data <= hex2ascii(p1_joy_state[27:24], 1'b1);
							3'd2: OSD_wr_data <= hex2ascii(p1_joy_state[23:20], 1'b1);
							3'd3: OSD_wr_data <= hex2ascii(p1_joy_state[19:16], 1'b1);
							3'd4: OSD_wr_data <= hex2ascii(p1_joy_state[15:12], 1'b1);
							3'd5: OSD_wr_data <= hex2ascii(p1_joy_state[11:8], 1'b1);
							3'd6: OSD_wr_data <= hex2ascii(p1_joy_state[7:4], 1'b1);
							3'd7: OSD_wr_data <= hex2ascii(p1_joy_state[3:0], 1'b1);
						endcase
						
					end else begin
						btn_cnt <= 6'd0;
						jvs_name_copy_state <= P2_JOY;
					end
				end

				P2_JOY: begin
					if (btn_cnt < 6'd8) begin
						btn_cnt <= btn_cnt + 6'd1;
						OSD_wr_en <= 1'b1;
						OSD_wr_addr <= JVS_P2_JOY_POS + btn_cnt; //set start of destination address;
						case(btn_cnt[2:0])
							3'd0: OSD_wr_data <= hex2ascii(p2_joy_state[31:28], 1'b1);
							3'd1: OSD_wr_data <= hex2ascii(p2_joy_state[27:24], 1'b1);
							3'd2: OSD_wr_data <= hex2ascii(p2_joy_state[23:20], 1'b1);
							3'd3: OSD_wr_data <= hex2ascii(p2_joy_state[19:16], 1'b1);
							3'd4: OSD_wr_data <= hex2ascii(p2_joy_state[15:12], 1'b1);
							3'd5: OSD_wr_data <= hex2ascii(p2_joy_state[11:8], 1'b1);
							3'd6: OSD_wr_data <= hex2ascii(p2_joy_state[7:4], 1'b1);
							3'd7: OSD_wr_data <= hex2ascii(p2_joy_state[3:0], 1'b1);
						endcase
					end else begin
						OSD_wr_en <= 1'b0;
						jvs_name_copy_state <= EOS;
					end
				end

				EOS: begin
						OSD_wr_addr <= 11'd0;		
						OSD_wr_data <= 8'd0;
						node_name_rd_addr <= 7'h0;
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
		//JVS Light crosshair
		.gun_trigger(1'b0),
    	.gun_x(12'd159),
    	.gun_y(12'd119)
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