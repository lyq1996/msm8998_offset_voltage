#!/system/bin/sh
# ui_print is not finish(used in twrp), now it's a lit bit diffcult, it must static-link compile with tool dtc and dtp

magisk_boot=./prebuilt/magiskboot
dtb_spliter=./prebuilt/dtp
dtc=./prebuilt/dtc
clean="1"
install="0"
voffset=$((0))
voffset_increase=$((0))
goffset=$((0))
goffset_increase=$((0))

cleanup() {
    $magisk_boot cleanup
}

abort() {
    echo >&2 '
*******************************
************ ABORT ************
*******************************
'
    echo "$1" >&2
    cleanup
    exit $((1))
}

if [ ! -d ./prebuilt ]; then
    echo "init: creating ./prebuilt ..."
    mkdir prebuilt
fi

if [ ! -f $magisk_boot ]; then
    echo "init: fetch ./prebuilt/magiskboot from github..."
    curl https://raw.githubusercontent.com/lyq1996/msm8998_offset_voltage/master/prebuilt/magiskboot >$magisk_boot
    if [ $? = "0" ]; then
        echo "fetched magiskboot"
        chmod +x $magisk_boot
    else
        rm -rf prebuilt
        abort "! fetch magiskboot failed, maybe you should check your network"
    fi
fi

if [ ! -f $dtc ]; then
    echo "init: fetch ./prebuilt/dtc from github..."
    curl https://raw.githubusercontent.com/lyq1996/msm8998_offset_voltage/master/prebuilt/dtc >$dtc
    if [ $? = "0" ]; then
        echo "fetched dtc"
        chmod +x $dtc
    else
        rm -rf prebuilt
        abort "! fetch dtc failed, maybe you should check your network"
    fi
fi

if [ ! -f $dtb_spliter ]; then
    echo "init: fetch ./prebuilt/dtb_spliter from github..."
    curl https://raw.githubusercontent.com/lyq1996/msm8998_offset_voltage/master/prebuilt/dtp >$dtb_spliter
    if [ $? = "0" ]; then
        echo "fetched dtp"
        chmod +x $dtb_spliter
    else
        rm -rf prebuilt
        abort "! fetch dtp failed, maybe you should check your network"
    fi
fi

set -- $(getopt -q icfu:b:g:r: "$@")
while [ -n "$1" ]; do
    case "$1" in
    -i)
        echo "found -i option: install after packing new-boot.img"
        install="1"
        ;;
    -c)
        echo "found -c option: no clean up workspace after script finished"
        clean="0"
        ;;
    -f)
        echo "found -f option: force backup boot.img"
        rm -f /sdcard/bootimage/.init
        ;;
    -u)
        param=$(echo $2 | sed 's/[^0-9]//g')
        if [ "$param" -gt $((125)) ] || [ "$param" -lt $((0)) ]; then
            abort "! cpu voltage offset too low or too high"
        fi
        #echo "cpu voltage offset decrease: -$param mv"
        voffset=$(($param))
        shift
        ;;
    -b)
        param=$(echo $2 | sed 's/[^0-9]//g')
        if [ "$param" -gt $((125)) ] || [ "$param" -lt $((0)) ]; then
            abort "! cpu voltage offset too low or too high"
        fi
        #echo "cpu voltage offset increase: +$param mv"
        voffset_increase=$(($param))
        shift
        ;;
    -g)
        param=$(echo $2 | sed 's/[^0-9]//g')
        if [ "$param" -gt $((160)) ] || [ "$param" -lt $((0)) ]; then
            abort "! gpu voltage offset too low or too high"
        fi
        #echo "gpu voltage offset decrease: -$param mv"
        goffset=$(($param))
        shift
        ;;
    -r)
        param=$(echo $2 | sed 's/[^0-9]//g')
        if [ "$param" -gt $((160)) ] || [ "$param" -lt $((0)) ]; then
            abort "! gpu voltage offset too low or too high"
        fi
        #echo "voltage offset increase: +$param mv"
        goffset_increase=$(($param))
        shift
        ;;
    --)
        shift
        break
        ;;
    *)
        abort "$1 is not option"
        ;;
    esac
    shift
