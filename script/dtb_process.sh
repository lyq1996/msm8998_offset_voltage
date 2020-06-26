#!/sbin/sh
dtc=/tmp/aroma/dtc
dtp=/tmp/aroma/dtp
bbox=/tmp/aroma/busybox
# magisk_boot=/tmp/aroma/magiskboot

val1=$($bbox cat /tmp/aroma/cpu_big_undervolt.prop | cut -d '=' -f2)
val2=$($bbox cat /tmp/aroma/gpu_undervolt.prop | cut -d '=' -f2)
val3=$($bbox cat /tmp/aroma/cpu_little_undervolt.prop | cut -d '=' -f2)
backup=$($bbox cat /tmp/aroma/backup.prop | cut -d '=' -f2)

cpu_big_offset=$((($val1 - 14) * 10))
cpu_little_offset=$((($val3 - 16) * 10))
gpu_offset=$((($val2 - 23) * 10))

$bbox touch /tmp/dtp_log
> /tmp/dtp_log

# error_status: 
# 0 or 1: OK
# 2: Something goes wrong 
$bbox touch /tmp/aroma/status.prop
echo "error_status=2" > /tmp/aroma/status.prop

if [ "$backup" = "1" ]; then
	$bbox mkdir /sdcard/bootimage
	$bbox cp /tmp/aroma/boot.img /sdcard/bootimage/boot-backup-$(date "+%Y-%m-%d-%H-%M-%S").img
	echo "Backup finished." >> /tmp/dtp_log
fi

if [ "$cpu_big_offset" = "0" ] && [ "$cpu_little_offset" = "0" ] && [ "$gpu_offset" = "0" ]; then
	echo "Bye-bye" >> /tmp/dtp_log
	echo "error_status=0" > /tmp/aroma/status.prop
	exit 0
fi
echo "CPU High Cluster Voltage Offset: $cpu_big_offset mv" >> /tmp/dtp_log
echo "CPU LITTLE Cluster Voltage Offset: $cpu_little_offset mv" >> /tmp/dtp_log
echo "GPU voltage offset: $gpu_offset mv" >> /tmp/dtp_log

$dtp -i kernel_dtb
if [ "$?" != "0" ]; then
	echo "Split dtb file error." >> /tmp/dtp_log
	exit 1
fi

# decompile dtb

echo "- Decompile adapted kernel_dtb..." >> /tmp/dtp_log
dtb_count=$(ls -lh kernel_dtb-* | wc -l)
board_id=$($bbox cat /proc/device-tree/qcom,board-id | $bbox xxd -p | $bbox xargs echo | $bbox sed 's/ //g' | $bbox sed 's/.\{8\}/&\n/g' | $bbox sed 's/^0\{6\}/0x/g' | $bbox sed 's/^0\{5\}/0x/g' | $bbox sed 's/^0\{4\}/0x/g' | $bbox sed 's/^0\{3\}/0x/g' | $bbox sed 's/^0\{2\}/0x/g' | $bbox sed 's/^0\{1\}x*/0x/g' | $bbox tr '\n' ' ' | $bbox sed 's/ *$/\n/g')
msm_id=$($bbox cat /proc/device-tree/qcom,msm-id | $bbox xxd -p | $bbox xargs echo | $bbox sed 's/ //g' | $bbox sed 's/.\{8\}/&\n/g' | $bbox sed 's/^0\{6\}/0x/g' | $bbox sed 's/^0\{5\}/0x/g' | $bbox sed 's/^0\{4\}/0x/g' | $bbox sed 's/^0\{3\}/0x/g' | $bbox sed 's/^0\{2\}/0x/g' | $bbox sed 's/^0\{1\}x*/0x/g' | $bbox tr '\n' ' ' | $bbox sed 's/ *$/\n/g')
echo "Device board_id: $board_id, msm_id: $msm_id" >> /tmp/dtp_log

