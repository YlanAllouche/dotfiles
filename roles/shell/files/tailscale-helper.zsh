#!/usr/bin/env zsh

# Function to display usage
usage() {
    echo "Usage: $0 [ip|hostname|ssh|exit-node]"
    echo ""
    echo "  ip       - Select device and return its IP"
    echo "  hostname - Select device and return its hostname"
    echo "  ssh      - Select device and execute SSH connection"
    echo "  exit-node - Select and set exit node (includes 'none' option)"
    exit 1
}

# Check if argument is provided
if [[ $# -ne 1 ]]; then
    usage
fi

MODE="$1"

# Validate argument
if [[ "$MODE" != "ip" && "$MODE" != "hostname" && "$MODE" != "ssh" && "$MODE" != "exit-node" ]]; then
    echo "Error: Invalid argument. Use 'ip', 'hostname', 'ssh', or 'exit-node'" >&2
    usage
fi

case "$MODE" in
    "ip"|"hostname"|"ssh")
        # Get tailscale status and parse for selection
        STATUS_OUTPUT=$(tailscale status 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to get tailscale status" >&2
            exit 1
        fi
        
        # Parse status output (skip header, get IP and hostname, exclude self)
        DEVICE_LIST=$(echo "$STATUS_OUTPUT" | awk 'NR>1 && !/^\s*$/ && $1 !~ /^100\..*/ || NR>1 && !/^\s*$/ && !($0 ~ /\s+[a-zA-Z0-9-]+\s+[a-zA-Z0-9-]+\s+.*\s+self\s*$/) {print $1 "\t" $2}')
        
        if [[ -z "$DEVICE_LIST" ]]; then
            echo "No devices found in tailscale status" >&2
            exit 1
        fi
        
        # Let user select device
        echo "Select a device:" >&2
        SELECTED=$(echo "$DEVICE_LIST" | fzf --prompt="Select device: " --with-nth=2 --delimiter='\t')
        
        if [[ -z "$SELECTED" ]]; then
            echo "No device selected. Exiting." >&2
            exit 1
        fi
        
        # Extract IP and hostname
        DEVICE_IP=$(echo "$SELECTED" | cut -f1)
        DEVICE_HOSTNAME=$(echo "$SELECTED" | cut -f2)
        
        case "$MODE" in
            "ip")
                echo "$DEVICE_IP"
                ;;
            "hostname")
                echo "$DEVICE_HOSTNAME"
                ;;
            "ssh")
                echo -n "Enter username: " >&2
                read SSH_USERNAME
                if [[ -z "$SSH_USERNAME" ]]; then
                    echo "No username provided. Exiting." >&2
                    exit 1
                fi
                echo "Connecting to $SSH_USERNAME@$DEVICE_HOSTNAME..." >&2
                exec ssh "$SSH_USERNAME@$DEVICE_HOSTNAME"
                ;;
        esac
        ;;
        
    "exit-node")
        # Get exit node list
        EXIT_NODES=$(tailscale exit-node list 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to get exit node list" >&2
            exit 1
        fi
        
        # Parse exit nodes (skip header line, get IP and create display format)
        PARSED_NODES=$(echo "$EXIT_NODES" | awk 'NR>1 && !/^\s*$/ && $1 ~ /^100\./ {
            # Create a display string: IP - HOSTNAME (COUNTRY, CITY)
            display = $1 " - " $2
            if ($3 != "-") display = display " (" $3
            if ($4 != "-" && $4 != $3) display = display ", " $4
            if ($3 != "-") display = display ")"
            print $1 "\t" display
        }')
        
        if [[ -z "$PARSED_NODES" ]]; then
            echo "No exit nodes found" >&2
            exit 1
        fi
        
        # Add "none" option at the top
        EXIT_NODE_LIST="none\tDisable exit node"$'\n'"$PARSED_NODES"
        
        # Let user select exit node
        echo "Select an exit node:" >&2
        SELECTED_NODE=$(echo "$EXIT_NODE_LIST" | fzf --prompt="Select exit node: " --with-nth=2 --delimiter='\t')
        
        if [[ -z "$SELECTED_NODE" ]]; then
            echo "No exit node selected. Exiting." >&2
            exit 1
        fi
        
        # Extract the IP/identifier
        NODE_IP=$(echo "$SELECTED_NODE" | cut -f1)
        
        if [[ "$NODE_IP" == "none" ]]; then
            # Disable exit node
            echo "Disabling exit node..." >&2
            tailscale set --exit-node= --accept-dns=false
            if [[ $? -eq 0 ]]; then
                echo "Exit node disabled successfully"
            else
                echo "Error: Failed to disable exit node" >&2
                exit 1
            fi
        else
            # Set the selected exit node
            echo "Setting exit node to $NODE_IP..." >&2
            tailscale set --exit-node="$NODE_IP" --accept-dns=true
            if [[ $? -eq 0 ]]; then
                echo "Exit node set to $NODE_IP successfully"
            else
                echo "Error: Failed to set exit node" >&2
                exit 1
            fi
        fi
        ;;
esac