done

cpu_offset=$(($voffset_increase - $voffset))
gpu_offset=$(($goffset_increase - $goffset))
if [ "$cpu_offset" = 0 ] && [ "$gpu_offset" = 0 ]; then
    abort "cpu and gpu voltage offset: 0mv! exit!"
fi
echo "cpu voltage offset: $cpu_offset mv, gpu voltage offset: $gpu_offset mv"

# step 1 get current boot.img

# ui_print "- backup origin boot.img to /sdcard/bootimage/boot.img"
dd if=/dev/block/bootdevice/by-name/boot of=./boot.img
mkdir -p /sdcard/bootimage
if [ ! -f "/sdcard/bootimage/.init" ]; then
    cp ./boot.img /sdcard/bootimage/boot-backup-$(date "+%Y-%m-%d-%H-%M-%S").img
    touch /sdcard/bootimage/.init
fi

# step 2 unpack boot.img

# ui_print "- unpacking boot.img"
$magisk_boot unpack boot.img
case $? in
0)
    echo "unpacked boot.img successful"
    ;;
1)
    abort "! Unsupported/Unknown image format"
    ;;
esac

# step 3 split all dtbs

# ui_print "- split kernel_dtb"
$dtb_spliter -i kernel_dtb
case $? in
1)
    abort "! Splited kernel_dtb failed"
    ;;
esac

# step 4 decompile dtb

# ui_print "- decompile adapted kernel_dtb"
dtb_count=$(ls -lh kernel_dtb-* | wc -l)
board_id=$(cat /proc/device-tree/qcom,board-id | xxd -p | xargs echo | sed 's/ //g' | sed 's/.\{8\}/&\n/g' | sed 's/^0\{6\}/0x/g' | sed 's/^0\{5\}/0x/g' | sed 's/^0\{4\}/0x/g' | sed 's/^0\{3\}/0x/g' | sed 's/^0\{2\}/0x/g' | sed 's/^0\{1\}x*/0x/g' | tr '\n' ' ' | sed 's/ *$/\n/g')
msm_id=$(cat /proc/device-tree/qcom,msm-id | xxd -p | xargs echo | sed 's/ //g' | sed 's/.\{8\}/&\n/g' | sed 's/^0\{6\}/0x/g' | sed 's/^0\{5\}/0x/g' | sed 's/^0\{4\}/0x/g' | sed 's/^0\{3\}/0x/g' | sed 's/^0\{2\}/0x/g' | sed 's/^0\{1\}x*/0x/g' | tr '\n' ' ' | sed 's/ *$/\n/g')
echo "device board_id: $board_id, msm_id: $msm_id"

i=0
while [ $i -lt $dtb_count ]; do
    $dtc -q -I dtb -O dts kernel_dtb-$i -o kernel_dtb_$i.dts
    dts_board_id=$(cat kernel_dtb_$i.dts | grep qcom,board-id | sed -e 's/[\t]*qcom,board-id = <//g' | sed 's/>;//g')
    dts_msm_id=$(cat kernel_dtb_$i.dts | grep qcom,msm-id | sed -e 's/[\t]*qcom,msm-id = <//g' | sed 's/>;//g')
    echo "kernel_dtb_$i.dts board_id: $dts_board_id, msm_id: $dts_msm_id"
    if [ "$dts_board_id" = "$board_id" ] && [ "$dts_msm_id" = "$msm_id" ]; then
        echo "got it, let's patch kernel_dtb_$i.dts"
        break
    fi
    rm -f kernel_dtb_$i.dts
    i=$((i + 1))
done
case $i in
$dtb_count)
    abort "! Unable to found matching kernel_dtb.dts"
    ;;
esac

# step 5 apply voltage offset!

