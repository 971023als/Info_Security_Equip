#!/bin/bash

# safety_guard.sh: Blocks unsafe commands in audit mode

SCRIPT_PATH=$1
AUDIT_ONLY=$2

if [[ -z "$SCRIPT_PATH" ]]; then
    echo "{\"status\": \"ERROR\", \"reason\": \"No script path provided to safety_guard\"}"
    exit 1
fi

# Phase 0 Forbidden commands
FORBIDDEN_COMMANDS=(
    "configure terminal" "conf t" "set " "delete " "unset " "commit" "save" 
    "write memory" "reload" "reboot" "shutdown" "restart" "factory-reset" 
    "clear config" "iptables -A" "iptables -D" "firewall-cmd --add" 
    "firewall-cmd --remove" "systemctl restart" "systemctl stop" 
    "service restart" "service stop" "rm -rf" "sed -i" "chmod 777" "chown" 
    "scp" "sftp" "ssh " "telnet " "curl -X POST" "curl -X PUT" 
    "curl -X DELETE" "kubectl apply" "kubectl delete" "docker stop" "docker rm"
)

UNSAFE_FOUND=""

for cmd in "${FORBIDDEN_COMMANDS[@]}"; do
    if grep -q "$cmd" "$SCRIPT_PATH" 2>/dev/null; then
        UNSAFE_FOUND="$cmd"
        break
    fi
done

if [[ -n "$UNSAFE_FOUND" ]]; then
    echo "{\"status\": \"ERROR\", \"reason\": \"Unsafe command detected in audit mode\", \"unsafe_command\": \"$UNSAFE_FOUND\", \"audit_only\": $AUDIT_ONLY}"
    exit 1
fi

echo "{\"status\": \"SAFE\"}"
exit 0