i=0
while [ $i -lt $dtb_count ]; do
	$dtc -q -I dtb -O dts kernel_dtb-$i -o /tmp/aroma/kernel_dtb_$i.dts
	dts_board_id=$($bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep qcom,board-id | $bbox sed -e 's/[\t]*qcom,board-id = <//g' | $bbox sed 's/>;//g')
	dts_msm_id=$($bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep qcom,msm-id | $bbox sed -e 's/[\t]*qcom,msm-id = <//g' | $bbox sed 's/>;//g')
	echo "kernel_dtb_$i.dts board_id: $dts_board_id, msm_id: $dts_msm_id" >> /tmp/dtp_log
	if [ "$dts_board_id" = "$board_id" ] && [ "$dts_msm_id" = "$msm_id" ]; then
		echo "got it, let's patch kernel_dtb_$i.dts" >> /tmp/dtp_log
		break
	fi
	$bbox rm -f /tmp/aroma/kernel_dtb_$i.dts
	i=$((i + 1))
done
case $i in
$dtb_count)
	echo "! Unable to found matching kernel_dtb.dts" >> /tmp/dtp_log
	exit 1
;;
esac

# apply voltage offset!

echo "- !! Undervolt ..." >> /tmp/dtp_log
gfx_cline=$($bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep -n 'gfx_corner' | $bbox awk '{print $1}' | $bbox sed 's/://g')
gfx_cline_=$(($gfx_cline + 25))
apc0_line=$($bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep -n 'apc0_pwrcl_corner' | $bbox awk '{print $1}' | $bbox sed 's/://g')
apc0_line_=$(($apc0_line + 27))
apc1_line=$($bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep -n 'apc1_perfcl_corner' | $bbox awk '{print $1}' | $bbox sed 's/://g')
apc1_line_=$(($apc1_line + 27))

# little cluster open-loop-voltage-fuse
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed -n "$apc0_line,$apc0_line_ p" | $bbox grep qcom,cpr-open-loop-voltage-fuse-adjustment > /tmp/aroma/filebuff_o
# big cluster open-loop-voltage-fuse
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed -n "$apc1_line,$apc1_line_ p" | $bbox grep qcom,cpr-open-loop-voltage-fuse-adjustment >> /tmp/aroma/filebuff_o
# gfx corner open-loop-voltage-fuse
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed -n "$gfx_cline,$gfx_cline_ p" | $bbox grep qcom,cpr-open-loop-voltage-fuse-adjustment >> /tmp/aroma/filebuff_o

# little cluster closed-loop-voltage-fuse
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed -n "$apc0_line,$apc0_line_ p" | $bbox grep qcom,cpr-closed-loop-voltage-fuse-adjustment >> /tmp/aroma/filebuff_o
# big cluster closed-loop-voltage-fuse
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed -n "$apc1_line,$apc1_line_ p" | $bbox grep qcom,cpr-closed-loop-voltage-fuse-adjustment >> /tmp/aroma/filebuff_o
# gfx corner closed-loop-voltage
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed -n "$gfx_cline,$gfx_cline_ p" | $bbox grep qcom,cpr-closed-loop-voltage-adjustment >> /tmp/aroma/filebuff_o

cp /tmp/aroma/filebuff_o /tmp/aroma/filebuff_s

