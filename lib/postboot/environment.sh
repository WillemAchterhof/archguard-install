#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Arch Secure Installer V2.6 — Prepare Postboot Environment
# ------------------------------------------------------------------------------
# /lib/postboot/environment.sh
# ------------------------------------------------------------------------------

prepare_environment()
{
    local target_dir="$AG_INSTALL_ROOT/opt/archguard"
    local target_file="$target_dir/run-postboot.sh"
    local wifi_source="$AG_DIR_STATE/config/wifi.env"
    local wifi_target="$target_dir/config/base/wifi.env"
    local postboot_url="https://raw.githubusercontent.com/WillemAchterhof/archguard-post/refs/heads/main/run-postboot.sh"

    BACKUP_SOURCE="$AG_DIR_STATE/backup/ArchGuard.png"
    BACKUP_TARGET="$target_dir/backup"
    mkdir -p -- "$target_dir"
    
    msg "Preparing postboot environment"

    mkdir -p -- "$target_dir"

    # --------------------------------------------------------------------------
    # Download postboot runner
    # --------------------------------------------------------------------------

    msg "Downloading postboot runner"

    curl -fsSL \
        "$postboot_url" \
        -o "$target_file" \
        || fatal "Failed to download postboot runner"

    chmod 755 "$target_file"

    msg "Postboot runner installed: $target_file"

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

    # ------------------------------------------------------------------------------
    # Copy ArchGuard background
    # ------------------------------------------------------------------------------

    mkdir -p -- "$BACKUP_TARGET"

    if [[ -f "$BACKUP_SOURCE" ]]; then
        cp -f -- "$BACKUP_SOURCE" "$BACKUP_TARGET/ArchGuard.png"
        printf "[*] ArchGuard background copied.\n"
    else
        printf "[!] ArchGuard background not found: %s\n" "$BACKUP_SOURCE"
    fi


    msg "Postboot environment prepared"
}