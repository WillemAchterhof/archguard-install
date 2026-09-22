# ArchGuard

**ArchGuard** is a security-focused Arch Linux installation and hardening framework.

It is designed around a simple principle:

> **Build a minimal Arch Linux system, establish a measured and trusted boot chain, reduce the attack surface, and make security-relevant changes explicit and verifiable.**

ArchGuard is not intended to be a universal "secure Arch" configuration. It is an opinionated personal project with hardware-aware configuration, measured boot, encrypted storage, kernel hardening, and controlled first-boot configuration.

The project is designed to keep the security model understandable rather than accumulating large numbers of unexplained hardening tweaks.

---

# Security Architecture

ArchGuard is organized into the following security layers:

```text
0. Hardware / Firmware
        │
        ▼
1. Boot Integrity
        │
        ▼
2. Secrets & Storage
        │
        ▼
3. Kernel Security
        │
        ▼
4. Network Security
        │
        ▼
5. Services & Privileges
        │
        ▼
6. Application Confinement
        │
        ▼
7. Virtualization Isolation
        │
        ▼
8. Detection & Response
```

The current installer implementation primarily establishes the foundations through the early security layers.

---

# 0. Hardware / Firmware

ArchGuard assumes a modern UEFI system with TPM 2.0 support.

The firmware layer provides the initial root of trust for the measured boot chain.

Primary goals:

* UEFI boot
* Secure Boot
* TPM 2.0
* measured boot
* hardware-aware configuration
* reduced unnecessary hardware support

ArchGuard does not assume that the TPM itself makes a system secure.

The TPM is used as one component of a larger chain of trust.

---

# 1. Boot Integrity

ArchGuard uses a **Unified Kernel Image (UKI)** together with Secure Boot and measured boot.

The intended boot chain is:

```text
UEFI
 │
 ├── Secure Boot
 │
 ▼
Signed UKI
 │
 ├── Kernel
 ├── initrd
 └── kernel command line
 │
 ▼
systemd-stub
 │
 ▼
Measured boot
 │
 ▼
TPM 2.0
```

The UKI is signed before Secure Boot is used to establish trust in the boot image.

The system uses `systemd-stub` to boot the UKI.

A direct UKI boot entry can be used without requiring a traditional installed systemd-boot configuration.

## Secure Boot

Secure Boot is expected to be enabled in **UEFI User Mode** before TPM enrollment.

This is important because TPM measurements and policies are only meaningful when the expected boot trust chain is actually enforced.

Arch Linux's current documentation also recommends ensuring Secure Boot is active before binding LUKS unlocking to TPM state.

---

# Kernel Lockdown

ArchGuard enables:

```text
lockdown=confidentiality
```

Kernel lockdown provides an additional security boundary when Secure Boot is active.

This deliberately restricts certain operations that could otherwise undermine the integrity or confidentiality of the running kernel.

An intentional consequence is:

> **Kernel hibernation is not supported by the ArchGuard security model.**

Suspend remains possible.

---

# 2. Secrets & Storage

ArchGuard uses encrypted storage as a fundamental security layer.

The intended storage architecture is:

```text
Physical Disk
     │
     ▼
   LUKS2
     │
     ▼
    LVM
     │
     ├── root
     └── swap
```

The root filesystem is encrypted using LUKS2.

Swap is also placed inside the encrypted storage hierarchy.

The goal is to prevent offline access to filesystem contents if the physical storage device is removed from the machine.

---

# TPM 2.0

ArchGuard uses TPM 2.0 as part of the LUKS unlock process.

The intended architecture is:

```text
              ┌─────────────────┐
              │   Secure Boot   │
              └────────┬────────┘
                       │
                       ▼
                Signed UKI
                       │
                       ▼
                Measured Boot
                       │
                       ▼
                   TPM 2.0
                       │
              ┌────────┴────────┐
              │                 │
           PCR state         TPM PIN
              │                 │
              └────────┬────────┘
                       ▼
                    LUKS2
                       │
                       ▼
                 Encrypted Root
```

`systemd-cryptenroll` provides the TPM-backed LUKS enrollment mechanism. TPM2 enrollment can bind the unlock key to selected PCRs and can additionally require a PIN.

---

# TPM PIN

ArchGuard requires an additional TPM PIN.

The model is therefore not simply:

```text
TPM → unlock
```

but:

```text
Trusted measured state
        +
TPM PIN
        ↓
    LUKS unlock
```

