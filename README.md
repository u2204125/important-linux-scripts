# Important Linux Scripts

This repository contains useful Linux scripts for system administration and troubleshooting. Each script is designed to automate or simplify common tasks.

## Script Index

Below is a list of scripts in this repository, along with a brief description and usage instructions. As new scripts are added, please update this README with details for each script.

---

### 1. `mount_fix.sh`

**Description:**
Fixes NTFS partition issues and installs required utilities for mounting NFS and CIFS shares.

**Usage:**
```
bash mount_fix.sh
```
The script will prompt you to enter the disk name (e.g., `/dev/sdb3`). It will then attempt to fix the NTFS partition and ensure necessary packages are installed.

**What it does:**
- Installs `nfs-common` and `cifs-utils` if not already present.
- Lists all disks using `fdisk -l`.
- Prompts for a disk name and runs `ntfsfix` on the specified disk.

---

## Adding New Scripts

For every new script added to this repository, please:
1. Add a new section in this README with the script name as a heading.
2. Provide a short description of what the script does.
3. Include usage instructions and any required arguments or dependencies.

This will help users quickly understand the purpose and usage of each script.
