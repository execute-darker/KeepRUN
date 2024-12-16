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
    MODDIR="${0%/*}"
    flag_debug="1"
#

# lib
    lock_val() {
        for p in $2; do
            if [ -f "$p" ]; then
                umount "$p" 2>/dev/null
                chown root:root "$p" 2>/dev/null
                chmod 0666 "$p" 2>/dev/null
                if [ "$flag_debug" = "1" ]; then
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')]----------debug----------"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')]dir:$p"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')]last val:$(cat $p)"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')]update val:$1"
                fi
                echo "$1" >"$p" 2>/dev/null
                chmod 0444 "$p" 2>/dev/null
                restorecon -R -F "$p" 2>/dev/null
                [ "$flag_debug" = "1" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')]now val:$(cat $p)"
                local TIME=$(date +"%s%N")
                if [ "$3" != "" ]; then
                    echo "$3" >/dev/mount_mask_$TIME 2>/dev/null
                else
                    echo "$1" >/dev/mount_mask_$TIME 2>/dev/null
                fi
                mount --bind /dev/mount_mask_$TIME "$p" 2>/dev/null
                if [ "$flag_debug" == "1" ]; then
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')]now mount val:$(cat $p)"
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')]-------------------------"
                fi
                rm -rf /dev/mount_mask_$TIME
            fi
        done
    }
#

# restart lmkd
    stop lmkd
    start lmkd
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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]----------Adding whitelist----------"
    for app in $(cat /data/system/packages.list | awk -v FS=' ' '{print $1}'); do
        dumpsys deviceidle whitelist +"$app"
    done
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]----------Adding whitelist------done"
#

echo "[$(date '+%Y-%m-%d %H:%M:%S')]: All the done"