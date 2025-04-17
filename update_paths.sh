#!/bin/bash

# Script to automatically update all paths in input files based on the current directory
# This allows the code to work on both your local machine and the server

# Get the current absolute path to the project directory
CURRENT_DIR=$(pwd)
echo "Current directory: $CURRENT_DIR"

# Check if this is a valid Graphene directory
if [ ! -d "$CURRENT_DIR/pseudo" ] || [ ! -d "$CURRENT_DIR/tmp" ]; then
  echo "Error: This doesn't seem to be a valid Graphene directory."
  echo "Make sure you run this script from the root of the Graphene directory."
  exit 1
fi

# Count how many files we'll update
FILE_COUNT=$(find "$CURRENT_DIR" -type f -name "*.in" | wc -l)
echo "Found $FILE_COUNT input files to update"

# Function to update a single file
update_file() {
  local file="$1"
  local base_name=$(basename "$file")
  echo "  Updating $base_name..."
  
  # Replace absolute paths with the current directory
  sed -i "s|pseudo_dir\s*=\s*['\"].*['\"]|pseudo_dir = '$CURRENT_DIR/pseudo/'|g" "$file"
  sed -i "s|pseudo_dir\s*=\s*[^ ,]*/pseudo/|pseudo_dir = '$CURRENT_DIR/pseudo/'|g" "$file"
  
  sed -i "s|outdir\s*=\s*['\"].*['\"]|outdir = '$CURRENT_DIR/tmp/'|g" "$file"
  sed -i "s|outdir\s*=\s*[^ ,]*/tmp/\?|outdir = '$CURRENT_DIR/tmp/'|g" "$file"
  
  # Also handle the bands.in files specifically
  if [ "$base_name" = "bands.in" ]; then
    sed -i "s|outdir\s*=\s*.*$|outdir = '$CURRENT_DIR/tmp/'|g" "$file"
  fi
}

# Create a temporary list of files to process
find "$CURRENT_DIR" -type f -name "*.in" > /tmp/graphene_files.txt

# Process files in batches to show progress
TOTAL=$(cat /tmp/graphene_files.txt | wc -l)
COUNTER=0

echo "Updating paths in input files..."
while IFS= read -r file; do
  update_file "$file"
  COUNTER=$((COUNTER + 1))
  PERCENTAGE=$((COUNTER * 100 / TOTAL))
  echo -ne "  Progress: $PERCENTAGE% ($COUNTER/$TOTAL)\r"
done < /tmp/graphene_files.txt

echo -e "\nAll input files updated successfully!"
echo ""
echo "Path information:"
echo "- Pseudopotential directory: $CURRENT_DIR/pseudo/"
echo "- Temporary files directory: $CURRENT_DIR/tmp/"
echo ""
echo "You can now run calculations with the corrected paths."