# ui_print "- !! default cpu 90mv gpu 0mv"
# remove gfx_corner open-loop-voltage-fuse-adjustment, i dont know what it is
gfx_cline=$(cat kernel_dtb_$i.dts | grep -n 'regulator-name = "gfx_corner";' | awk '{print $1}' | sed 's/://g')
gfx_cline_=$(($gfx_cline + 25))
cat kernel_dtb_$i.dts | sed "$gfx_cline,$gfx_cline_ d" | grep qcom,cpr-open-loop-voltage-fuse-adjustment >filebuff_o
cat kernel_dtb_$i.dts | sed -n "$gfx_cline,$gfx_cline_ p" | grep qcom,cpr-open-loop-voltage-fuse-adjustment | sed 's/qcom,/gfx,/g' >>filebuff_o
cat kernel_dtb_$i.dts | grep qcom,cpr-closed-loop-voltage-fuse-adjustment >>filebuff_o
cat kernel_dtb_$i.dts | sed -n "$gfx_cline,$gfx_cline_ p" | grep qcom,cpr-closed-loop-voltage-adjustment | sed 's/qcom,/gfx,/g' >>filebuff_o

cp filebuff_o filebuff_s

o_line=$(cat filebuff_o | sed -e 's/[\t]*.*<//g' | sed 's/>;//g' | wc -l)
j=1

while [ $j -le $o_line ]; do
    #echo $j
    line=$(cat filebuff_o | awk "NR==$j")
    open_loop_voltage_=$(echo "$line" | sed -e 's/[\t]*.*<//g' | sed 's/>;//g' | sed 's/\(0x[^ ]* \)\{4\}/&\n/g')
    first_line=$(echo "$open_loop_voltage_" | head -n1)

    result=$(echo "$line" | grep gfx,cpr)
    if [ "$result" != "" ] && [ "$gpu_offset" != "0" ]; then
        echo "gfx loop voltage adjustment detceted"
        next_line=$(echo "$open_loop_voltage_" | awk "NR==2")
        close_flag=$(echo "$first_line" | grep "$next_line")
        if [ "$close_flag" = "" ]; then
            open_loop_voltage_=$(cat filebuff_o | awk "NR==$j" | sed -e 's/[\t]*.*<//g' | sed 's/>;//g' | sed 's/\(0x[^ ]* \)\{8\}/&\n/g')
            first_line=$(echo "$open_loop_voltage_" | head -n1)
            loop_adjust=$(echo "$first_line" | sed 's/ $//g')
            new_v1=$(($(echo "$loop_adjust" | awk '{print $1}') + (5 * $gpu_offset / 10) * 1000))
            new_v2=$(($(echo "$loop_adjust" | awk '{print $2}') + (5 * $gpu_offset / 10) * 1000))
            new_v3=$(($(echo "$loop_adjust" | awk '{print $3}') + (6 * $gpu_offset / 10) * 1000))
            new_v4=$(($(echo "$loop_adjust" | awk '{print $4}') + (6 * $gpu_offset / 10) * 1000))
            new_v5=$(($(echo "$loop_adjust" | awk '{print $5}') + (8 * $gpu_offset / 10) * 1000))
            new_v6=$(($(echo "$loop_adjust" | awk '{print $6}') + (8 * $gpu_offset / 10) * 1000))
            new_v7=$(($(echo "$loop_adjust" | awk '{print $7}') + $gpu_offset * 1000))
            new_v8=$(($(echo "$loop_adjust" | awk '{print $8}') + $gpu_offset * 1000))
            new_v=$(printf "0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 $new_v5 $new_v6 $new_v7 $new_v8 | sed 's/0xf\{8\}/0x/g')
            echo "replacing $loop_adjust with $new_v"
            sed -i "s/$loop_adjust/$new_v/g" filebuff_s
        else
            loop_adjust=$(echo "$first_line" | sed 's/ $//g')
            new_v1=$(($(echo "$loop_adjust" | awk '{print $1}') + (5 * $gpu_offset / 10) * 1000))
            new_v2=$(($(echo "$loop_adjust" | awk '{print $2}') + (6 * $gpu_offset / 10) * 1000))
            new_v3=$(($(echo "$loop_adjust" | awk '{print $3}') + (8 * $gpu_offset / 10) * 1000))
            new_v4=$(($(echo "$loop_adjust" | awk '{print $4}') + $gpu_offset * 1000))
            new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | sed 's/0xf\{8\}/0x/g')
            echo "replacing $loop_adjust with $new_v"
            sed -i "s/$loop_adjust/$new_v/g" filebuff_s
        fi
        ori_line=$(cat filebuff_o | awk "NR==$j" | sed "s/gfx,/qcom,/g")
        mod_line=$(cat filebuff_s | awk "NR==$j" | sed "s/gfx,/qcom,/g")
        sed -i "s/$ori_line/$mod_line/g" kernel_dtb_$i.dts
    elif [ "$cpu_offset" != "0" ] && [ "$result" = "" ]; then
        loop_adjust=$(echo "$first_line" | sed 's/ $//g')
        # echo "$voffset"
        # Linux x86 integer takes up 8 bytes, so it will display as 0xfffffffffff0bdc0, don't worry its correct in arm-linux.
        # really rubbish, arm awk dont support -n
        # new_v=$(echo "$loop_adjust" | awk '{printf("0x%x 0x%x 0x%x 0x%x\n", $1 - dt + it,$2 - dt + it,$3 - dt + it,$4 - dt + it)}' dt="$voffset" it="$voffset_increase")

        new_v1=$(($(echo "$loop_adjust" | awk '{print $1}') + (9 * $cpu_offset / 10) * 1000))
        new_v2=$(($(echo "$loop_adjust" | awk '{print $2}') + (9 * $cpu_offset / 10) * 1000))
        new_v3=$(($(echo "$loop_adjust" | awk '{print $3}') + $cpu_offset * 1000))
        new_v4=$(($(echo "$loop_adjust" | awk '{print $4}') + $cpu_offset * 1000))
        new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | sed 's/0xf\{8\}/0x/g')
        echo "replacing $loop_adjust with $new_v"
        sed -i "s/$loop_adjust/$new_v/g" filebuff_s
        ori_line=$(cat filebuff_o | awk "NR==$j")
        mod_line=$(cat filebuff_s | awk "NR==$j")
        sed -i "s/$ori_line/$mod_line/g" kernel_dtb_$i.dts
    fi
    case $? in
    1)
        abort "! Unable to patched kernel_dtb_$i.dts"
        ;;
    esac
    j=$((j + 1))
