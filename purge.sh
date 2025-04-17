#!/bin/bash

# purge.sh - Clean all calculation output files after saving important results
#
# This script will remove all output files from calculations, but will NOT
# remove files from the saved_results directory.
#
# Usage: ./purge.sh [--dry-run] [--force]
# Recommendation: Run ./save_results.sh first to backup important files

# Print help message
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: ./purge.sh [--dry-run] [--force]"
  echo ""
  echo "Options:"
  echo "  --dry-run   Show what would be deleted without actually deleting anything"
  echo "  --force     Skip confirmation prompt and proceed with purge"
  echo "  --help      Show this help message"
  echo ""
  echo "This script will clean all calculation outputs."
# echo "IMPORTANT: Run ./save_results.sh first to backup important files!"
  exit 0
fi

# Check arguments
dry_run=0
force=0
for arg in "$@"; do
  case $arg in
    --dry-run)
      dry_run=1
      ;;
    --force)
      force=1
      ;;
    *)
      echo "Unknown option: $arg. Use --help for usage information."
      exit 1
      ;;
  esac
done

# Check if saved_results directory exists, if not issue a warning
if [ ! -d "saved_results" ] && [ $dry_run -eq 0 ]; then
  echo "WARNING: 'saved_results' directory not found!"
# echo "It is recommended to run ./save_results.sh before purging to backup important files." 
  echo ""
  
  if [ $force -eq 0 ]; then
    read -p "Continue without backing up? (y/n): " continue_without_backup
    if [[ "$continue_without_backup" != "y" && "$continue_without_backup" != "Y" ]]; then
      echo "Purge aborted"
  #   echo "Purge aborted. Please run ./save_results.sh first."
      exit 0
    fi
  fi
fi

# Define files to be purged
echo "Identifying files to purge..."

# Function to list files that would be purged
list_purgeable_files() {
  # Output files in convergence tests
  find convergence -name "*.out" -type f
  find convergence -name "*.dat" -type f
  find convergence -name "scf_*.in" -type f  # Input files from convergence tests
  
  # Output files in structures
  find structures -name "*.out" -type f
  find structures -name "*.bands" -type f
  find structures -name "*.bands.gnu" -type f
  find structures -name "*.bands.rap" -type f
  
  # Generated plot files (excluding saved_results directory and venv-dft)
  find . -name "plot-bands.pdf" -type f -not -path "./saved_results/*" -not -path "./venv-dft/*"
  find . -name "*_convergence.pdf" -type f -not -path "./saved_results/*" -not -path "./venv-dft/*"
  find . -name "*.png" -type f -not -path "./saved_results/*" -not -path "./venv-dft/*"
  
  # Temporary files
  find tmp -type f
  
  # Log files
  find logs -type f
}

# Count files to be purged
purgeable_files=$(list_purgeable_files)
file_count=$(echo "$purgeable_files" | wc -l)

if [ $dry_run -eq 1 ]; then
  echo "DRY RUN: Would purge $file_count files."
  echo "Files that would be purged:"
  echo "$purgeable_files"
  echo "No files were actually deleted. Run without --dry-run to perform the purge."
  exit 0
fi

# Perform the purge
echo "Purging $file_count files..."

# Remove output files
for file in $purgeable_files; do
  echo "Removing $file"
  rm -f "$file"
done

# Clean empty directories
find convergence structures tmp logs -type d -empty -delete 2>/dev/null

echo "Purge completed successfully."
#echo "Important results have been preserved in the 'saved_results' directory."
