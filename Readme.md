# JVS_Debugger core by Javier @RndMnkIII and Sébastien DUPONCHEEL @totalyfury:
<img src="https://github.com/RndMnkIII/JVS_Debugger/blob/main/doc/jvs_logo_hr_2048x1024.png" width="512"  />

This core lets you test the communication with JVS I/O boards and display their status. It is a work in progress. It requires the JVS SNAC adapter designed by Sébastien DUPONCHEEL, connected to the Analogizer SNAC port (SNAC controller type: **JVS IO**).

## Installation

This project uses a git submodule for the JVS controller implementation. To properly clone the repository with all its dependencies:

```bash
# Clone the repository with submodules
# http version
git clone --recursive https://github.com/RndMnkIII/JVS_Debugger.git

# ssh version
git clone --recursive git@github.com:RndMnkIII/JVS_Debugger.git

# OR if you already cloned without --recursive:
git submodule update --init --recursive
```

### SD card

Copy the content of `dist/` to the root of the SD card:

| Path | Content |
| :--- | :------ |
| `Cores/RndMnkIII.JVS_Debugger/` | core (`jvs_debug.rbf_r`) and definition files |
| `Assets/jvs/common/jvs_init.bin` | 128 KB file receiving the bus capture of the init sequence |
| `Assets/jvs/common/jvs_dump.bin` | 128 KB file receiving the bus capture saved with the Start button |
| `Assets/jvs/RndMnkIII.JVS_Debugger/jvs_vendor.bin` | 256 byte JVS vendor init table, loaded at startup (default: MAINID of the adapter, see below) |
| `Assets/jvs/RndMnkIII.JVS_Debugger/jvs_namco_timecrisys4.bin` | vendor init table for Time Crisis 4 (Namco NA-JV), to load from the core menu |
| `Assets/jvs/common/jvs_sniff_init.bin` | 128 KB file receiving the first sniffer capture (from the first E0 seen on the bus) |
| `Assets/jvs/common/jvs_sniff.bin` | 128 KB file receiving the bus capture saved with the Start button in sniffer mode |

The two capture files must exist on the SD card: the core writes into them, it does not create them.

## Building

The JVS controller implementation is located in the `src/fpga/analogizer/jvs/` submodule. The Quartus project file automatically includes all necessary files from the submodule via the `jvs.qip` file.

The Pocket bitstream (`jvs_debug.rbf_r`) is `output_files/JVS_Debugger.rbf` with the bits of every byte reversed:
```bash
cd src/fpga/output_files
python3 -c 't=bytes(int(f"{i:08b}"[::-1],2) for i in range(256)); open("jvs_debug.rbf_r","wb").write(open("JVS_Debugger.rbf","rb").read().translate(t))'
```

## Relevant Pocket menu options:
* __Enable Analogizer: Off, On__: if you don't enable this option all functionality related to Analogizer will be disabled.

## JVS debugger

### Pocket controls

| Button | Action |
| :----- | :----- |
| D-pad left / right | Select the displayed JVS node (chained I/O boards) |
| D-pad up / down | Select the displayed analog pair (CH0/CH1, CH2/CH3, ...) |
| A | Digital output test (nodes with outputs, flag `D`), sent to the selected node only: each press doubles the value sent with the OUTPUT1 command (0 → 1 → 2 → 4 ... → 8000 → 0) |
| X | Analog output test (nodes with analog outputs), sent to the selected node only: each press sends the next value with the ANLOUT command on every channel (0000 → 2000 → 4000 ... → E000 → FFFF → 0000). On NAOMI cabinets channel 1 drives the light on top of the cabinet |
| Start | Save the bus capture to `jvs_dump.bin` (`jvs_sniff.bin` in sniffer mode) |
| Select | Sniffer mode on / off (see below) |
| Y | Gun recoil mode (shown as `RECOIL:` and as a pistol / machine gun icon at the right of the JVS logo; shooting the icon with the P1 gun toggles it too): **SINGLE**, one 50 ms pulse per trigger press, or **AUTO**, 50 ms on / 150 ms off (5 shots per second) while the trigger is held. Triggers and recoil outputs come from the JVS profile (see below) |

### Screen

