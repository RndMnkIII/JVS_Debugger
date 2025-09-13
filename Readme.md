# JVS_Debugger core by Javier @RndMnkIII and Sébastien DUPONCHEEL @totalyfury:
<img src="https://github.com/RndMnkIII/JVS_Debugger/blob/main/doc/jvs_logo_hr_2048x1024.png" width="512"  />

This core allows you to test communication with JVS IO devices and display their status. This is a work in progress. It requires a specific JVS SNAC adapter designed by Sébastien DUPONCHEEL connected to the Analogizer SNAC port.

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

## Building

The JVS controller implementation is located in the `src/fpga/analogizer/jvs/` submodule. The Quartus project file automatically includes all necessary files from the submodule via the `jvs.qip` file.

## Relevant Pocket menu options: 
* __Enable Analogizer: Off, On__: if you don't enable this option all functionality related to Analogizer will be disabled.

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
| JVS IO                  | A                            |  ⌛    |
