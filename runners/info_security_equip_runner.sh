#!/bin/bash

# info_security_equip_runner.sh: Orchestrates the diagnosis process
set -euo pipefail
umask 077
cd "$(dirname "${BASH_SOURCE[0]}")/.."

PROFILE=""
CHECK_ID=""
DRY_RUN=true
VERIFY=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --profile)
            [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { echo "missing --profile value" >&2; exit 1; }
            PROFILE="$2"; shift ;;
        --check)
            # An explicitly empty value means "all checks for the profile"; a missing value is still an error
            [[ $# -ge 2 && "$2" != --* ]] || { echo "missing --check value" >&2; exit 1; }
            CHECK_ID="$2"; shift ;;
        --dry-run)
            [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { echo "missing --dry-run value" >&2; exit 1; }
            DRY_RUN="$2"; shift ;;
        --verify) VERIFY=true ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

case "$PROFILE" in fw|vpn|ids|ips|ddos|waf) ;; *) echo "Invalid profile" >&2; exit 1 ;; esac
if [[ -n "$CHECK_ID" && ! "$CHECK_ID" =~ ^ISE-[0-9]{3}$ ]]; then
    echo "Invalid check ID" >&2; exit 1
fi
CATALOG="info_security_equip_check_catalog.json"
RESULT_FILE="output/json/info_security_equip_assessment_result.json"

# Initialize Result File if not exists
if [[ ! -f "$RESULT_FILE" ]]; then
    mkdir -p "$(dirname "$RESULT_FILE")"
    echo "{\"results\": []}" > "$RESULT_FILE"
fi

# Validate catalog membership before executing any script.
CHECK_LIST=$(python3 - "$CATALOG" "$PROFILE" "$CHECK_ID" <<'EOF'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    catalog = json.load(f)
checks = [item['id'] for item in catalog if sys.argv[2] in item.get('profiles', [])]
if sys.argv[3]:
    if sys.argv[3] not in checks:
        raise SystemExit('Check is unknown or not applicable to this profile')
    checks = [sys.argv[3]]
if not checks:
    raise SystemExit('No applicable checks')
print('\n'.join(checks))
EOF
)
mapfile -t CHECKS <<< "$CHECK_LIST"

