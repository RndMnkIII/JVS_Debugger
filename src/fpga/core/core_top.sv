//
// User core top-level
//
// Instantiated by the real top-level: apf_top
//
`timescale 1ns/1ps
`default_nettype none
import JVS_pkg::*;
module core_top 
#(
    // Video
    parameter BPP_R          = 8,     //! Bits Per Pixel Red
    parameter BPP_G          = 8,     //! Bits Per Pixel Green
    parameter BPP_B          = 8,     //! Bits Per Pixel Blue
    // Audio
    parameter AUDIO_DW       = 16,    //! Audio Bits
    parameter AUDIO_S        = 1,     //! Signed Audio
    parameter STEREO         = 1,     //! Stereo Output
    parameter AUDIO_MIX      = 0,     //! [0] No Mix | [1] 25% | [2] 50% | [3] 100% (mono)
    parameter MUTE_PAUSE     = 1,     //! Mute Audio on Pause
    // Data I/O - [MPU -> FPGA]
    parameter DIO_MASK       = 4'h0,  //! Upper 4 bits of address
    parameter DIO_AW         = 25,    //! Address Width
    parameter DIO_DW         = 8,     //! Data Width (8 or 16 bits)
    parameter DIO_DELAY      = 12,     //! Number of clock cycles to delay each write output
    parameter DIO_HOLD       = 4     //! Number of clock cycles to hold the ioctl_wr signal high

)
(

    //
    // physical connections
    //

    ///////////////////////////////////////////////////
    // clock inputs 74.25mhz. not phase aligned, so treat these domains as asynchronous

    input wire clk_74a,  // mainclk1
    input wire clk_74b,  // mainclk1 

    ///////////////////////////////////////////////////
    // cartridge interface
    // switches between 3.3v and 5v mechanically
    // output enable for multibit translators controlled by pic32

    // GBA AD[15:8]
    inout  wire [7:0] cart_tran_bank2,
    output wire       cart_tran_bank2_dir,

    // GBA AD[7:0]
    inout  wire [7:0] cart_tran_bank3,
    output wire       cart_tran_bank3_dir,

    // GBA A[23:16]
    inout  wire [7:0] cart_tran_bank1,
    output wire       cart_tran_bank1_dir,

    // GBA [7] PHI#
    // GBA [6] WR#
    // GBA [5] RD#
    // GBA [4] CS1#/CS#
    //     [3:0] unwired
    inout  wire [7:4] cart_tran_bank0,
    output wire       cart_tran_bank0_dir,

    // GBA CS2#/RES#
    inout  wire cart_tran_pin30,
    output wire cart_tran_pin30_dir,
    // when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
    // the goal is that when unconfigured, the FPGA weak pullups won't interfere.
    // thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
    // and general IO drive this pin.
    output wire cart_pin30_pwroff_reset,

    // GBA IRQ/DRQ
    inout  wire cart_tran_pin31,
    output wire cart_tran_pin31_dir,

    // infrared
    input  wire port_ir_rx,
    output wire port_ir_tx,
    output wire port_ir_rx_disable,

    // GBA link port
    inout  wire port_tran_si,
    output wire port_tran_si_dir,
    inout  wire port_tran_so,
    output wire port_tran_so_dir,
    inout  wire port_tran_sck,
    output wire port_tran_sck_dir,
    inout  wire port_tran_sd,
    output wire port_tran_sd_dir,

    ///////////////////////////////////////////////////
    // cellular psram 0 and 1, two chips (64mbit x2 dual die per chip)

    output wire [21:16] cram0_a,
    inout  wire [ 15:0] cram0_dq,
    input  wire         cram0_wait,
    output wire         cram0_clk,
    output wire         cram0_adv_n,
    output wire         cram0_cre,
    output wire         cram0_ce0_n,
    output wire         cram0_ce1_n,
    output wire         cram0_oe_n,
    output wire         cram0_we_n,
    output wire         cram0_ub_n,
    output wire         cram0_lb_n,

    output wire [21:16] cram1_a,
    inout  wire [ 15:0] cram1_dq,
    input  wire         cram1_wait,
    output wire         cram1_clk,
    output wire         cram1_adv_n,
    output wire         cram1_cre,
    output wire         cram1_ce0_n,
    output wire         cram1_ce1_n,
    output wire         cram1_oe_n,
    output wire         cram1_we_n,
    output wire         cram1_ub_n,
    output wire         cram1_lb_n,

    ///////////////////////////////////////////////////
    // sdram, 512mbit 16bit

    output wire [12:0] dram_a,
    output wire [ 1:0] dram_ba,
    inout  wire [15:0] dram_dq,
    output wire [ 1:0] dram_dqm,
    output wire        dram_clk,
    output wire        dram_cke,
    output wire        dram_ras_n,
    output wire        dram_cas_n,
    output wire        dram_we_n,

    ///////////////////////////////////////////////////
    // sram, 1mbit 16bit

    output wire [16:0] sram_a,
    inout  wire [15:0] sram_dq,
    output wire        sram_oe_n,
    output wire        sram_we_n,
    output wire        sram_ub_n,
    output wire        sram_lb_n,

    ///////////////////////////////////////////////////
    // vblank driven by dock for sync in a certain mode

    input wire vblank,

    ///////////////////////////////////////////////////
    // i/o to 6515D breakout usb uart

    output wire dbg_tx,
    input  wire dbg_rx,

    ///////////////////////////////////////////////////
    // i/o pads near jtag connector user can solder to

    output wire user1,
    input  wire user2,

    ///////////////////////////////////////////////////
    // RFU internal i2c bus 

    inout  wire aux_sda,
    output wire aux_scl,

    ///////////////////////////////////////////////////
    // RFU, do not use
    output wire vpll_feed,


    //
    // logical connections
    //

    ///////////////////////////////////////////////////
    // video, audio output to scaler
    output wire [23:0] video_rgb,
    output wire        video_rgb_clock,
    output wire        video_rgb_clock_90,
    output wire        video_de,
    output wire        video_skip,
    output wire        video_vs,
    output wire        video_hs,

    output wire audio_mclk,
    input  wire audio_adc,
    output wire audio_dac,
    output wire audio_lrck,

    ///////////////////////////////////////////////////
    // bridge bus connection
    // synchronous to clk_74a
    output wire        bridge_endian_little,
    input  wire [31:0] bridge_addr,
    input  wire        bridge_rd,
    output reg  [31:0] bridge_rd_data,
    input  wire        bridge_wr,
    input  wire [31:0] bridge_wr_data,

    ///////////////////////////////////////////////////
    // controller data
    // 
    // key bitmap:
    //   [0]    dpad_up
    //   [1]    dpad_down
    //   [2]    dpad_left
    //   [3]    dpad_right
    //   [4]    face_a
    //   [5]    face_b
    //   [6]    face_x
    //   [7]    face_y
    //   [8]    trig_l1
    //   [9]    trig_r1
    //   [10]   trig_l2
    //   [11]   trig_r2
    //   [12]   trig_l3
    //   [13]   trig_r3
    //   [14]   face_select
    //   [15]   face_start
    // joy values - unsigned
    //   [ 7: 0] lstick_x
    //   [15: 8] lstick_y
    //   [23:16] rstick_x
    //   [31:24] rstick_y
    // trigger values - unsigned
    //   [ 7: 0] ltrig
    //   [15: 8] rtrig
    //
    input wire [15:0] cont1_key,
    input wire [15:0] cont2_key,
    input wire [15:0] cont3_key,
    input wire [15:0] cont4_key,
    input wire [31:0] cont1_joy,
    input wire [31:0] cont2_joy,
    input wire [31:0] cont3_joy,
    input wire [31:0] cont4_joy,
    input wire [15:0] cont1_trig,
    input wire [15:0] cont2_trig,
    input wire [15:0] cont3_trig,
    input wire [15:0] cont4_trig

);

  //Analogizer settings
  localparam [7:0] ADDRESS_ANALOGIZER_CONFIG = 8'hF7;

  // not using the IR port, so turn off both the LED, and
  // disable the receive circuit to save power
  assign port_ir_tx              = 0;
  assign port_ir_rx_disable      = 1;

  // bridge endianness
  assign bridge_endian_little    = 0;

  // link port is input only
  assign port_tran_so            = 1'bz;
  assign port_tran_so_dir        = 1'b0;  // SO is output only
  assign port_tran_si            = 1'bz;
  assign port_tran_si_dir        = 1'b0;  // SI is input only
  assign port_tran_sck           = 1'bz;
  assign port_tran_sck_dir       = 1'b0;  // clock direction can change
  assign port_tran_sd            = 1'bz;
  assign port_tran_sd_dir        = 1'b0;  // SD is input and not used

  // tie off the rest of the pins we are not using
  assign cram0_a                 = 'h0;
  assign cram0_dq                = {16{1'bZ}};
  assign cram0_clk               = 0;
  assign cram0_adv_n             = 1;
  assign cram0_cre               = 0;
  assign cram0_ce0_n             = 1;
  assign cram0_ce1_n             = 1;
  assign cram0_oe_n              = 1;
  assign cram0_we_n              = 1;
  assign cram0_ub_n              = 1;
  assign cram0_lb_n              = 1;

  assign cram1_a                 = 'h0;
  assign cram1_dq                = {16{1'bZ}};
  assign cram1_clk               = 0;
  assign cram1_adv_n             = 1;
  assign cram1_cre               = 0;
  assign cram1_ce0_n             = 1;
  assign cram1_ce1_n             = 1;
  assign cram1_oe_n              = 1;
  assign cram1_we_n              = 1;
  assign cram1_ub_n              = 1;
  assign cram1_lb_n              = 1;

  assign dram_a = 'h0;
  assign dram_ba = 'h0;
  assign dram_dq = {16{1'bZ}};
  assign dram_dqm = 'h0;
  assign dram_clk = 'h0;
  assign dram_cke = 'h0;
  assign dram_ras_n = 'h1;
  assign dram_cas_n = 'h1;
  assign dram_we_n = 'h1;

  assign sram_a                  = 'h0;
  assign sram_dq                 = {16{1'bZ}};
  assign sram_oe_n               = 1;
  assign sram_we_n               = 1;
  assign sram_ub_n               = 1;
  assign sram_lb_n               = 1;

  assign dbg_tx                  = 1'bZ;
  assign user1                   = 1'bZ;
  assign aux_scl                 = 1'bZ;
  assign vpll_feed               = 1'bZ;

    //!-------------------------------------------------------------------------
    //! Host/Target Command Handler
    //!-------------------------------------------------------------------------
    wire        reset_n;  // driven by host commands, can be used as core-wide reset
    wire [31:0] cmd_bridge_rd_data;

    // bridge host commands
    // synchronous to clk_74a
    wire        status_boot_done  = pll_core_locked_s; //pll_core_locked_s;
    wire        status_setup_done = pll_core_locked_s; //pll_core_locked_s; // rising edge triggers a target command
    wire        status_running    = reset_n;           // we are running as soon as reset_n goes high

    wire        dataslot_requestread;
    wire [15:0] dataslot_requestread_id;
    wire        dataslot_requestread_ack = 1;
    wire        dataslot_requestread_ok  = 1;

    wire        dataslot_requestwrite;
    wire [15:0] dataslot_requestwrite_id;
    wire [31:0] dataslot_requestwrite_size;
    wire        dataslot_requestwrite_ack = 1;
    wire        dataslot_requestwrite_ok  = 1;

    wire        dataslot_update;
    wire [15:0] dataslot_update_id;
    wire [31:0] dataslot_update_size;

    wire        dataslot_allcomplete;

    wire [31:0] rtc_epoch_seconds;
    wire [31:0] rtc_date_bcd;
    wire [31:0] rtc_time_bcd;
    wire        rtc_valid;

    wire        savestate_supported;
    wire [31:0] savestate_addr;
    wire [31:0] savestate_size;
    wire [31:0] savestate_maxloadsize;

    wire        savestate_start;
    wire        savestate_start_ack;
    wire        savestate_start_busy;
    wire        savestate_start_ok;
    wire        savestate_start_err;

    wire        savestate_load;
    wire        savestate_load_ack;
    wire        savestate_load_busy;
    wire        savestate_load_ok;
    wire        savestate_load_err;

    wire        osnotify_inmenu;
    wire        osnotify_docked;
    wire        osnotify_grayscale;

    // bridge target commands
    // synchronous to clk_74a
    reg         target_dataslot_read;
    reg         target_dataslot_write;
    reg         target_dataslot_getfile;    // require additional param/resp structs to be mapped
    reg         target_dataslot_openfile;   // require additional param/resp structs to be mapped

    wire        target_dataslot_ack;
    wire        target_dataslot_done;
    wire  [2:0] target_dataslot_err;

    reg  [15:0] target_dataslot_id;
    reg  [31:0] target_dataslot_slotoffset;
    reg  [31:0] target_dataslot_bridgeaddr;
    reg  [31:0] target_dataslot_length;

    wire [31:0] target_buffer_param_struct; // to be mapped/implemented when using some Target commands
    wire [31:0] target_buffer_resp_struct;  // to be mapped/implemented when using some Target commands

    // bridge data slot access
    // synchronous to clk_74a
    wire  [9:0] datatable_addr;
    wire        datatable_wren;
    wire [31:0] datatable_data;
    wire [31:0] datatable_q;

    core_bridge_cmd u_pocket_apf_bridge
    (
        .clk                        ( clk_74a                    ),
        .reset_n                    ( reset_n                    ),

        .bridge_endian_little       ( bridge_endian_little       ),
        .bridge_addr                ( bridge_addr                ),
        .bridge_rd                  ( bridge_rd                  ),
        .bridge_rd_data             ( cmd_bridge_rd_data         ),
        .bridge_wr                  ( bridge_wr                  ),
        .bridge_wr_data             ( bridge_wr_data             ),

        .status_boot_done           ( status_boot_done           ),
        .status_setup_done          ( status_setup_done          ),
        .status_running             ( status_running             ),

        .dataslot_requestread       ( dataslot_requestread       ),
        .dataslot_requestread_id    ( dataslot_requestread_id    ),
        .dataslot_requestread_ack   ( dataslot_requestread_ack   ),
        .dataslot_requestread_ok    ( dataslot_requestread_ok    ),

        .dataslot_requestwrite      ( dataslot_requestwrite      ),
        .dataslot_requestwrite_id   ( dataslot_requestwrite_id   ),
        .dataslot_requestwrite_size ( dataslot_requestwrite_size ),
        .dataslot_requestwrite_ack  ( dataslot_requestwrite_ack  ),
        .dataslot_requestwrite_ok   ( dataslot_requestwrite_ok   ),

        .dataslot_update            ( dataslot_update            ),
        .dataslot_update_id         ( dataslot_update_id         ),
        .dataslot_update_size       ( dataslot_update_size       ),

        .dataslot_allcomplete       ( dataslot_allcomplete       ),

        .rtc_epoch_seconds          ( rtc_epoch_seconds          ),
        .rtc_date_bcd               ( rtc_date_bcd               ),
        .rtc_time_bcd               ( rtc_time_bcd               ),
        .rtc_valid                  ( rtc_valid                  ),

        .savestate_supported        ( savestate_supported        ),
        .savestate_addr             ( savestate_addr             ),
        .savestate_size             ( savestate_size             ),
        .savestate_maxloadsize      ( savestate_maxloadsize      ),

        .savestate_start            ( savestate_start            ),
        .savestate_start_ack        ( savestate_start_ack        ),
        .savestate_start_busy       ( savestate_start_busy       ),
        .savestate_start_ok         ( savestate_start_ok         ),
        .savestate_start_err        ( savestate_start_err        ),

        .savestate_load             ( savestate_load             ),
        .savestate_load_ack         ( savestate_load_ack         ),
        .savestate_load_busy        ( savestate_load_busy        ),
        .savestate_load_ok          ( savestate_load_ok          ),
        .savestate_load_err         ( savestate_load_err         ),

        .osnotify_inmenu            ( osnotify_inmenu            ),
        .osnotify_docked            ( osnotify_docked            ),
        .osnotify_grayscale         ( osnotify_grayscale         ),

        .target_dataslot_read       ( target_dataslot_read       ),
        .target_dataslot_write      ( target_dataslot_write      ),
        .target_dataslot_getfile    ( target_dataslot_getfile    ),
        .target_dataslot_openfile   ( target_dataslot_openfile   ),

        .target_dataslot_ack        ( target_dataslot_ack        ),
        .target_dataslot_done       ( target_dataslot_done       ),
        .target_dataslot_err        ( target_dataslot_err        ),

        .target_dataslot_id         ( target_dataslot_id         ),
        .target_dataslot_slotoffset ( target_dataslot_slotoffset ),
        .target_dataslot_bridgeaddr ( target_dataslot_bridgeaddr ),
        .target_dataslot_length     ( target_dataslot_length     ),

        .target_buffer_param_struct ( target_buffer_param_struct ),
        .target_buffer_resp_struct  ( target_buffer_resp_struct  ),

        .datatable_addr             ( datatable_addr             ),
        .datatable_wren             ( datatable_wren             ),
        .datatable_data             ( datatable_data             ),
        .datatable_q                ( datatable_q                )
    );

    //! END OF APF /////////////////////////////////////////////////////////////

    //! ////////////////////////////////////////////////////////////////////////
    //! @ System Modules
    //! ////////////////////////////////////////////////////////////////////////

    //!-------------------------------------------------------------------------
    //! APF Bridge Read Data
    //!-------------------------------------------------------------------------
    wire [31:0] int_bridge_rd_data;

    always_comb begin
        casex(bridge_addr)
            32'hF8xxxxxx:                                begin bridge_rd_data <= cmd_bridge_rd_data;        end // APF Bridge (Reserved)
            32'hF2000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Modifiers (Analogizer Enable option)
            32'hF0000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Reset
            {ADDRESS_ANALOGIZER_CONFIG,24'h0}:           begin bridge_rd_data <= analogizer_bridge_rd_data; end // analogizer.bin configuration file
            //32'hFC000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Inputs
            default:                                     begin bridge_rd_data <= 32'h0;                     end
        endcase
    end

    //!-------------------------------------------------------------------------
    //! Interact: Dip Switches, Modifiers, Filters and Reset
    //!-------------------------------------------------------------------------
    wire        reset_sw;
    wire  [7:0] mod_sw0;

    interact u_pocket_interact
    (
        // Clocks and Reset
        .clk_74a        ( clk_74a            ), // [i]
        .clk_sync       ( clk_sys            ), // [i]
        .reset_n        ( reset_n            ), // [i]
        // Reset Switch
        .reset_sw       ( reset_sw           ), // [o]
        // Modifiers
        .mod_sw0        ( mod_sw0            ), // [o]
        // Pocket Bridge
        .bridge_addr    ( bridge_addr        ), // [i]
        .bridge_wr      ( bridge_wr          ), // [i]
        .bridge_wr_data ( bridge_wr_data     ), // [i]
        .bridge_rd      ( bridge_rd          ), // [i]
        .bridge_rd_data ( int_bridge_rd_data )  // [o]
    );

    //!-------------------------------------------------------------------------
    //! Audio
    //!-------------------------------------------------------------------------

    // audio_mixer #(.DW(AUDIO_DW),.MUTE_PAUSE(MUTE_PAUSE),.STEREO(STEREO)) u_pocket_audio_mixer
    // (
    //     // Clocks and Reset
    //     .clk_74b    ( clk_74b    ),
    //     .clk_sys    ( clk_sys    ),
    //     .reset      ( reset   ),
    //     // Controls
    //     .afilter_sw ( '0 ),
    //     .vol_att    ( 4'd7),
    //     .mix        ( AUDIO_MIX  ),
    //     .pause_core ( '0),
    //     // Audio From Core
    //     .is_signed  ( AUDIO_S    ),
    //     .core_l     ( '0 ),
    //     .core_r     ( '0 ),
    //     // I2S
    //     .audio_mclk ( audio_mclk ),
    //     .audio_lrck ( audio_lrck ),
    //     .audio_dac  ( audio_dac  )
    // );

    assign audio_dac = 0;
    assign audio_lrck = 0;
    assign audio_mclk = 0; 

    //!-------------------------------------------------------------------------
    //! Video (for Pocket Display)
    //!-------------------------------------------------------------------------
    wire             grayscale_en;           // Enable Grayscale Output
    wire       [2:0] video_preset;           // Video Preset Configuration
    wire [BPP_R-1:0] core_r;                 // Video Red
    wire [BPP_G-1:0] core_g;                 // Video Green
    wire [BPP_B-1:0] core_b;                 // Video Blue
    wire             core_hs, core_hb;       // Horizontal Sync/Blank
    wire             core_vs, core_vb;       // Vertical Sync/Blank
    wire             core_ce;                // Pixel Clock Enable (8 MHz)
    wire             interlaced, field;      // Interlaced Video | Even/Odd Field

    synch_3 sync_bwmode(osnotify_grayscale, grayscale_en, clk_vid);

    video_mixer #(
        .RW                       ( BPP_R                    ), // [p]
        .GW                       ( BPP_G                    ), // [p]
        .BW                       ( BPP_B                    ),  // [p]
        .EN_INTERLACED            ( 0                        )
    ) u_pocket_video_mixer (
        // Clocks
        .clk_sys                  ( clk_sys                  ), // [i]
        .clk_vid                  ( clk_vid                  ), // [i]
        .clk_vid_90deg            ( clk_vid_90deg            ), // [i]
        .reset                    ( reset                    ), // [i]
        // DIP Switch for Configuration
        .video_sw                 ( 32'd0                    ), // [i]
        // Display Controls
        .grayscale_en             ( grayscale_en             ), // [i]
        .blackout_en              ( 0                        ), // [i]
        .video_preset             ( 3'd0       ), // [i]
        // Interlaced Video Controls
        .field                    ( 0                        ), // [i]
        .interlaced               ( 0                        ), // [i]
        // Input Video from Core
        .core_r                   ( video_rgb_jvs[23:16]    ), // [i]
        .core_g                   ( video_rgb_jvs[15:8]     ), // [i]
        .core_b                   ( video_rgb_jvs[7:0]      ), // [i]
        .core_hs                  ( HS_out               ), // [i]
        .core_vs                  ( VS_out               ), // [i]
        .core_hb                  ( HB_out              ), // [i]
        .core_vb                  ( VB_out             ), // [i]
        // Output to Display
        .video_rgb                ( video_rgb                ), // [o]
        .video_hs                 ( video_hs                 ), // [o]
        .video_vs                 ( video_vs                 ), // [o]
        .video_de                 ( video_de                 ), // [o]
        .video_skip               ( video_skip               ), // [o]
        .video_rgb_clock          ( video_rgb_clock          ), // [o]
        .video_rgb_clock_90       ( video_rgb_clock_90       )  // [o]
    );

    //!-------------------------------------------------------------------------
    //! Data I/O
    //!-------------------------------------------------------------------------
    wire              ioctl_download;
    wire       [15:0] ioctl_index;
    wire              ioctl_wr;
    wire [DIO_AW-1:0] ioctl_addr;
    wire [DIO_DW-1:0] ioctl_data;

    // data_io #(.MASK(DIO_MASK),.AW(DIO_AW),.DW(DIO_DW),.DELAY(DIO_DELAY),.HOLD(DIO_HOLD)) u_pocket_data_io
    // (
    //     // Clocks and Reset
    //     .clk_74a                  ( clk_74a                  ), // [i]
    //     .clk_memory               ( clk_sys                  ), // [i]
    //     // Pocket Bridge Slots
    //     .dataslot_requestwrite    ( dataslot_requestwrite    ), // [i]
    //     .dataslot_requestwrite_id ( dataslot_requestwrite_id ), // [i]
    //     .dataslot_allcomplete     ( dataslot_allcomplete     ), // [i]
    //     // MPU -> FPGA (MPU Write to FPGA)
    //     // Pocket Bridge
    //     .bridge_endian_little     ( bridge_endian_little     ), // [i]
    //     .bridge_addr              ( bridge_addr              ), // [i]
    //     .bridge_wr                ( bridge_wr                ), // [i]
    //     .bridge_wr_data           ( bridge_wr_data           ), // [i]
    //     // Controller Interface
    //     .ioctl_download           ( ioctl_download           ), // [o]
    //     .ioctl_index              ( ioctl_index              ), // [o]
    //     .ioctl_wr                 ( ioctl_wr                 ), // [o]
    //     .ioctl_addr               ( ioctl_addr               ), // [o]
    //     .ioctl_data               ( ioctl_data               )  // [o]
    // );  

//! ------------------------------------------------------------------------
    //! Clocks
    //! ------------------------------------------------------------------------
    wire pll_core_locked, pll_core_locked_s;
    wire clk_sys;       //! Core :  48.000Mhz
    wire clk_vid;       //! Video:   6.000Mhz
    wire clk_vid_90deg; //! Video:   6.000Mhz @ 90deg Phase Shift
    wire clk_ram;       //! SDRAM: 96.000Mhz

    pll_master core_pll
    (
        .refclk   ( clk_74a         ),
        .rst      ( 0               ),

        .outclk_0 ( clk_ram         ),
        .outclk_1 ( clk_sys         ),
        .outclk_2 ( clk_vid         ),
        .outclk_3 ( clk_vid_90deg   ),
        .locked   ( pll_core_locked )
    );

    wire reset = reset_sw;

    // Synchronize pll_core_locked into clk_74a domain before usage
    synch_3 sync_lck2(pll_core_locked, pll_core_locked_s, clk_sys);

//Video gen
logic hblank_core, vblank_core;
logic hsync_core, vsync_core;
logic ce_pixel_core;

video_sync_gen_320x240_6mhz_pixclk_en vidsync(
  .clk48(clk_sys), 
  .rst(reset),
  .pixel_clock_en(ce_pixel_core),
  .xpos(),
  .ypos(),
  .hblank(hblank_core), 
  .vblank(vblank_core), 
  .hsync(hsync_core), 
  .vsync(vsync_core)
);

/*[ANALOGIZER_HOOK_BEGIN]*/
    //reg analogizer_ena;
    wire [3:0] analogizer_video_type;
    wire [4:0] snac_game_cont_type;
    wire [3:0] snac_cont_assignment;
    wire       pocket_blank_screen;

    wire analogizer_ena = mod_sw0[0]; //setting from Pocket Menu

    //create aditional switch to blank Pocket screen.
    wire [23:0] video_rgb_jvs;
    assign video_rgb_jvs = (pocket_blank_screen && analogizer_ena) ? 24'h000000: {RGB_out_R,RGB_out_G,RGB_out_B};
    //assign video_rgb_jvs = (pocket_blank_screen && analogizer_ena) ? 24'h000000: {video_r_core,video_g_core,video_b_core};

    //switch between Analogizer SNAC and Pocket Controls for P1-P4 (P3,P4 when uses PCEngine Multitap)
    wire [15:0] p1_btn, p2_btn, p3_btn, p4_btn;
    wire [31:0] p1_joy, p2_joy;
    reg [31:0] p1_joystick, p2_joystick;
    reg  [15:0] p1_controls, p2_controls;

    wire snac_is_analog = (snac_game_cont_type == 5'h12) || (snac_game_cont_type == 5'h13);

    //! Player 1 ---------------------------------------------------------------------------
    reg p1_up, p1_down, p1_left, p1_right;
    wire p1_up_analog, p1_down_analog, p1_left_analog, p1_right_analog;
    //using left analog joypad
    assign p1_up_analog    = (p1_joy[15:8] < 8'h40) ? 1'b1 : 1'b0; //analog range UP 0x00 Idle 0x7F DOWN 0xFF, DEADZONE +- 0x15
    assign p1_down_analog  = (p1_joy[15:8] > 8'hC0) ? 1'b1 : 1'b0; 
    assign p1_left_analog  = (p1_joy[7:0]  < 8'h40) ? 1'b1 : 1'b0; //analog range LEFT 0x00 Idle 0x7F RIGHT 0xFF, DEADZONE +- 0x15
    assign p1_right_analog = (p1_joy[7:0]  > 8'hC0) ? 1'b1 : 1'b0;

    always @(posedge clk_74a) begin
        p1_up    <= (snac_is_analog) ? p1_up_analog    : p1_btn[0];
        p1_down  <= (snac_is_analog) ? p1_down_analog  : p1_btn[1];
        p1_left  <= (snac_is_analog) ? p1_left_analog  : p1_btn[2];
        p1_right <= (snac_is_analog) ? p1_right_analog : p1_btn[3];
    end
    //! Player 2 ---------------------------------------------------------------------------
    reg p2_up, p2_down, p2_left, p2_right;
    wire p2_up_analog, p2_down_analog, p2_left_analog, p2_right_analog;
    //using left analog joypad
    assign p2_up_analog    = (p2_joy[15:8] < 8'h40) ? 1'b1 : 1'b0; //analog range UP 0x00 Idle 0x7F DOWN 0xFF, DEADZONE +- 0x15
    assign p2_down_analog  = (p2_joy[15:8] > 8'hC0) ? 1'b1 : 1'b0; 
    assign p2_left_analog  = (p2_joy[7:0]  < 8'h40) ? 1'b1 : 1'b0; //analog range LEFT 0x00 Idle 0x7F RIGHT 0xFF, DEADZONE +- 0x15
    assign p2_right_analog = (p2_joy[7:0]  > 8'hC0) ? 1'b1 : 1'b0;

    always @(posedge clk_74a) begin
        p2_up    <= (snac_is_analog) ? p2_up_analog    : p2_btn[0];
        p2_down  <= (snac_is_analog) ? p2_down_analog  : p2_btn[1];
        p2_left  <= (snac_is_analog) ? p2_left_analog  : p2_btn[2];
        p2_right <= (snac_is_analog) ? p2_right_analog : p2_btn[3];
    end
    always @(posedge clk_74a) begin
        reg [31:0] p1_pocket_btn, p1_pocket_joy;
        reg [31:0] p2_pocket_btn, p2_pocket_joy;

        if((snac_game_cont_type == 5'h0) || !analogizer_ena) begin //SNAC is disabled
        //if((snac_game_cont_type == 5'h0)) begin //SNAC is disabled
            p1_controls <= cont1_key;
            p2_controls <= cont2_key;
        end
        else begin
        case(snac_cont_assignment[1:0])
        2'h0:    begin  //SNAC P1 -> Pocket P1
            p1_controls <= {p1_btn[15:4],p1_right,p1_left,p1_down,p1_up};
            p2_controls <= cont1_key;
            end
        2'h1: begin  //SNAC P1 -> Pocket P2
            p1_controls <= cont1_key;
            p2_controls <= p1_btn;
            end
        2'h2: begin //SNAC P1 -> Pocket P1, SNAC P2 -> Pocket P2
            p1_controls <= {p1_btn[15:4],p1_right,p1_left,p1_down,p1_up};
            p2_controls <= {p2_btn[15:4],p2_right,p2_left,p2_down,p2_up};
            end
        2'h3: begin //SNAC P1 -> Pocket P2, SNAC P2 -> Pocket P1
            p1_controls <= {p2_btn[15:4],p2_right,p2_left,p2_down,p2_up};
            p2_controls <= {p1_btn[15:4],p1_right,p1_left,p1_down,p1_up};
            end
        default: begin 
            p1_controls <= cont1_key;
            p2_controls <= cont2_key;
            end
        endcase
        end
    end

    wire [15:0] p1_btn_CK, p2_btn_CK;
    wire [31:0] p1_joy_CK, p2_joy_CK;
    synch_3 #(
    .WIDTH(16)
    ) p1b_s (
        p1_btn_CK,
        p1_btn,
        clk_74a
    );

    synch_3 #(
        .WIDTH(16)
    ) p2b_s (
        p2_btn_CK,
        p2_btn,
        clk_74a
    );

    synch_3 #(
    .WIDTH(32)
    ) p3b_s (
        p1_joy_CK,
        p1_joy,
        clk_74a
    );
        
    synch_3 #(
        .WIDTH(32)
    ) p4b_s (
        p2_joy_CK,
        p2_joy,
        clk_74a
    );


    // Video Y/C Encoder settings
    // Follows the Mike Simone Y/C encoder settings:
    // https://github.com/MikeS11/MiSTerFPGA_YC_Encoder
    // SET PAL and NTSC TIMING and pass through status bits. ** YC must be enabled in the qsf file **
    wire [39:0] CHROMA_PHASE_INC;
    wire [26:0] COLORBURST_RANGE;

    wire PALFLAG;

    parameter NTSC_REF = 3.579545;   
    parameter PAL_REF = 4.43361875;

    // Parameters to be modifed
    parameter CLK_VIDEO_NTSC = 48.0; // Must be filled E.g XX.X Hz - CLK_VIDEO
    parameter CLK_VIDEO_PAL  = 48.0; // Must be filled E.g XX.X Hz - CLK_VIDEO


    //PAL CLOCK FREQUENCY SHOULD BE 42.56274
    localparam [39:0] NTSC_PHASE_INC1 = 40'd81994819784; // ((NTSC_REF * 2^40) / CLK_VIDEO_NTSC)
    localparam [39:0] PAL_PHASE_INC1  = 40'd101558653516; // ((PAL_REF * 2^40) / CLK_VIDEO_PAL)


	localparam [6:0] COLORBURST_START1 = (3.7 * (CLK_VIDEO_NTSC/NTSC_REF));
	localparam [9:0] COLORBURST_NTSC_END1 = (9 * (CLK_VIDEO_NTSC/NTSC_REF)) + COLORBURST_START1;
	localparam [9:0] COLORBURST_PAL_END1 = (10 * (CLK_VIDEO_PAL/PAL_REF)) + COLORBURST_START1;

    always @(posedge clk_sys) begin
        CHROMA_PHASE_INC <= PALFLAG ? PAL_PHASE_INC1 : NTSC_PHASE_INC1; 
        COLORBURST_RANGE <= {COLORBURST_START1, COLORBURST_NTSC_END1, COLORBURST_PAL_END1};
    end

    logic start_r, up_r, down_r, left_r, right_r, btnA_r, p1r1_r, p2r1_r;

    always_ff @(posedge clk_sys) begin 
       start_r <= p1_controls[15];
       up_r    <= p1_controls[0];
       down_r  <= p1_controls[1];
       left_r  <= p1_controls[2];
       right_r <= p1_controls[3]; 
       btnA_r  <= p1_controls[4];
       p1r1_r    <= p1_controls[9]; //R1 button toggles credits
       p2r1_r    <= p2_controls[9]; //R1 button toggles credits

    end

    //Debug OSD: shows Xoffset and Yoffset values and the detected video resolution for Analogizer
    wire [7:0] RGB_out_R, RGB_out_G, RGB_out_B;
    wire HS_out, VS_out, HB_out, VB_out;

   osd_top #(
   .CLK_HZ(48_000_000)
   ) osd_debug_inst (
       .clk(clk_sys),
       .reset(reset),
       .pixel_ce(ce_pixel_core),
       .R_in(8'h00),
       .G_in(8'h00),
       .B_in(8'h00),
       .hsync_in(hsync_core),
       .vsync_in(vsync_core),
       .hblank(hblank_core),
       .vblank(vblank_core),
       .R_out(RGB_out_R),
       .G_out(RGB_out_G),
       .B_out(RGB_out_B),
       .hsync_out(HS_out),
       .vsync_out(VS_out),
       .hblank_out(HB_out),
       .vblank_out(VB_out)
   );

    //32_000_000
    wire [31:0] analogizer_bridge_rd_data;
    wire busy;
    wire VIDEO_DE = ~(hblank_core | vblank_core);
    openFPGA_Pocket_Analogizer #(.MASTER_CLK_FREQ(48_000_000), .LINE_LENGTH(320), .ADDRESS_ANALOGIZER_CONFIG(ADDRESS_ANALOGIZER_CONFIG)) analogizer (
        .clk_74a(clk_74a),
        .i_clk(clk_sys),
        .i_rst_apf(reset), //i_rst_apf is active high
        .i_rst_core(reset), //i_rst_core is active high
        .i_ena(analogizer_ena),

        //Video interface
        .video_clk(clk_sys),
        .R(RGB_out_R),
        .G(RGB_out_G),
        .B(RGB_out_B),
        .Hblank(HB_out),
        .Vblank(VB_out),
        .Hsync(HS_out), //composite SYNC on HSync.
        .Vsync(VS_out),

        //openFPGA Bridge interface
        .bridge_endian_little(bridge_endian_little),
        .bridge_addr(bridge_addr),
        .bridge_rd(bridge_rd),
        .analogizer_bridge_rd_data(analogizer_bridge_rd_data),
        .bridge_wr(bridge_wr),
        .bridge_wr_data(bridge_wr_data),

        //Analogizer settings
        .snac_game_cont_type_out(snac_game_cont_type),
        .snac_cont_assignment_out(snac_cont_assignment),
        .analogizer_video_type_out(analogizer_video_type),
        .SC_fx_out(),
        .pocket_blank_screen_out(pocket_blank_screen),
        .analogizer_osd_out(),

        //Video Y/C Encoder interface
        .CHROMA_PHASE_INC(CHROMA_PHASE_INC),
        .COLORBURST_RANGE(COLORBURST_RANGE),
        .CHROMA_ADD(0),
        .CHROMA_MUL(0),
        .PALFLAG(PALFLAG),

        //Video SVGA Scandoubler interface
        .ce_pix(ce_pixel_core),
        .scandoubler(1'b1), //logic for disable/enable the scandoubler

        //SNAC interface
        .p1_btn_state(p1_btn_CK),
        .p1_joy_state(p1_joy_CK),
        .p2_btn_state(p2_btn_CK),  
        .p2_joy_state(p2_joy_CK),
        .p3_btn_state(),
        .p4_btn_state(),  
        .busy(busy),    
        
        //Pocket Analogizer IO interface to the Pocket cartridge port
        .cart_tran_bank2(cart_tran_bank2),
        .cart_tran_bank2_dir(cart_tran_bank2_dir),
        .cart_tran_bank3(cart_tran_bank3),
        .cart_tran_bank3_dir(cart_tran_bank3_dir),
        .cart_tran_bank1(cart_tran_bank1),
        .cart_tran_bank1_dir(cart_tran_bank1_dir),
        .cart_tran_bank0(cart_tran_bank0),
        .cart_tran_bank0_dir(cart_tran_bank0_dir),
        .cart_tran_pin30(cart_tran_pin30),
        .cart_tran_pin30_dir(cart_tran_pin30_dir),
        .cart_pin30_pwroff_reset(cart_pin30_pwroff_reset),
        .cart_tran_pin31(cart_tran_pin31),
        .cart_tran_pin31_dir(cart_tran_pin31_dir),
        //debug
        .o_stb()
    );
    /*[ANALOGIZER_HOOK_END]*/
endmodule