#!/usr/bin/env bash
# ==============================================================================
#  Arch Secure Installer V2.6 — Post-Boot Preparation
# ==============================================================================
#  lib/postboot/run.sh
# ==============================================================================

set -Eeuo pipefail

prepare_post_environment()
{
    prepare_environment
    prepare_service
    clean_wifi_config
}