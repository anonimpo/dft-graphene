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
  
  # Replace the entire line containing pseudo_dir or outdir
  # This is more robust than trying to match specific path formats
  sed -i "s|^.*pseudo_dir.*$|  pseudo_dir    = '$CURRENT_DIR/pseudo'|" "$file"
  sed -i "s|^.*outdir.*$|  outdir        = '$CURRENT_DIR/tmp'|" "$file"
}

# Define the path for the temporary file list within the project's tmp directory
TMP_FILE_LIST="$CURRENT_DIR/tmp/graphene_files.list"

# Create a temporary list of files to process
echo "Creating temporary file list at $TMP_FILE_LIST..."
find "$CURRENT_DIR" -type f -name "*.in" > "$TMP_FILE_LIST"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create temporary file list at $TMP_FILE_LIST."
    echo "Please check permissions for the directory $CURRENT_DIR/tmp/"
    exit 1
fi


# Process files in batches to show progress
TOTAL=$(cat "$TMP_FILE_LIST" | wc -l)
COUNTER=0

echo "Updating paths in input files..."
while IFS= read -r file; do
  update_file "$file"
  COUNTER=$((COUNTER + 1))
  # Avoid division by zero if TOTAL is 0
  if [ "$TOTAL" -gt 0 ]; then
    PERCENTAGE=$((COUNTER * 100 / TOTAL))
    echo -ne "  Progress: $PERCENTAGE% ($COUNTER/$TOTAL)\r"
  else
    echo -ne "  Progress: 0% (0/0)\r"
  fi
done < "$TMP_FILE_LIST"

# Clean up the temporary file
rm "$TMP_FILE_LIST"

echo -e "\nAll input files updated successfully!"
echo ""
echo "Path information:"
echo "- Pseudopotential directory: $CURRENT_DIR/pseudo/"
echo "- Temporary files directory: $CURRENT_DIR/tmp/"
#hourspend=3