if [ "$cpu_little_offset" != "0" ]; then
	apc0_open_voltage_data=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==1")
	apc0_open_voltage_fuse=$(echo "$apc0_open_voltage_data" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{4\}/&\n/g' | head -n1 | sed 's/ $//g')
	new_v1=$(($(echo "$apc0_open_voltage_fuse" | $bbox awk '{print $1}') + (9 * $cpu_little_offset / 10) * 1000))
	new_v2=$(($(echo "$apc0_open_voltage_fuse" | $bbox awk '{print $2}') + (9 * $cpu_little_offset / 10) * 1000))
	new_v3=$(($(echo "$apc0_open_voltage_fuse" | $bbox awk '{print $3}') + $cpu_little_offset * 1000))
	new_v4=$(($(echo "$apc0_open_voltage_fuse" | $bbox awk '{print $4}') + $cpu_little_offset * 1000))
	new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | $bbox sed 's/0xf\{8\}/0x/g')
	echo "Replacing $apc0_open_voltage_fuse with $new_v" >> /tmp/dtp_log
	$bbox sed -i "s/$apc0_open_voltage_fuse/$new_v/g" /tmp/aroma/filebuff_s
	ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==1")
	mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==1")
	$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts

	apc0_closed_voltage_data=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==4")
	apc0_closed_voltage_fuse=$(echo "$apc0_closed_voltage_data" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{4\}/&\n/g' | head -n1 | sed 's/ $//g')
	new_v1=$(($(echo "$apc0_closed_voltage_fuse" | $bbox awk '{print $1}') + (9 * $cpu_little_offset / 10) * 1000))
	new_v2=$(($(echo "$apc0_closed_voltage_fuse" | $bbox awk '{print $2}') + (9 * $cpu_little_offset / 10) * 1000))
	new_v3=$(($(echo "$apc0_closed_voltage_fuse" | $bbox awk '{print $3}') + $cpu_little_offset * 1000))
	new_v4=$(($(echo "$apc0_closed_voltage_fuse" | $bbox awk '{print $4}') + $cpu_little_offset * 1000))
	new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | $bbox sed 's/0xf\{8\}/0x/g')
	echo "Replacing $apc0_closed_voltage_fuse with $new_v" >> /tmp/dtp_log
	$bbox sed -i "s/$apc0_closed_voltage_fuse/$new_v/g" /tmp/aroma/filebuff_s
	ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==4")
	mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==4")
	$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts
fi

if [ "$cpu_big_offset" != "0" ]; then
	apc1_open_voltage_data=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==2")
	apc1_open_voltage_fuse=$(echo "$apc1_open_voltage_data" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{4\}/&\n/g' | head -n1 | sed 's/ $//g')
	new_v1=$(($(echo "$apc1_open_voltage_fuse" | $bbox awk '{print $1}') + (9 * $cpu_big_offset / 10) * 1000))
	new_v2=$(($(echo "$apc1_open_voltage_fuse" | $bbox awk '{print $2}') + (9 * $cpu_big_offset / 10) * 1000))
	new_v3=$(($(echo "$apc1_open_voltage_fuse" | $bbox awk '{print $3}') + $cpu_big_offset * 1000))
	new_v4=$(($(echo "$apc1_open_voltage_fuse" | $bbox awk '{print $4}') + $cpu_big_offset * 1000))
	new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | $bbox sed 's/0xf\{8\}/0x/g')
	echo "Replacing $apc1_open_voltage_fuse with $new_v" >> /tmp/dtp_log
	$bbox sed -i "s/$apc1_open_voltage_fuse/$new_v/g" /tmp/aroma/filebuff_s
	ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==2")
	mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==2")
	$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts

	apc1_closed_voltage_data=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==5")
	apc1_closed_voltage_fuse=$(echo "$apc1_closed_voltage_data" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{4\}/&\n/g' | head -n1 | sed 's/ $//g')
	new_v1=$(($(echo "$apc1_closed_voltage_fuse" | $bbox awk '{print $1}') + (9 * $cpu_big_offset / 10) * 1000))
	new_v2=$(($(echo "$apc1_closed_voltage_fuse" | $bbox awk '{print $2}') + (9 * $cpu_big_offset / 10) * 1000))
	new_v3=$(($(echo "$apc1_closed_voltage_fuse" | $bbox awk '{print $3}') + $cpu_big_offset * 1000))
	new_v4=$(($(echo "$apc1_closed_voltage_fuse" | $bbox awk '{print $4}') + $cpu_big_offset * 1000))
	new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | $bbox sed 's/0xf\{8\}/0x/g')
	echo "Replacing $apc1_closed_voltage_fuse with $new_v" >> /tmp/dtp_log
	$bbox sed -i "s/$apc1_closed_voltage_fuse/$new_v/g" /tmp/aroma/filebuff_s
	ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==5")
	mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==5")
	$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts
