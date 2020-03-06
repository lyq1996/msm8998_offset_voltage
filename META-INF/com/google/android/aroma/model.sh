#!/sbin/sh

platform=$(getprop ro.hardware.gatekeeper)

if [ $platform = "msm8998" ];then
    exit 0
else
    exit 1
fi