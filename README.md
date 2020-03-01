### cpu and gpu voltage offset on msm8998
The shell script use for msm8998(Snapdragon 835) undervolt

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

### prebuilt tools
There are 3 prebuilt tools in prebuilt/.  
1. magiskboot used to pack/unpack boot.img.
2. dtp used to split kernel_dtb into sub kernel_dtb-*.(one kernel_dtb exract from boot.img contains some dtbs, only one dtb is vaild)
3. dtc used to decompile dtb file to dts file.

### processes
1. use `dd` command to get boot.img
2. use `magiskboot` to unpack boot.img into kernel+kernel_dtb
3. use `dtp` to split kernel_dtb into sub kernel_dtb-*
4. find the adapted dtb according to `qcom, board-id` and `qcom, msm-id`
5. use `dtc` to decompile the selected dtb(binary) into .dts(source)
6. undervolt by change `qcom,cpr-open-loop-voltage-fuse-adjustment` `qcom,cpr-closed-loop-voltage-fuse-adjustment` `qcom,cpr-closed-loop-voltage-adjustment` in device-tree source file
7. compile dts to dtb and pack boot.img

### prepare
1. Termux: [Google Play](https://play.google.com/store/apps/details?id=com.termux)(or other)
2. Your device is rooted

### usage
```
./dtb_process.sh -i -c -f [-u undervolt] [-b overvolt] 
    -i              install boot.img after generation
    -c              does not cleanup workspace after finished(you wanna debug)
    -f              force backup the current boot(milestone) to /sdcard/bootimage/, otherwise only backup boot on first time
    -u              cpu undervolt value, default 0, range(0-125), unit mv
    -b              cpu overvolt value, default 0, range(0-125), unit mv
    -g              gpu undervolt value, default 0, range(0-160), unit mv
    -r              gpu overvolt value, default 0, range(0-160), unit mv
```

### Let's go
#### get the srcipt

open termux bash:
```
$ su
:/data/data/com.termux/files/home # curl https://github.com/lyq1996/msm8998_offset_voltage/blob/master/dtb_process.sh > dtb_process.sh
:/data/data/com.termux/files/home # chmod +x dtb_process.sh
```

undervolt!!
~~if not set `-u` and `-g`, default undervolt cpu and gpu 100mv~~(default 0 mv)

```
:/data/data/com.termux/files/home # ./dtb_process.sh -u 100 -g 100
```

install the new boot  
```
:/data/data/com.termux/files/home # dd if=./new-boot.img of=/dev/block/bootdevice/by-name/boot
```

or use option `-i`(then you don't need step `install the new boot`)

```
:/data/data/com.termux/files/home # ./dtb_process.sh -u 100 -g 100 -i
```

same as overvolt
~~please remember set `-u` and `-b` 0, because~~ (no longer need) the final `offset=(-b value)-(-u value)`

```
:/data/data/com.termux/files/home # ./dtb_process.sh -b 100 -r 100
```

if you are boring

```
:/data/data/com.termux/files/home # ./dtb_process.sh -u 90 -b 100 -g 90 -r 100    # same as ./dtb_process.sh -b 10-r 10
```

### restore
if something goes wrong, you can restore your origin boot, please check /sdcard/bootimage/ for the original boot image name.    

do remember to delete /sdcard/bootimage/.init after flashed a new ROM, otherwise the script will not backup the new rom boot.

```
su
dd if=/sdcard/bootimage/boot-*.img of=/dev/block/bootdevice/by-name/boot  # change it!
```

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