fi

if [ "$gpu_offset" != "0" ]; then
	gfx_open_voltage_data=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==3")
	gfx_open_loop_voltage_fuse=$(echo "$gfx_open_voltage_data" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{4\}/&\n/g' | head -n1 | sed 's/ $//g')
	new_v1=$(($(echo "$gfx_open_loop_voltage_fuse" | $bbox awk '{print $1}') + (5 * $gpu_offset / 10) * 1000))
	new_v2=$(($(echo "$gfx_open_loop_voltage_fuse" | $bbox awk '{print $2}') + (6 * $gpu_offset / 10) * 1000))
	new_v3=$(($(echo "$gfx_open_loop_voltage_fuse" | $bbox awk '{print $3}') + (8 * $gpu_offset / 10) * 1000))
	new_v4=$(($(echo "$gfx_open_loop_voltage_fuse" | $bbox awk '{print $4}') + $gpu_offset * 1000))
	new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | $bbox sed 's/0xf\{8\}/0x/g')
	echo "Replacing $gfx_open_loop_voltage_fuse with $new_v" >> /tmp/dtp_log
	$bbox sed -i "s/$gfx_open_loop_voltage_fuse/$new_v/g" /tmp/aroma/filebuff_s
	ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==3")
	mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==3")
	$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts

	gfx_closed_voltage_data=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==6")
	gfx_closed_loop_voltage=$(echo "$gfx_closed_voltage_data" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{8\}/&\n/g' | head -n1 | sed 's/ $//g')
	new_v1=$(($(echo "$gfx_closed_loop_voltage" | $bbox awk '{print $1}') + (5 * $gpu_offset / 10) * 1000))
	new_v2=$(($(echo "$gfx_closed_loop_voltage" | $bbox awk '{print $2}') + (5 * $gpu_offset / 10) * 1000))
	new_v3=$(($(echo "$gfx_closed_loop_voltage" | $bbox awk '{print $3}') + (6 * $gpu_offset / 10) * 1000))
	new_v4=$(($(echo "$gfx_closed_loop_voltage" | $bbox awk '{print $4}') + (6 * $gpu_offset / 10) * 1000))
	new_v5=$(($(echo "$gfx_closed_loop_voltage" | $bbox awk '{print $5}') + (8 * $gpu_offset / 10) * 1000))
	new_v6=$(($(echo "$gfx_closed_loop_voltage" | $bbox awk '{print $6}') + (8 * $gpu_offset / 10) * 1000))
	new_v7=$(($(echo "$gfx_closed_loop_voltage" | $bbox awk '{print $7}') + $gpu_offset * 1000))
	new_v8=$(($(echo "$gfx_closed_loop_voltage" | $bbox awk '{print $8}') + $gpu_offset * 1000))
	new_v=$(printf "0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 $new_v5 $new_v6 $new_v7 $new_v8 | $bbox sed 's/0xf\{8\}/0x/g')
	echo "Replacing $gfx_closed_loop_voltage with $new_v" >> /tmp/dtp_log
	$bbox sed -i "s/$gfx_closed_loop_voltage/$new_v/g" /tmp/aroma/filebuff_s
	ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==6")
	mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==6")
	$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts
fi

case $? in
1)
	echo "! Unable to patched kernel_dtb_$i.dts" >> /tmp/dtp_log
	exit 1
;;
esac


# compile dts to dtb
$dtc -q -I dts -O dtb /tmp/aroma/kernel_dtb_$i.dts -o kernel_dtb-$i

# generate new dtb
i=0
echo "Generating new kernel_dtb.." >> /tmp/dtp_log
> kernel_dtb
while [ $i -lt $dtb_count ]; do
	$bbox cat kernel_dtb-$i >> kernel_dtb
	i=$((i + 1))
done

echo "Done." >> /tmp/dtp_log
echo "error_status=1" > /tmp/aroma/status.prop
exit 0
