#! /bin/bash

playlist=$(wofi -d -p "Select JSON file" < <(find ~/share/_tmp -maxdepth 1 -type f -name "*.json" | sed -E 's/.*\///; s/\.json$//; s/_/ /g' | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1' | paste -d'\n' <(find ~/share/_tmp -maxdepth 1 -type f -name "*.json")))

jelly_play_yt $(video-picker.py $playlist)
