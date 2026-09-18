#!/usr/bin/env bash
# ==============================================================================
#  Arch Secure Installer V2.6 — Postboot Module
# ==============================================================================
#  lib/postboot/module.sh
#
#  Loads postboot preparation components.
# ==============================================================================

source "$AG_DIR_POSTBOOT/run.sh"
source "$AG_DIR_POSTBOOT/environment.sh"
source "$AG_DIR_POSTBOOT/service.sh"
source "$AG_DIR_POSTBOOT/cleanup_preboot.sh"