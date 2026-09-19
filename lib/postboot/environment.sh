#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# ArchGuard Post-Boot
# ------------------------------------------------------------------------------
# /run-postboot.sh
# ------------------------------------------------------------------------------

set -Eeuo pipefail

POST_INSTALL_URL="https://github.com/WillemAchterhof/archguard-post.git"
POST_INSTALL="/opt/archguard/post_install"

BACKUP_SOURCE="$AG_DIR_STATE/backup/ArchGuard.png"
BACKUP_TARGET="$POST_INSTALL/backup"

printf "[*] Preparing ArchGuard Post-Install...\n"

# ------------------------------------------------------------------------------
# Clone Post-Install
# ------------------------------------------------------------------------------

git clone \
    "$POST_INSTALL_URL" \
    "$POST_INSTALL"

chmod +x "$POST_INSTALL/root-run.sh"

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

# ------------------------------------------------------------------------------
# Start Post-Install
# ------------------------------------------------------------------------------

printf "[*] Starting ArchGuard Post-Install...\n"

exec "$POST_INSTALL/root-run.sh"