#!/bin/bash
echo "Undo automatic boot-up driver loading..."
echo

directory="/lib/modprobe.d"
for file in "$directory"/*.disable; do
    if [ -f "$file" ]; then
        new_name="${file%.disable}.conf"
        mv -v "$file" "$new_name"
    fi
done

rm -fv /etc/modules-load.d/01_hobot_audio_module.conf

echo "Restore pulseaudio configuration..."
echo

if [ -f /etc/pulse/default.bak ]; then
    mv -v /etc/pulse/default.bak /etc/pulse/default.pa  
fi

sync
sync

echo -e "\e[31mChanges will be applied on next boot\e[0m"
echo