#!/bin/bash
session_num=$1
session_name=$(tmux list-sessions -F '#{session_name}' | sed -n "${session_num}p")
if [ -n "$session_name" ]; then
    tmux switch-client -t "$session_name"
fi