* **Status indicators**: `SETUP`, `LINK` (same meaning as the adapter LEDs), `TX`, `RX` (bus activity), `OUT` (digital output low byte not zero).
* **STATE**: `INITIALIZING` / `ADDR NODE n` (bus reset and addressing), `IDENTIFYING` (identity, revisions, features), `READY` (input polling), `NO ANSWER` (3 consecutive timeouts, the init sequence restarts automatically), `LINK LOST` (board unplugged while polling: polling resumes if it comes back within 3 s, otherwise full re-init), `SNIFFER`.
* **DUMP**: bus capture status (see below).
* **NODE# x/n**, **BRAND**, **MODEL**: selected node and its identity string. `DOUT:xxxx AOUT:xxxx` show the digital and analog output test values.
* **COIN**: coin slots of the selected node, counter (decimal) and condition (`J` jam, `D` disconnected, `B` busy).
* **CMD / JVS / COM VER**, **SWITCH**, **ANALOG**, **Features**: revisions and capabilities of the selected node.
* **Player rows**: players of the selected node, directions, Start, Coin and push buttons 1-10 (grey released, yellow pressed).
* **Analog**: X/Y gauges of the selected pair and an X/Y target with the position decomposition.

### JVS SNAC adapter LEDs

| LED | Lit when |
| :-- | :------- |
| TX / RX | a byte is sent / received (~100 ms pulse). RX may flicker with no board plugged: the RS485 bus is not biased |
| SETUP | the SENSE line reports "not addressed" (also lit when nothing is plugged); off once every board has its address |
| LINK | intended as "board present"; on this adapter it does not follow the SENSE line reliably, do not rely on it |

### Bus captures

The core records both serial lines, the SETUP / LINK lines and the RS485 direction (DIR) with a microsecond timestamp:

1. **`jvs_init.bin`**: the capture starts with the core; when the buffer is full (a few seconds after `READY`) it is saved automatically (`DUMP:SAVED INIT`). It holds the complete init sequence.
2. The capture then keeps the last ~4 seconds of traffic (`DUMP:LAST`). **Start** saves them to **`jvs_dump.bin`** (`DUMP:SAVED DUMP`).

Decode a capture on a PC:
```bash
python3 src/fpga/analogizer/jvs/scripts/jvs_dump.py jvs_dump.bin
```
Every frame is listed with its timestamp and checksum check, plus the measured RS485 timing. A capture can also be replayed in simulation against the controller (see the `jvs` submodule README).

### Sniffer mode

In sniffer mode (**Select**) the controller is off, the RS485 driver of the adapter stays disabled and the whole bus traffic is recorded (`DUMP:SNIF`): plug the adapter **in parallel** on the cable between an arcade host and its I/O board, play, then press **Start** to save the last ~4 seconds to **`jvs_sniff.bin`** (`DUMP:SAVED SNIF`), so the debugger captures in `jvs_dump.bin` are kept.

Like the normal mode, each sniffer session starts with an init capture: the logger waits for the first SYNC byte (`DUMP:WAIT E0`), records from there until the buffer is full (`DUMP:SINI nnnn`) and saves it automatically to **`jvs_sniff_init.bin`** (`DUMP:SAVED SINI`); it then keeps the last seconds (`DUMP:SNIF nnnn`) for the Start button. To capture the init sequence of a host, enable the sniffer before powering the cabinet on. `jvs_dump.py` then shows host requests (`HOST ->`) and board answers (`BOARD <-`), told apart by their destination node: the DIR line of the host and of the board is not visible on the cable, and the logged DIR is the adapter's own, held at 0 (driver disabled) during the whole sniffer capture.

Wiring: connect only **D+ (A), D- (B) and GND**. Do **not** connect the SENSE line (VBUS pin): the adapter pull-up would disturb the addressing between the host and the board. The adapter has a 100 Ω termination between A and B; on a bus already terminated at both ends this lowers the signal level, remove it on the adapter used for sniffing if frames are badly decoded.

### Vendor init (`jvs_vendor.bin`)

Some I/O boards need host specific frames after the standard init. The Namco NA-JV of Time Crisis 4 only drives its outputs (gun recoil solenoid) after the host sends MAINID `namco ltd.;S246;VerA;JPN` and the Namco command `70 18 50 4C 14 40`. Nothing of this is built into the core: the optional `jvs_vendor.bin` (256 bytes, loaded at startup) gives, per node, what to send after the feature check. A missing or empty file means a standard init.

