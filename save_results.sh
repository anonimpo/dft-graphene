#!/bin/bash

# Create timestamped directory in Save_results
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SAVE_DIR="./Saved_results/${TIMESTAMP}"
mkdir -p "$SAVE_DIR"

# Find and copy specific file types from convergence directory
find ./convergence -type f \( -name "*.png" -o -name "*.dat" -o -name "*.pdf" -o -name "*.txt" -o -name "*.bands.gnu" \) -exec cp --parents {} "$SAVE_DIR" \;

echo "Results saved to $SAVE_DIR"