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
#

# lib
    wait_until_ready() {
        while true; do
            sleep 10
            [ "$(getprop sys.boot_completed)" = "1" ] && break
        done
        while true; do
            sleep 10
            [ -d "/sdcard/Android" ] && break
        done
        while true; do
            sleep 10
            [ "$(dumpsys window | grep mDreamingLockscreen=true)" = "" ] && break
        done
    }
#

# Waiting for device start
    wait_until_ready
#

# After startup
    sh "$MODDIR"/after.sh >"$MODDIR"/run.log 2>&1 &
    logcat | nohup grep lowmemorykiller >"$MODDIR"/lmkd.log 2>&1 &
#
