//This module encapsulates all Analogizer adapter SNAC controllers
// Original work by @RndMnkIII. 
// Date: 01/2024 
// Release: 1.0

// *** Analogizer R.3 adapter ***
//SNAC mappings:
//USB 3 Type A connector   ______________________________________________________________________________________                             
//PIN_NUMBER:             /           1      2       3       4       5       6       7       8       9           \
//PIN_NAME:              |             VBUS   D-      D+      GND     RX-     RX+     GND_D   TX-     TX+         |
//FUNCTION:              |             +5V    OUT1    OUT2    GND     IO3     IN4     IO5     IO6     IN7         |
//                       |  A                   ^       ^              ^       |       ^       ^       |          |
//                       |  N                   |       |              |       |    +--|-------|-------+          |
//                       |  A       +-----------|-------|--------------|-------+    |  |       +----------------+ |                              
//                       |  L       |         +-|-------|--------------|------------+  +--------+               | |            
//                       |  O       |         | |       |              |      +------------+    |               | |
//                       |  G       |         | |       |              |   +->| B        B |----|------+        | |
//                       |  I       |         | |       |              +---|->| CONF. SW.  |<---+      |        | |
//                       |  Z       |         | |   +---|-------<----------|<-| A        A |<----+     |        | |
//                       |  E       |         | |   |   |                  |  +------------+     |     |        | |
//                       |  R       |         | |   |   |             +-->-+------>--------->----+     |        | |         
//                       |         I|        I| |   |   +-------+     |                                |        | |
//                       |  R      N|        N| +---------+     |    B|A     B OUT                     |        | |
//                       |  3      4|   I    7|  IO3| OUT1| OUT2|  IO3|IO5  +-----------------------------------+ |
//                       |          |   O   IN|    A|     |O    |O   O|O    |A IN                      |          |  
//                       |         I|   5+----|-----|-----|U----|U---U|U ---|--------------------------+          |  
//                       |      ___N|___B|IN__|___IN|_____|T____|T___T|T____|_____                                |  
//POCKET                 |     /    V    V    V     V     ^     ^     ^     V     \                               |    
//CARTRIDGE PIN #:        \___|     2    3    4     5 ... 28    29    30    31     |_____________________________/
//                             \____|____|____|_____|_____|_____|_____|_____|_____/
//Pocket Pin Name:                  |    |    |     |     |     |     |     |
//cart_tran_bank0[7] ---------------+    |    |     |     |     |     |     | cart_tran_bank0_dir=1'b0; //input
//cart_tran_bank0[6] --------------------+    |     |     |     |     |     |
//cart_tran_bank0[5] -------------------------+     |     |     |     |     |
//cart_tran_bank0[4] -------------------------------+     |     |     |     |
//cart_tran_bank1[6] -------------------------------------+     |     |     | cart_tran_bank1_dir=1'b1 //output
//cart_tran_bank1[7] -------------------------------------------+     |     |
//cart_tran_pin30    -------------------------------------------------+     | cart_tran_pin30_dir=1'b1, cart_pin30_pwroff_reset=1'b1 (GPIO USE)
//cart_tran_pin31    -------------------------------------------------------+ cart_tran_pin31_dir=1'b0 / 1'b1 
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------++------------------
//                                                      C O N F I G U R A T I O N   A                                                                                || CONFIGURATION  B
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------++------------------
//     DEV TYPE          0                   1                    2                   3                   4                     5                 6                  || 16         
//     PIN_NAME         SNAC DISABLED        DB15		          NES                 SNES                PCENGINE(2BTN)        PCENGINE(6BTN)    PCENGINE(MULTITAP) || PSX
//USB3       SNAC                                                                                                                                                    ||                  
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------||------------------
//VBUS 		 	                             +5V                  +5V                 +5V                 +5V                   +5V               +5V                || +5V                 
//D-		 OUT1      	                     CLK(O)               CLK_1(O)            CLK_1(O)            CLR(O)(*)             CLR(O)(*)         CLR(O)(*)          || AT1(O)     
//D+		 OUT2      	                     LAT(O)               LAT(O)              LAT(O)              SEL(O)(*)             SEL(O)(*)         SEL(O)(*)          || AT2(O)     
//GND 		 	                             GND                  GND                 GND                 GND                   GND               GND                || GND     
//RX-		  IO3                            DAT(I)               D0_1(I)             D0_1(I)             D2 (I)(*)             D2 (I)(*)         D2 (I)(*)          || CLK(O)          +
//RX+		  IN4                                                 D4_2(I)             IO_2(I)             D0 (I)(*)             D0 (I)(*)         D0 (I)(*)          || DAT(I)      
//GND_DRAIN	  IO5                                                 CLK_2(O)            CLK_2(O)                                                                       || ACK(I)          +
//TX-		  IO6                            DAT(I)(1)            D3_2(I)             D3_2(I)             D1 (I)(*)             D1 (I)(*)         D1 (I)(*)          || CMD(O)          +    
//TX+		  IN7                            D0_2(I)              D0_2(I)             D3 (I)(*)           D3 (I)(*)             D3 (I)(*)         D3 (I)(*)          || IRQ10(I)      
//
//(1) Alternate output of DAT (for male-to-male extension cables which cross Tx,Rx lines)

//(*) Needs a specific cable harness for use MiSTer SNAC adapter with the Pocket:
//  SNAC      PCENGINE     POCKET
// ADAPTER    FUNCTION     SNAC
//   D-    -> D0       ->  RX+    IN4
//   D+    -> D1       ->  TX-    IO6 (IN)
//   RX-   -> D2       ->  RX-    IO3 (IN)
//   RX+   -> CLR      ->  D-     OUT1
//   GND_D -> D3       ->  TX+    IN7 
//   TX-   -> SEL      ->  D+     OUT2
`default_nettype none
`timescale 1ns / 1ps

import jvs_node_info_pkg::*;