This prevents possession of the physical machine from automatically being sufficient for unattended TPM-based unlocking.

---

# TPM PCR Policy

ArchGuard currently uses the following PCRs for the TPM enrollment:

```text
PCR 0
PCR 1
PCR 2
PCR 4
PCR 5
PCR 7
PCR 12
```

using the SHA-256 PCR bank.

PCR 11 is handled separately through a **signed PCR policy**.

The resulting design is:

```text
Raw PCR binding:
    0 + 1 + 2 + 4 + 5 + 7 + 12

Signed PCR policy:
    PCR 11
```

This allows ArchGuard to bind the LUKS unlock process to both the platform/boot state and the measured boot phase without treating PCR 11 as an ordinary static PCR binding.

Modern systemd documentation explicitly supports signed PCR policies and recommends considering PCR policies instead of simply binding secrets to raw PCR values.

---

# Why These PCRs?

The selected PCRs represent different parts of the trusted boot environment.

```text
PCR 0  → firmware/platform measurements
PCR 1  → firmware configuration
PCR 2  → firmware/option ROM measurements
PCR 4  → boot loader / boot path
PCR 5  → boot configuration / partition-related measurements
PCR 7  → Secure Boot state and policy
PCR 11 → systemd measured boot phases
PCR 12 → kernel command line / related measured state
```

The exact measurements depend on the platform and boot configuration.

The selection intentionally favors security sensitivity over maximum convenience.

A legitimate security-relevant change may therefore cause TPM unlocking to fail.

That is a feature of the design, not automatically an error.

---

# No Automatic TPM Re-enrollment

ArchGuard deliberately does **not** automatically re-enroll the TPM after a security-relevant change.

The intended response to an unexpected TPM mismatch is:

```text
TPM unlock fails
        │
        ▼
Manual LUKS unlock
        │
        ▼
ArchGuard detects changed state
        │
        ▼
Security warning / investigation
        │
        ▼
Network quarantine where applicable
        │
        ▼
User explicitly approves the change
        │
        ▼
Manual TPM re-enrollment
```

The important principle is:

> **A changed security measurement must not automatically become trusted merely because the system can boot again.**

Automatic re-enrollment would weaken the purpose of binding the encrypted system to a known measured state.

---

# TPM Recovery

The TPM is not intended to be the only way to unlock the encrypted system.

A normal LUKS recovery mechanism remains available.

This is necessary because TPM-bound unlocks can legitimately stop working after:

* firmware changes
* Secure Boot changes
* UKI changes
* kernel changes
* boot configuration changes
* measured system changes
* TPM changes or resets

Arch Linux documentation also recommends maintaining an alternative recovery mechanism when using TPM-backed LUKS unlocking.

---

# TPM Verification

ArchGuard verifies the TPM configuration rather than assuming enrollment succeeded.

Useful verification points include:

```bash
systemd-analyze has-tpm2
```

and:

```bash
cryptsetup luksDump /dev/<luks-device>
```

The LUKS header should contain a `systemd-tpm2` token when TPM enrollment is active.

PCR state can also be inspected using:

```bash
tpm2_pcrread sha256:0,1,2,4,5,7,11,12
```

The goal is to verify the actual state of the machine rather than simply checking whether TPM-related packages are installed.

---

# 3. Kernel Security

ArchGuard applies several kernel-level hardening measures.

Current security decisions include:

* kernel lockdown
* module signature enforcement
* hardware-aware module minimization
* disabled kexec loading
* restricted unprivileged BPF
* BPF LSM
* restricted performance counters
* Yama
* AppArmor
* Landlock
* kernel information restrictions
* ASLR-related hardening
* personal kernel module blacklist

The exact configuration is maintained in ArchGuard's configuration files.

---

# Kernel Module Signatures

ArchGuard requires signed kernel modules.

The goal is to prevent an attacker from simply loading an arbitrary unsigned kernel module into the running kernel.

This complements Secure Boot and kernel lockdown.

The security chain therefore becomes:

```text
Secure Boot
     │
     ▼
Signed UKI
     │
     ▼
Locked-down Kernel
     │
     ▼
Signed Kernel Modules
```

---

# Hardware-Aware Module Minimization

ArchGuard does **not** use a universal blacklist containing every kernel module that could theoretically be abused.

Instead, the blacklist is hardware- and usage-specific.

For example, a system that does not contain or require:

* FireWire
* Thunderbolt
* floppy hardware
* legacy serial hardware
* optical drives
* legacy ATA controllers
* unused filesystems
* unused network protocols

