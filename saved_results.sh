#!/bin/bash

# saved_results.sh
# Script to save important calculation outputs to a timestamped directory for archiving/analysis.

# Absolute project path
PROJECT_PATH="/home/rfa/SATA/Skripsi/DFT/dft-graphene"     #! will updated by update_paths.sh

# Check if PROJECT_PATH is set
if [ -z "$PROJECT_PATH" ]; then
  echo "ERROR: PROJECT_PATH is not set.  Please run update_paths.sh first." >&2
  exit 1
fi

save_path="$(PROJECT_PATH)/Saved_results"

# Create target directory if it doesn't exist
timestamp=$(date +%Y%m%d_%H%M%S)
random_string=$(openssl rand -hex 4) # Requires openssl
TARGET_DIR="$save_path/${timestamp}_${random_string}"
mkdir -p "$TARGET_DIR"

# Find and copy important files
echo "Saving important calculation results to $TARGET_DIR..."

# Function to find and copy files
copy_files() {
  local file_pattern="$1"
  find . -path "$PROJECT_PATH/convergence" -prune -o \( -name "$file_pattern" -print0 \) | xargs -0 cp -v -t "$TARGET_DIR"
}

# PNG files
copy_files "*.png"

# DAT files
copy_files "*.dat"

# PDF files
copy_files "*.pdf"

# GNU band files
copy_files "*.bands.gnu"

# Review markdown files
copy_files "*review.md"

echo "Done!"
