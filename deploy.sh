#!/usr/bin/env bash
set -e 

if [ "$#" -ne 3 ]; then
    echo "Usage: ./deploy.sh <hostname> <target_ip> <path_to_key>"
    echo "Example 1 (Encrypted): ./deploy.sh <hostname> <ip-address> secrets/admin.age"
    echo "Example 2 (Plaintext): ./deploy.sh <hostname> <ip-address> /etc/nryn-laptop-boot.txt"
    exit 1
fi

HOSTNAME=$1
TARGET_IP=$2
KEY_INPUT=$3

echo "1. Creating temporary staging folder in RAM..."
STAGE_DIR=$(mktemp -d)
trap "rm -rf $STAGE_DIR" EXIT

echo "2. Building the /etc folder structure..."
mkdir -p "$STAGE_DIR/etc"

echo "3. Extracting the boot secret from SOPS..."

# Check if the file ends in .age to determine how to handle it
if [[ "$KEY_INPUT" == *.age ]]; then
    echo "   -> Detected encrypted .age file. (You may be prompted for your password)"
    DECRYPTED_ADMIN_KEY=$(nix run nixpkgs#age -- -d "$KEY_INPUT" 2>/dev/null | grep AGE-SECRET-KEY)
    
    env -u SOPS_AGE_KEY_FILE SOPS_AGE_KEY="$DECRYPTED_ADMIN_KEY" nix run nixpkgs#sops -- -d --extract "[\"${HOSTNAME}-boot\"]" "secrets/${HOSTNAME}.yaml" > "$STAGE_DIR/etc/${HOSTNAME}-boot.txt"
else
    echo "   -> Detected plaintext key file (using sudo to read restricted file)."
    
    # Use sudo to read the root-owned file into a temporary RAM variable
    DECRYPTED_ADMIN_KEY=$(sudo cat "$KEY_INPUT")
    
    # Inject it directly into the SOPS environment (ignoring the file path)
    env -u SOPS_AGE_KEY_FILE SOPS_AGE_KEY="$DECRYPTED_ADMIN_KEY" nix run nixpkgs#sops -- -d --extract "[\"${HOSTNAME}-boot\"]" "secrets/${HOSTNAME}.yaml" > "$STAGE_DIR/etc/${HOSTNAME}-boot.txt"
fi

# Lock permissions for sops-nix
chmod 400 "$STAGE_DIR/etc/${HOSTNAME}-boot.txt"

echo "4. Running nixos-anywhere deployment..."
nix run github:nix-community/nixos-anywhere -- --extra-files "$STAGE_DIR" --flake ".#${HOSTNAME}" "root@${TARGET_IP}"

echo "5. Done! The trap has deleted the temporary files and cleared memory."