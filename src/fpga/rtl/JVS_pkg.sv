//@RndMnkIII 19/11/2022
//Based on the work of: Martin Donlon @wickerwaka for MiSTer Irem M72 Core. 2022
//Define where the ROM areas going to be stored and the base address for SDRAM space
`define CPU_OVERCLOCK_HACK
package JVS_pkg;
    typedef enum bit[1:0] {
        VIDEO_57HZ = 2'd0,
        VIDEO_60HZ = 2'd1,
        NO_VIDEO1 = 2'd2,
        NO_VIDEO2 = 2'd3
    } video_timing_t;
endpackage