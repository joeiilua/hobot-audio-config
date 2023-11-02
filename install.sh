#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 1>&2
   exit -1
fi

echo "What type of audio board do you have?"
echo "1. WM8960 Audio HAT"
echo "2. Audio Driver HAT"
read ans
file_prefix=""
asound_state_file=""
if [ "$ans" = "1" ]; then
    echo "CODEC: WM8960"
    file_prefix="WM8960"
    asound_state_file="wm8960_asound.state"
elif [ "$ans" = "2" ]; then
    echo "CODEC: ES7210 + ES8156"
    file_prefix="ES7210"
else
    echo "Invalid option"
    exit 1
fi


board_type=$(cat /sys/class/socinfo/som_name)
file_suffix=""
if [ "$board_type" = "5" ]; then
    echo "Your board type is X3 PI V1.1"
    file_suffix="_pi_1.x"
elif [ "$board_type" = "6" ]; then
    echo "Your board type is X3 PI V1.2"
    file_suffix="_pi_1.x"
elif [ "$board_type" = '8' ]; then
    echo "Your board type is X3 PI V2.1"
    file_suffix="_pi_2.1"
elif [ "$board_type" = 'b' ]; then
    echo "Your board type is X3 MD"
    file_suffix="_md_1.0"
fi


echo "Loading driver..."
echo
modprobe hobot-i2s-dma
modprobe hobot-cpudai
echo "Set the driver to load automatically at boot..."
echo
if [ "$ans" = "1" ]; then
    modprobe snd-soc-wm8960
    modprobe hobot-snd-wm8960

    #restore wm8960 alsa config
    rm -fv /var/lib/alsa/asound.state
    rm -rfv /etc/wm8960_config/

    mkdir -pv /etc/wm8960_config
    cp $asound_state_file /etc/wm8960_config/ -v
    ln -s /etc/wm8960_config/wm8960_asound.state /var/lib/alsa/asound.state
    alsactl restore

    mv -v /lib/modprobe.d/blacklist-hobot-codec-wm8960.conf /lib/modprobe.d/blacklist-hobot-codec-wm8960.disable
elif [ "$ans" = "2" ]; then
    modprobe es7210
    modprobe es8156
    modprobe hobot-snd-7210

    mv -v /lib/modprobe.d/blacklist-hobot-codec-es7210.conf /lib/modprobe.d/blacklist-hobot-codec-es7210.disable
fi

#modprobe iis driver at startup
mv -v /lib/modprobe.d/blacklist-hobot-iis.conf /lib/modprobe.d/blacklist-hobot-iis.disable

cp -v ./01_hobot_audio_module.conf /etc/modules-load.d/

echo "Setting pulseaudio config"
echo 
kill -9 $(pidof pulseaudio)
pulse_config="$file_prefix$file_suffix"
echo "$pulse_config"

if [ -f $pulse_config ]; then
    cp -v /etc/pulse/default.pa /etc/pulse/default.bak
    cp -v $pulse_config /etc/pulse/default.pa   
    echo "The original configuration file has been renamed default.bak"
    echo 
fi
sync
sync

echo -e "\e[31mUse the following command to reboot to apply the changes \e[0m"
echo 
echo -e "\e[31m sync && reboot \e[0m"
