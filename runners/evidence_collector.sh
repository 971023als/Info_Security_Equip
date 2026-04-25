#!/bin/bash

# evidence_collector.sh: Collects and organizes evidence for each check

PROFILE=$1
CHECK_ID=$2
OUTPUT_BASE="output/evidence/info_security_equip/$PROFILE/$CHECK_ID"

mkdir -p "$OUTPUT_BASE"

# This script is called after execution to finalize the evidence directory
# Files like stdout.txt, stderr.txt, etc. are moved/copied here by the runner

# Sensitivity Masking (Simplified)
# In a real scenario, we would use sed to mask IPs/Passwds
mask_sensitive_data() {
    local file=$1
    if [[ -f "$file" ]]; then
        # Mask IP addresses (e.g., 192.168.1.1 -> 192.168.x.x)
        sed -r 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.x.x/g' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
}

mask_sensitive_data "$OUTPUT_BASE/stdout.txt"

# Update manifest (Placeholder logic)
MANIFEST="output/evidence/info_security_equip/evidence_manifest.json"
if [[ ! -f "$MANIFEST" ]]; then
    echo "[]" > "$MANIFEST"
fi

# Appending to manifest is tricky with bash only, but we'll try to keep it simple
# For Phase 0, we can just log the entry
echo "$(date '+%Y-%m-%dT%H:%M:%S') | $PROFILE | $CHECK_ID | Evidence Collected" >> "output/logs/evidence.log"
