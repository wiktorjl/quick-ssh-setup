#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo -e "${RED}Usage: $0 <user_name> <host_friendly_name> <host_canonical_name>${NC}"
    exit 1
fi

USER_NAME=$1
HOST_FRIENDLY_NAME=$2
HOST_CANONICAL_NAME=$3
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
LOCAL_KEY="$SSH_DIR/id_rsa"
LOCAL_KEY_PUB="$SSH_DIR/id_rsa.pub"

# Ensure .ssh directory exists
mkdir -p $SSH_DIR
chmod 700 $SSH_DIR

# Generate SSH key if it does not exist
if [ ! -f "$LOCAL_KEY" ]; then
    echo -e "${YELLOW}Generating SSH key...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$LOCAL_KEY" -N ""
fi

# Check if the config entry already exists
if grep -q "$HOST_FRIENDLY_NAME" "$SSH_CONFIG"; then
    echo -e "${RED}SSH config entry for $HOST_FRIENDLY_NAME already exists.${NC}"
else
    echo -e "${GREEN}Adding SSH config entry for $HOST_FRIENDLY_NAME...${NC}"
    cat >> "$SSH_CONFIG" <<EOL

Host $HOST_FRIENDLY_NAME
    HostName $HOST_CANONICAL_NAME
    User $USER_NAME
    IdentityFile $LOCAL_KEY
EOL
fi

# Check if the public key is already in the remote authorized_keys
echo -e "${YELLOW}Checking if the public key is already on the remote host...${NC}"
if ssh -o PasswordAuthentication=no $USER_NAME@$HOST_CANONICAL_NAME "grep -q '$(cat $LOCAL_KEY_PUB)' ~/.ssh/authorized_keys"; then
    echo -e "${RED}Public key already exists in the remote authorized_keys.${NC}"
else
    echo -e "${GREEN}Copying public key to remote authorized_keys...${NC}"
    ssh-copy-id -i $LOCAL_KEY_PUB $USER_NAME@$HOST_CANONICAL_NAME
fi

# Test the final setup
echo -e "${YELLOW}Testing SSH connection to $HOST_FRIENDLY_NAME...${NC}"
ssh -o PasswordAuthentication=no $HOST_FRIENDLY_NAME "echo -e '${GREEN}SSH connection successful.${NC}'" || echo -e "${RED}SSH connection failed.${NC}"

