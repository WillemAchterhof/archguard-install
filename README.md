# Arch Guard V2

Arch Guard is a project for building a secure, reproducible Arch Linux installation environment.

## Step 1 — Bootable ISO

The first step is a bootable ISO containing:

* Arch Linux Live
* Secure Boot support
* Persistent `ARCHGUARD_DATA` storage
* Automatic launch of the Arch Guard installer

USB

├── ARCHGUARD_LIVE
└── ARCHGUARD_DATA (currently created manually)

The live environment provides the boot and installation environment.
The data partition provides persistent storage for Arch Guard.

**Goal:** Create a bootable ISO that can be written to USB.

**Status:** Step 1 — In development.
