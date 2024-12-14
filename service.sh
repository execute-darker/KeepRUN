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

# Waiting for lmkd start
until pidof lmkd; do
	sleep 1
done

stop lmkd
start lmkd

nohup "$MODDIR"/bin/inject -p "$(pidof lmkd)" -so "$(realpath "$MODDIR"/bin/hookLib.so)" -symbols hook_lmkd

for app in $(pm list packages | awk -F':' '{print $2}'); do
    dumpsys deviceidle whitelist +"$app"
done
