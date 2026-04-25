#!/bin/bash

# ISE-001: 보안장비 정책 및 로그 백업 설정 여부
# Profile: {profile}

# Input Evidence
# - backup_config.txt
# - backup_policy.txt
# - backup_log.txt

PROFILE=$1
EVIDENCE_DIR="input/evidence/info_security_equip/$PROFILE"

echo "STATUS=MANUAL_REVIEW"
echo "REASON=백업 관련 증적 파일 존재 여부 확인 중"

FILES=("backup_config.txt" "backup_policy.txt" "backup_log.txt")
FOUND_COUNT=0

for file in "${FILES[@]}"; do
    if [[ -s "$EVIDENCE_DIR/$file" ]]; then
        ((FOUND_COUNT++))
    fi
done

if [[ $FOUND_COUNT -eq 3 ]]; then
    echo "STATUS=PASS"
    echo "REASON=모든 필수 백업 증적 파일($FOUND_COUNT/3)이 존재하며 내용이 있음"
    echo "EVIDENCE=${FILES[*]}"
elif [[ $FOUND_COUNT -gt 0 ]]; then
    echo "STATUS=MANUAL_REVIEW"
    echo "REASON=일부 백업 증적 파일($FOUND_COUNT/3)만 존재함. 백업 주기 및 보관 상태 수동 확인 필요"
    echo "EVIDENCE=Found: $FOUND_COUNT files"
else
    echo "STATUS=EVIDENCE_MISSING"
    echo "REASON=필수 백업 증적 파일이 존재하지 않거나 비어 있음"
    echo "EVIDENCE=Missing: ${FILES[*]}"
fi
