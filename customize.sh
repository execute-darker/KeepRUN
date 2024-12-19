#!/bin/sh



#           <Keep the all application tasks in the background>
#                Copyright (C) <2024>  <execute_darker>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.



# Global variables
    MODS_PATH="/data/adb/modules"
#

#lib
    newcp() {
        # shellcheck disable=SC2153
        cp -af "$MODPATH"/bin/sdk"$1"/lmkd "$MODPATH"/system/bin/lmkd
        rm -rf "$MODPATH"/bin/sdk* "$MODS_PATH"/lmkd_hook "$MODPATH"/system/bin/empty
        set_perm_recursive "$MODPATH"/bin 0 0 0755 0755
        set_perm_recursive "$MODPATH"/system/bin 0 2000 0755 0755
    }
#
ui_print '- *******************************
  _  __               ____  _   _ _   _ 
 | |/ /___  ___ _ __ |  _ \| | | | \ | |
 | " // _ \/ _ \ "_ \| |_) | | | |  \| |
 | . \  __/  __/ |_) |  _ <| |_| | |\  |
 |_|\_\___|\___| .__/|_| \_\\___/|_| \_|
               |_|
- *******************************

- 𝕂𝕖𝕖𝕡ℝ𝕌ℕ - Keep the all application tasks in the background. '
echo "
- Version: $(grep_prop version "$MODPATH"/module.prop)
- Author: $(grep_prop author "$MODPATH"/module.prop)
- *******************************
"

ui_print "- Check environment..."

# Check environment

    [ -n "$KSU" ] && abort "


- ! Not support KernelSU

- *******************************
"

    [ "$ARCH" != "arm64" ] && abort "


- ! Only support aarch64 architecture

- *******************************
"

    [ "$API" != "33" ] && [ "$API" != "34" ] && abort "


- ! Only supports Android-SDK 33-34 version

- *******************************
"

    if [ "$(getprop ro.hardware)" = "qcom" ]; then

        ui_print "


- ! Qualcomm devices maybe boot fail, Are you sure?

- *******************************

[ VOL+ ] = [ Continue ]
[ VOL- ] = [ Exit ]

- *******************************
"

        while true; do
            keys=$(getevent -lqc1)

            if echo "$keys" | grep -q 'KEY_VOLUMEUP.*DOWN'; then
                break
            elif echo "$keys" | grep -q 'KEY_VOLUMEDOWN.*DOWN'; then
                abort "- Exit install"
            fi
        done
    fi

    awk -v FS='=' '{print $1}' "$MODPATH/system.prop" | while IFS= read -r list; do
        [ -z "$list" ] && continue    
        grep -l "$list" "$MODS_PATH"/../*/*/system.prop | while IFS= read -r files; do
            [ -z "$files" ] && continue     
            if [ "$(echo "$files" | grep -c "$(grep_prop "id" "$MODPATH"/module.prop)")" -eq 0 ] && [ -n "$(grep_prop "$list" "$files")" ]; then
                echo "- Remove duplicate system prop settings in $files: $list"
                sed -i "/^$list/d" "$files"
            fi
        done
    done

    find "$MODS_PATH/.." -name "lmkd" | while IFS= read -r i; do
        [ -z "$i" ] && continue    
        if [ "$(echo "$i" | grep -c "$(grep_prop "id" "$MODPATH"/module.prop)")" -eq 0 ]; then
            echo "- Remove duplicate lmkd bin in $i"
            rm -rf "$i"
        fi
    done
#

ui_print "- Check environment...done"

# Copy files
    if [ "$API" = "33" ]; then
        newcp 33
    else
        newcp 34
    fi
#

ui_print "- Adding app to doze whitelist..."

# Add whitelist
    all_apps=$(awk -v FS=' ' '{print $1}' </data/system/packages.list)
    whitelisted_apps=$(dumpsys deviceidle whitelist | cut -f2 -d ',')
    for app in $all_apps; do
        if [ "$(echo "$whitelisted_apps" | grep "$app")" = "" ]; then
            temp="$(dumpsys deviceidle whitelist +"$app" | grep -v Unknown)"
            [ "$temp" != "" ] && echo "- $temp"
            sleep 0.025
        fi
    done
#

ui_print "- Add whitelist...done"

ui_print "- All the done"