can disable those modules.

The principle is:

> **Reduce unnecessary kernel attack surface without disabling hardware that the system actually requires.**

The blacklist is therefore considered a **personal/hardware-specific configuration**, not a universal Arch Linux security policy.

---

# Personal Kernel Module Blacklist

The current blacklist includes hardware and functionality that is known not to be required by the target system.

Examples include:

```text
Thunderbolt
FireWire
Floppy
PC Speaker
Parallel ports
Legacy PS/2 mouse
Legacy serial hardware
Optical drives
Legacy ATA controllers
Legacy SCSI controllers
Game controllers
Selected uncommon filesystems
Selected uncommon network protocols
```

This list should be reviewed when ArchGuard is deployed on different hardware.

USB itself is **not** disabled through the kernel module blacklist.

USB device authorization is handled separately through USBGuard.

---

# kexec

ArchGuard disables kernel kexec loading:

```text
kernel.kexec_load_disabled=1
```

The intention is to prevent a running system from using kexec to load another kernel and bypass parts of the normal boot chain.

---

# BPF

ArchGuard does not disable BPF completely.

Instead, unprivileged BPF is restricted:

```text
kernel.unprivileged_bpf_disabled=1
```

BPF LSM remains available as part of the kernel security architecture.

This preserves legitimate kernel security functionality while reducing unnecessary exposure to unprivileged users.

---

# Performance Counters

ArchGuard restricts access to kernel performance monitoring interfaces.

The current configuration uses:

```text
kernel.perf_event_paranoid=2
```

The intention is to reduce the information available to unprivileged processes through performance monitoring facilities.

---

# 4. Network Security

ArchGuard uses **nftables** as the host firewall.

The firewall is designed around explicit trust boundaries rather than assuming that local traffic is automatically trusted.

The intended architecture is:

```text
Internet
   │
   ▼
┌───────────────┐
│ ArchGuard     │
│ Host          │
└───────┬───────┘
        │
      virbr0
        │
   ┌────┴────┐
   │         │
  VM        VM
```

The firewall policy is designed to control communication between:

* Internet
* host
* virtual machines

The ArchGuard firewall owns only its own nftables tables.

It does **not** globally flush the nftables ruleset.

This is important because other components such as libvirt may maintain their own nftables rules.

---

# 5. Services & Privileges

ArchGuard attempts to keep the installed system minimal.

Services should only be enabled when they are actually required.

Static configuration is separated from runtime actions.

Static configuration files belong in:

```text
install/configs/
```

Installer and installation logic belongs in:

```text
install/lib/
```

First-boot/runtime actions belong in:

```text
install/lib/postboot/
```

Temporary installer state belongs in:

```text
state/
```

This separation keeps configuration files independent from the code that deploys them.

---

# 6. Application Confinement

ArchGuard uses Linux security mechanisms including:

* AppArmor
* Landlock
* kernel lockdown
* systemd service restrictions
* filesystem permissions
* application sandboxing where available

The goal is not to assume that every installed application is trustworthy.

Instead:

> **Applications should have only the privileges and access they actually need.**

Desktop applications such as Plasma and Firefox are currently configured **manually** and are therefore not considered part of the ArchGuard installer baseline.

This distinction is intentional.

ArchGuard establishes the security foundation; desktop software can then be installed and configured according to the user's requirements.

---

# 7. Virtualization Isolation

Virtualization support is part of the broader ArchGuard design, but the VM environment is kept separate from the core installer security baseline.

KVM/QEMU/libvirt can be installed independently.

The intended model is that virtual machines should not automatically receive access to host resources such as:

```text
/home
SSH keys
browser profiles
password stores
personal documents
host sockets
```

Host filesystem sharing and automatic USB passthrough should only be enabled when explicitly required.

---

# 8. Detection & Response

ArchGuard treats security events as something that should be detected and acted upon rather than silently ignored.

Examples include:

* unexpected TPM state
* changed measured boot state
* unexpected hardware changes
* unauthorized USB devices
* network security violations
* security service failures

The long-term goal is for **ASBGuard** to provide the detection and response layer.

---

# USBGuard

USBGuard provides device-level USB authorization.

The intended architecture is:

```text
USB Hardware
     │
     ▼
Linux USB subsystem
     │
     ▼
USBGuard
     │
     ├── Authorized device
     │
     └── Blocked device
```

