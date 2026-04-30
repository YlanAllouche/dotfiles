#!/bin/bash

OBSIDIAN_URI="obsidian://advanced-uri"
VAULT_NAME="share"  # Replace with your Obsidian vault name
# REMOTE_HOST="your_remote_host"  # Replace with your remote host
# REMOTE_USER="your_remote_user"  # Replace with your remote user (optional, if using ssh keys)

JS_CODE='let tp = app.plugins.plugins["templater-obsidian"].templater.current_functions_object; tp.user.marshallAllQueries(tp); tp.user.nvimDashboard(tp);'
# JS_CODE='let tp = app.plugins.plugins["templater-obsidian"].templater.current_functions_object; tp.user.nvimDashboard(tp);'

ENCODED_JS_CODE=$(echo "$JS_CODE" | jq -sRr @uri)

URI="$OBSIDIAN_URI?vault=$VAULT_NAME&eval=$ENCODED_JS_CODE"

# ssh $REMOTE_USER@$REMOTE_HOST obsidian $URI
obsidian $URI
