#!/usr/bin/env bash
# ==============================================================================
#  Arch Secure Installer V2.6 — Main Pipeline
# ==============================================================================
# install/orchestrator/pipeline.sh
#
#  Defines the installer's top-level stage sequence.
#
#  Responsibilities:
#    - Run each stage in order
#    - Handle early exit
#
#  Does NOT:
#    - Implement stage logic itself
#    - Load modules directly (uses run_module via modules.sh)
# ==============================================================================

run_pipeline()
{
    log_header "Arch Secure Installer V2.6"
    msg "Installer started"

    msg "Loading core services"
    module_services

    msg "Hardware detection"
    module_precheck

    msg "Prepare installer"
    module_prepare

    while true; do
        msg "Configure profile"
        module_menu
    
        [[ "$AG_MENU_EXIT" == "1" ]] && { msg "Installer exited"; exit 0; }
        
        msg "Validate profile"
        module_validate
    
        [[ "$AG_MENU_PROCEED" == "1" ]] && break
    done

    msg "Install system"
    module_install

    msg "Prepare Postboot Installation"
    module_postboot

    msg "Installer finished"
    log_header "SESSION COMPLETE"

    reboot_to_uefi
}
