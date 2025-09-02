# JVS_Debugger core by Javier @RndMnkIII and Sébastien DUPONCHEEL @totalyfury:
<img src="https://github.com/RndMnkIII/JVS_Debugger/blob/main/doc/jvs_logo_hr_2048x1024.png" width="512"  />

This core allows you to test communication with JVS IO devices and display their status. This is a work in progress. It requires a specific JVS SNAC adapter designed by Sébastien DUPONCHEEL connected to the Analogizer SNAC port.

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