module openFPGA_Pocket_Analogizer_SNAC #(parameter MASTER_CLK_FREQ=50_000_000)
(
    input wire i_clk, //Core Master Freq.
    input wire i_rst, //Core general reset
    input wire conf_AB, //0 conf. A(default), 1 conf. B (see graph above)
    input wire [4:0] game_cont_type, //0-15 Conf. A, 16-31 Conf. B
    //input wire [2:0] game_cont_sample_rate, //0 compatibility mode (slowest), 1 normal mode, 2 fast mode, 3 superfast mode
        //PSX rumble interface joy1, joy2
    input [1:0] i_VIB_SW1,  //  Vibration SW  VIB_SW[0] Small Moter OFF 0:ON  1:
                                //VIB_SW[1] Bic Moter   OFF 0:ON  1(Dualshook Only)
	input [7:0] i_VIB_DAT1,  //  Vibration(Bic Moter)Data   8'H00-8'HFF (Dualshook Only)
    input [1:0] i_VIB_SW2,
	input [7:0] i_VIB_DAT2,  
    output reg [15:0] p1_btn_state,
    output reg [31:0] p1_joy_state,
    output reg [15:0] p2_btn_state,
    output reg [31:0] p2_joy_state,
    output reg [15:0] p3_btn_state,
    output reg [31:0] p3_joy_state,
    output reg [15:0] p4_btn_state,
    output reg [31:0] p4_joy_state,
    output reg busy,    
    //SNAC Pocket cartridge port interface (see graph above)   
    output reg [7:4] CART_BK0_OUT,
    input  wire [7:4] CART_BK0_IN,
    output reg CART_BK0_DIR, 
    output reg [7:6] CART_BK1_OUT_P76,
    output reg CART_PIN30_OUT,
    input  wire CART_PIN30_IN,
    output reg CART_PIN30_DIR, 
    output reg CART_PIN31_OUT,
    input  wire CART_PIN31_IN,
    output reg CART_PIN31_DIR,
    //debug
    output wire [3:0] DBG_TX,
    output wire o_stb,
    //JVS node information structure
    output logic jvs_data_ready,
    output jvs_node_info_t jvs_nodes,
    output jvs_bus_state_t jvs_bus_state,
    //RAM interface for node names (for debug/display purposes)
    output logic [7:0] node_name_rd_data,
    input logic [jvs_node_info_pkg::NAME_BRAM_ADDR_BITS-1:0] node_name_rd_addr,
    // JVS vendor init table (jvs_vendor.bin data slot, written by the APF bridge in the
    // clk_74a domain): word w = file bytes 4w..4w+3, first byte in [31:24]
    input  wire        clk_74a,
    input  wire        vendor_wr,
    input  wire [5:0]  vendor_wr_addr,
    input  wire [31:0] vendor_wr_data,
    
    // Snac gun register
    output reg snac_gun_trigger,
    output reg [11:0] snac_gun_x,
    output reg [11:0] snac_gun_y,
    
    // GPIO output value for OSD display
    output wire [7:0] gpio_output_value,

    // Digital output test value from the OSD (Pocket A button): when non zero it replaces
    // the gun recoil value sent with the JVS OUTPUT1 (32) command
    input  wire [15:0] dout_test,
    // Analog output test value from the OSD (Pocket X button), sent on every ANLOUT (33) channel
    input  wire [15:0] aout_test,
    // Node shown in the OSD (0 = first node): the only one receiving OUTPUT1 / ANLOUT
    input  wire [3:0]  output_node_sel,
    // Gun triggers / recoil of each player (JVS profile, jvs_vendor.bin): pN_trigger = a
    // switch of the player trigger mask is pressed; while pN_recoil is high the player recoil
    // mask bits are set in OUTPUT1 (the recoil pulses are generated by the user of this module)
    // Gun positions of P2..P4 (P1: snac_gun_x / snac_gun_y), 0..319 x 0..239, from the analog
    // pairs CH3/CH4, CH5/CH6, CH7/CH8 (global channels, JVS profile inversions applied), and
    // gun players (trigger mask defined in the JVS profile)
    output wire [11:0] p2_gun_x, p2_gun_y,
    output wire [11:0] p3_gun_x, p3_gun_y,
    output wire [11:0] p4_gun_x, p4_gun_y,
    output wire [3:0]  p_gun_defined,
    output wire        p1_trigger,
    output wire        p2_trigger,
    output wire        p3_trigger,
    output wire        p4_trigger,
    input  wire        p1_recoil,
    input  wire        p2_recoil,
    input  wire        p3_recoil,
    input  wire        p4_recoil,

    // JVS sniffer mode: the controller is held in reset, the RS485 driver stays disabled
    // (DIR = 0) and TX idle, so the adapter can listen to another host on the same bus
    input  wire        jvs_sniffer,

    // Per node JVS analog channels for OSD display: node n channel c at [(n*8 + c)*16 +: 16]
    output wire [jvs_node_info_pkg::MAX_JVS_NODES*128-1:0] jvs_node_analog,   // raw, per node
    // Raw coin slot status (global slots 0..3): {condition[1:0], counter[13:0]}
    output wire [4*16-1:0] jvs_coin_status,
    
    // SNAC IO signals for OSD display
    output wire snac_io3,
    output wire snac_in7,
    // JVS line activity for OSD indicators (stretched like the adapter TX/RX LEDs)
    output reg  jvs_tx_activity,
    output reg  jvs_rx_activity,
    // Raw JVS lines for the bus logger
    output wire jvs_tx_line,
    output wire jvs_rx_line,
    output wire jvs_dir_line
); 
    //
    logic SNAC_OUT1 ; //cart_tran_bank1[6]                                           D-
    logic SNAC_OUT2 ; //cart_tran_bank1[7]                                           D+
    logic SNAC_IO3_A ;//Conf.A: cart_tran_bank0[4] (in),  Conf.B: pin30(out)         RX- 
    logic SNAC_IO3_B ;//Conf.B: cart_tran_bank0[4] (in),  Conf.B: pin30(out)         RX-
    logic SNAC_IN4 ;  //cart_tran_bank0[7]                                           RX+
    logic SNAC_IO5_A ;//Conf.A: pin30(out),               Conf.B: cart_tran_bank1[6] GND_D
	logic SNAC_IO5_B ;//Conf.A: pin30(out),               Conf.B: cart_tran_bank1[6] GND_D
    logic SNAC_IO6_A ;//Conf.A: pin31(in),                Conf.B: pin31(out)         TX-
    logic SNAC_IO6_B ;//Conf.A: pin31(in),                Conf.B: pin31(out)         TX-
    logic SNAC_IN7 ;   //cart_tran_bank0[5]                                          TX+
    
    // GPIO control signals for recoil
    logic [7:0] gpio_output_value_reg;
    
    // Assign output wires - JVS digital output replaces GPIO output
    // (gpio_output_value: see pN_dout_to_ctrl below)
    assign snac_io3 = SNAC_IO3_A;
    assign snac_in7 = SNAC_IN7;
    
    //calculate step sizes for fract clock enables
    // localparam pce_compat_polling_freq    =  20_000; //  20_000 / 5 =   4K samples/sec PCE
    localparam pce_normal_polling_freq    =  40_000; //  40_000 / 5 =   8K samples/sec PCE
    localparam pce_fast_polling_freq      =  80_000; //  80_000 / 5 =  16K samples/sec PCE
    // localparam pce_very_fast_polling_freq = 100_000; // 100_000 / 5 =  20K samples/sec PCE

    // localparam Compat_60Hz_polling_freq        =   1_080; //  
    // localparam Compat_120Hz_polling_freq        =  2_160; //  
    localparam snes_compat_polling_freq        =   50_000; //                                           
    // localparam serlatch_compat_polling_freq    =   100_000; //  100_000 / 25 =  4K samples/sec DB15    100_000 / 18 =  5.55K samples/sec NES/SNES
    localparam serlatch_normal_polling_freq    =   200_000; //  200_000 / 25 =  8K samples/sec DB15    200_000 / 18 = 11.11K samples/sec NES/SNES
    localparam serlatch_fast_polling_freq      =   400_000; //  400_000 / 25 = 16K samples/sec DB15    400_000 / 18 = 22.22K samples/sec NES/SNES
    // localparam serlatch_very_fast_polling_freq = 1_000_000; //1_000_000 / 25 = 32K samples/sec DB15  1_000_000 / 18 = 55.55K samples/sec NES/SNES

    localparam psx_normal_polling_freq = 125_000;
    localparam psx_fast_polling_freq = 250_000;
        localparam psx_ultra_fast_polling_freq = 500_000;
    localparam psx_multitap_polling_freq = 1_000_000;

    // localparam uart_dbg_freq = 500_000 * 16; //115_200 * 16;
    localparam uart_dbg_freq = 1_000_000; //115_200 * 16;
    localparam [64:0] uart_dbg_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * uart_dbg_freq * 2) / 1000;
    localparam [32:0] uart_dbg_pstep    = uart_dbg_pstep_[32:0];


    //the FSM is clocked 2x the polling freq.
    localparam [32:0] MAX_INT = 33'h0ffffffff;
    // localparam [64:0] pce_compat_pstep_ = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * pce_compat_polling_freq * 2) / 1000;
    // localparam [32:0] pce_compat_pstep  = pce_compat_pstep_[32:0];
    localparam [64:0] pce_normal_pstep_ = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * pce_normal_polling_freq * 2) / 1000;
    localparam [32:0] pce_normal_pstep  = pce_normal_pstep_[32:0];
    localparam [64:0] pce_fast_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * pce_fast_polling_freq * 2) / 1000;
    localparam [32:0] pce_fast_pstep    = pce_fast_pstep_[32:0];

    localparam [64:0] psx_fast_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * psx_fast_polling_freq * 2) / 1000;
    localparam [32:0] psx_fast_pstep    = psx_fast_pstep_[32:0];
    localparam [64:0] psx_normal_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * psx_normal_polling_freq * 2) / 1000;
    localparam [32:0] psx_normal_pstep    = psx_normal_pstep_[32:0];
        localparam [64:0] psx_ultra_fast_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * psx_ultra_fast_polling_freq * 2) / 1000;
    localparam [32:0] psx_ultra_fast_pstep    = psx_ultra_fast_pstep_[32:0];
    localparam [64:0] psx_multitap_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * psx_multitap_polling_freq * 2) / 1000;
    localparam [32:0] psx_multitap_pstep    = psx_multitap_pstep_[32:0];
    // localparam [64:0] pce_very_fast_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) *pce_very_fast_polling_freq * 2) / 1000;
    // localparam [32:0] pce_very_fast_pstep    = pce_very_fast_pstep_[32:0];

    // localparam [64:0] serlatch_compat_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * serlatch_compat_polling_freq * 2) / 1000;
    // localparam [32:0] serlatch_compat_pstep    = serlatch_compat_pstep_[32:0];
    localparam [64:0] serlatch_normal_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * serlatch_normal_polling_freq * 2) / 1000;
    localparam [32:0] serlatch_normal_pstep    = serlatch_normal_pstep_[32:0];
    localparam [64:0] serlatch_fast_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * serlatch_fast_polling_freq * 2) / 1000;
    localparam [32:0] serlatch_fast_pstep    = serlatch_fast_pstep_[32:0];
    // localparam [64:0] serlatch_very_fast_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * serlatch_very_fast_polling_freq * 2) / 1000;
    // localparam [32:0] serlatch_very_fast_pstep    = serlatch_very_fast_pstep_[32:0];
    
    localparam [64:0] snes_compat_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * snes_compat_polling_freq  * 2) / 1000;
    localparam [32:0] snes_compat_pstep    = snes_compat_pstep_[32:0];

    // localparam [64:0] Compat_60Hz_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * Compat_60Hz_polling_freq  * 2) / 1000;
    // localparam [32:0] Compat_60Hz_pstep    = Compat_60Hz_pstep_[32:0];
    // localparam [64:0] Compat_120Hz_pstep_   = ((MAX_INT / (MASTER_CLK_FREQ / 1000)) * Compat_120Hz_polling_freq  * 2) / 1000;
    // localparam [32:0] Compat_120Hz_pstep    = Compat_120Hz_pstep_[32:0];
    
    //Supported game controller types
    localparam GC_DISABLED        = 5'h0;
    localparam GC_DB15            = 5'h1;
    localparam GC_NES             = 5'h2;
    localparam GC_SNES            = 5'h3;
    localparam GC_PCE_2BTN        = 5'h4;
    localparam GC_PCE_6BTN        = 5'h5;
    localparam GC_PCE_MULTITAP    = 5'h6;
    localparam GC_DB15_FAST       = 5'h9;
    localparam GC_SNES_SWAP       = 5'hB;
    localparam GC_PSX             = 5'h10; //16 PSX 125KHz
    localparam GC_PSX_FAST        = 5'h11; //17 PSX 250KHz
    localparam GC_PSX_ANALOG      = 5'h12; //16 PSX 125KHz
    localparam GC_PSX_ANALOG_FAST = 5'h13; //17 PSX 250KHz
    localparam GC_JVS             = 5'h14; //20 JVS RS485/RS232

    //Configuration:
    localparam CONF_A = 1'b0;
    localparam CONF_B = 1'b1;

    reg conf_AB_r;
    reg [4:0] game_cont_type_r;
    // reg [2:0] game_cont_sample_rate_r;
    reg [32:0] strobe_step_size;
    reg reset_on_change;

    always @(posedge i_clk) begin
        //register SNAC settings
        conf_AB_r <= conf_AB;
        game_cont_type_r <= game_cont_type;
        //game_cont_sample_rate_r <= game_cont_sample_rate;

        //detect change of SNAC settings and reset clock divider and set new settings
        reset_on_change <= 1'b0;
        //if(i_rst || (game_cont_type_r != game_cont_type) || (game_cont_sample_rate_r != game_cont_sample_rate)) begin
        if(i_rst || (game_cont_type_r != game_cont_type)) begin
            reset_on_change <= 1'b1;
        end
    end

    reg serlat_ena;
    reg pce_ena;
    reg psx_ena;
    reg jvs_ena;

    always @(posedge i_clk) begin
        case (game_cont_type)
            GC_PSX, GC_PSX_ANALOG: begin
                psx_ena    <= 1'b1;
                strobe_step_size <= psx_normal_pstep;   
            end
            GC_PSX_FAST, GC_PSX_ANALOG_FAST: begin
                psx_ena    <= 1'b1;
                strobe_step_size <= psx_fast_pstep;   
            end
            GC_DB15: begin 
                serlat_ena <= 1'b1;
                strobe_step_size <= serlatch_normal_pstep;    
                // case (game_cont_sample_rate)
                //     0: begin strobe_step_size <= serlatch_compat_pstep;    end
                //     1: begin strobe_step_size <= serlatch_normal_pstep;    end
                //     2: begin strobe_step_size <= serlatch_fast_pstep;      end
                //     // 3: begin strobe_step_size <= serlatch_very_fast_pstep; end 
                //     // 4: begin strobe_step_size <= snes_compat_pstep;        end 
                //     // 5: begin strobe_step_size <= Compat_60Hz_pstep;        end
                //     // 6: begin strobe_step_size <= Compat_120Hz_pstep;       end
                //     default: begin strobe_step_size <= serlatch_compat_pstep ;  end
                // endcase
            end
            GC_DB15_FAST: begin 
                serlat_ena <= 1'b1;
                strobe_step_size <= serlatch_fast_pstep;    
            end
            GC_NES, GC_SNES, GC_SNES_SWAP: begin 
                serlat_ena <= 1'b1;
                strobe_step_size <= snes_compat_pstep;
                // case (game_cont_sample_rate)
                //     0: begin strobe_step_size <= serlatch_compat_pstep ;   end
                //     1: begin strobe_step_size <= serlatch_normal_pstep;    end
                //     2: begin strobe_step_size <= serlatch_fast_pstep;      end
                //     // 3: begin strobe_step_size <= serlatch_very_fast_pstep; end 
                //     // 4: begin strobe_step_size <= snes_compat_pstep;        end 
                //     // 5: begin strobe_step_size <= Compat_60Hz_pstep;        end
                //     // 6: begin strobe_step_size <= Compat_120Hz_pstep;       end
                //     default: begin strobe_step_size <= serlatch_compat_pstep ;  end
                // endcase
            end
            GC_PCE_2BTN, GC_PCE_6BTN: begin
                pce_ena    <= 1'b1;
                strobe_step_size <= pce_normal_pstep;
                // case (game_cont_sample_rate)
                //     0: begin strobe_step_size <= pce_compat_pstep;    end
                //     1: begin strobe_step_size <= pce_normal_pstep;    end
                //     2: begin strobe_step_size <= pce_fast_pstep;      end
                //     3: begin strobe_step_size <= pce_very_fast_pstep; end 
                //     default: begin strobe_step_size <= pce_compat_pstep;    end
                // endcase 
            end
            GC_PCE_MULTITAP: begin
                pce_ena    <= 1'b1;
                strobe_step_size <= pce_fast_pstep;
            end
            GC_JVS: begin
                jvs_ena    <= 1'b1;
                strobe_step_size <= psx_normal_pstep; // Use moderate polling rate for JVS
            end

           default: begin//disabled
                serlat_ena <= 1'b0;
                pce_ena    <= 1'b0;
                psx_ena    <= 1'b0;
                jvs_ena    <= 1'b0;
                strobe_step_size <= 33'h0;
            end
        endcase
    end

    always @(posedge i_clk) begin
        case (conf_AB)         
            CONF_A: begin
                CART_BK0_DIR                   <= 1'b0;                                           //INPUT
                {SNAC_IN4,SNAC_IN7,SNAC_IO3_A} <= {CART_BK0_IN[7],CART_BK0_IN[5],CART_BK0_IN[4]}; //OUTPUT
                CART_BK1_OUT_P76                <= {SNAC_OUT2,SNAC_OUT1};                          //OUTPUT 
                CART_PIN30_DIR                 <= 1'b1;                                           //OUTPUT 
                CART_PIN30_OUT                 <= SNAC_IO5_A; 
                CART_PIN31_DIR                 <= 1'b0;                                           //INPUT
                SNAC_IO6_A                     <= CART_PIN31_IN;  
            end 
            CONF_B: begin 
                CART_BK0_DIR                    <= 1'b0;                                           //INPUT
                {SNAC_IN4,SNAC_IO5_B,SNAC_IN7} <= {CART_BK0_IN[7],CART_BK0_IN[6],CART_BK0_IN[5]}; //OUTPUT
                CART_BK1_OUT_P76                <= {SNAC_OUT2,SNAC_OUT1};                          //OUTPUT 
                CART_PIN30_DIR                 <= 1'b1;                                           //OUTPUT           
                CART_PIN30_OUT                 <= SNAC_IO3_B; 
                CART_PIN31_DIR                 <= 1'b1;                                           //OUTPUT
                CART_PIN31_OUT                 <= SNAC_IO6_B;
            end
        endcase
    end
                                               
    wire stb_clk ;
    clock_divider_fract ckdiv( 
    .i_clk (i_clk),
    .i_rst(reset_on_change), //reset on polling freq change
    .i_step(strobe_step_size[31:0]),
    .o_stb (stb_clk)
    );

	//  wire dbg_clk_w;
	//  reg dbg_clk /* synthesis noprune */;
    // clock_divider_fract dbgckdiv(
    // .i_clk (i_clk),
    // .i_rst(reset_on_change), //reset on polling freq change
    // .i_step(uart_dbg_pstep[31:0]),
    // .o_stb (dbg_clk_w)
    // );
	 
	//  always @(posedge i_clk) dbg_clk <= dbg_clk_w;

    assign o_stb = stb_clk;

    //PSX game controller for 1/2 players
    wire [15:0] psx_key1, psx_key2;
    wire [31:0] psx_joy1, psx_joy2;
    wire PSX_SNAC_OUT1 ;
    wire PSX_SNAC_OUT2 ;
    analogizer_psx #(.MASTER_CLK_FREQ(MASTER_CLK_FREQ)) psx (
        .i_clk(i_clk),
        .i_rst(reset_on_change),
        .i_ena(psx_ena),
        .i_stb(stb_clk),
        .key1(psx_key1),
        .joy1(psx_joy1),
        .key2(psx_key2),
        .joy2(psx_joy2),
        //PSX RUMBLE INTERFACE
        .i_VIB_SW1(i_VIB_SW1), .i_VIB_DAT1(i_VIB_DAT1), .i_VIB_SW2(i_VIB_SW2), .i_VIB_DAT2(i_VIB_DAT2), 
        //PSX EXTERNAL INTERFACE
        .PSX_CLK(SNAC_IO3_B),
        .PSX_DAT(SNAC_IN4),
        .PSX_CMD(SNAC_IO6_B),
        .PSX_ATT1(PSX_SNAC_OUT1),
        .PSX_ATT2(PSX_SNAC_OUT2),
        .PSX_ACK(SNAC_IO5_B),
        .DBG_TX(DBG_TX)
    );
    //assign PSX_SNAC_OUT2 = 1'b1;

    //DB15/NES/SNES game controller
    wire [15:0] sl_p1 ;
    wire [15:0] sl_p2 ;
    wire SERLAT_SNAC_OUT1 ;
    wire SERLAT_SNAC_OUT2 ;
    reg [1:0] i_D3_r;
    reg [1:0] i_D4_r;
    //wire SERLAT_SNAC_IO5_A /* synthesis keep */;
    
    //shift in D3 and D4 from SNAC_IN4 and SNAC_IO6_A for NES Zapper controller
    always @(posedge i_clk) begin
        i_D3_r <= {i_D3_r[0],SNAC_IO6_A};
        i_D4_r <= {i_D4_r[0],SNAC_IN4};
    end
    serlatch_game_controller #(.MASTER_CLK_FREQ(MASTER_CLK_FREQ)) slgc
    (
        .i_clk(i_clk),
        .i_rst(reset_on_change),
        .game_controller_type(game_cont_type[3:0]), //0x1 DB15, 0x2 NES, 0x3 SNES, 0x9 DB15 FAST, 0XB SNES SWAP A,B<->X,Y
        .i_stb(stb_clk),
        .p1_btn_state(sl_p1),
        .p2_btn_state(sl_p2),
        .busy(),
        //SNAC Game controller interface
        .o_clk(SERLAT_SNAC_OUT1), //shared for 2 controllers
        .o_clk2(SNAC_IO5_A),
        .o_lat(SERLAT_SNAC_OUT2), //shared for 2 controllers
        .i_dat1((game_cont_type == 5'h1 || game_cont_type == 5'h9) ? SNAC_IO3_A & SNAC_IO6_A : SNAC_IO3_A ), //data from controller 1
        .i_dat2(SNAC_IN7)  //data from controller 2
    );

    //PCENGINE game controller
    wire [15:0] pce_p1 ;
    wire PCE_SNAC_OUT1 ;
    wire PCE_SNAC_OUT2 ;

    pcengine_game_controller #(.MASTER_CLK_FREQ(MASTER_CLK_FREQ), .PULSE_CLR_LINE(1'b1)) pcegc1
    (
        .i_clk(i_clk),
        .i_rst(reset_on_change),
        .game_controller_type(game_cont_type[3:0]), //0X4 2btn, 0X5 6btn
        .i_stb(stb_clk),
        .player_btn_state(pce_p1),
        .busy(),
        //SNAC Game controller interface
        .o_clr(PCE_SNAC_OUT1), //shared for 2 controllers
        .o_sel(PCE_SNAC_OUT2), //shared for 2 controllers
        .i_dat({SNAC_IN7,SNAC_IO3_A,SNAC_IO6_A,SNAC_IN4}) //data from controller
    );

