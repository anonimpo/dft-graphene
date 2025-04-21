#!/bin/bash

# README{
# Script to determine the convergence of an energy calculation based on Ecut and energy values.
# Reads a data file with Ecut in column 1 and Energy in column 2.
# Checks if the absolute energy difference between consecutive steps falls below a threshold.
#
# Usage:
#   ./check_convergence.sh <data_file> [threshold]
#
# Arguments:
#   <data_file> : Path to the data file containing Ecut (col 1) and Energy (col 2).
#                 Lines starting with '#' or empty lines are ignored.
#   [threshold] : Optional convergence threshold in Ry.
#                 If not provided, defaults to 0.001 Ry.
#
# Example:
#   ./check_convergence.sh results/ecut_vs_energy.dat 0.0005
#   ./check_convergence.sh results/ecut_vs_energy.dat

#}

# Check if the data file exists
data_file=$1          #argument path data
if [[ ! -f "$data_file" ]]; then
    echo "Error: Data file '$data_file' not found."
    exit 1
fi

# Set the convergence threshold
threshold=$2
if [[ -z "$threshold" ]]; then
    # If no threshold is provided, use the default value
    threshold=0.001
    echo "Info: No threshold provided. Using default value: $threshold Ry"
elif ! [[ "$threshold" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    # Validate if the provided threshold is a positive number
    echo "Error: Invalid threshold value '$threshold'. Must be a positive number."
    exit 1
fi

# Initialize variables
previous_ecut=""
previous_energy=""
converged=false

# Read the file line by line, skipping comments or empty lines
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines or lines starting with #
    [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # Validate the line format (two numbers, potentially negative energy)
    # Allows optional leading sign for energy
    if ! [[ "$line" =~ ^[[:space:]]*[0-9]+(\.[0-9]+)?[[:space:]]+-?[0-9]+(\.[0-9]+)?[[:space:]]*$ ]]; then
        echo "Warning: Skipping invalid data format in line: '$line'"
        continue # Skip to the next line
    fi

    # Extract Ecut (col 1) and Energy (col 2) using awk for efficiency
    read -r current_ecut current_energy <<< "$(echo "$line" | awk '{print $1, $2}')"
    if [[ -z "$current_ecut" ]] || [[ -z "$current_energy" ]]; then
         echo "Warning: Failed to extract Ecut or Energy from line: '$line'"
         continue # Skip if awk failed to extract both values
    fi


    # Check if we have a previous energy value to compare with
    if [[ -n "$previous_energy" ]]; then
        # Calculate absolute difference and compare with threshold using awk
        # awk returns 1 if converged, 0 otherwise, and the calculated difference
        read -r comparison energy_diff <<< $(awk -v ce="$current_energy" -v pe="$previous_energy" -v th="$threshold" '
            BEGIN {
                diff = ce - pe;
                abs_diff = (diff < 0) ? -diff : diff;
                converged = (abs_diff < th) ? 1 : 0;
                printf "%d %.10f\n", converged, abs_diff;
            }')

        if [[ "$comparison" -eq 1 ]]; then
            printf "Convergence reached at Ecut = %.1f Ry\n" "$current_ecut"
            printf "  Previous Ecut = %-8.1f Ry, Energy = %-15.8f Ry\n" "$previous_ecut" "$previous_energy"
            printf "  Current Ecut  = %-8.1f Ry, Energy = %-15.8f Ry\n" "$current_ecut" "$current_energy"
            printf "  Energy difference = %.10f Ry (Threshold = %s Ry)\n" "$energy_diff" "$threshold"
            converged=true
            break # Exit the loop once converged
        fi
    fi

    # Store current values for the next iteration
    previous_ecut="$current_ecut"
    previous_energy="$current_energy"

done < "$data_file"

# Check if convergence was achieved
if [[ "$converged" = false ]]; then
    echo "Convergence not reached within the given data (Threshold = $threshold Ry)."
fi

exit 0
