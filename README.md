### Visable and Flashable tool for msm8998 undervolt offset

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
### Useage
Boot to TWRP and flash msm8998-Undervolt-Tool.zip

### build flashable zip
zip -r9 msm8998-Undervolt-Tool.zip * -x .git README.md .gitignore dtp_src

### result
before cpu undervolt:
```
OnePlus5T:/ $ su -c dmesg -T | grep add_opp
[Fri Jun 26 15:43:14 2020] [    0.453782]@4 add_opp: Set OPP pair (300000000 Hz, 660000 uv) on cpu0
[Fri Jun 26 15:43:14 2020] [    0.454379]@4 add_opp: Set OPP pair (1900800000 Hz, 908000 uv) on cpu0
[Fri Jun 26 15:43:14 2020] [    0.454404]@4 add_opp: Set OPP pair (300000000 Hz, 660000 uv) on cpu1
[Fri Jun 26 15:43:14 2020] [    0.454769]@4 add_opp: Set OPP pair (1900800000 Hz, 908000 uv) on cpu1
[Fri Jun 26 15:43:14 2020] [    0.454801]@4 add_opp: Set OPP pair (300000000 Hz, 660000 uv) on cpu2
[Fri Jun 26 15:43:14 2020] [    0.455156]@4 add_opp: Set OPP pair (1900800000 Hz, 908000 uv) on cpu2
[Fri Jun 26 15:43:14 2020] [    0.455190]@4 add_opp: Set OPP pair (300000000 Hz, 660000 uv) on cpu3
[Fri Jun 26 15:43:14 2020] [    0.455555]@4 add_opp: Set OPP pair (1900800000 Hz, 908000 uv) on cpu3
[Fri Jun 26 15:43:14 2020] [    0.455580]@4 add_opp: Set OPP pair (300000000 Hz, 656000 uv) on cpu4
[Fri Jun 26 15:43:14 2020] [    0.456101]@4 add_opp: Set OPP pair (2457600000 Hz, 1052000 uv) on cpu4
[Fri Jun 26 15:43:14 2020] [    0.456124]@4 add_opp: Set OPP pair (300000000 Hz, 656000 uv) on cpu5
[Fri Jun 26 15:43:14 2020] [    0.456631]@4 add_opp: Set OPP pair (2457600000 Hz, 1052000 uv) on cpu5
[Fri Jun 26 15:43:14 2020] [    0.456663]@4 add_opp: Set OPP pair (300000000 Hz, 656000 uv) on cpu6
[Fri Jun 26 15:43:14 2020] [    0.457181]@4 add_opp: Set OPP pair (2457600000 Hz, 1052000 uv) on cpu6
[Fri Jun 26 15:43:14 2020] [    0.457212]@4 add_opp: Set OPP pair (300000000 Hz, 656000 uv) on cpu7
[Fri Jun 26 15:43:14 2020] [    0.457735]@4 add_opp: Set OPP pair (2457600000 Hz, 1052000 uv) on cpu7
```

cpu little cluster undervolt 50mv and cpu big cluster undervolt 100mv:
```
OnePlus5T:/ $ su -c dmesg -T | grep add_opp
[Fri Jun 26 15:36:11 2020] [    0.453347]@4 add_opp: Set OPP pair (300000000 Hz, 616000 uv) on cpu0
[Fri Jun 26 15:36:11 2020] [    0.453947]@4 add_opp: Set OPP pair (1900800000 Hz, 860000 uv) on cpu0
[Fri Jun 26 15:36:11 2020] [    0.453971]@4 add_opp: Set OPP pair (300000000 Hz, 616000 uv) on cpu1
[Fri Jun 26 15:36:11 2020] [    0.454342]@4 add_opp: Set OPP pair (1900800000 Hz, 860000 uv) on cpu1
[Fri Jun 26 15:36:11 2020] [    0.454367]@4 add_opp: Set OPP pair (300000000 Hz, 616000 uv) on cpu2
[Fri Jun 26 15:36:11 2020] [    0.454733]@4 add_opp: Set OPP pair (1900800000 Hz, 860000 uv) on cpu2
[Fri Jun 26 15:36:11 2020] [    0.454767]@4 add_opp: Set OPP pair (300000000 Hz, 616000 uv) on cpu3
[Fri Jun 26 15:36:11 2020] [    0.455142]@4 add_opp: Set OPP pair (1900800000 Hz, 860000 uv) on cpu3
[Fri Jun 26 15:36:11 2020] [    0.455166]@4 add_opp: Set OPP pair (300000000 Hz, 568000 uv) on cpu4
[Fri Jun 26 15:36:11 2020] [    0.455692]@4 add_opp: Set OPP pair (2457600000 Hz, 952000 uv) on cpu4
[Fri Jun 26 15:36:11 2020] [    0.455714]@4 add_opp: Set OPP pair (300000000 Hz, 568000 uv) on cpu5
[Fri Jun 26 15:36:11 2020] [    0.456237]@4 add_opp: Set OPP pair (2457600000 Hz, 952000 uv) on cpu5
[Fri Jun 26 15:36:11 2020] [    0.456269]@4 add_opp: Set OPP pair (300000000 Hz, 568000 uv) on cpu6
[Fri Jun 26 15:36:11 2020] [    0.456793]@4 add_opp: Set OPP pair (2457600000 Hz, 952000 uv) on cpu6
[Fri Jun 26 15:36:11 2020] [    0.456825]@4 add_opp: Set OPP pair (300000000 Hz, 568000 uv) on cpu7
[Fri Jun 26 15:36:11 2020] [    0.457349]@4 add_opp: Set OPP pair (2457600000 Hz, 952000 uv) on cpu7
```

before GPU undervolt:
```
OnePlus5T:/ $ su -c dmesg -T | grep gfx3d_clk_src
[Fri Jun 26 15:15:13 2020] gfx3d_clk_src: set OPP pair(180000000 Hz: 656000 uV) on 5000000.qcom,kgsl-3d0
[Fri Jun 26 15:15:13 2020] gfx3d_clk_src: set OPP pair(710000000 Hz: 964000 uV) on 5000000.qcom,kgsl-3d0
```

after GPU undervolt 200mv:
```
OnePlus5T:/ $ su -c dmesg -T | grep gfx3d_clk_src
[Fri Jun 26 15:43:14 2020] gfx3d_clk_src: set OPP pair(180000000 Hz: 556000 uV) on 5000000.qcom,kgsl-3d0
[Fri Jun 26 15:43:14 2020] gfx3d_clk_src: set OPP pair(710000000 Hz: 764000 uV) on 5000000.qcom,kgsl-3d0
```

### special thanks
* [asto18089](https://github.com/asto18089)
* [南昌狗头人](https://github.com/aa889788)