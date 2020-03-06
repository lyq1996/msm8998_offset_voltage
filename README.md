### AROMA
Flash in TWRP

```
#include <std_disclaimer.h>

/*
 * Your warranty is now void.
 *
 * We are not responsible for bricked devices, dead SD cards,
 * thermonuclear war or you getting fired because the alarm app failed. Please
 * do some research if you have any concerns about features included in this ROM
 * before flashing it! YOU are choosing to make these modifications and if
 * you point the finger at us for messing up your device, we will laugh at you. Hard & a lot.
 *
 */
```

### build flashable zip
zip -r9 msm8998-Undervolt-Tools.zip * -x .git README.md .gitignore dtp_src

### result
before undervolt:

```
# 
[    0.440216] [    0.440200]@4 add_opp: Set OPP pair (300000000 Hz, 660000 uv) on cpu0
[    0.440810] [    0.440807]@4 add_opp: Set OPP pair (1900800000 Hz, 908000 uv) on cpu0
[    0.440841] [    0.440839]@4 add_opp: Set OPP pair (300000000 Hz, 660000 uv) on cpu1
[    0.441210] [    0.441208]@4 add_opp: Set OPP pair (1900800000 Hz, 908000 uv) on cpu1
[    0.441235] [    0.441233]@4 add_opp: Set OPP pair (300000000 Hz, 660000 uv) on cpu2
[    0.441607] [    0.441605]@4 add_opp: Set OPP pair (1900800000 Hz, 908000 uv) on cpu2
[    0.441631] [    0.441629]@4 add_opp: Set OPP pair (300000000 Hz, 660000 uv) on cpu3
[    0.441996] [    0.441994]@4 add_opp: Set OPP pair (1900800000 Hz, 908000 uv) on cpu3
[    0.442028] [    0.442026]@4 add_opp: Set OPP pair (300000000 Hz, 656000 uv) on cpu4
[    0.442547] [    0.442545]@4 add_opp: Set OPP pair (2457600000 Hz, 1052000 uv) on cpu4
[    0.442578] [    0.442576]@4 add_opp: Set OPP pair (300000000 Hz, 656000 uv) on cpu5
[    0.443097] [    0.443095]@4 add_opp: Set OPP pair (2457600000 Hz, 1052000 uv) on cpu5
[    0.443120] [    0.443117]@4 add_opp: Set OPP pair (300000000 Hz, 656000 uv) on cpu6
[    0.443660] [    0.443657]@4 add_opp: Set OPP pair (2457600000 Hz, 1052000 uv) on cpu6
[    0.443685] [    0.443682]@4 add_opp: Set OPP pair (300000000 Hz, 656000 uv) on cpu7
[    0.444202] [    0.444200]@4 add_opp: Set OPP pair (2457600000 Hz, 1052000 uv) on cpu7
```
after undervolt 90mv:
```
[    0.454104] [    0.454088]@4 add_opp: Set OPP pair (300000000 Hz, 580000 uv) on cpu0
[    0.454723] [    0.454720]@4 add_opp: Set OPP pair (1900800000 Hz, 820000 uv) on cpu0
[    0.454756] [    0.454753]@4 add_opp: Set OPP pair (300000000 Hz, 580000 uv) on cpu1
[    0.455132] [    0.455130]@4 add_opp: Set OPP pair (1900800000 Hz, 820000 uv) on cpu1
[    0.455157] [    0.455154]@4 add_opp: Set OPP pair (300000000 Hz, 580000 uv) on cpu2
[    0.455525] [    0.455523]@4 add_opp: Set OPP pair (1900800000 Hz, 820000 uv) on cpu2
[    0.455548] [    0.455546]@4 add_opp: Set OPP pair (300000000 Hz, 580000 uv) on cpu3
[    0.455914] [    0.455911]@4 add_opp: Set OPP pair (1900800000 Hz, 820000 uv) on cpu3
[    0.455948] [    0.455946]@4 add_opp: Set OPP pair (300000000 Hz, 576000 uv) on cpu4
[    0.456461] [    0.456459]@4 add_opp: Set OPP pair (2457600000 Hz, 960000 uv) on cpu4
[    0.456494] [    0.456492]@4 add_opp: Set OPP pair (300000000 Hz, 576000 uv) on cpu5
[    0.457025] [    0.457023]@4 add_opp: Set OPP pair (2457600000 Hz, 960000 uv) on cpu5
[    0.457052] [    0.457050]@4 add_opp: Set OPP pair (300000000 Hz, 576000 uv) on cpu6
[    0.457572] [    0.457570]@4 add_opp: Set OPP pair (2457600000 Hz, 960000 uv) on cpu6
[    0.457598] [    0.457596]@4 add_opp: Set OPP pair (300000000 Hz, 576000 uv) on cpu7
[    0.458135] [    0.458133]@4 add_opp: Set OPP pair (2457600000 Hz, 960000 uv) on cpu7
```

### special thanks
* [asto18089](https://github.com/asto18089)
* 南昌狗头人(coolapk)