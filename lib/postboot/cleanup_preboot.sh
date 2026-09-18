#!/usr/bin/env bash
# ==============================================================================
#  Arch Secure Installer V2.6 — Clean Wi-Fi Configuration
# ==============================================================================
#  lib/postboot/cleanup_preboot.sh
#
#  Provides:
#    clean_wifi_config
#
#  Removes the temporary Wi-Fi credentials after they have been used.
#  The credentials are stored only for the duration of postboot.
# ==============================================================================

set -Eeuo pipefail

clean_wifi_config()
{
    log "[*] Removing temporary Wi-Fi configuration"

    if [[ -f "$AG_POST_CONF/wifi.env" ]]; then
        rm -f -- "$AG_POST_CONF/wifi.env"

        log "[+] Temporary Wi-Fi configuration removed"
    else
        log "[*] No temporary Wi-Fi configuration found"
    fi
}