* Header, 2 bytes per node n = 1..8: offset `2(n-1)` = MAINID pointer, `2(n-1)+1` = vendor frames pointer (`00` = nothing to send).
* MAINID entry: `00` terminated string, sent as `15 <string> 00`.
* Vendor entry: frames `[L][L bytes: command + data]`, ended by `00`.
* Digital output profile, fixed block at `0xF0`: flags (bit 0 = valid), then the 3 OUTPUT1 base bytes, then the recoil mask of each player at `0xF4` (P1), `0xF7` (P2), `0xFA` (P3), `0xFD` (P4), 3 bytes each: bits set in OUTPUT1 during the player gun recoil pulse (50 ms on each trigger press). Options `--dout-recoil-mask` (P1) and `--dout-recoil-mask-p2` ... `-p4`.
* Player analog axes at `0xD8` (P1 X, P1 Y, P2 X ... P4 Y), one byte each: bit 7 = defined, bits 6..4 = node - 1, bit 3 = inverted (value → ~value, e.g. the Time Crisis 4 gun X axis), bits 2..0 = channel. A defined axis drives the player joystick (`pN_joy_state`) and gun crosshair; otherwise the default mapping is kept (single player boards, or channel pairs CH1/2, CH3/4 ... of the chained nodes). Options `--p1-x 1:2 --p1-y 1:3` (node:CH, `:i` to invert, e.g. `--p1-x 1:0:i`) ... `--p4-y`.
* Gun crosshairs: one per player with a recoil trigger in the profile (P1 green, P2 cyan, P3 yellow, P4 magenta, red while the trigger is pressed).
* Recoil trigger mask of each player at `0xE8` (P1), `0xEA`, `0xEC`, `0xEE` (P4), 2 bytes each in JVS order (player switch bytes 1 and 2 of the SWINP answer, e.g. `08 00` = LEFT): the pulse starts when any masked switch is pressed. Options `--recoil-trigger` (P1) and `--recoil-trigger-p2` ... `-p4`; default `08 00` (LEFT, Time Crisis 4 wiring) for a player with a recoil mask. Without profile OUTPUT1 stays `00 00 00`: **no recoil by default**, since the output wiring is specific to each cabinet. The **A** button test value still overrides it.

The file is built with `src/fpga/analogizer/jvs/scripts/jvs_vendor.py`:
```sh
# Time Crisis 4 (Namco NA-JV on node 1, recoil solenoid on output 1, lamps A0), shipped as Assets/jvs/RndMnkIII.JVS_Debugger/jvs_namco_timecrisys4.bin
python3 src/fpga/analogizer/jvs/scripts/jvs_vendor.py --node 1 --mainid "namco ltd.;S246;VerA;JPN" \
        --frame "70 18 50 4C 14 40" --p1-x 1:0:i --p1-y 1:1 --dout-base "00 A0 00" --dout-recoil-mask "80 00 00" -o jvs_vendor.bin
```
The default `jvs_vendor.bin` sends MAINID `TFURY.COM; JVS Adapter V1.0` to every node, without vendor frame (`jvs_vendor.py --node all --mainid "TFURY.COM; JVS Adapter V1.0" -o jvs_vendor.bin`). It is loaded at startup. Another table of `Assets/jvs/RndMnkIII.JVS_Debugger/` (e.g. `jvs_namco_timecrisys4.bin`, or `jvs_vendor_empty.bin` for a standard init) can be loaded from **Core Settings > JVS Profile**: the JVS init restarts and the new table is applied right away.

## Analogizer options:

The core can output RGBS, RGsB, YPbPr, Y/C and SVGA scandoubler (50% scanlines) video signals.
| Video output | Status | SOG Switch(Only R2,R3 Analogizer) |
| :----------- | :----: | :-------------------------------: |
| RGBS         |  ✅    |     Off                           |
| RGsB         |  ✅    |     On                            |
| YPbPr        |  ✅🔹  |     On                            |
| Y/C NTSC     |  ✅    |     Off                           |
| Y/C PAL      |  ✅    |     Off                           |
| Scandoubler  |  ✅    |     Off                           |

🔹 Tested with Sony PVM-9044D

| :SNAC game controller:  | Analogizer A/B config Switch | Status |
| :---------------------- | :--------------------------- | :----: |
| DB15                    | A                            |  ✅    |
| NES                     | A                            |  ✅    |
| SNES                    | A                            |  ✅    |
| PCENGINE                | A                            |  ✅    |
| PCE MULTITAP            | A                            |  ✅    |
| PSX DS/DS2 Digital DPAD | B                            |  ✅    |
| PSX DS/DS2 Analog  DPAD | B                            |  ✅    |
| JVS IO                  | A                            |  ✅🔸  |

🔸 Tested with SEGA 838-13683B I/O boards (single and two chained boards), see the `jvs` submodule README for the compatibility list.