done
echo "patched done."

# step 6 compile dts to dtb
$dtc -q -I dts -O dtb kernel_dtb_$i.dts -o kernel_dtb-$i
if [ "$clean" = "1" ]; then
    echo "removing useless kernetl_dtb_$i.dis.."
    rm -f kernel_dtb_$i.dts
fi

# step 7 generate new dtb
i=0
echo "generating new kernel_dtb.."
>kernel_dtb
echo "dtb_count: $dtb_count"
while [ $i -lt $dtb_count ]; do
    cat kernel_dtb-$i >>kernel_dtb
    i=$((i + 1))
done
if [ "$clean" = "1" ]; then
    echo "removing useless kernetl_dtb-*.."
    rm -f kernel_dtb-*
    rm -f filebuff_o filebuff_s
fi

# step 8 packing boot.img
echo "repacking boot.img..."
$magisk_boot repack boot.img
case $? in
0)
    echo "packed boot.img successful"
    ;;
1)
    abort "! Unsupported/Unknown image format"
    ;;
esac

rm -f boot.img
if [ $install == "1" ]; then
    echo "flashing new boot.."
    dd if=./new-boot.img of=/dev/block/bootdevice/by-name/boot
    if [ "$clean" = "1" ]; then
        rm -f new-boot.img
    fi
fi

# final step clean up and good bye
if [ "$clean" = "1" ]; then
    cleanup
fi
echo "
*******************************
*********** NOTICE ************
*******************************
"
echo "Done in your own risk!!!"
echo "
*******************************
*********** NOTICE ************
*******************************
"
