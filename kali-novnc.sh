#!/bin/bash

# --- Configuration ---
# 1. Choose where on your Q4OS system the Kali data will be stored.
#    This directory will be created if it doesn't exist.
PERSISTENT_DATA_DIR="$HOME/my_workspace/kali-novnc/"

# 2. Docker Image and Ports
IMAGE_NAME="lonetis/kali-docker:latest"
NOVNC_PORT=9020 # Access noVNC in your browser: http://localhost:9020
VNC_PORT=9021   # Direct VNC access

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
            echo "✅ Docker installation complete. Adding current user to the docker group."
            sudo usermod -aG docker "$USER"
            echo "❗❗ You need to **log out and log back in** for the docker group change to take effect."
            echo "   Please log out and run this script again."
            exit 1
        else
            echo "❌ Docker installation failed. Please check the error messages."
            exit 1
        fi
    fi
}

# --- Main Execution ---

# 1. Run the Docker check/install function
check_and_install_docker

# Check for persistence directory and create if not exists
if [ ! -d "$PERSISTENT_DATA_DIR" ]; then
    echo "Creating persistent data directory at: $PERSISTENT_DATA_DIR"
    mkdir -p "$PERSISTENT_DATA_DIR"
fi

echo "--- Starting Kali Docker Container ---"
echo "Data will be saved to: $PERSISTENT_DATA_DIR"
echo "Access noVNC at: http://localhost:$NOVNC_PORT"

# The core command: running the container with persistence (-v)
docker run --rm -it \
    -p "$NOVNC_PORT":8080 \
    -p "$VNC_PORT":5900 \
    -v "$PERSISTENT_DATA_DIR":/root/ \
    "$IMAGE_NAME"

echo "--- Container Stopped ---"