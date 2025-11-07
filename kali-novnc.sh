#!/bin/bash

# --- Configuration ---
# 1. Choose where on your Q4OS system the Kali data will be stored.
#    This directory will be created if it doesn't exist.
PERSISTENT_DATA_DIR="$HOME/my_workspace/kali-novnc/"

# 2. Docker Image and Ports
IMAGE_NAME="iphoneintosh/kali-docker:latest"
NOVNC_PORT=9020 # Access noVNC in your browser: http://localhost:9020
VNC_PORT=9021   # Direct VNC access

# Optional: target screen resolution. If not set, the script will try to auto-detect
# using `xdpyinfo` or `xrandr` when available, otherwise falls back to 1920x1080.
# You can override by exporting SCREEN_WIDTH and SCREEN_HEIGHT before running.
SCREEN_WIDTH="${SCREEN_WIDTH:-}"
SCREEN_HEIGHT="${SCREEN_HEIGHT:-}"

# Enable extra privileges and mounts to allow services like NetworkManager and systemd
# to function inside the container. Set to "1" to enable (default: 1 because NetworkManager
# typically requires these). Set to "0" to avoid privileged mounts and use a safer but
# potentially less-functional container environment.
ENABLE_PRIVILEGED="${ENABLE_PRIVILEGED:-1}"

# --- Function to check and install Docker ---
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "🚨 Docker is not installed. Starting installation (requires sudo)..."
        # Run the official installation steps for Debian-based systems (like Q4OS)
        sudo apt update
        sudo apt install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        
        # Set up the repository for the current Debian codename
        DEBIAN_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
        echo "Setting up Docker repository for Debian codename: $DEBIAN_CODENAME"
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
          \"$DEBIAN_CODENAME\" stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        if [ $? -eq 0 ]; then
            echo "✅ Docker installation complete."
            echo "Note: this script will NOT add your user to the 'docker' group automatically."
            echo "If you prefer to run docker without sudo, add your user manually and re-login:"
            echo "  sudo usermod -aG docker \$USER"
            echo "Or continue and this script will run Docker commands with sudo if required."
        else
            echo "❌ Docker installation failed. Please check the error messages."
            exit 1
        fi
    fi
}

# --- Main Execution ---

# 1. Run the Docker check/install function
check_and_install_docker

# Detect or build screen resolution string
detect_resolution() {
    if [ -n "$SCREEN_WIDTH" ] && [ -n "$SCREEN_HEIGHT" ]; then
        SCREEN_RES="${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
        return
    fi
    # Try xdpyinfo if DISPLAY is set
    if [ -n "$DISPLAY" ] && command -v xdpyinfo &> /dev/null; then
        dims=$(xdpyinfo | awk -F: '/dimensions:/ {gsub(/^[ \t]+/,"",$2); print $2}' | awk '{print $1}')
        if [ -n "$dims" ]; then
            SCREEN_RES="$dims"
            SCREEN_WIDTH="${dims%x*}"
            SCREEN_HEIGHT="${dims#*x}"
            return
        fi
    fi
    # Try xrandr
    if command -v xrandr &> /dev/null; then
        dims=$(xrandr | grep '\*' | uniq | awk '{print $1}')
        if [ -n "$dims" ]; then
            SCREEN_RES="$dims"
            SCREEN_WIDTH="${dims%x*}"
            SCREEN_HEIGHT="${dims#*x}"
            return
        fi
    fi
    # Fallback
    SCREEN_WIDTH="${SCREEN_WIDTH:-1920}"
    SCREEN_HEIGHT="${SCREEN_HEIGHT:-1080}"
    SCREEN_RES="${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
}

detect_resolution

# Determine current user UID/GID so we don't have to create accounts inside the container.
USER_UID=$(id -u)
USER_GID=$(id -g)


# Check for persistence directory and create if not exists
if [ ! -d "$PERSISTENT_DATA_DIR" ]; then
    echo "Creating persistent data directory at: $PERSISTENT_DATA_DIR"
    mkdir -p "$PERSISTENT_DATA_DIR"
    # Ensure the directory is owned by the current user so the container (run with the same UID)
    # can write to it without creating files owned by root.
    chown -R "$USER_UID":"$USER_GID" "$PERSISTENT_DATA_DIR" 2>/dev/null || true
fi

echo "--- Starting Kali Docker Container ---"
echo "Data will be saved to: $PERSISTENT_DATA_DIR"
echo "Access noVNC at: http://localhost:$NOVNC_PORT"


echo "Starting container as UID:GID ${USER_UID}:${USER_GID} with resolution ${SCREEN_RES}"

# Build extra flags needed for NetworkManager/systemd inside the container
EXTRA_DOCKER_FLAGS=""
if [ "$ENABLE_PRIVILEGED" != "0" ]; then
    echo "Enabling privileged mounts and tmpfs to allow NetworkManager/systemd inside container."
    # tmpfs for /run and /run/lock help systemd and dbus; mount cgroup to allow systemd to detect cgroups
    EXTRA_DOCKER_FLAGS="--privileged --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /lib/modules:/lib/modules:ro"
else
    echo "Not enabling privileged mounts (ENABLE_PRIVILEGED=0). NetworkManager may not work inside the container."
fi

# The core command: running the container with persistence (-v). We pass the UID so you don't need
# to create a separate non-root user inside the container and we export resolution variables so
# images that support them can pick them up (commonly RESOLUTION or SCREEN_WIDTH/SCREEN_HEIGHT).
set -x
docker run $EXTRA_DOCKER_FLAGS --rm -it \
    -u "${USER_UID}:${USER_GID}" \
    -p "$NOVNC_PORT":8080 \
    -p "$VNC_PORT":5900 \
    -v "$PERSISTENT_DATA_DIR":/root/ \
    -e VNCDISPLAY="$SCREEN_RES" \
    "$IMAGE_NAME"
set +x

echo "--- Container Stopped ---"