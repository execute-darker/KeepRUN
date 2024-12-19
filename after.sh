#!/bin/sh



#           <Keep the all application tasks in the background>
#            Copyright (C) <2024>  <execute_darker>
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
    MODDIR="${0%/*}"
    flag_debug="1"
#

# lib
    # $1:value $2:path
    lock_val() {
        [ -z "$2" ] && return 0
        find "$2" | while read -r file; do
            umount "$file" 2>/dev/null
            chmod +w "$file" 2>/dev/null
            if [ "$flag_debug" = "1" ]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')]------lock_val-dbg-------"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')]- Dir:$file"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')]- Last val:$(cat "$file")"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')]- Update val:$1"
            fi
            echo "$1" >"$file" 2>/dev/null
            chmod -w "$file" 2>/dev/null
            restorecon -R -F "$file" 2>/dev/null
            [ "$flag_debug" = "1" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')]- Now val:$(cat "$file")"
            TIME=$(date +"%s%N")
            if [ "$3" != "" ]; then
                echo "$3" >/dev/mount_mask_"$TIME"
            else
                echo "$1" >/dev/mount_mask_"$TIME"
            fi
            mount --bind /dev/mount_mask_"$TIME" "$file" 2>/dev/null
            if [ "$flag_debug" = "1" ]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')]- Now mount val:$(cat "$file")"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')]-------------------------"
            fi
        done
    }
    
    grep_prop() {
        REGEX="s/^$1=//p"
        shift
        FILES="$(printf '%s\n' "$@")"
        [ -z "$FILES" ] && FILES='/system/build.prop'
        first_file="$(echo "$FILES" | head -n 1)"
        < "$first_file" dos2unix | sed -n "$REGEX" | head -n 1
    }
#

# Check environment
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]------------Check environment-------------"
    awk -v FS='=' '{print $1}' "$MODDIR/system.prop" | while IFS= read -r list; do
        [ -z "$list" ] && continue
        grep -l "$list" "$MODDIR"/../../*/*/system.prop | while IFS= read -r files; do
            [ -z "$files" ] && continue
            if [ "$(echo "$files" | awk -v FS='/../../' '{print $2}' | grep -c "$(grep_prop "id" "$MODDIR"/module.prop)")" -eq 0 ] && [ -n "$(grep_prop "$list" "$files")" ]; then
                echo "- Remove duplicate system prop settings in $files: $list"
                sed -i "/^$list/d" "$files"
            fi
        done
    done

    find "$MODDIR/../.." -name "lmkd" | while IFS= read -r i; do
        [ -z "$i" ] && continue
        if [ "$(echo "$i" | awk -v FS='/../../' '{print $2}' | grep -c "$(grep_prop "id" "$MODDIR"/module.prop)")" -eq 0 ]; then
            echo "- Remove duplicate lmkd bin in $i"
            rm -rf "$i"
        fi
    done
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]------------Check environment---------done"
#

echo ""

# Restart lmkd
    stop lmkd
    start lmkd
    logcat | nohup grep lowmemorykiller >"$MODDIR"/lmkd.log 2>&1 &
#

# Reset Settings
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]----------Reset Settings----------"
    lock_val "200" /proc/sys/vm/swappiness
    lock_val "0" /proc/sys/vm/extra_free_kbytes
    lock_val "1" /proc/sys/vm/watermark_scale_factor
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]----------Reset Settings------done"
#

echo ""

# Injection lmkd
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]----------Start Injection---------"
    nohup "$MODDIR"/bin/inject -p "$(pidof lmkd)" -so "$(realpath "$MODDIR"/bin/hookLib.so)" -symbols hook_lmkd
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]------------Injection---------done"
#

echo ""

# Add whitelist
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]----------Add new app to doze whitelist----------"
    all_apps=$(awk -v FS=' ' '{print $1}' </data/system/packages.list)
    whitelisted_apps=$(dumpsys deviceidle whitelist | cut -f2 -d ',')  
    for app in $all_apps; do
        if [ "$(echo "$whitelisted_apps" | grep "$app")" = "" ]; then
            dumpsys deviceidle whitelist +"$app" | grep -v Unknown
        fi
    done
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]----------Add new app to doze whitelist------done"
#

echo "[$(date '+%Y-%m-%d %H:%M:%S')]: All the done"
