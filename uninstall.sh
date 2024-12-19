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



# lib
    wait_until_login() {
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

# After startup
(
    # Waiting for device login
        wait_until_login
    #
    
    # Whitelist cleanup
        dumpsys deviceidle whitelist | while read -r item; do
            app=$(echo "$item" | cut -f2 -d ',')
            [ -n "$app" ] && dumpsys deviceidle whitelist -"$app"
        done
    #
) &
#