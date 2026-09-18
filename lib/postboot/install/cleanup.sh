#!/usr/bin/env bash
# ==============================================================================
#  Arch Secure Installer V2.6 — Postboot Cleanup
# ==============================================================================
#  lib/postboot/install/cleanup.sh
#
#  Provides:
#    clean_postboot
#
#  Removes the postboot login hook and the complete temporary postboot
#  environment.
# ==============================================================================

set -Eeuo pipefail

log_cleanup()
{
    printf '[ArchGuard Cleanup] %s\n' "$*"
}

clean_postboot()
{
    local username="${1:-}"
    local home
    local bash_profile

    [[ -n "$username" ]] \
        || {
            log_cleanup "ERROR: Installation username was not supplied"
            return 1
        }

    home="/home/$username"
    bash_profile="$home/.bash_profile"

    log_cleanup "Starting postboot cleanup"
    log_cleanup "User: $username"

    # --------------------------------------------------------------------------
    # Remove postboot login hook
    # --------------------------------------------------------------------------

    if [[ -f "$bash_profile" ]]; then
        log_cleanup "Removing postboot login hook"

        sed -i \
            '/# ARCHGUARD_POSTBOOT_START/,/# ARCHGUARD_POSTBOOT_END/d' \
            "$bash_profile"
    else
        log_cleanup "No .bash_profile found: $bash_profile"
    fi

    # --------------------------------------------------------------------------
    # Remove complete postboot environment
    # --------------------------------------------------------------------------

    if [[ -d "$POSTBOOT_ROOT" ]]; then
        log_cleanup "Removing postboot environment: $POSTBOOT_ROOT"

        rm -rf -- "$POSTBOOT_ROOT"
    else
        log_cleanup "Postboot environment already removed"
    fi

    # --------------------------------------------------------------------------
    # Verify cleanup
    # --------------------------------------------------------------------------

    [[ ! -e "$POSTBOOT_ROOT" ]] \
        || {
            log_cleanup "ERROR: Failed to remove $POSTBOOT_ROOT"
            return 1
        }

    log_cleanup "Postboot cleanup completed"
}