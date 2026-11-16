#!/bin/bash

echo Begin Runing...
SNDCPY_PORT=28200
SNDCPY_APK=sndcpy.apk
ADB=./adb

serial=
if [[ $# -ge 2 ]]; then
    serial="-s $1"
    SNDCPY_PORT=$2
fi

echo "Waiting for device $1..."
$ADB $serial wait-for-device
echo "Find device $1"

sndcpy_installed=$($ADB $serial shell pm path com.rom1v.sndcpy)
if [[ $sndcpy_installed == "" ]]; then
    echo Install $SNDCPY_APK...
    $ADB $serial uninstall com.rom1v.sndcpy || echo uninstall failed
    $ADB $serial install -t -r -g $SNDCPY_APK
    echo Install $SNDCPY_APK success
fi

echo Request PROJECT_MEDIA permission...
$ADB $serial shell appops set com.rom1v.sndcpy PROJECT_MEDIA allow
$ADB $serial forward tcp:$SNDCPY_PORT localabstract:sndcpy
$ADB $serial shell am start com.rom1v.sndcpy/.MainActivity

while ((1)); do
    sleep 0.1
    sndcpy_started=$($ADB shell 'ps | grep com.rom1v.sndcpy')
    [[ $sndcpy_started != "" ]] && break
done
echo Ready playing...