wire [15:0] pce_multitap_p1, pce_multitap_p2, pce_multitap_p3, pce_multitap_p4;
wire PCE_MULTITAP_SNAC_OUT1, PCE_MULTITAP_SNAC_OUT2;

pcengine_game_controller_multitap #(.MASTER_CLK_FREQ(MASTER_CLK_FREQ)) pcegmutitap
(
        .i_clk(i_clk),
        .i_rst(reset_on_change),
        .game_controller_type(game_cont_type[3:0]), //0x6 multitap
        .i_stb(stb_clk),
        .player1_btn_state(pce_multitap_p1),
        .player2_btn_state(pce_multitap_p2),
        .player3_btn_state(pce_multitap_p3),
        .player4_btn_state(pce_multitap_p4),
        .player5_btn_state(),
        .busy(),
    //SNAC Game controller interface
    .o_clr(PCE_MULTITAP_SNAC_OUT1), //shared for 2 controllers
    .o_sel(PCE_MULTITAP_SNAC_OUT2), //shared for 2 controllers
    .i_dat({SNAC_IN7,SNAC_IO3_A,SNAC_IO6_A,SNAC_IN4}) //data from controller
);

    //JVS game controller interface - generic API
    wire [15:0] jvs_player1_input_switch /* synthesis keep */;
    wire [15:0] jvs_player2_input_switch /* synthesis keep */;
    wire [15:0] jvs_player3_input_switch /* synthesis keep */;
    wire [15:0] jvs_player4_input_switch /* synthesis keep */;
    wire coin1;
    wire coin2;
    wire coin3;
    wire coin4;
    // Analog channels from jvs_ctrl (raw), then with the JVS profile inversions (see below)
    wire [15:0] jvs_analog_raw [8];
    wire [jvs_node_info_pkg::MAX_JVS_NODES*128-1:0] jvs_node_analog_raw;
    wire [15:0] jvs_analog_ch1 /* synthesis keep */;
    wire [15:0] jvs_analog_ch2 /* synthesis keep */;
    wire [15:0] jvs_analog_ch3 /* synthesis keep */;
    wire [15:0] jvs_analog_ch4 /* synthesis keep */;
    wire [15:0] jvs_analog_ch5 /* synthesis keep */;
    wire [15:0] jvs_analog_ch6 /* synthesis keep */;
    wire [15:0] jvs_analog_ch7 /* synthesis keep */;
    wire [15:0] jvs_analog_ch8 /* synthesis keep */;

    logic [23:0] p_output_digital [4];   // per player OUTPUT1 bits {byte 3, 2, 1} (see recoil below)


    wire JVS_UART_TX /* synthesis keep */;

    assign jvs_tx_line  = JVS_UART_TX;
    assign jvs_rx_line  = SNAC_IN4;
    // Logged DIR = level actually driven on the adapter (forced 0 in sniffer mode). The DIR
    // of the sniffed host / board is not visible on the cable: their frames are told
    // apart by destination node (jvs_dump.py)
    assign jvs_dir_line = jvs_sniffer ? 1'b0 : JVS_485_DIR;

    // Value sent with OUTPUT1 (32): OSD test value when set, otherwise gun recoil logic
    // OSD test value (A button) replaces the outputs of every player: the selected node
    // (output_node) receives it whatever its players
    wire        dout_test_on = (dout_test != 16'h0000);
    wire [23:0] p1_dout_to_ctrl = dout_test_on ? {8'h00, dout_test} : p_output_digital[0];
    wire [23:0] p2_dout_to_ctrl = dout_test_on ? {8'h00, dout_test} : p_output_digital[1];
    wire [23:0] p3_dout_to_ctrl = dout_test_on ? {8'h00, dout_test} : p_output_digital[2];
    wire [23:0] p4_dout_to_ctrl = dout_test_on ? {8'h00, dout_test} : p_output_digital[3];
    assign gpio_output_value = p1_dout_to_ctrl[7:0] | p2_dout_to_ctrl[7:0] | p3_dout_to_ctrl[7:0] | p4_dout_to_ctrl[7:0];

    // TX/RX activity: a start bit (falling edge of the idle-high UART line) re-triggers a
    // ~100 ms pulse, like the 74HC123 monostables driving the adapter TX/RX LEDs
    localparam int ACT_PULSE_CYCLES = MASTER_CLK_FREQ / 10;
    logic [$clog2(ACT_PULSE_CYCLES+1)-1:0] tx_act_cnt = '0, rx_act_cnt = '0;
    logic tx_line_d = 1'b1, rx_line_d = 1'b1;
    always @(posedge i_clk) begin
        tx_line_d <= JVS_UART_TX;
        rx_line_d <= SNAC_IN4;
        if (tx_line_d && !JVS_UART_TX)  tx_act_cnt <= ACT_PULSE_CYCLES[$bits(tx_act_cnt)-1:0];
        else if (tx_act_cnt != 0)       tx_act_cnt <= tx_act_cnt - 1'b1;
        if (rx_line_d && !SNAC_IN4)     rx_act_cnt <= ACT_PULSE_CYCLES[$bits(rx_act_cnt)-1:0];
        else if (rx_act_cnt != 0)       rx_act_cnt <= rx_act_cnt - 1'b1;
        jvs_tx_activity <= (tx_act_cnt != 0) && jvs_ena;
        jvs_rx_activity <= (rx_act_cnt != 0) && jvs_ena;
    end
    wire JVS_485_DIR /* synthesis keep */;
    


    // Screen position outputs from JVS controller
    wire [15:0] jvs_screen_pos_x /* synthesis keep */;
    wire [15:0] jvs_screen_pos_y /* synthesis keep */;
    wire jvs_has_screen_pos /* synthesis keep */;

    // JVS SNAC adapter: SENSE is decoded by a window comparator (LM393)
    //  - IN7 (SETUP comparator, open collector): high when SENSE < ~1V  -> all devices addressed
    //  - IO3 (LINK comparator, open collector) : low  when SENSE < ~3.1V -> device present
    // HAS_LINK_DETECT is disabled: tested I/O boards keep SENSE above the LINK
    // threshold until they are reset/addressed, so LINK cannot gate transmission.
    //-------------------------------------------------------------------------
    // JVS vendor init table: 256 bytes, dual clock BRAM (bridge writes in clk_74a, jvs_ctrl
    // reads in i_clk, registered: byte valid 2 cycles after vendor_rd_addr). All zero when
    // jvs_vendor.bin is missing: standard init, no MAINID / vendor frame.
    //-------------------------------------------------------------------------
    (* ramstyle = "M10K" *) logic [31:0] vendor_mem [0:63];
    initial for (int i = 0; i < 64; i++) vendor_mem[i] = 32'h0;
    always @(posedge clk_74a) if (vendor_wr) vendor_mem[vendor_wr_addr] <= vendor_wr_data;
    wire  [7:0]  vendor_rd_addr;
    logic [31:0] vendor_rd_word;
    logic [1:0]  vendor_rd_lane;
    always @(posedge i_clk) begin
        vendor_rd_word <= vendor_mem[vendor_rd_addr[7:2]];
        vendor_rd_lane <= vendor_rd_addr[1:0];
    end
    wire  [7:0]  vendor_rd_data = vendor_rd_word[8*(3 - vendor_rd_lane) +: 8];

    // JVS profile, fixed block at the end of the table (see jvs_vendor.py):
    //   0xE0..0xE7 reserved
    //   0xE8..0xEF recoil trigger mask of P1..P4, 2 bytes each in JVS order (SWINP player
    //              bytes 1 and 2, e.g. 08 00 = switch LEFT): any masked switch pressed
    //   0xF0       flags (bit 0 = valid)
    //   0xF1..0xF3 OUTPUT1 base bytes 1..3
    //   0xF4, 0xF7, 0xFA, 0xFD: recoil mask of P1..P4 (OUTPUT1 bits set during the pulse)
    // No profile: OUTPUT1 = 00 00 00, no recoil.
    // Captured while the bridge writes the table (words 0x38..0x3F), held in registers.
    logic [31:0] dout_words_74 [8] = '{default: 32'h0};
    always @(posedge clk_74a)
        if (vendor_wr && vendor_wr_addr[5:3] == 3'b111) dout_words_74[vendor_wr_addr[2:0]] <= vendor_wr_data;
    // static once loaded (the JVS controller is held in reset while the table is written)
    logic [7:0] dout_prof [32];              // bytes 0xE0..0xFF
    always @(posedge i_clk) begin
        for (int b = 0; b < 32; b++) dout_prof[b] <= dout_words_74[b / 4][8 * (3 - b % 4) +: 8];
    end
    wire        dout_profile_valid = dout_prof[16][0];                       // 0xF0 bit 0
    wire [23:0] dout_base = {dout_prof[19], dout_prof[18], dout_prof[17]};   // OUTPUT1 bytes {3, 2, 1}
    wire [23:0] dout_recoil_mask [4];                                           // per player
    assign dout_recoil_mask[0] = {dout_prof[22], dout_prof[21], dout_prof[20]};  // P1 0xF4..0xF6
    assign dout_recoil_mask[1] = {dout_prof[25], dout_prof[24], dout_prof[23]};  // P2 0xF7..0xF9
    assign dout_recoil_mask[2] = {dout_prof[28], dout_prof[27], dout_prof[26]};  // P3 0xFA..0xFC
    assign dout_recoil_mask[3] = {dout_prof[31], dout_prof[30], dout_prof[29]};  // P4 0xFD..0xFF
    // Player analog axes: 0xD8..0xDF = P1 X, P1 Y, P2 X, P2 Y ... P4 Y, one byte each:
    // bit 7 = defined, bits 6..4 = node - 1, bit 3 = inverted (value -> ~value, e.g. the
    // Time Crisis 4 gun X axis), bits 2..0 = channel (CH0..CH7 of the node).
    // A defined axis drives pN_joy_state and the player gun position; undefined axes keep
    // the default mapping (single player / channel pairs, see the GC_JVS case below).
    logic [31:0] axis_words_74 [2] = '{default: 32'h0};
    always @(posedge clk_74a)
        if (vendor_wr && (vendor_wr_addr == 6'h36 || vendor_wr_addr == 6'h37)) axis_words_74[vendor_wr_addr[0]] <= vendor_wr_data;
    logic [7:0] axis_prof [8];
    always @(posedge i_clk) begin
        for (int b = 0; b < 8; b++) axis_prof[b] <= axis_words_74[b / 4][8 * (3 - b % 4) +: 8];
    end
    logic [7:0]  axis_defined;                // [2p] = player p X, [2p+1] = player p Y
    logic [15:0] axis_value [8];
    always_comb begin : player_axes_comb
        logic [6:0] idx;
        for (int a = 0; a < 8; a++) begin
            idx = {axis_prof[a][6:4], axis_prof[a][2:0]};          // node * 8 + channel
            axis_defined[a] = axis_prof[a][7] && (axis_prof[a][6:4] < jvs_node_info_pkg::MAX_JVS_NODES);
            axis_value[a]   = !axis_defined[a] ? 16'h8000 :
                              axis_prof[a][3] ? ~jvs_node_analog_raw[idx*16 +: 16] : jvs_node_analog_raw[idx*16 +: 16];
        end
    end

    // Analog channels used as they come (inversions are per player axis, see above)
    assign jvs_node_analog = jvs_node_analog_raw;
    assign jvs_analog_ch1 = jvs_analog_raw[0];
    assign jvs_analog_ch2 = jvs_analog_raw[1];
    assign jvs_analog_ch3 = jvs_analog_raw[2];
    assign jvs_analog_ch4 = jvs_analog_raw[3];
    assign jvs_analog_ch5 = jvs_analog_raw[4];
    assign jvs_analog_ch6 = jvs_analog_raw[5];
    assign jvs_analog_ch7 = jvs_analog_raw[6];
    assign jvs_analog_ch8 = jvs_analog_raw[7];

    wire [15:0] recoil_trigger_mask [4];                                        // {byte 1, byte 2}
    assign recoil_trigger_mask[0] = {dout_prof[8],  dout_prof[9]};               // P1 0xE8..0xE9
    assign recoil_trigger_mask[1] = {dout_prof[10], dout_prof[11]};              // P2 0xEA..0xEB
    assign recoil_trigger_mask[2] = {dout_prof[12], dout_prof[13]};              // P3 0xEC..0xED
    assign recoil_trigger_mask[3] = {dout_prof[14], dout_prof[15]};              // P4 0xEE..0xEF

    // Table (re)loaded from the Pocket menu while running (user reloadable data slot): hold
    // the controller in reset during the transfer and 10 ms after the last word, so that
    // the JVS init restarts and the new table is applied right away
    localparam int VENDOR_LOAD_HOLD = 742_500;               // 10 ms at 74.25 MHz (clk_74a)
    logic [$clog2(VENDOR_LOAD_HOLD+1)-1:0] vendor_load_cnt = '0;
    logic vendor_loading_74 = 1'b0;
    always @(posedge clk_74a) begin
        if (vendor_wr)                  vendor_load_cnt <= VENDOR_LOAD_HOLD[$bits(vendor_load_cnt)-1:0];
        else if (vendor_load_cnt != 0)  vendor_load_cnt <= vendor_load_cnt - 1'b1;
        vendor_loading_74 <= vendor_wr || (vendor_load_cnt != 0);
    end
    logic [1:0] vendor_loading_s = 2'b00;                     // to i_clk
    always @(posedge i_clk) vendor_loading_s <= {vendor_loading_s[0], vendor_loading_74};

    jvs_ctrl #(
        .MASTER_CLK_FREQ(MASTER_CLK_FREQ),
        .HAS_LINK_DETECT(0)
    ) jvs_inst (
        .i_clk(i_clk),
        // Sniffer: controller and jvs_com held in reset (the bus logger decodes the lines by
        // itself); leaving the sniffer restarts the controller from a clean power-up state
        // (and while a new vendor init table is being loaded: init restarts with it)
        .i_rst(reset_on_change || jvs_sniffer || vendor_loading_s[1]),
        .i_ena(jvs_ena),
        .i_stb(stb_clk),

        .i_uart_rx(SNAC_IN4),
        .o_uart_tx(JVS_UART_TX),
        .i_sense(SNAC_IN7),     // JVS SENSE addressed (SETUP comparator output)
        .i_link(~SNAC_IO3_A),   // LINK comparator output is active low
        .o_rx485_dir(JVS_485_DIR),
        .o_bus_state(jvs_bus_state),

        .player1_input_switch(jvs_player1_input_switch),
        .player2_input_switch(jvs_player2_input_switch),
        .player3_input_switch(jvs_player3_input_switch),
        .player4_input_switch(jvs_player4_input_switch),
        .analog_ch1(jvs_analog_raw[0]),
        .analog_ch2(jvs_analog_raw[1]),
        .analog_ch3(jvs_analog_raw[2]),
        .analog_ch4(jvs_analog_raw[3]),
        .analog_ch5(jvs_analog_raw[4]),
        .analog_ch6(jvs_analog_raw[5]),
        .analog_ch7(jvs_analog_raw[6]),
        .analog_ch8(jvs_analog_raw[7]),
        .node_analog(jvs_node_analog_raw),

        // Digital output channels
        .p1_output_digital(p1_dout_to_ctrl),
        .p2_output_digital(p2_dout_to_ctrl),
        .p3_output_digital(p3_dout_to_ctrl),
        .p4_output_digital(p4_dout_to_ctrl),
        .output_analog({8{aout_test}}),
        // OUTPUT1 / ANLOUT: OSD output tests (A / X) go to the selected node only (address =
        // index + 1); otherwise every node receives the outputs of its own players (recoil)
        .output_node((dout_test_on || aout_test != 16'h0000) ? ({4'd0, output_node_sel} + 8'd1) : 8'd0),

        // Screen position outputs (light gun/touch screen)
        .screen_pos_x(jvs_screen_pos_x),
        .screen_pos_y(jvs_screen_pos_y),
        .has_screen_pos(jvs_has_screen_pos),

        // Coin counter outputs - not used in current SNAC implementation
        .coin_count(),  // 4-element array, left unconnected
        .coin1(coin1),       // Not connected
        .coin2(coin2),       // Not connected
        .coin3(coin3),       // Not connected
        .coin4(coin4),       // Not connected
        .coin_status(jvs_coin_status),

        //JVS node info
        .jvs_data_ready(jvs_data_ready),
        .jvs_nodes(jvs_nodes),
        .node_name_rd_data(node_name_rd_data),
        .node_name_rd_addr(node_name_rd_addr),
        // Vendor init table (MAINID / vendor frames sent after the feature check)
        .vendor_rd_addr(vendor_rd_addr),
        .vendor_rd_data(vendor_rd_data)
    );

    always @(*) begin
        p1_joy_state = 32'h80808080; //analog stick neutral position value
        p2_joy_state = 32'h80808080; //analog stick neutral position value
        p3_joy_state = 32'h80808080; //analog stick neutral position value
        p4_joy_state = 32'h80808080; //analog stick neutral position value

        case(game_cont_type)
        // GC_DISABLED: begin
        //     SNAC_OUT1 = 1'b0;
        //     SNAC_OUT2 = 1'b0;
        //     p1_btn_state = 16'h0; 
        //     p2_btn_state = 16'h0;
        //     p3_btn_state = 16'h0; 
        //     p4_btn_state = 16'h0;
        // end
        GC_DB15, GC_DB15_FAST, GC_SNES, GC_SNES_SWAP: begin
            SNAC_OUT1 = SERLAT_SNAC_OUT1;
            SNAC_OUT2 = SERLAT_SNAC_OUT2;            
            p1_btn_state = sl_p1;
            p2_btn_state = sl_p2;
            p3_btn_state = 16'h0; 
            p4_btn_state = 16'h0;

        end
        //added special case for NES Zapper
        GC_NES: begin
            SNAC_OUT1 = SERLAT_SNAC_OUT1;
            SNAC_OUT2 = SERLAT_SNAC_OUT2;            
            p1_btn_state = sl_p1; //{sl_p1[15:8], ~i_D4_r[1], ~i_D3_r[1], sl_p1[5:0]};  //insert D4 and D3 at 7 and 6 bit positions (X,Y buttons)                            
            p2_btn_state = {sl_p2[15:8], ~i_D4_r[1], ~i_D3_r[1], sl_p2[5:0]};
            p3_btn_state = 16'h0; 
            p4_btn_state = 16'h0;

        end
        GC_PCE_2BTN, GC_PCE_6BTN: begin
            SNAC_OUT1 = PCE_SNAC_OUT1;
            SNAC_OUT2 = PCE_SNAC_OUT2;
            p1_btn_state = pce_p1; 
            p2_btn_state = 16'h0;
            p3_btn_state = 16'h0; 
            p4_btn_state = 16'h0;
        end
        GC_PCE_MULTITAP: begin
            SNAC_OUT1 = PCE_MULTITAP_SNAC_OUT1;
            SNAC_OUT2 = PCE_MULTITAP_SNAC_OUT2;
            p1_btn_state = pce_multitap_p1; 
            p2_btn_state = pce_multitap_p2;
            p3_btn_state = pce_multitap_p3; 
            p4_btn_state = pce_multitap_p4;
        end
        GC_PSX, GC_PSX_ANALOG, GC_PSX_FAST, GC_PSX_ANALOG_FAST: begin
            SNAC_OUT1 = PSX_SNAC_OUT1;
            SNAC_OUT2 = PSX_SNAC_OUT2;
            p1_btn_state = psx_key1; 
            p1_joy_state = psx_joy1;
            p2_btn_state = psx_key2; 
            p2_joy_state = psx_joy2;
            p3_btn_state = 16'h0;
            p4_btn_state = 16'h0;
        end
        GC_JVS: begin
            SNAC_OUT1 = jvs_sniffer ? 1'b1 : JVS_UART_TX;   // sniffer: TX idle
            SNAC_OUT2 = jvs_sniffer ? 1'b0 : JVS_485_DIR;   // sniffer: RS485 driver disabled
            // Map coin inputs to SELECT button (bit 14) for each player
            p1_btn_state = {jvs_player1_input_switch[15], coin1, jvs_player1_input_switch[13:0]};
            p2_btn_state = {jvs_player2_input_switch[15], coin2, jvs_player2_input_switch[13:0]};
            p3_btn_state = {jvs_player3_input_switch[15], coin3, jvs_player3_input_switch[13:0]};
            p4_btn_state = {jvs_player4_input_switch[15], coin4, jvs_player4_input_switch[13:0]};

            // Special analog mapping logic based on number of players
            if (jvs_nodes.node_players[0] == 1) begin
                // Single player mode (Time Crisis style)
                // Channel 1&2: P1 joystick with inverted X and direct Y
                p1_joy_state = {jvs_analog_ch1, jvs_analog_ch2}; // inversions: JVS profile player axes
                p2_joy_state = 32'h80808080; // Neutral position
                p3_joy_state = 32'h80808080; // Neutral position
                p4_joy_state = 32'h80808080; // Neutral position

                // Channel 3&4: Screen position for light gun
                snac_gun_x = (jvs_analog_ch3 * 320) >> 16; // Screen X from channel 3
                snac_gun_y = (jvs_analog_ch4 * 240) >> 16; // Screen Y from channel 4
                snac_gun_trigger = jvs_player1_input_switch[2]; // Trigger from button
            end else begin
                // Multi-player mode (standard mapping)
                // Standard mapping: Ch1&2 for P1, Ch3&4 for P2, Ch5&6 for P3, Ch7&8 for P4
                p1_joy_state = {jvs_analog_ch2, jvs_analog_ch1}; // P1: Y,X
                p2_joy_state = {jvs_analog_ch4, jvs_analog_ch3}; // P2: Y,X
                p3_joy_state = {jvs_analog_ch6, jvs_analog_ch5}; // P3: Y,X
                p4_joy_state = {jvs_analog_ch8, jvs_analog_ch7}; // P4: Y,X

                // Gun coordinates from P1 joystick
                snac_gun_x = (jvs_analog_ch1 * 320) >> 16;
                snac_gun_y = (jvs_analog_ch2 * 240) >> 16;
                snac_gun_trigger = jvs_player1_input_switch[2];
            end
            // JVS profile player axes (node / channel) replace the default mapping
            if (axis_defined[0] || axis_defined[1]) begin
                p1_joy_state = {axis_value[1], axis_value[0]};          // P1: Y,X
                snac_gun_x = (axis_value[0] * 320) >> 16;
                snac_gun_y = (axis_value[1] * 240) >> 16;
            end
            if (axis_defined[2] || axis_defined[3]) p2_joy_state = {axis_value[3], axis_value[2]};
            if (axis_defined[4] || axis_defined[5]) p3_joy_state = {axis_value[5], axis_value[4]};
            if (axis_defined[6] || axis_defined[7]) p4_joy_state = {axis_value[7], axis_value[6]};
        end
        default: begin
            SNAC_OUT1 = 1'b0;
            SNAC_OUT2 = 1'b0;
            p1_btn_state = 16'h0; 
            p2_btn_state = 16'h0;
            p3_btn_state = 16'h0; 
            p4_btn_state = 16'h0;
            
            // Initialize SNAC gun outputs
            snac_gun_trigger = 1'b0;
            snac_gun_x = 12'd159;
            snac_gun_y = 12'd119;
        end
        endcase
    end

    // Gun triggers and recoil outputs of each player. Trigger = any switch of the player
    // trigger mask pressed (e.g. LEFT on Time Crisis 4). Output of player N = base value of the
    // digital output profile, with its recoil mask bits while pN_recoil is high; jvs_ctrl sends
    // each node the OR of its players outputs. Without profile everything stays 0 (no recoil:
    // the output wiring is cabinet specific)
    // player switches back in JVS order (SWINP bytes 1, 2), see RX_PARSE_SWINP in jvs_ctrl
    function automatic [15:0] jvs_order(input [15:0] sw);
        jvs_order = {sw[15], sw[14], sw[0], sw[1], sw[2], sw[3], sw[4], sw[5],
                     sw[6], sw[7], sw[8], sw[9], sw[10], sw[11], sw[12], sw[13]};
    endfunction
    assign p_gun_defined = {|recoil_trigger_mask[3], |recoil_trigger_mask[2], |recoil_trigger_mask[1], |recoil_trigger_mask[0]};
    // P2..P4 gun positions: JVS profile player axes, or the channel pairs CH3/4, CH5/6, CH7/8
    wire [15:0] p2_ax = (axis_defined[2] || axis_defined[3]) ? axis_value[2] : jvs_analog_ch3;
    wire [15:0] p2_ay = (axis_defined[2] || axis_defined[3]) ? axis_value[3] : jvs_analog_ch4;
    wire [15:0] p3_ax = (axis_defined[4] || axis_defined[5]) ? axis_value[4] : jvs_analog_ch5;
    wire [15:0] p3_ay = (axis_defined[4] || axis_defined[5]) ? axis_value[5] : jvs_analog_ch6;
    wire [15:0] p4_ax = (axis_defined[6] || axis_defined[7]) ? axis_value[6] : jvs_analog_ch7;
    wire [15:0] p4_ay = (axis_defined[6] || axis_defined[7]) ? axis_value[7] : jvs_analog_ch8;
    assign p2_gun_x = (p2_ax * 32'd320) >> 16;
    assign p2_gun_y = (p2_ay * 32'd240) >> 16;
    assign p3_gun_x = (p3_ax * 32'd320) >> 16;
    assign p3_gun_y = (p3_ay * 32'd240) >> 16;
    assign p4_gun_x = (p4_ax * 32'd320) >> 16;
    assign p4_gun_y = (p4_ay * 32'd240) >> 16;
    assign p1_trigger = |(jvs_order(jvs_player1_input_switch) & recoil_trigger_mask[0]);
    assign p2_trigger = |(jvs_order(jvs_player2_input_switch) & recoil_trigger_mask[1]);
    assign p3_trigger = |(jvs_order(jvs_player3_input_switch) & recoil_trigger_mask[2]);
    assign p4_trigger = |(jvs_order(jvs_player4_input_switch) & recoil_trigger_mask[3]);
    wire [3:0] p_recoil = {p4_recoil, p3_recoil, p2_recoil, p1_recoil};
    always @(posedge i_clk) begin
        for (int p = 0; p < 4; p++)
            p_output_digital[p] <= !dout_profile_valid ? 24'h000000 :
                                   (dout_base | (p_recoil[p] ? dout_recoil_mask[p] : 24'h000000));
    end
    
endmodule