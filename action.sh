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



# tools.temporary whitelist cleanup

echo "- Temporarily clear the doze whitelist."
echo "- Start running this in three seconds"
echo ""
sleep 3
echo "- Removing..."
dumpsys deviceidle whitelist | while read -r item; do
    app=$(echo "$item" | cut -f2 -d ',')
    if [ -n "$app" ]; then
        temp="$(dumpsys deviceidle whitelist -"$app" | grep -v Unknown)"
        [ "$temp" != "" ] && echo "- $temp"
        sleep 0.025
    fi
done
echo "- Remove done"
exit 0