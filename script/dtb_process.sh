#!/sbin/sh
dtc=/tmp/aroma/dtc
dtp=/tmp/aroma/dtp
bbox=/tmp/aroma/busybox
# magisk_boot=/tmp/aroma/magiskboot

val1=$($bbox cat /tmp/aroma/cpu_undervolt.prop | cut -d '=' -f2)
cpu_offset=$((($val1 - 14) * 10))

platform_select=$($bbox cat /tmp/aroma/platform.prop | cut -d '=' -f2)
if [ "$platform_select" = "1" ]; then
	platform=msm8998
	val2=$($bbox cat /tmp/aroma/gpu_undervolt.prop | cut -d '=' -f2)
	gpu_offset=$((($val2 - 23) * 10))
elif [ "$platform_select" = "2" ]; then
	platform=sdm660
fi
backup=$($bbox cat /tmp/aroma/backup.prop | cut -d '=' -f2)

$bbox touch /tmp/dtp_log
> /tmp/dtp_log

$bbox touch /tmp/aroma/need_pack.prop
echo "todo_pack=2" > /tmp/aroma/need_pack.prop

if [ "$backup" = "1" ]; then
	$bbox mkdir /sdcard/bootimage
	$bbox cp /tmp/aroma/boot.img /sdcard/bootimage/boot-backup-$(date "+%Y-%m-%d-%H-%M-%S").img
	echo "Backup finished." >> /tmp/dtp_log
fi

if [ "$cpu_offset" = "0" ] && [ "$platform" = "sdm660" ]; then
	echo "Bye-bye" >> /tmp/dtp_log
	echo "todo_pack=0" > /tmp/aroma/need_pack.prop
	exit 0
elif [ "$cpu_offset" = "0" ] && [ "$gpu_offset" = "0" ] && [ "$platform" = "msm8998" ]; then
	echo "Bye-bye" >> /tmp/dtp_log
	echo "todo_pack=0" > /tmp/aroma/need_pack.prop
	exit 0
fi
echo "CPU voltage offset: $cpu_offset mv" >> /tmp/dtp_log
if [ "$platform" = "msm8998" ]; then
echo "GPU voltage offset: $gpu_offset mv" >> /tmp/dtp_log
fi


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

if [ "$platform" = "sdm660" ]; then
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep qcom,cpr-open-loop-voltage-fuse-adjustment > /tmp/aroma/filebuff_o
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep qcom,cpr-closed-loop-voltage-fuse-adjustment >> /tmp/aroma/filebuff_o

cp /tmp/aroma/filebuff_o /tmp/aroma/filebuff_s
o_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | wc -l)

j=1
while [ $j -le $o_line ]; do
	line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==$j")
	open_loop_voltage_=$(echo "$line" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{5\}/&\n/g')
	first_line=$(echo "$open_loop_voltage_" | head -n1)

	loop_adjust=$(echo "$first_line" | $bbox sed 's/ $//g')
	new_v1=$(($(echo "$loop_adjust" | $bbox awk '{print $1}') + (9 * $cpu_offset / 10) * 1000))
	new_v2=$(($(echo "$loop_adjust" | $bbox awk '{print $2}') + (9 * $cpu_offset / 10) * 1000))
	new_v3=$(($(echo "$loop_adjust" | $bbox awk '{print $3}') + $cpu_offset * 1000))
	new_v4=$(($(echo "$loop_adjust" | $bbox awk '{print $4}') + $cpu_offset * 1000))
	new_v5=$(($(echo "$loop_adjust" | $bbox awk '{print $5}') + $cpu_offset * 1000))
	new_v=$(printf "0x%x 0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 $new_v5 | $bbox sed 's/0xf\{8\}/0x/g')
	echo "Replacing $loop_adjust with $new_v" >> /tmp/dtp_log
	$bbox sed -i "s/$loop_adjust/$new_v/g" /tmp/aroma/filebuff_s
	ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==$j")
	mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==$j")
	$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts
	
	case $? in
	1)
		echo "! Unable to patched kernel_dtb_$i.dts" >> /tmp/dtp_log
		exit 1
	;;
	esac
	j=$((j + 1))
done

elif [ "$platform" = "msm8998" ]; then
gfx_cline=$($bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep -n 'regulator-name = "gfx_corner";' | $bbox awk '{print $1}' | $bbox sed 's/://g')
gfx_cline_=$(($gfx_cline + 25))
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed "$gfx_cline,$gfx_cline_ d" | $bbox grep qcom,cpr-open-loop-voltage-fuse-adjustment > /tmp/aroma/filebuff_o
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed -n "$gfx_cline,$gfx_cline_ p" | $bbox grep qcom,cpr-open-loop-voltage-fuse-adjustment | $bbox sed 's/qcom,/gfx,/g' >> /tmp/aroma/filebuff_o
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox grep qcom,cpr-closed-loop-voltage-fuse-adjustment >> /tmp/aroma/filebuff_o
$bbox cat /tmp/aroma/kernel_dtb_$i.dts | $bbox sed -n "$gfx_cline,$gfx_cline_ p" | $bbox grep qcom,cpr-closed-loop-voltage-adjustment | $bbox sed 's/qcom,/gfx,/g' >> /tmp/aroma/filebuff_o

cp /tmp/aroma/filebuff_o /tmp/aroma/filebuff_s
o_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | wc -l)

