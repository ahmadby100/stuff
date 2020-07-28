#!/bin/bash

until ! screen -list | grep -q "yt" &> /dev/null
do
    sleep 60
done


/usr/bin/screen -d -m -S ytup /bin/bash /home/amady/scripts/upload.sh