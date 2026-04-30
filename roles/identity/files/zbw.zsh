#!/usr/bin/env zsh

# Function to display usage
usage() {
    echo "Usage: $0 [password|fields] [output|completion]"
    echo ""
    echo "First argument - what to get:"
    echo "  password - Get/generate command for password"
    echo "  fields   - Get/generate command for field value"
    echo ""
    echo "Second argument - how to return it:"
    echo "  output     - Return the actual value"
    echo "  completion - Return the command to get the value"
    exit 1
}

# Check if both arguments are provided
if [[ $# -ne 2 ]]; then
    usage
fi

MODE="$1"
RETURN_TYPE="$2"

# Validate arguments
if [[ "$MODE" != "password" && "$MODE" != "fields" ]]; then
    echo "Error: Invalid first argument. Use 'password' or 'fields'" >&2
    usage
fi

if [[ "$RETURN_TYPE" != "output" && "$RETURN_TYPE" != "completion" ]]; then
    echo "Error: Invalid second argument. Use 'output' or 'completion'" >&2
    usage
fi

# Get list of entries and let user select one
echo "Select an entry:" >&2
ENTRY=$(rbw list | fzf --prompt="Select entry: ")

# Check if user made a selection
if [[ -z "$ENTRY" ]]; then
    echo "No entry selected. Exiting." >&2
    exit 1
fi

case "$MODE" in
    "password")
        if [[ "$RETURN_TYPE" == "completion" ]]; then
            # Return the command to get password
            echo "rbw get \"$ENTRY\""
        else
            # Get the actual password
            PASSWORD=$(rbw get "$ENTRY" 2>/dev/null)
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to get password for entry '$ENTRY'" >&2
                exit 1
            fi
            echo "$PASSWORD"
        fi
        ;;
    
    "fields")
        # For fields mode, we need to get the raw data first to show field options
        JSON_DATA=$(rbw get "$ENTRY" --raw 2>/dev/null)
        
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to get data for entry '$ENTRY'" >&2
            exit 1
        fi
        
        # Get list of field names and let user select one
        FIELD_NAMES=$(echo "$JSON_DATA" | jq -r '.fields[]? | .name' 2>/dev/null)
        
        if [[ -z "$FIELD_NAMES" ]]; then
            echo "No custom fields found for this entry" >&2
            exit 1
        fi
        
        echo "Select a field:" >&2
        SELECTED_FIELD=$(echo "$FIELD_NAMES" | fzf --prompt="Select field: ")
        
        if [[ -z "$SELECTED_FIELD" ]]; then
            echo "No field selected. Exiting." >&2
            exit 1
        fi
        
        if [[ "$RETURN_TYPE" == "completion" ]]; then
            # Return the command to get the field value
            echo "rbw get \"$ENTRY\" --raw | jq -r '.fields[] | select(.name == \"$SELECTED_FIELD\") | .value'"
        else
            # Get the actual field value
            FIELD_VALUE=$(echo "$JSON_DATA" | jq -r --arg field "$SELECTED_FIELD" '.fields[]? | select(.name == $field) | .value // empty')
            
            if [[ -n "$FIELD_VALUE" ]]; then
                echo "$FIELD_VALUE"
            else
                echo "No value found for field '$SELECTED_FIELD'" >&2
                exit 1
            fi
        fi
        ;;
esac
