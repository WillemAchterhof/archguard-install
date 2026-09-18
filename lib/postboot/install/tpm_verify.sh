#!/usr/bin/env bash
# ==============================================================================
#  Arch Secure Installer V2.6 — TPM Verification
# ==============================================================================
#  lib/postboot/install/base/verify.sh
#
#  Provides:
#    verify_tpm
# ==============================================================================

set -Eeuo pipefail

log_tpm_verify()
{
    printf '[ArchGuard TPM] %s\n' "$*"
}

get_luks_device_verify()
{
    local device

    device="$(cryptsetup status cryptroot 2>/dev/null \
        | awk '/device:/ {print $2; exit}')"

    [[ -n "$device" ]] \
        || {
            log_tpm_verify "ERROR: Unable to determine LUKS device for cryptroot"
            return 1
        }

    printf '%s\n' "$device"
}

base_verify_tpm()
{
    local luks_device

    log_tpm_verify "Verifying TPM2 enrollment"

    luks_device="$(get_luks_device_verify)"

    log_tpm_verify "LUKS device: $luks_device"

    cryptsetup luksDump "$luks_device" 2>/dev/null \
        | grep -q 'systemd-tpm2' \
        || {
            log_tpm_verify "ERROR: No systemd TPM2 token found"
            return 1
        }

    log_tpm_verify "TPM2 token found"

    log_tpm_verify "TPM2 enrollment verification successful"
}