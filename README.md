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

### 2. `kali-novnc.sh`

**Description:**
Runs a Kali Linux Docker container with noVNC exposed so you can access the desktop in your browser. The script sets up a persistent host directory mounted at `/root/` inside the container so your files survive container restarts.

**Key configuration variables (top of script):**
- `PERSISTENT_DATA_DIR` — path on the host where container `/root/` will be mounted (script default: `$HOME/my_workspace/kali-novnc/`).
- `IMAGE_NAME` — Docker image used (script default: `iphoneintosh/kali-docker:latest`).
- `NOVNC_PORT` — host port forwarded to container's noVNC web UI (script default: `9020`).
- `VNC_PORT` — host port forwarded to container's VNC server (script default: `9021`).

**Requirements:**
- Docker installed and working. The script will try to install Docker on Debian-based systems if it is missing (requires sudo).
- If the script installs Docker it will add your user to the `docker` group — you must log out and log back in for group changes to take effect.

**Usage:**
```bash
# Make executable if needed and run:
bash kali-novnc.sh
```

What the script does:
- Ensures the persistence directory exists (creates it if missing).
- Checks for Docker and runs a Debian-style install if Docker is not present (requires sudo). If Docker is installed by the script it instructs you to relogin and exits.
- Runs the Docker container with host ports forwarded for noVNC and VNC and mounts the host persistent directory into `/root/` inside the container.

**Access:**
- Open your browser to: http://localhost:<NOVNC_PORT> (default http://localhost:9020)
- Connect with a VNC client to localhost:<VNC_PORT> if you prefer direct VNC access (default mapped to host port 9021 -> container 5900).

**Example (defaults):**
- noVNC: http://localhost:9020
- VNC: connect to localhost:9021 with a VNC client


**Notes & Troubleshooting:**
- The script runs the container with `--rm` so the container is removed after it stops; persistent data is kept on the host at `PERSISTENT_DATA_DIR`.
- If ports 9020 or 9021 are already in use, edit `NOVNC_PORT` and `VNC_PORT` at the top of the script before running.
- The script will NOT add your user to the `docker` group automatically. Either run the script with sudo-enabled docker commands (the script will use `sudo docker` when needed) or add your user to the `docker` group manually and re-login.
- The script will attempt to auto-detect your screen resolution (via `xdpyinfo` or `xrandr`) and pass a `SCREEN_RES` environment variable (and `SCREEN_WIDTH`/`SCREEN_HEIGHT`) into the container.
- If you want the container to persist beyond the current session, remove `--rm` from the `docker run` command inside the script and run it in detached mode.

Reference and tweaks:
- This project uses a Kali Docker image by default; for additional environment variables, geometry options and other tweaks see the lonetis project: https://github.com/lonetis/kali-docker

---

## Adding New Scripts

For every new script added to this repository, please:
1. Add a new section in this README with the script name as a heading.
2. Provide a short description of what the script does.
3. Include usage instructions and any required arguments or dependencies.

This will help users quickly understand the purpose and usage of each script.
