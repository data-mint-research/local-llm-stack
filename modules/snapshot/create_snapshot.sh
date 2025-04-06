#!/bin/bash
# Simple snapshot script for LOCAL-LLM-Stack
# Creates a copy of all data and folders in the LOCAL-LLM-STACK directory
# and saves it under data/snapshots/yyyy-mm-dd

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/utils.sh"

# Get the current date in yyyy-mm-dd format
CURRENT_DATE=$(date +"%Y-%m-%d")

# Define the source and destination directories/files
SOURCE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOTS_DIR="${SOURCE_DIR}/data/snapshots"
ARCHIVE_FILE="${SNAPSHOTS_DIR}/snapshot-${CURRENT_DATE}.tar.gz"

# Create the snapshots directory if it doesn't exist
echo -e "${BLUE}Creating snapshots directory: ${SNAPSHOTS_DIR}${NC}"
mkdir -p "${SNAPSHOTS_DIR}"

# Check if the snapshots directory was created successfully
if [[ ! -d "${SNAPSHOTS_DIR}" ]]; then
    echo -e "${RED}Error: Failed to create snapshots directory${NC}"
    exit 1
fi

# Create a list of directories to exclude from the snapshot
# We don't want to include the snapshots directory itself to avoid recursion
# Also exclude large directories that might not need to be backed up
EXCLUDE_DIRS=(
    "./data/snapshots"
    "./data/models"  # Exclude large model files that can be re-downloaded
)

# Build the tar exclude options
EXCLUDE_OPTS=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_OPTS="${EXCLUDE_OPTS} --exclude=${dir}"
done

# Change to the source directory
cd "${SOURCE_DIR}" || handle_error 1 "Failed to change to source directory"

# Check if we have enough disk space (at least 1GB free)
FREE_SPACE=$(get_disk_space "$SOURCE_DIR")
if [[ "$FREE_SPACE" -lt 1 ]]; then
    echo -e "${RED}Error: Not enough disk space. You need at least 1GB free space.${NC}"
    exit 1
fi

# Check if we need sudo (if we don't own some of the files)
NEED_SUDO=0
if need_sudo "$SOURCE_DIR"; then
    NEED_SUDO=1
fi

# Create a tar.gz archive of all data and folders
echo -e "${BLUE}Creating snapshot archive of LOCAL-LLM-Stack...${NC}"

# Create the archive
if [[ $NEED_SUDO -eq 1 ]]; then
    echo -e "${YELLOW}This may require your sudo password...${NC}"
    sudo tar -czf "${ARCHIVE_FILE}" ${EXCLUDE_OPTS} .
    sudo chown $(whoami):$(whoami) "${ARCHIVE_FILE}"
else
    tar -czf "${ARCHIVE_FILE}" ${EXCLUDE_OPTS} .
fi

# Check if the archive was created successfully
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Snapshot archive created successfully at: ${ARCHIVE_FILE}${NC}"
    echo -e "${BLUE}Archive size: $(du -sh ${ARCHIVE_FILE} | cut -f1)${NC}"
else
    echo -e "${RED}Error: Failed to create snapshot archive${NC}"
    exit 1
fi

echo -e "${GREEN}Snapshot process completed${NC}"