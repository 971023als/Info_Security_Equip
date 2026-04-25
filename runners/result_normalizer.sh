#!/bin/bash

# result_normalizer.sh: Standardizes script output into standard statuses

STDOUT_FILE=$1
STDERR_FILE=$2
EXIT_CODE_FILE=$3

EXIT_CODE=$(cat "$EXIT_CODE_FILE" 2>/dev/null || echo "1")
STDOUT_CONTENT=$(cat "$STDOUT_FILE" 2>/dev/null)
STDERR_CONTENT=$(cat "$STDERR_FILE" 2>/dev/null)

STATUS="MANUAL_REVIEW"
REASON="Unknown error or unparsable output"

# Parse status from stdout
if grep -q "STATUS=" "$STDOUT_FILE" 2>/dev/null; then
    RAW_STATUS=$(grep "STATUS=" "$STDOUT_FILE" | tail -1 | cut -d'=' -f2 | tr -d '\r')
    case $RAW_STATUS in
        양호|PASS|pass|OK|정상) STATUS="PASS" ;;
        취약|FAIL|fail|위험|미흡) STATUS="FAIL" ;;
        해당없음|N/A|NA) STATUS="NA" ;;
        수동점검|수동|MANUAL|MANUAL_REVIEW) STATUS="MANUAL_REVIEW" ;;
        증적없음|근거없음|파일없음|EVIDENCE_MISSING) STATUS="EVIDENCE_MISSING" ;;
        오류|ERROR|error) STATUS="ERROR" ;;
        미구현|TODO|NOT_IMPLEMENTED) STATUS="NOT_IMPLEMENTED" ;;
        *) STATUS="MANUAL_REVIEW" ;;
    esac
fi

# Parse reason from stdout
if grep -q "REASON=" "$STDOUT_FILE" 2>/dev/null; then
    REASON=$(grep "REASON=" "$STDOUT_FILE" | tail -1 | cut -d'=' -f2- | tr -d '\r')
fi

# Override rules
if [[ $EXIT_CODE -ne 0 ]]; then
    STATUS="ERROR"
    REASON="Script exited with non-zero code ($EXIT_CODE). Error: $STDERR_CONTENT"
fi

if [[ -z "$STDOUT_CONTENT" && $EXIT_CODE -eq 0 ]]; then
    STATUS="MANUAL_REVIEW"
    REASON="Script produced no output but exited successfully"
fi

# Demote PASS to EVIDENCE_MISSING if it's suspicious (handled here or in runner)

echo "{\"status\": \"$STATUS\", \"reason\": \"$REASON\"}"
