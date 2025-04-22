
#!/bin/bash

# Script to automatically update all paths in input files based on the current directory

# Use absolute path from the start to avoid surprises
CURRENT_DIR=$(pwd)
# or CURRENT_DIR=$(realpath .)  # More robust, handles symlinks

echo "Current directory: $CURRENT_DIR"

# Define the specific shell scripts to update PROJECT_PATH in
TARGET_SH_SCRIPTS=(
  "saved_results.sh"
  "convergence/ecut/run_ecut_tests.sh"
  "convergence/kpoints/run_kpoints_tests.sh"
)

# Check if this is a valid Graphene directory
if [ ! -d "$CURRENT_DIR/pseudo" ] || [ ! -d "$CURRENT_DIR/tmp" ]; then
  echo "Error: This doesn't seem to be a valid Graphene directory."
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
  if ! sed -i "s|^ *pseudo_dir *=.*$|  pseudo_dir    = '$CURRENT_DIR/pseudo'|" "$file"; then
    echo "Error: Failed to update pseudo_dir in $file" >&2 
    return 1 
  fi

  if ! sed -i "s|^ *outdir *=.*$|  outdir        = '$CURRENT_DIR/tmp'|" "$file"; then
    echo "Error: Failed to update outdir in $file" >&2 
    return 1 
  fi
  return 0 
}


# Process files in batches to show progress
TOTAL="$FILE_COUNT" 
COUNTER=0

echo "Updating paths in input files..."

find "$CURRENT_DIR" -type f -name "*.in" | while IFS= read -r file; do
  if update_file "$file"; then
    COUNTER=$((COUNTER + 1))
    # Avoid division by zero if TOTAL is 0
    if [ "$TOTAL" -gt 0 ]; then
      PERCENTAGE=$((COUNTER * 100 / TOTAL))
      echo -ne "  Progress: $PERCENTAGE% ($COUNTER/$TOTAL)\r"
    else
      echo -ne "  Progress: 0% (0/0)\r"
    fi
  else
    echo "Error: Failed to update $file.  Skipping." >&2
  fi
done

echo -e "\nAll input files updated successfully!"

# --- Update PROJECT_PATH in specific shell scripts ---
echo ""
echo "Path information:"
ehco "- Project directory         : $CURRENT_DIR/"
echo "- Pseudopotential directory : $CURRENT_DIR/pseudo/"
echo "- Temporary files directory : $CURRENT_DIR/tmp/"
echo "Attempting to update PROJECT_PATH in specific shell scripts..."

SH_UPDATED_COUNT=0
SH_SKIPPED_COUNT=0

for script_relative_path in "${TARGET_SH_SCRIPTS[@]}"; do
  sh_file="$CURRENT_DIR/$script_relative_path"
  sh_basename=$(basename "$sh_file")

  if [ ! -f "$sh_file" ]; then
    echo "  Skipping: $sh_basename (File not found at $sh_file)"
    SH_SKIPPED_COUNT=$((SH_SKIPPED_COUNT + 1))
    continue
  fi

  # Check if the file contains the marker comment on a PROJECT_PATH line
  if grep -q '^PROJECT_PATH=.*#! will updated by update_paths.sh$' "$sh_file"; then
    echo "  Updating PROJECT_PATH in $sh_basename..."
    # Use sed with a temporary file for safety
    # Create temp file in the same directory to avoid cross-device move issues
    tmp_file=$(mktemp "$CURRENT_DIR/sed_temp.XXXXXX")
    if [ -z "$tmp_file" ] || [ ! -f "$tmp_file" ]; then
        echo "Error: Could not create temporary file in $CURRENT_DIR for $sh_basename. Check permissions." >&2
        SH_SKIPPED_COUNT=$((SH_SKIPPED_COUNT + 1))
        continue # Skip this file
    fi

    # Escape CURRENT_DIR for sed replacement
    ESCAPED_CURRENT_DIR=$(sed 's/[&/\]/\\&/g' <<<"$CURRENT_DIR")

    # Perform substitution
    if sed "s|^PROJECT_PATH=.*#! will updated by update_paths.sh$|PROJECT_PATH=\"$ESCAPED_CURRENT_DIR\" #! will updated by update_paths.sh|" "$sh_file" > "$tmp_file"; then
      # Check write permissions before moving
      if [ -w "$sh_file" ] && [ -w "$(dirname "$sh_file")" ]; then
        # Overwrite original file
        if mv "$tmp_file" "$sh_file"; then
            SH_UPDATED_COUNT=$((SH_UPDATED_COUNT + 1))
        else
            echo "Error: Failed to move temporary file to $sh_file. Check permissions or disk space." >&2
            rm "$tmp_file" # Clean up temp file
            SH_SKIPPED_COUNT=$((SH_SKIPPED_COUNT + 1))
        fi
      else
        echo "Error: No write permission for $sh_file or its directory. Skipping." >&2
        rm "$tmp_file" # Clean up temp file
        SH_SKIPPED_COUNT=$((SH_SKIPPED_COUNT + 1))
      fi
    else
      echo "Error: sed command failed for $sh_file. Skipping." >&2
      rm "$tmp_file" # Clean up temp file
      SH_SKIPPED_COUNT=$((SH_SKIPPED_COUNT + 1))
    fi
  else
    echo "  Skipping: $sh_basename (Marker comment '#! will updated by update_paths.sh' not found on PROJECT_PATH line)"
    SH_SKIPPED_COUNT=$((SH_SKIPPED_COUNT + 1))
  fi
done

echo "Shell script update summary: $SH_UPDATED_COUNT updated, $SH_SKIPPED_COUNT skipped."

# --- Final Summary ---
echo ""
echo "Path information:"
echo "- Project directory         : $CURRENT_DIR/"
echo "- Pseudopotential directory : $CURRENT_DIR/pseudo/"
echo "- Temporary files directory : $CURRENT_DIR/tmp/"
echo ""
echo "Remember to add the marker comment '#! will updated by update_paths.sh' to the end of the PROJECT_PATH line in any .sh script you want this tool to update."
echo "Example: PROJECT_PATH=\"/old/path/to/project\" #! will updated by update_paths.sh"

# Suggest renaming the script
if [[ "$(basename "$0")" == "test.sh" ]]; then
    echo ""
    echo "Suggestion: Rename this script to 'update_paths.sh' for clarity:"
    echo "  mv test.sh update_paths.sh && chmod +x update_paths.sh"
fi

#hourspend=3
echo "Path information:"
echo "- Project directory         : $CURRENT_DIR/"
echo "- Pseudopotential directory : $CURRENT_DIR/pseudo/"
echo "Reminder: Ensure the PROJECT_PATH line in the target scripts (${TARGET_SH_SCRIPTS[*]})"
echo "ends with the marker comment: '#! will updated by update_paths.sh'"
echo "Example: PROJECT_PATH=\"/old/path/to/project\" #! will updated by update_paths.sh"

# Suggest renaming the script
if [[ "$(basename "$0")" == "test.sh" ]]; then
    echo ""
    echo "Suggestion: Rename this script to 'update_paths.sh' for clarity:"
    echo "  mv test.sh update_paths.sh && chmod +x update_paths.sh"
fi


#hourspend=3
