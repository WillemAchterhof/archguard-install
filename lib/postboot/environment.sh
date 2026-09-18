#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Arch Secure Installer V2.6 — Prepare Postboot Environment
# ------------------------------------------------------------------------------
# /lib/postboot/environment.sh
# ------------------------------------------------------------------------------

prepare_environment()
{
    local source_postboot_file="$AG_DIR_POSTBOOT/run-postboot.sh"
    local target_dir="$AG_INSTALL_ROOT/opt/archguard"
    local wifi_source="$AG_DIR_STATE/config/wifi.env"
    local wifi_target="$target_dir/config/base/wifi.env"

    msg "Preparing postboot environment"

    [[ -f "$source_postboot_file" ]] \
        || fatal "Postboot runner missing: $source_postboot_file"

    rm -rf -- "$target_dir"
    mkdir -p -- "$target_dir"

    cp -a -- "$source_postboot_file" "$target_dir/"

    # --------------------------------------------------------------------------
    # Wi-Fi configuration
    # --------------------------------------------------------------------------

    if [[ -f "$wifi_source" ]]; then
        mkdir -p -- "$(dirname "$wifi_target")"

        cp -f -- "$wifi_source" "$wifi_target"
        chmod 600 "$wifi_target"

        msg "Saved Wi-Fi configuration copied to postboot environment"
    else
        msg "No saved Wi-Fi configuration found"
    fi

    msg "Postboot environment prepared"
}