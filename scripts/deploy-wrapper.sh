#!/bin/bash
# Secure wrapper - handles both inline and export-style env vars

# Get the full command
CMD="$SSH_ORIGINAL_COMMAND"

# If no command, run deploy.sh normally
if [ -z "$CMD" ]; then
    exec /home/deployer/deploy.sh
fi

# Extract and export environment variables (handles both formats)
# Format 1: VAR="value" (manual SSH)
# Format 2: export VAR="value" (GitHub Actions)

if echo "$CMD" | grep -q "RESEND_API_KEY="; then
    RESEND_API_KEY=$(echo "$CMD" | grep -oP 'RESEND_API_KEY="\K[^"]+' | head -1)
    export RESEND_API_KEY
fi

if echo "$CMD" | grep -q "RESEND_EMAIL_DOMAIN="; then
    RESEND_EMAIL_DOMAIN=$(echo "$CMD" | grep -oP 'RESEND_EMAIL_DOMAIN="\K[^"]+' | head -1)
    export RESEND_EMAIL_DOMAIN
fi

if echo "$CMD" | grep -q "TARGET_INBOX="; then
    TARGET_INBOX=$(echo "$CMD" | grep -oP 'TARGET_INBOX="\K[^"]+' | head -1)
    export TARGET_INBOX
fi

# Extract the actual script command (last line that mentions deploy.sh)
SCRIPT_CMD=$(echo "$CMD" | grep -oP '(bash |/bin/bash )?(/home/deployer/)?deploy\.sh.*$' | tail -1)

# Normalize the command (remove bash prefix if present)
SCRIPT_CMD=$(echo "$SCRIPT_CMD" | sed 's/^bash *//' | sed 's/^\/bin\/bash *//')

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
        echo "Extracted command: '$SCRIPT_CMD'"
        echo "Original: $CMD"
        exit 1
        ;;
esac