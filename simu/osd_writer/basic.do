onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tb_osd_writer/WIDTH_BITS
add wave -noupdate -radix unsigned /tb_osd_writer/COLS
add wave -noupdate -radix unsigned /tb_osd_writer/ROWS
add wave -noupdate /tb_osd_writer/clk
add wave -noupdate /tb_osd_writer/rst
add wave -noupdate /tb_osd_writer/v_we
add wave -noupdate -color {Dark Orchid} -radix unsigned /tb_osd_writer/v_wr_addr
add wave -noupdate /tb_osd_writer/v_wr_data
add wave -noupdate /tb_osd_writer/dut/disp_we
add wave -noupdate /tb_osd_writer/dut/disp_data
add wave -noupdate /tb_osd_writer/dut/disp_addr
add wave -noupdate /tb_osd_writer/osd_writer_clear_char
add wave -noupdate /tb_osd_writer/osd_writer_clear_en
add wave -noupdate /tb_osd_writer/osd_writer_start_init
add wave -noupdate /tb_osd_writer/osd_writer_value1
add wave -noupdate /tb_osd_writer/osd_writer_value2
add wave -noupdate -divider osd_print_dispatcher
add wave -noupdate /tb_osd_writer/dut/disp_i/dstate
add wave -noupdate /tb_osd_writer/dut/disp_i/wptr
add wave -noupdate /tb_osd_writer/dut/disp_i/WIDTH
add wave -noupdate /tb_osd_writer/dut/disp_i/value
add wave -noupdate /tb_osd_writer/dut/disp_i/udec_we
add wave -noupdate /tb_osd_writer/dut/disp_i/udec_start
add wave -noupdate /tb_osd_writer/dut/disp_i/udec_done
add wave -noupdate /tb_osd_writer/dut/disp_i/udec_data
add wave -noupdate /tb_osd_writer/dut/disp_i/udec_busy
add wave -noupdate /tb_osd_writer/dut/disp_i/udec_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/str_we
add wave -noupdate /tb_osd_writer/dut/disp_i/str_start
add wave -noupdate /tb_osd_writer/dut/disp_i/str_rd_en_i
add wave -noupdate /tb_osd_writer/dut/disp_i/str_rd_en
add wave -noupdate /tb_osd_writer/dut/disp_i/str_rd_data
add wave -noupdate /tb_osd_writer/dut/disp_i/str_rd_addr_i
add wave -noupdate /tb_osd_writer/dut/disp_i/str_rd_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/str_done
add wave -noupdate /tb_osd_writer/dut/disp_i/str_data
add wave -noupdate /tb_osd_writer/dut/disp_i/str_busy
add wave -noupdate /tb_osd_writer/dut/disp_i/str_base_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/STR_ADDR_W
add wave -noupdate /tb_osd_writer/dut/disp_i/str_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/sdec_we
add wave -noupdate /tb_osd_writer/dut/disp_i/sdec_start
add wave -noupdate /tb_osd_writer/dut/disp_i/sdec_done
add wave -noupdate /tb_osd_writer/dut/disp_i/sdec_data
add wave -noupdate /tb_osd_writer/dut/disp_i/sdec_busy
add wave -noupdate /tb_osd_writer/dut/disp_i/sdec_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/rst
add wave -noupdate /tb_osd_writer/dut/disp_i/rptr
add wave -noupdate /tb_osd_writer/dut/disp_i/RD_LATENCY
add wave -noupdate /tb_osd_writer/dut/disp_i/q_value
add wave -noupdate /tb_osd_writer/dut/disp_i/q_type
add wave -noupdate /tb_osd_writer/dut/disp_i/q_str_base
add wave -noupdate /tb_osd_writer/dut/disp_i/q_hex_uc
add wave -noupdate /tb_osd_writer/dut/disp_i/q_hex_pfx
add wave -noupdate /tb_osd_writer/dut/disp_i/q_hex_min
add wave -noupdate /tb_osd_writer/dut/disp_i/q_dec_zpad
add wave -noupdate /tb_osd_writer/dut/disp_i/q_dec_minw
add wave -noupdate /tb_osd_writer/dut/disp_i/q_bin_pfx
add wave -noupdate /tb_osd_writer/dut/disp_i/q_bin_g4
add wave -noupdate /tb_osd_writer/dut/disp_i/q_base_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/mem
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_we
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_uppercase
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_start
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_prefix_0x
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_min_nibbles
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_done
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_data
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_busy
add wave -noupdate /tb_osd_writer/dut/disp_i/hex_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/fifo_level
add wave -noupdate /tb_osd_writer/dut/disp_i/FIFO_DEPTH
add wave -noupdate /tb_osd_writer/dut/disp_i/dstate
add wave -noupdate /tb_osd_writer/dut/disp_i/do_wr
add wave -noupdate /tb_osd_writer/dut/disp_i/do_rd
add wave -noupdate /tb_osd_writer/dut/disp_i/dec_zero_pad
add wave -noupdate /tb_osd_writer/dut/disp_i/dec_min_width
add wave -noupdate /tb_osd_writer/dut/disp_i/count
add wave -noupdate /tb_osd_writer/dut/disp_i/CMDW
add wave -noupdate /tb_osd_writer/dut/disp_i/cmd_valid
add wave -noupdate /tb_osd_writer/dut/disp_i/cmd_type
add wave -noupdate /tb_osd_writer/dut/disp_i/cmd_ready
add wave -noupdate /tb_osd_writer/dut/disp_i/clk
add wave -noupdate /tb_osd_writer/dut/disp_i/char_we
add wave -noupdate /tb_osd_writer/dut/disp_i/char_data
add wave -noupdate /tb_osd_writer/dut/disp_i/char_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/bin_we
add wave -noupdate /tb_osd_writer/dut/disp_i/bin_start
add wave -noupdate /tb_osd_writer/dut/disp_i/bin_prefix_0b
add wave -noupdate /tb_osd_writer/dut/disp_i/bin_group4
add wave -noupdate /tb_osd_writer/dut/disp_i/bin_done
add wave -noupdate /tb_osd_writer/dut/disp_i/bin_data
add wave -noupdate /tb_osd_writer/dut/disp_i/bin_busy
add wave -noupdate /tb_osd_writer/dut/disp_i/bin_addr
add wave -noupdate /tb_osd_writer/dut/disp_i/base_addr
add wave -noupdate {/tb_osd_writer/dut/disp_i/cmd_type[0]}
add wave -noupdate -divider osd_init_fsm_dyn
add wave -noupdate -radix unsigned /tb_osd_writer/dut/init_i/NUM_CMDS_MAX
add wave -noupdate -radix unsigned /tb_osd_writer/dut/init_i/COLS
add wave -noupdate -radix unsigned /tb_osd_writer/dut/init_i/ROWS
add wave -noupdate -radix unsigned /tb_osd_writer/dut/init_i/DEPTH
add wave -noupdate /tb_osd_writer/dut/init_i/clk
add wave -noupdate /tb_osd_writer/dut/init_i/rst
add wave -noupdate /tb_osd_writer/dut/init_i/init_start
add wave -noupdate /tb_osd_writer/dut/init_i/init_busy
add wave -noupdate /tb_osd_writer/dut/init_i/init_done
add wave -noupdate /tb_osd_writer/dut/init_i/clear_enable
add wave -noupdate /tb_osd_writer/dut/init_i/clear_char
add wave -noupdate /tb_osd_writer/dut/init_i/vram_we
add wave -noupdate /tb_osd_writer/dut/init_i/vram_addr
add wave -noupdate /tb_osd_writer/dut/init_i/vram_data
add wave -noupdate /tb_osd_writer/dut/init_i/prog_valid
add wave -noupdate /tb_osd_writer/dut/init_i/prog_ready
add wave -noupdate /tb_osd_writer/dut/init_i/prog_cmd
add wave -noupdate /tb_osd_writer/dut/init_i/prog_last
add wave -noupdate /tb_osd_writer/dut/init_i/be_load_we
add wave -noupdate /tb_osd_writer/dut/init_i/be_load_addr
add wave -noupdate /tb_osd_writer/dut/init_i/be_load_data
add wave -noupdate /tb_osd_writer/dut/init_i/be_seq_count
add wave -noupdate /tb_osd_writer/dut/init_i/be_start
add wave -noupdate /tb_osd_writer/dut/init_i/be_busy
add wave -noupdate /tb_osd_writer/dut/init_i/be_done
add wave -noupdate /tb_osd_writer/dut/init_i/clr_idx
add wave -noupdate /tb_osd_writer/dut/init_i/cmd_count
add wave -noupdate /tb_osd_writer/dut/init_i/state
add wave -noupdate /tb_osd_writer/dut/init_i/seq_count_latched
add wave -noupdate -divider osd_cmd_batch_enqueuer
add wave -noupdate /tb_osd_writer/dut/beq_i/state
add wave -noupdate /tb_osd_writer/dut/beq_i/seq_count
add wave -noupdate /tb_osd_writer/dut/disp_i/cmd_type
add wave -noupdate /tb_osd_writer/dut/beq_i/WIDTH
add wave -noupdate /tb_osd_writer/dut/beq_i/DEPTH
add wave -noupdate /tb_osd_writer/dut/beq_i/clk
add wave -noupdate /tb_osd_writer/dut/beq_i/rst
add wave -noupdate /tb_osd_writer/dut/beq_i/load_we
add wave -noupdate /tb_osd_writer/dut/beq_i/load_addr
add wave -noupdate /tb_osd_writer/dut/beq_i/load_data
add wave -noupdate /tb_osd_writer/dut/beq_i/start
add wave -noupdate /tb_osd_writer/dut/beq_i/busy
add wave -noupdate /tb_osd_writer/dut/beq_i/done
add wave -noupdate /tb_osd_writer/dut/beq_i/cmd_valid
add wave -noupdate /tb_osd_writer/dut/beq_i/cmd_ready
add wave -noupdate /tb_osd_writer/dut/beq_i/cmd_type
add wave -noupdate /tb_osd_writer/dut/beq_i/base_addr
add wave -noupdate /tb_osd_writer/dut/beq_i/value
add wave -noupdate /tb_osd_writer/dut/beq_i/str_base_addr
add wave -noupdate /tb_osd_writer/dut/beq_i/dec_min_width
add wave -noupdate /tb_osd_writer/dut/beq_i/dec_zero_pad
add wave -noupdate /tb_osd_writer/dut/beq_i/hex_prefix_0x
add wave -noupdate /tb_osd_writer/dut/beq_i/hex_uppercase
add wave -noupdate /tb_osd_writer/dut/beq_i/hex_min_nibbles
add wave -noupdate /tb_osd_writer/dut/beq_i/bin_prefix_0b
add wave -noupdate /tb_osd_writer/dut/beq_i/bin_group4
add wave -noupdate /tb_osd_writer/dut/beq_i/ram
add wave -noupdate /tb_osd_writer/dut/beq_i/idx
add wave -noupdate /tb_osd_writer/dut/beq_i/q
add wave -noupdate /tb_osd_writer/dut/beq_i/have_q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 240
configure wave -valuecolwidth 342
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {13041664 ps}
