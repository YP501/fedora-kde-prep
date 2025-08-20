export SSH_ASKPASS="${SSH_ASKPASS:-/usr/bin/ksshaskpass}"

# Start an agent if none exists for this user
if ! pgrep -u "$USER" -x ssh-agent >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
    {
        printf 'SSH_AUTH_SOCK=%s\n' "$SSH_AUTH_SOCK"
        printf 'SSH_AGENT_PID=%s\n' "$SSH_AGENT_PID"
        printf 'export SSH_AUTH_SOCK SSH_AGENT_PID\n'
    } > "$HOME/.ssh-agent-info"
fi

# If our env vars aren’t set yet, try the saved ones
if [ -z "$SSH_AGENT_PID" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
    [ -r "$HOME/.ssh-agent-info" ] && . "$HOME/.ssh-agent-info"
fi
