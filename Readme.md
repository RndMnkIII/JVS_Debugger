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
| `Platforms/jvs.json`, `Platforms/_images/jvs.bin` | platform definition (Tools) |
| `Assets/jvs/common/jvs_init.bin` | 128 KB file receiving the bus capture of the init sequence |
| `Assets/jvs/common/jvs_dump.bin` | 128 KB file receiving the bus capture saved with the Start button |
| `Assets/jvs/common/jvs_sniff_init.bin` | 128 KB file receiving the first sniffer capture (from the first E0 seen on the bus) |
| `Assets/jvs/common/jvs_sniff.bin` | 128 KB file receiving the bus capture saved with the Start button in sniffer mode |
| `Assets/jvs/RndMnkIII.JVS_Debugger/jvs_vendor.bin` | default JVS profile, loaded at startup (MAINID of the adapter only, see [JVS profiles](#jvs-profiles)) |
| `Assets/jvs/RndMnkIII.JVS_Debugger/jvs_vendor_empty.bin` | empty JVS profile (standard JVS init, no output) |
| `Assets/jvs/RndMnkIII.JVS_Debugger/jvs_namco_timecrisys4.bin` | JVS profile for Time Crisis 4 (Namco NA-JV) |

The four capture files must exist on the SD card: the core writes into them, it does not create them.

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
| A | Digital output test (nodes with outputs, flag `D`), sent to the selected node only (it replaces the profile outputs while not 0000): each press doubles the value sent with the OUTPUT1 command (0 → 1 → 2 → 4 ... → 8000 → 0) |
| X | Analog output test (nodes with analog outputs), sent to the selected node only while not 0000: each press sends the next value with the ANLOUT command on every channel (0000 → 2000 → 4000 ... → E000 → FFFF → 0000). On NAOMI cabinets channel 1 drives the light on top of the cabinet |
| Start | Save the bus capture to `jvs_dump.bin` (`jvs_sniff.bin` in sniffer mode) |
| Select | Sniffer mode on / off (see below) |
| Y | Gun recoil mode: **SINGLE**, one 50 ms pulse per trigger press, or **AUTO**, 50 ms on / 150 ms off (5 shots per second) while the trigger is held. Shooting the pistol / machine gun icon at the right of the JVS logo with any gun toggles it too. Triggers and recoil outputs come from the [JVS profile](#jvs-profiles) |

### Screen

* **Recoil mode**: pistol (single) or machine gun (automatic) icon at the right of the JVS logo, inside a double border (the zone to shoot), and `RECOIL:SINGLE` / `RECOIL:AUTO`.
* **Gun crosshairs**: one per gun player of the JVS profile (P1 green, P2 cyan, P3 yellow, P4 magenta, red while the trigger is pressed). P1 is also shown for single player and screen position boards.
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

### JVS profiles

Every cabinet wires its I/O board differently, and some boards need host specific frames. A JVS profile (256 byte file) describes it; nothing cabinet specific is built into the core.

* `jvs_vendor.bin` is loaded at startup. Another profile of `Assets/jvs/RndMnkIII.JVS_Debugger/` can be loaded from **Core Settings > JVS Profile**: the JVS init restarts and the new profile is applied right away.
* A missing or empty profile means a standard JVS init, OUTPUT1 at `00 00 00` and **no recoil** (the output wiring is specific to each cabinet).

A profile defines:

* **Init frames** sent to each node after the feature check, 10 ms apart: MAINID (`15 <string> 00`) and vendor specific frames. Example: the Namco NA-JV of Time Crisis 4 only drives its outputs after MAINID `namco ltd.;S246;VerA;JPN` and the Namco command `70 18 50 4C 14 40`.
* **Player analog axes**: which channel of which node gives the X / Y of each player, optionally inverted. They drive the player joystick (`pN_joy_state`) and gun crosshair. Undefined axes keep the default mapping (single player boards, or channel pairs CH1/2, CH3/4 ... of the chained nodes).
* **Gun triggers and recoil**: for each player, the switches that trigger the recoil (any of them pressed) and the OUTPUT1 bits set during its recoil pulse, on top of an OUTPUT1 base value (e.g. lamps). Each node receives in OUTPUT1 the outputs of its own players.

| Offset | Content |
| :----- | :------ |
| `0x00..0x0F` | 2 bytes per node n = 1..8: `2(n-1)` = MAINID pointer, `2(n-1)+1` = vendor frames pointer (`00` = nothing to send) |
| `0x10..0xD7` | data: MAINID strings (`00` terminated), vendor frames `[L][L bytes: command + data]` ... `[00]` |
| `0xD8..0xDF` | player axes P1 X, P1 Y, P2 X ... P4 Y, one byte each: bit 7 = defined, bits 6..4 = node - 1, bit 3 = inverted, bits 2..0 = channel |
| `0xE0..0xE7` | reserved |
| `0xE8..0xEF` | recoil trigger mask of P1..P4, 2 bytes each in JVS order (player switch bytes 1 and 2 of the SWINP answer: `08 00` = LEFT, `02 00` = push 1) |
| `0xF0` | flags: bit 0 = digital output profile valid |
| `0xF1..0xF3` | OUTPUT1 base value, bytes 1..3 |
| `0xF4..0xFF` | recoil mask of P1, P2, P3, P4 (3 bytes each): OUTPUT1 bits set during the player recoil pulse |

Profiles are built with `src/fpga/analogizer/jvs/scripts/jvs_vendor.py` (`--help` for every option):

| Option | Meaning |
| :----- | :------ |
| `--node N` / `--node all` | node the next `--mainid` / `--frame` apply to |
| `--mainid "string"` | MAINID string of the node |
| `--frame "70 18 50 4C 14 40"` | vendor frame of the node (repeatable) |
| `--p1-x 1:2`, `--p1-y 1:3:i` ... `--p4-y` | player axis: node:CH, `:i` = inverted |
| `--dout-base "00 A0 00"` | OUTPUT1 base value |
| `--dout-recoil-mask "80 00 00"`, `--dout-recoil-mask-p2` ... `-p4` | OUTPUT1 bits of the player recoil |
| `--recoil-trigger "08 00"`, `--recoil-trigger-p2` ... `-p4` | player trigger switches (default `08 00` = LEFT for a player with a recoil mask) |

```sh
J=src/fpga/analogizer/jvs/scripts/jvs_vendor.py
# Default profile: MAINID of the adapter to every node
python3 $J --node all --mainid "TFURY.COM; JVS Adapter V1.0" -o jvs_vendor.bin
# Time Crisis 4: Namco init, gun on node 1 CH0 (inverted) / CH1, solenoid on output 1, lamps A0
python3 $J --node 1 --mainid "namco ltd.;S246;VerA;JPN" --frame "70 18 50 4C 14 40" \
        --p1-x 1:0:i --p1-y 1:1 --dout-base "00 A0 00" --dout-recoil-mask "80 00 00" -o jvs_namco_timecrisys4.bin
# Test with two chained SEGA 838-13683B boards: 4 guns, recoil on the LEDs 1 / 2 of each board, push 1 = trigger
python3 $J --node all --mainid "TFURY.COM; JVS Adapter V1.0" --dout-base "00 00 00" \
        --dout-recoil-mask "01 00 00" --dout-recoil-mask-p2 "02 00 00" --dout-recoil-mask-p3 "01 00 00" --dout-recoil-mask-p4 "02 00 00" \
        --recoil-trigger "02 00" --recoil-trigger-p2 "02 00" --recoil-trigger-p3 "02 00" --recoil-trigger-p4 "02 00" \
        --p1-x 1:0 --p1-y 1:1 --p2-x 1:2 --p2-y 1:3 --p3-x 2:0 --p3-y 2:1 --p4-x 2:2 --p4-y 2:3 -o jvs_sega_recoil_test.bin
```

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

🔸 Tested with SEGA 838-13683B I/O boards (single and two chained boards) and the Namco NA-JV of Time Crisis 4 (with its JVS profile), see the `jvs` submodule README for the compatibility list.