if [[ ${#CHECKS[@]} -eq 0 ]]; then
    echo "[ERROR] No checks found for profile: $PROFILE"
    exit 1
fi

echo "[*] Running ${#CHECKS[@]} checks for profile: $PROFILE"

ENTRY_FILE=""
cleanup_entry_file() {
    if [[ -n "$ENTRY_FILE" ]]; then
        rm -f "$ENTRY_FILE"
    fi
}
trap cleanup_entry_file EXIT

for cid in "${CHECKS[@]}"; do
    echo "[*] Running $cid for $PROFILE..."

    SCRIPT_PATH="shell_scirpt/info_security_equip/$PROFILE/$cid.sh"
    OUTPUT_DIR="output/evidence/info_security_equip/$PROFILE/$cid"
    mkdir -p "$OUTPUT_DIR"
    : > "$OUTPUT_DIR/stderr.txt"

    if [[ ! -f "$SCRIPT_PATH" ]]; then
        STATUS="NOT_IMPLEMENTED"
        REASON="Check script not found: $SCRIPT_PATH"
        echo "STATUS=$STATUS" > "$OUTPUT_DIR/stdout.txt"
        echo "REASON=$REASON" >> "$OUTPUT_DIR/stdout.txt"
        echo "0" > "$OUTPUT_DIR/exit_code.txt"
    else
        # Safety Check
        SAFETY_RC=0
        SAFETY_JSON=$(bash runners/safety_guard.sh "$SCRIPT_PATH" "$DRY_RUN") || SAFETY_RC=$?
        if [[ "$SAFETY_RC" -ne 0 ]] || echo "$SAFETY_JSON" | grep -q "ERROR"; then
            STATUS="ERROR"
            REASON=$(echo "$SAFETY_JSON" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
            echo "STATUS=$STATUS" > "$OUTPUT_DIR/stdout.txt"
            echo "REASON=$REASON" >> "$OUTPUT_DIR/stdout.txt"
            echo "1" > "$OUTPUT_DIR/exit_code.txt"
        else
            # Execute Script
            RC=0
            bash "$SCRIPT_PATH" "$PROFILE" > "$OUTPUT_DIR/stdout.txt" 2> "$OUTPUT_DIR/stderr.txt" || RC=$?
            echo "$RC" > "$OUTPUT_DIR/exit_code.txt"
        fi
    fi

    # Collect Evidence
    bash runners/evidence_collector.sh "$PROFILE" "$cid"

    # Serialize status and reason with a JSON encoder, not shell interpolation.
    EXIT_CODE=$(cat "$OUTPUT_DIR/exit_code.txt" 2>/dev/null || echo "1")


    # Record the result into the assessment result JSON
    ENTRY_FILE=$(mktemp)
    python3 - "$ENTRY_FILE" "$PROFILE" "$cid" "$SCRIPT_PATH" "$EXIT_CODE" "$OUTPUT_DIR" <<'EOF'
import json, os, sys

entry_file, profile, cid, script_path, exit_code, output_dir = sys.argv[1:7]
with open(os.path.join(output_dir, 'stdout.txt'), encoding='utf-8', errors='replace') as f:
    text = f.read()
fields = {}
for line in text.splitlines():
    key, sep, value = line.partition('=')
    if sep and key in ('STATUS', 'REASON'):
        fields[key] = value.rstrip('\r')
status_map = {
    '양호':'PASS', 'PASS':'PASS', 'pass':'PASS', 'OK':'PASS', '정상':'PASS',
    '취약':'FAIL', 'FAIL':'FAIL', 'fail':'FAIL', '위험':'FAIL', '미흡':'FAIL',
    '해당없음':'NA', 'N/A':'NA', 'NA':'NA',
    '수동점검':'MANUAL_REVIEW', '수동':'MANUAL_REVIEW', 'MANUAL':'MANUAL_REVIEW', 'MANUAL_REVIEW':'MANUAL_REVIEW',
    '증적없음':'EVIDENCE_MISSING', '근거없음':'EVIDENCE_MISSING', '파일없음':'EVIDENCE_MISSING', 'EVIDENCE_MISSING':'EVIDENCE_MISSING',
    '오류':'ERROR', 'ERROR':'ERROR', 'error':'ERROR',
    '미구현':'NOT_IMPLEMENTED', 'TODO':'NOT_IMPLEMENTED', 'NOT_IMPLEMENTED':'NOT_IMPLEMENTED',
}
norm = {'status': status_map.get(fields.get('STATUS'), 'MANUAL_REVIEW'),
        'reason': fields.get('REASON', 'Unknown or unparsable output')}
if int(exit_code) != 0:
    norm = {'status': 'ERROR', 'reason': 'Script exited with code ' + exit_code}
elif not text.strip():
    norm = {'status': 'MANUAL_REVIEW', 'reason': 'Script produced no output'}

evidence = []
if os.path.isdir(output_dir):
    evidence = sorted(
        os.path.join(output_dir, name)
        for name in os.listdir(output_dir)
        if os.path.isfile(os.path.join(output_dir, name))
    )

error_message = ""
stderr_file = os.path.join(output_dir, "stderr.txt")
if exit_code != "0" and os.path.isfile(stderr_file):
    with open(stderr_file, encoding="utf-8", errors="replace") as f:
        error_message = f.read()[:2000]

entry = {
    "profile": profile,
    "id": cid,
    "status": norm.get("status", "ERROR"),
    "reason": norm.get("reason", ""),
    "script": {"path": script_path, "exit_code": int(exit_code)},
    "evidence": evidence,
    "error_message": error_message,
}
with open(entry_file, "w", encoding="utf-8") as f:
    json.dump(entry, f, ensure_ascii=False)
EOF
    if ! python3 tools/update_result.py --result-file "$RESULT_FILE" --entry-file "$ENTRY_FILE" --catalog "$CATALOG"; then
        echo "[ERROR] could not record result for $PROFILE/$cid; aborting audit" >&2
        exit 1
    fi
    rm -f "$ENTRY_FILE"
    ENTRY_FILE=""
done

echo "[+] Audit completed for profile: $PROFILE"
echo "[+] Results recorded in $RESULT_FILE"

