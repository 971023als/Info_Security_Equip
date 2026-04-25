#!/bin/bash

# Information Security Equipment (ISE) Diagnosis Automation Tool
# Version: 0.1
# Author: Senior Security Engineer

# Global Variables
VERSION="0.1"
AUDIT_ONLY=true
DRY_RUN=true
REMEDIATE=false
NOT_IMPLEMENTED_AS_PASS=false
EVIDENCE_REQUIRED=true
DIRECT_DEVICE_ACCESS=false

# Allowed Profiles
ALLOWED_PROFILES=("fw" "vpn" "ids" "ips" "ddos" "waf")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function show_usage() {
    echo "Usage: $0 [module] [command] [options]"
    echo ""
    echo "Modules:"
    echo "  ise         Information Security Equipment module"
    echo ""
    echo "ISE Commands:"
    echo "  setup       Initialize directory structure and sample evidence files"
    echo "  audit       Run diagnosis (requires --profile)"
    echo "  report      Generate assessment reports (JSON, CSV, HTML, PDF)"
    echo "  verify      Verify a specific check (requires --profile --check)"
    echo ""
    echo "ISE Options:"
    echo "  --profile [fw|vpn|ids|ips|ddos|waf]    Target equipment profile"
    echo "  --check ISE-XXX                        Run a specific check item"
    echo "  --dry-run                              Run without modifying any state (default)"
    echo ""
    echo "Example:"
    echo "  $0 ise setup"
    echo "  $0 ise audit --profile fw --dry-run"
    echo "  $0 ise report"
}

function ise_setup() {
    echo -e "${YELLOW}[*] Initializing ISE Diagnosis Environment...${NC}"
    
    # Directories are already created by the main script or manual setup
    # Create sample evidence files if they don't exist
    for profile in "${ALLOWED_PROFILES[@]}"; do
        mkdir -p "input/evidence/info_security_equip/$profile"
        touch "input/evidence/info_security_equip/$profile/backup_config.txt"
        touch "input/evidence/info_security_equip/$profile/backup_policy.txt"
        touch "input/evidence/info_security_equip/$profile/backup_log.txt"
        touch "input/evidence/info_security_equip/$profile/log_config.txt"
        touch "input/evidence/info_security_equip/$profile/syslog_config.txt"
        touch "input/evidence/info_security_equip/$profile/remote_log_server.txt"
        touch "input/evidence/info_security_equip/$profile/zone_config.txt"
        touch "input/evidence/info_security_equip/$profile/interface_config.txt"
        echo -e "${GREEN}[+] Setup completed for profile: $profile${NC}"
    done
}

function ise_audit() {
    local profile=""
    local check=""
    local dry_run=true

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --profile) profile="$2"; shift ;;
            --check) check="$2"; shift ;;
            --dry-run) dry_run=true ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
        shift
    done

    if [[ -z "$profile" ]]; then
        echo -e "${RED}[ERROR] --profile is required for audit${NC}"
        echo "Allowed profiles: ${ALLOWED_PROFILES[*]}"
        return 1
    fi

    # Check if profile is allowed
    local profile_valid=false
    for p in "${ALLOWED_PROFILES[@]}"; do
        if [[ "$p" == "$profile" ]]; then
            profile_valid=true
            break
        fi
    done

    if [[ "$profile_valid" == false ]]; then
        echo -e "${RED}[ERROR] Invalid profile: $profile${NC}"
        echo "Allowed profiles: ${ALLOWED_PROFILES[*]}"
        return 1
    fi

    echo -e "${YELLOW}[*] Starting ISE Audit for profile: $profile${NC}"
    bash runners/info_security_equip_runner.sh --profile "$profile" --check "$check" --dry-run "$dry_run"
}

function ise_report() {
    echo -e "${YELLOW}[*] Generating ISE Assessment Reports...${NC}"
    python3 tools/ise_json_to_csv.py
    python3 tools/ise_json_to_html.py
    python3 tools/ise_html_to_pdf.py
}

function ise_verify() {
    local profile=""
    local check=""

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --profile) profile="$2"; shift ;;
            --check) check="$2"; shift ;;
        esac
        shift
    done

    if [[ -z "$profile" || -z "$check" ]]; then
        echo -e "${RED}[ERROR] --profile and --check are required for verify${NC}"
        return 1
    fi

    echo -e "${YELLOW}[*] Verifying check $check for profile $profile...${NC}"
    bash runners/info_security_equip_runner.sh --profile "$profile" --check "$check" --verify
}

# Main Logic
if [[ $# -lt 1 ]]; then
    show_usage
    exit 1
fi

MODULE=$1
shift

case $MODULE in
    ise)
        COMMAND=$1
        shift
        case $COMMAND in
            setup) ise_setup "$@" ;;
            audit) ise_audit "$@" ;;
            report) ise_report "$@" ;;
            verify) ise_verify "$@" ;;
            *) show_usage; exit 1 ;;
        esac
        ;;
    *)
        # Existing Linux Diagnosis Logic (U-01 ~ U-72)
        # This part is preserved for future Linux integration
        echo -e "${YELLOW}[!] Linux diagnosis module not implemented in this version.${NC}"
        echo "Use 'ise' module for Information Security Equipment diagnosis."
        show_usage
        exit 1
        ;;
esac