USBGuard is deliberately separate from the kernel module blacklist.

The kernel blacklist answers:

> **Should the operating system support this type of hardware/functionality at all?**

USBGuard answers:

> **Should this particular USB device be authorized?**

---

# USBGuard Installation

USBGuard is installed during the postboot stage.

The intended sequence is:

```text
Install USBGuard
      │
      ▼
Generate initial policy
      │
      ▼
Enable USBGuard
      │
      ▼
Start USBGuard
```

The initial policy is generated before the service is activated.

This is important because currently connected input devices such as the keyboard and mouse need to be included in the initial policy.

---

# USBGuard Policy

The initial policy is generated using:

```bash
usbguard generate-policy
```

The resulting policy is written to:

```text
/etc/usbguard/rules.conf
```

The generated policy is a starting point rather than a universal security policy.

Devices should be reviewed before permanently trusting additional hardware.

The intended security model is:

```text
Known / explicitly authorized USB device
        │
        ▼
      ALLOW


Unknown USB device
        │
        ▼
      DENY
```

---

# USBGuard and the Kernel

USBGuard does not replace kernel-level USB support.

The layers work together:

```text
USB device
    │
    ▼
USB controller / kernel
    │
    ▼
USB device enumeration
    │
    ▼
USBGuard authorization
    │
    ├── allowed
    │
    └── blocked
```

The USB subsystem therefore remains functional while individual devices can be controlled.

---

# Current Security Decisions

| Area                        | Decision          |
| --------------------------- | ----------------- |
| UEFI                        | Required          |
| Secure Boot                 | Enabled           |
| UKI                         | Enabled           |
| TPM 2.0                     | Used              |
| LUKS2                       | Enabled           |
| LVM                         | Used              |
| TPM PIN                     | Enabled           |
| TPM PCR policy              | Enabled           |
| Automatic TPM re-enrollment | Disabled          |
| Kernel lockdown             | `confidentiality` |
| Module signatures           | Enabled           |
| kexec                       | Disabled          |
| Unprivileged BPF            | Restricted        |
| BPF LSM                     | Enabled           |
| Performance counters        | Restricted        |
| AppArmor                    | Enabled           |
| Landlock                    | Enabled           |
| Yama                        | Enabled           |
| nftables                    | Enabled           |
| USBGuard                    | Enabled           |
| Hardware-specific blacklist | Yes               |
| Universal kernel blacklist  | No                |
| Hibernation                 | Unsupported       |
| Desktop installation        | Manual            |
| Firefox configuration       | Manual            |

---

# Design Philosophy

ArchGuard follows several principles.

### 1. Explicit trust

Do not silently turn an unexpected state into a trusted state.

### 2. Least privilege

Install and enable only what is required.

### 3. Layered security

No individual security mechanism should be considered sufficient by itself.

### 4. Hardware awareness

Do not disable hardware blindly for theoretical security benefits.

### 5. Separation of responsibilities

Configuration, installation logic, runtime actions, and temporary state remain separate.

### 6. Fail closed where practical

Unexpected security states should result in denial, quarantine, or a clear warning rather than silent acceptance.

### 7. Keep the system understandable

Security should not depend on an enormous collection of unexplained tweaks.

### 8. Prefer upstream mechanisms

Where possible, ArchGuard uses established Linux security mechanisms rather than inventing replacements.

---

# Project Status

ArchGuard is an actively developed personal security-focused Arch Linux installer.

The security foundation currently includes:

* UEFI installation
* Secure Boot
* Unified Kernel Image
* measured boot
* TPM 2.0
* LUKS2
* LVM
* TPM-based LUKS unlocking
* TPM PIN
* PCR-based TPM policy
* signed PCR policy
* kernel lockdown
* kernel hardening
* kernel module signatures
* hardware-aware module minimization
* nftables
* AppArmor
* Landlock
* USBGuard
* postboot configuration and cleanup

The graphical desktop environment and Firefox are **not currently installed or configured by ArchGuard**. They are manually configured after the secure base system has been installed.

---

# Disclaimer

ArchGuard is a personal security project.

It is **not a security certification, hardened distribution, or guarantee of system security**.

Security settings can cause compatibility problems, prevent hardware from working, or require manual intervention after legitimate system changes.

Always test ArchGuard on hardware you control before relying on it for important systems.

Keep independent backups of important data.

---

# License

License: **TBD**

Until a license is explicitly selected, the project should not be assumed to grant broad redistribution or modification rights.
