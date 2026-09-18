#!/usr/bin/env bash
# ==============================================================================
#  Arch Secure Installer V2.6 — Postboot Runner
# ==============================================================================
#  lib/postboot/run-postboot.sh
#
#  Loads all postboot components recursively and executes the final actions.
# ==============================================================================

set -Eeuo pipefail

POSTBOOT_ROOT="/opt/archguard"

# ==============================================================================
#  LOAD ALL POSTBOOT COMPONENTS
# ==============================================================================

while IFS= read -r -d '' file; do
    [[ "$file" == "$POSTBOOT_ROOT/run-postboot.sh" ]] && continue

    source "$file"
done < <(
    find "$POSTBOOT_ROOT" \
        -type f \
        -name '*.sh' \
        -print0
)


read -r -p 'Launch ArchGuard Post-Install configuration? [Y/n]: ' answer < /dev/tty

# ==============================================================================
#  BASE POSTBOOT ACTIONS
# ==============================================================================
#
base_connectivity

# ==============================================================================
#  Setting up USBGuard
# ==============================================================================

base_usbguard

# ==============================================================================
#  OPTIONAL POSTBOOT
# ==============================================================================

ask_post_install()
{
    case "${answer,,}" in
        ""|y|yes)
            printf "Installing ArchGuard Post-Install..."

            git clone \
                "https://github.com/WillemAchterhof/archguard-post-install.git" \
                "$POSTBOOT_ROOT/post_install"

            chmod +x "$POSTBOOT_ROOT/post_install/root-run.sh"
            "$POSTBOOT_ROOT/post_install/root-run.sh"
            ;;

        *)
            printf "Post-Install skipped."
            ;;
    esac
}

ask_post_install

# ==============================================================================
#  TPM ENROLLMENT
# ==============================================================================
sudo systemctl enable sddm
base_enroll_tpm
base_verify_tpm

# ==============================================================================
#  CLEANUP
# ==============================================================================

clean_postboot "${SUDO_USER:-$(whoami)}"
