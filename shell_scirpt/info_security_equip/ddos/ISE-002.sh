#!/bin/bash

# ISE-002: 원격 로그 서버 사용 여부
# Profile: {profile}

# Input Evidence
# - log_config.txt
# - syslog_config.txt
# - remote_log_server.txt

PROFILE=$1
EVIDENCE_DIR="input/evidence/info_security_equip/$PROFILE"

KEYWORDS=("syslog" "remote" "siem" "log-server" "loghost" "forward" "collector" "514" "6514")
FOUND_KEYWORDS=()

if [[ ! -d "$EVIDENCE_DIR" ]]; then
    echo "STATUS=EVIDENCE_MISSING"
    echo "REASON=증적 디렉터리가 존재하지 않음"
    exit 0
fi

# Search keywords in evidence files
for file in "log_config.txt" "syslog_config.txt" "remote_log_server.txt"; do
    if [[ -f "$EVIDENCE_DIR/$file" ]]; then
        for kw in "${KEYWORDS[@]}"; do
            if grep -qi "$kw" "$EVIDENCE_DIR/$file" 2>/dev/null; then
                FOUND_KEYWORDS+=("$kw")
            fi
        done
    fi
done

# Remove duplicates
UNIQUE_KEYWORDS=($(echo "${FOUND_KEYWORDS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

if [[ ${#UNIQUE_KEYWORDS[@]} -gt 0 ]]; then
    echo "STATUS=PASS"
    echo "REASON=원격 로그 전송 관련 설정 키워드(${UNIQUE_KEYWORDS[*]})가 발견됨"
    echo "EVIDENCE=Keywords found: ${UNIQUE_KEYWORDS[*]}"
else
    echo "STATUS=MANUAL_REVIEW"
    echo "REASON=로그 설정 증적은 존재하나 원격 전송 여부가 불분명함 (키워드 미발견)"
    echo "EVIDENCE=Checked files: log_config.txt, syslog_config.txt"
fi