j=1
while [ $j -le $o_line ]; do
	line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==$j")
	open_loop_voltage_=$(echo "$line" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{4\}/&\n/g')
	first_line=$(echo "$open_loop_voltage_" | head -n1)

	result=$(echo "$line" | $bbox grep gfx,cpr)
	if [ "$result" != "" ] && [ "$gpu_offset" != "0" ]; then
		echo "GFX loop voltage adjustment detceted" >> /tmp/dtp_log
		next_line=$(echo "$open_loop_voltage_" | $bbox awk "NR==2")
		close_flag=$(echo "$first_line" | $bbox grep "$next_line")
		if [ "$close_flag" = "" ]; then
			open_loop_voltage_=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==$j" | $bbox sed -e 's/[\t]*.*<//g' | $bbox sed 's/>;//g' | $bbox sed 's/\(0x[^ ]* \)\{8\}/&\n/g')
			first_line=$(echo "$open_loop_voltage_" | head -n1)
			loop_adjust=$(echo "$first_line" | $bbox sed 's/ $//g')
			new_v1=$(($(echo "$loop_adjust" | $bbox awk '{print $1}') + (5 * $gpu_offset / 10) * 1000))
			new_v2=$(($(echo "$loop_adjust" | $bbox awk '{print $2}') + (5 * $gpu_offset / 10) * 1000))
			new_v3=$(($(echo "$loop_adjust" | $bbox awk '{print $3}') + (6 * $gpu_offset / 10) * 1000))
			new_v4=$(($(echo "$loop_adjust" | $bbox awk '{print $4}') + (6 * $gpu_offset / 10) * 1000))
			new_v5=$(($(echo "$loop_adjust" | $bbox awk '{print $5}') + (8 * $gpu_offset / 10) * 1000))
			new_v6=$(($(echo "$loop_adjust" | $bbox awk '{print $6}') + (8 * $gpu_offset / 10) * 1000))
			new_v7=$(($(echo "$loop_adjust" | $bbox awk '{print $7}') + $gpu_offset * 1000))
			new_v8=$(($(echo "$loop_adjust" | $bbox awk '{print $8}') + $gpu_offset * 1000))
			new_v=$(printf "0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 $new_v5 $new_v6 $new_v7 $new_v8 | $bbox sed 's/0xf\{8\}/0x/g')
			echo "Replacing $loop_adjust with $new_v" >> /tmp/dtp_log
			$bbox sed -i "s/$loop_adjust/$new_v/g" /tmp/aroma/filebuff_s
		else
			loop_adjust=$(echo "$first_line" | $bbox sed 's/ $//g')
			new_v1=$(($(echo "$loop_adjust" | $bbox awk '{print $1}') + (5 * $gpu_offset / 10) * 1000))
			new_v2=$(($(echo "$loop_adjust" | $bbox awk '{print $2}') + (6 * $gpu_offset / 10) * 1000))
			new_v3=$(($(echo "$loop_adjust" | $bbox awk '{print $3}') + (8 * $gpu_offset / 10) * 1000))
			new_v4=$(($(echo "$loop_adjust" | $bbox awk '{print $4}') + $gpu_offset * 1000))
			new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | $bbox sed 's/0xf\{8\}/0x/g')
			echo "Replacing $loop_adjust with $new_v" >> /tmp/dtp_log
			$bbox sed -i "s/$loop_adjust/$new_v/g" /tmp/aroma/filebuff_s
		fi
		ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==$j" | $bbox sed "s/gfx,/qcom,/g")
		mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==$j" | $bbox sed "s/gfx,/qcom,/g")
		$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts
	elif [ "$cpu_offset" != "0" ] && [ "$result" = "" ]; then
		loop_adjust=$(echo "$first_line" | $bbox sed 's/ $//g')
		new_v1=$(($(echo "$loop_adjust" | $bbox awk '{print $1}') + (9 * $cpu_offset / 10) * 1000))
		new_v2=$(($(echo "$loop_adjust" | $bbox awk '{print $2}') + (9 * $cpu_offset / 10) * 1000))
		new_v3=$(($(echo "$loop_adjust" | $bbox awk '{print $3}') + $cpu_offset * 1000))
		new_v4=$(($(echo "$loop_adjust" | $bbox awk '{print $4}') + $cpu_offset * 1000))
		new_v=$(printf "0x%x 0x%x 0x%x 0x%x\n" $new_v1 $new_v2 $new_v3 $new_v4 | $bbox sed 's/0xf\{8\}/0x/g')
		echo "Replacing $loop_adjust with $new_v" >> /tmp/dtp_log
		$bbox sed -i "s/$loop_adjust/$new_v/g" /tmp/aroma/filebuff_s
		ori_line=$($bbox cat /tmp/aroma/filebuff_o | $bbox awk "NR==$j")
		mod_line=$($bbox cat /tmp/aroma/filebuff_s | $bbox awk "NR==$j")
		$bbox sed -i "s/$ori_line/$mod_line/g" /tmp/aroma/kernel_dtb_$i.dts
	fi
	case $? in
	1)
		echo "! Unable to patched kernel_dtb_$i.dts" >> /tmp/dtp_log
		exit 1
	;;
	esac
	j=$((j + 1))
done
fi

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
echo "todo_pack=1" > /tmp/aroma/need_pack.prop
exit 0
