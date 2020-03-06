#!/sbin/sh
exit 0
platform=$(getprop ro.board.platform)

if [ $platform = "msm8998" ];then
    exit 0
else
    exit 1
fi