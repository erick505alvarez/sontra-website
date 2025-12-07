#!/bin/bash
# Secure wrapper - passes through env vars and validates command

# Get the full command
CMD="$SSH_ORIGINAL_COMMAND"

# If no command, run deploy.sh normally
if [ -z "$CMD" ]; then
    exec /home/deployer/deploy.sh
fi

# Extract environment variables and export them
if echo "$CMD" | grep -q "RESEND_API_KEY="; then
    export RESEND_API_KEY=$(echo "$CMD" | grep -oP 'RESEND_API_KEY="\K[^"]+')
fi

if echo "$CMD" | grep -q "RESEND_EMAIL_DOMAIN="; then
    export RESEND_EMAIL_DOMAIN=$(echo "$CMD" | grep -oP 'RESEND_EMAIL_DOMAIN="\K[^"]+')
fi

if echo "$CMD" | grep -q "TARGET_INBOX="; then
    export TARGET_INBOX=$(echo "$CMD" | grep -oP 'TARGET_INBOX="\K[^"]+')
fi

# Extract the actual command (everything after the last env var)
SCRIPT_CMD=$(echo "$CMD" | sed 's/.*TARGET_INBOX="[^"]*" *//')

# Validate and execute
case "$SCRIPT_CMD" in
    /home/deployer/deploy.sh|./deploy.sh|deploy.sh)
        exec /home/deployer/deploy.sh
        ;;
    "/home/deployer/deploy.sh --force"|"./deploy.sh --force"|"deploy.sh --force")
        exec /home/deployer/deploy.sh --force
        ;;
    "/home/deployer/deploy.sh -f"|"./deploy.sh -f"|"deploy.sh -f")
        exec /home/deployer/deploy.sh -f
        ;;
    *)
        echo "Error: Command not allowed"
        echo "Extracted command: $SCRIPT_CMD"
        echo "Original: $CMD"
        exit 1
        ;;
esac