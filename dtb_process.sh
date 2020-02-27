#!/system/bin/sh
# ui_print is not finish(used in twrp), now it's a lit bit diffcult, it must static-link compile with tool dtc and dtp

magisk_boot=./prebuilt/magiskboot
dtb_spliter=./prebuilt/dtp
dtc=./prebuilt/dtc
clean="1"
install="0"
voffset=$((100000))

cleanup() {
  $magisk_boot cleanup
}

abort() {
  echo >&2 '
***************
*** ABORTED ***
***************
'
  echo "$1" >&2
  cleanup
  exit $((1))
}

set -- $(getopt -q icu: "$@")
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
  -u)
    param=$(echo $2 | sed 's/[^0-9]//g')
    if [ "$param" -gt $((125)) ] || [ "$param" -lt $((0)) ]; then
      abort "! cpu voltage offset too low or too high"
    fi
    echo "voltage offset: -$param mv"
    voffset=$(($param * 1000))
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "$1 is not option"
    ;;
  esac
  shift
done

# step 1 get current boot.img

# ui_print "- backup origin boot.img to /sdcard/bootimage/boot.img"
dd if=/dev/block/bootdevice/by-name/boot of=./boot.img
mkdir -p /sdcard/bootimage
cp ./boot.img /sdcard/bootimage/boot-$(date "+%Y-%m-%d-%H-%M-%S").img

# step 2 unpack boot.img

# ui_print "- unpacking boot.img"
$magisk_boot unpack boot.img
case $? in
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
board_id=$(cat /proc/device-tree/qcom,board-id | xxd -p | sed 's/.\{8\}/&\n/g' | sed 's/^0\{6\}/0x/g' | sed 's/^0\{5\}/0x/g' | sed 's/^0\{4\}/0x/g' | sed 's/^0\{3\}/0x/g' | sed 's/^0\{2\}/0x/g' | sed 's/^0\{1\}x*/0x/g' | tr '\n' ' ' | sed 's/ *$/\n/g')
msm_id=$(cat /proc/device-tree/qcom,msm-id | xxd -p | sed 's/.\{8\}/&\n/g' | sed 's/^0\{6\}/0x/g' | sed 's/^0\{5\}/0x/g' | sed 's/^0\{4\}/0x/g' | sed 's/^0\{3\}/0x/g' | sed 's/^0\{2\}/0x/g' | sed 's/^0\{1\}x*/0x/g' | tr '\n' ' ' | sed 's/ *$/\n/g')
echo "device board_id: $board_id, msm_id: $msm_id"

i=0
while [ $i -lt $dtb_count ]; do
  $dtc -q -I dtb -O dts kernel_dtb-$i -o kernel_dtb_$i.dts
  dts_board_id=$(cat kernel_dtb_$i.dts | grep board | sed -e 's/[\t]*qcom,board-id = <//g' | sed 's/>;//g')
  dts_msm_id=$(cat kernel_dtb_$i.dts | grep qcom,msm-id | sed -e 's/[\t]*qcom,msm-id = <//g' | sed 's/>;//g')
  echo "kernel_dtb_$i.dts board_id: $dts_board_id, msm_id: $dts_msm_id"
  if [ "$dts_board_id" = "$board_id" ] && [ "$dts_msm_id" = "$msm_id" ]; then
    echo "got it, ready to patch kernel_dtb_$i.dts"
    break
  fi
  i=$((i + 1))
done
case $i in
$dtb_count)
  abort "! Unable to found matching kernel_dtb.dts"
  ;;
esac

# step 5 apply voltage offset!

# ui_print "- !! default 100mv"
# remove gfx_corner open-loop-voltage-fuse-adjustment, i dont know what it is
gfx_cline=`cat kernel_dtb_$i.dts | grep -n 'regulator-name = "gfx_corner";' | awk '{print $1}' | sed 's/://g'`
gfx_cline_=$(($gfx_cline + 25))
cat kernel_dtb_$i.dts | sed "$gfx_cline,$gfx_cline_ d" | grep qcom,cpr-open-loop-voltage-fuse-adjustment >filebuff_o
cat kernel_dtb_$i.dts | grep qcom,cpr-closed-loop-voltage-fuse-adjustment >>filebuff_o
cp filebuff_o filebuff_s
j=1
o_line=$(cat filebuff_o | sed -e 's/[\t]*.*<//g' | sed 's/>;//g' | wc -l)

while [ $j -le $o_line ]; do # remember
  #echo $j
  open_loop_voltage_=$(cat filebuff_o | sed -e 's/[\t]*.*<//g' | sed 's/>;//g' | awk "NR==$j" | sed 's/\(0x[^ ]* \)\{4\}/&\n/g')
  open_loop_voltage_line=$(echo "$open_loop_voltage_" | wc -l)
  first_line=$(echo "$open_loop_voltage_" | head -n1)
  z=1
  while [ $z -le $open_loop_voltage_line ]; do # remember
    open_loop_voltage_per_line=$(echo "$open_loop_voltage_" | awk "NR==$z")
    result=$(echo "$first_line" | grep "$open_loop_voltage_per_line")
    if [ "$result" = "" ]; then
      echo "$z","$first_line","$open_loop_voltage_per_line"
      abort "! loop error"
    fi
    z=$((z + 1))
  done
  cricle_adjust=$(echo "$first_line" | sed 's/ $//g')
  echo "patching $cricle_adjust ..."
  # echo "$voffset"
  # Linux x86 integer takes up 8 bytes, so it will display as 0xfffffffffff0bdc0, don't worry its correct in arm-linux.
  new_v=$(echo "$cricle_adjust" | awk '{printf("0x%x 0x%x 0x%x 0x%x\n", $1 - ot,$2 - ot,$3 - ot,$4 - ot)}' ot="$voffset") # really rubbish
  sed -i "s/$cricle_adjust/$new_v/g" filebuff_s
  ori_line=$(cat filebuff_o | awk "NR==$j")
  mod_line=$(cat filebuff_s | awk "NR==$j")
  sed -i "s/$ori_line/$mod_line/g" kernel_dtb_$i.dts
  case $i in
  $dtb_count)
    abort "! Unable to patched kernel_dtb_$i.dts"
    ;;
  esac
  j=$((j + 1))
done
echo "patched done."

# step 6 compile dts to dtb
$dtc -q -I dts -O dtb kernel_dtb_$i.dts -o kernel_dtb-$i
if [ "$clean" = "1" ]; then
  echo "removing useless kernetl_dtb-*.dis.."
  rm -f kernel_dtb_*.dts
fi

# step 7 generate new dtb
i=0
echo "generating new kernel_dtb.."
echo "" >kernel_dtb
echo "dtb_count: $dtb_count"
while [ $i -lt $dtb_count ]; do
  echo "i: $i"
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
***************
*** NOTICE ***
***************
"
echo "Done in your own risk!"
