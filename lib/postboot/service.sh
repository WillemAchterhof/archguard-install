#!/usr/bin/env bash
# ==============================================================================
#  Arch Secure Installer V2.6 — Postboot Service Preparation
# ==============================================================================
#  lib/postboot/service.sh
#
#  Prepares postboot execution through the installation user's login shell.
# ==============================================================================

prepare_service()
{
    local home="$AG_INSTALL_ROOT/home/$AG_P_USERNAME"
    local bash_profile="$home/.bash_profile"

    msg "Preparing postboot service"

    [[ -n "${AG_P_USERNAME:-}" ]] \
        || fatal "AG_P_USERNAME is not set"

    [[ -d "$home" ]] \
        || fatal "Home directory not found: $home"

    # --------------------------------------------------------------------------
    # Create .bash_profile if it does not exist
    # --------------------------------------------------------------------------

    [[ -f "$bash_profile" ]] || touch "$bash_profile"

    # --------------------------------------------------------------------------
    # Remove an existing ArchGuard postboot block
    # --------------------------------------------------------------------------

    sed -i \
        '/# ARCHGUARD_POSTBOOT_START/,/# ARCHGUARD_POSTBOOT_END/d' \
        "$bash_profile"

    # --------------------------------------------------------------------------
    # Start postboot after user login
    # --------------------------------------------------------------------------

    cat >> "$bash_profile" <<'EOF'

# ARCHGUARD_POSTBOOT_START
if [[ -f "/opt/archguard/run.sh" ]]; then
    sudo bash "/opt/archguard/run.sh"
fi
# ARCHGUARD_POSTBOOT_END
EOF

    # --------------------------------------------------------------------------
    # Set ownership inside the installed system
    # --------------------------------------------------------------------------

    run_chroot chown "$AG_P_USERNAME:$AG_P_USERNAME" \
        "/home/$AG_P_USERNAME/.bash_profile"

    msg "Postboot service prepared for user: $AG_P_USERNAME"
}