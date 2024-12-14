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
    sdk="$(getprop ro.build.version.sdk)"
#

#lib
    grep_prop() {
        REGEX="s/^$1=//p"
        shift
        FILES="$(printf '%s\n' "$@")"
        [ -z "$FILES" ] && FILES='/system/build.prop'
        first_file="$(echo "$FILES" | head -n 1)"
        < "$first_file" dos2unix | sed -n "$REGEX" | head -n 1
    }
    
    newcp() {
        cp -af "$MODS_PATH"/KeepRUN/bin/sdk"$1"/lmkd "$MODS_PATH"/KeepRUN/system/bin/lmkd
        # shellcheck disable=SC2153
        cp -af "$MODPATH"/bin/sdk"$1"/lmkd "$MODPATH"/system/bin/lmkd
        rm -rf "$MODS_PATH"/KeepRUN/bin/sdk* "$MODPATH"/bin/sdk* "$MODS_PATH"/lmkd_hook "$MODS_PATH"/KeepRUN/system/bin/empty "$MODPATH"/system/bin/empty
    }
#

# Check the environment
    [ "$KSU" ] && abort "- Not support KernelSU"

    [ "$ARCH" != "arm64" ] && abort "- Only support aarch64 architecture"

    [ "$sdk" != "33" ] && [ "$sdk" != "34" ] && \
    abort "- Only supports Android-SDK 33-34 version"

    awk -F '=' '{print $1}' "$MODPATH/system.prop" | while IFS= read -r list; do
        [ -z "$list" ] && continue    
        grep -l "$list" "$MODS_PATH"/*/system.prop | while IFS= read -r files; do
            [ -z "$files" ] && continue     
            if [ "$(echo "$files" | grep -c "KeepRUN")" -eq 0 ] && [ -n "$(grep_prop "$list" "$files")" ]; then
                echo "Remove duplicate system prop settings in $files: $list"
                sed -i "/^$list/d" "$files"
            fi
        done
    done

    find "$MODS_PATH" -name "lmkd" | while IFS= read -r i; do
        [ -z "$i" ] && continue    
        if [ "$(echo "$i" | grep -c "KeepRUN")" -eq 0 ]; then
            echo "Remove duplicate lmkd bin in $i"
            rm -rf "$i"
        fi
    done
#

# Set permissions
    # shellcheck disable=SC2153
    rm -rf "$MODPATH"/customize.sh; cp -af "$MODPATH" "$MODS_PATH"
    chown -R root:root "$MODS_PATH" "$MODPATH"
    chmod -R 775 "$MODS_PATH" "$MODPATH"
    chmod +x "$MODS_PATH"
#

# Copy files
    if [ "$sdk" = "33" ]; then
        newcp 33
    else
        newcp 34
    fi
#


# Add list
    for app in $(pm list packages | awk -F':' '{print $2}'); do
        echo "Adding $app to doze whitelist..."
        dumpsys deviceidle whitelist +"$app"
        sleep 0.035
    done
#

echo "All the done"