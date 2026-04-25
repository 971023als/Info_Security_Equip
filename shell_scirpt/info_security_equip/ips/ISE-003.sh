#!/bin/bash

# ISE-003: DMZ 구간 설정 여부
# Profile: {profile}

# Applicable: fw, vpn
# NA: ids, ips, ddos, waf

PROFILE=$1
EVIDENCE_DIR="input/evidence/info_security_equip/$PROFILE"

# Check applicability
if [[ "$PROFILE" != "fw" && "$PROFILE" != "vpn" ]]; then
    echo "STATUS=NA"
    echo "REASON=해당 장비 유형($PROFILE)은 DMZ 구간 설정 점검 대상이 아님"
    exit 0
fi

KEYWORDS=("dmz" "zone" "segment" "interface" "external" "internal" "untrust" "trust")
FOUND_KEYWORDS=()

# Search keywords in zone/interface config
for file in "zone_config.txt" "interface_config.txt"; do
    if [[ -f "$EVIDENCE_DIR/$file" ]]; then
        for kw in "${KEYWORDS[@]}"; do
            if grep -qi "$kw" "$EVIDENCE_DIR/$file" 2>/dev/null; then
                FOUND_KEYWORDS+=("$kw")
            fi
        done
    fi
done

UNIQUE_KEYWORDS=($(echo "${FOUND_KEYWORDS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

if [[ ${#UNIQUE_KEYWORDS[@]} -gt 0 ]]; then
    echo "STATUS=PASS"
    echo "REASON=DMZ 또는 네트워크 존 설정 키워드(${UNIQUE_KEYWORDS[*]})가 발견됨"
    echo "EVIDENCE=Keywords found: ${UNIQUE_KEYWORDS[*]}"
else
    echo "STATUS=MANUAL_REVIEW"
    echo "REASON=존 설정 증적은 존재하나 DMZ/업무망 구분이 불명확함"
    echo "EVIDENCE=Checked files: zone_config.txt, interface_config.txt"
fi
