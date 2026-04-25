#!/bin/bash

# info_security_equip_runner.sh: Orchestrates the diagnosis process

PROFILE=""
CHECK_ID=""
DRY_RUN=true
VERIFY=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --profile) PROFILE="$2"; shift ;;
        --check) CHECK_ID="$2"; shift ;;
        --dry-run) DRY_RUN="$2"; shift ;;
        --verify) VERIFY=true ;;
    esac
    shift
done

CATALOG="info_security_equip_check_catalog.json"
RESULT_FILE="output/json/info_security_equip_assessment_result.json"

# Initialize Result File if not exists
if [[ ! -f "$RESULT_FILE" ]]; then
    echo "{\"results\": []}" > "$RESULT_FILE"
fi

# Determine checks to run
if [[ -n "$CHECK_ID" ]]; then
    CHECKS=("$CHECK_ID")
else
    # In Phase 0, we just run 001, 002, 003
    CHECKS=("ISE-001" "ISE-002" "ISE-003")
fi

for cid in "${CHECKS[@]}"; do
    echo "[*] Running $cid for $PROFILE..."
    
    SCRIPT_PATH="shell_scirpt/info_security_equip/$PROFILE/$cid.sh"
    OUTPUT_DIR="output/evidence/info_security_equip/$PROFILE/$cid"
    mkdir -p "$OUTPUT_DIR"

    if [[ ! -f "$SCRIPT_PATH" ]]; then
        STATUS="NOT_IMPLEMENTED"
        REASON="Check script not found: $SCRIPT_PATH"
        echo "STATUS=$STATUS" > "$OUTPUT_DIR/stdout.txt"
        echo "REASON=$REASON" >> "$OUTPUT_DIR/stdout.txt"
        echo "0" > "$OUTPUT_DIR/exit_code.txt"
    else
        # Safety Check
        SAFETY_JSON=$(bash runners/safety_guard.sh "$SCRIPT_PATH" "$DRY_RUN")
        if echo "$SAFETY_JSON" | grep -q "ERROR"; then
            STATUS="ERROR"
            REASON=$(echo "$SAFETY_JSON" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
            echo "STATUS=$STATUS" > "$OUTPUT_DIR/stdout.txt"
            echo "REASON=$REASON" >> "$OUTPUT_DIR/stdout.txt"
            echo "1" > "$OUTPUT_DIR/exit_code.txt"
        else
            # Execute Script
            bash "$SCRIPT_PATH" "$PROFILE" > "$OUTPUT_DIR/stdout.txt" 2> "$OUTPUT_DIR/stderr.txt"
            echo $? > "$OUTPUT_DIR/exit_code.txt"
        fi
    fi

    # Normalize Result
    NORM_JSON=$(bash runners/result_normalizer.sh "$OUTPUT_DIR/stdout.txt" "$OUTPUT_DIR/stderr.txt" "$OUTPUT_DIR/exit_code.txt")
    
    # Collect Evidence
    bash runners/evidence_collector.sh "$PROFILE" "$cid"

    # Log Final Result
    STATUS=$(echo "$NORM_JSON" | sed -n 's/.*"status": "\([^"]*\)".*/\1/p')
    REASON=$(echo "$NORM_JSON" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
    echo -e "    -> STATUS: $STATUS ($REASON)"
    
    # In a real tool, we would update the result JSON here. 
    # For Phase 0, we'll just keep the stdout/stderr files as evidence.
done

echo "[+] Audit completed for profile: $PROFILE"
