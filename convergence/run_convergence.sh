#!/bin/bash

# Main script to run all convergence tests sequentially (ecut -> kpoints -> vacuum)
# where each step uses optimal parameters from previous steps
# 
# Usage: ./run_convergence.sh <cpus> <stacking> <layers> [options]
# Options:
#   --only-layer            Only run for specific layer(s) provided in <layers>
#   --only-stacking         Only run for specific stacking(s) provided in <stacking>
#   --ignore=<tests>        Skip specified tests (comma-separated: ecut,kpoints,vacuum)
#
# Examples:
#   ./run_convergence.sh 4 AA 2              # Run all tests for AA bilayer with 4 CPUs
#   ./run_convergence.sh 4 "AA AB" "2 3"     # Run for AA and AB stacking with 2 and 3 layers
#   ./run_convergence.sh 4 AA 2 --ignore=vacuum  # Skip vacuum tests
#   ./run_convergence.sh 4 AA 2 --only-stacking  # Only run for AA stacking

# Default values
cpus=""
stacking_list=""
layers_list=""
ignore_list=""
only_layer=false
only_stacking=false

# Process arguments
if [ $# -lt 3 ]; then
  echo "Error: Not enough arguments."
  echo "Usage: $0 <cpus> <stacking> <layers> [options]"
  echo "Options:"
  echo "  --only-layer            Only run for specific layer(s)"
  echo "  --only-stacking         Only run for specific stacking(s)"
  echo "  --ignore=<tests>        Skip specified tests (comma-separated: ecut,kpoints,vacuum)"
  exit 1
fi

cpus=$1
stacking_list=$2
layers_list=$3

# Process options
shift 3
while [ "$#" -gt 0 ]; do
  case "$1" in
    --only-layer)
      only_layer=true
      ;;
    --only-stacking)
      only_stacking=true
      ;;
    --ignore=*)
      ignore_list="${1#*=}"
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# Get script directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Check if test should be run based on ignore list
should_run_test() {
  local test_name=$1
  if [[ "$ignore_list" == *"$test_name"* ]]; then
    return 1  # Don't run
  else
    return 0  # Run
  fi
}

# Get all available stacking types if not restricted to specific ones
get_stacking_types() {
  if $only_stacking; then
    echo "$stacking_list"
  else
    # Include 1L and all stacking types from directories
    echo "1L AA AB ABC"
  fi
}

# Get all available layer numbers for a stacking if not restricted to specific ones
get_layer_numbers() {
  local stacking=$1
  
  if [ "$stacking" = "1L" ]; then
    echo "1"
    return
  fi
  
  if $only_layer; then
    echo "$layers_list"
  else
    case "$stacking" in
      AA|AB)
        echo "2 3 4"
        ;;
      ABC)
        echo "3 4"
        ;;
      *)
        echo "Error: Unknown stacking type: $stacking" >&2
        exit 1
        ;;
    esac
  fi
}

# Function to find optimal value from convergence data
# Arguments: data_file threshold_percent
find_optimal_value() {
  local data_file=$1
  local threshold=${2:-0.001}  # Default threshold 0.001 Ry (~0.01 eV)
  
  if [ ! -f "$data_file" ]; then
    echo "Error: Data file $data_file not found!" >&2
    return 1
  fi
  
  # Sort by the first column (numerical) and get the last energy value as reference
  local last_energy=$(sort -n "$data_file" | tail -1 | awk '{print $2}')
  
  # Loop through values to find the point of convergence
  while read -r value energy; do
    local diff=$(echo "$last_energy - $energy" | bc -l | awk '{print ($1<0)?-$1:$1}')
    local rel_diff=$(echo "$diff / $last_energy * 100" | bc -l)
    
    # If difference is less than threshold, this is our converged value
    if (( $(echo "$rel_diff < $threshold" | bc -l) )); then
      echo "$value"
      return 0
    fi
  done < <(sort -n "$data_file")
  
  # If no convergence found, return the last value
  local last_value=$(sort -n "$data_file" | tail -1 | awk '{print $1}')
  echo "$last_value"
}

# Print run configuration
echo "Running convergence tests with:"
echo "- CPUs: $cpus"
echo "- Stacking types: $(get_stacking_types)"
for stacking in $(get_stacking_types); do
  echo "  - $stacking layers: $(get_layer_numbers $stacking)"
done
echo "- Tests to run:"
should_run_test "ecut" && echo "  - Energy cutoff (ecut)"
should_run_test "kpoints" && echo "  - K-points mesh"
should_run_test "vacuum" && echo "  - Vacuum size"
echo

# Main execution loop
for stacking in $(get_stacking_types); do
  for layers in $(get_layer_numbers $stacking); do
    echo "======================================================"
    echo "Processing: $stacking with $layers layer(s)"
    echo "======================================================"
    
    # Determine the test directory structure
    if [ "$stacking" = "1L" ]; then
      test_dir_suffix="1L"
    else
      test_dir_suffix="${stacking}/${layers}L"
    fi
    
    optimal_ecut=""
    optimal_kpoints=""
    
    # 1. Run ecut convergence
    if should_run_test "ecut"; then
      echo "Step 1: Running energy cutoff (ecut) convergence..."
      cd "$SCRIPT_DIR/ecut"
      ./run_ecut_tests.sh $stacking $layers $cpus
      
      # Find optimal ecut value
      ecut_data="$SCRIPT_DIR/ecut/$test_dir_suffix/results/ecut_vs_energy.dat"
      if [ -f "$ecut_data" ]; then
        optimal_ecut=$(find_optimal_value "$ecut_data")
        echo "Optimal energy cutoff (ecut) = $optimal_ecut Ry"
      else
        echo "Warning: Could not find ecut convergence data!"
        optimal_ecut=60  # Default fallback value
      fi
      
      cd - > /dev/null
      echo "Energy cutoff convergence completed."
    else
      echo "Skipping energy cutoff convergence as requested."
      # Use a default value if ecut was skipped
      optimal_ecut=60
    fi
    
    # 2. Run k-points convergence with optimal ecut
    if should_run_test "kpoints" && [ -n "$optimal_ecut" ]; then
      echo "Step 2: Running k-points mesh convergence with ecut = $optimal_ecut Ry..."
      
      # Update the kpoints template with optimal ecut
      kpoints_template="$SCRIPT_DIR/kpoints/$test_dir_suffix/template.in"
      if [ -f "$kpoints_template" ]; then
        # Backup original template
        cp "$kpoints_template" "${kpoints_template}.bak"
        # Update template with optimal ecut
        sed -i "s/ecutwfc\s*=\s*[0-9.]\+/ecutwfc = $optimal_ecut/g" "$kpoints_template"
      fi
      
      cd "$SCRIPT_DIR/kpoints"
      ./run_kpoints_tests.sh $stacking $layers $cpus
      
      # Find optimal kpoints value
      kpoints_data="$SCRIPT_DIR/kpoints/$test_dir_suffix/results/kpoints_vs_energy.dat"
      if [ -f "$kpoints_data" ]; then
        optimal_kpoints=$(find_optimal_value "$kpoints_data")
        echo "Optimal k-points mesh = $optimal_kpoints x $optimal_kpoints x 1"
      else
        echo "Warning: Could not find kpoints convergence data!"
        optimal_kpoints=12  # Default fallback value
      fi
      
      # Restore original template
      if [ -f "${kpoints_template}.bak" ]; then
        mv "${kpoints_template}.bak" "$kpoints_template"
      fi
      
      cd - > /dev/null
      echo "K-points mesh convergence completed."
    else
      echo "Skipping k-points convergence as requested or missing ecut value."
      # Use a default value if kpoints was skipped
      optimal_kpoints=12
    fi
    
    # 3. Run vacuum convergence with optimal ecut and kpoints
    if should_run_test "vacuum" && [ -n "$optimal_ecut" ] && [ -n "$optimal_kpoints" ]; then
      echo "Step 3: Running vacuum size convergence with ecut = $optimal_ecut Ry and k-points = $optimal_kpoints x $optimal_kpoints x 1..."
      
      # Update the vacuum template with optimal ecut and kpoints
      vacuum_template="$SCRIPT_DIR/vacuum/$test_dir_suffix/template.in"
      if [ -f "$vacuum_template" ]; then
        # Backup original template
        cp "$vacuum_template" "${vacuum_template}.bak"
        # Update template with optimal values
        sed -i "s/ecutwfc\s*=\s*[0-9.]\+/ecutwfc = $optimal_ecut/g" "$vacuum_template"
        sed -i "s/K_POINTS.*automatic/K_POINTS automatic/g" "$vacuum_template"
        sed -i "s/\([0-9]\+\s\+[0-9]\+\s\+[0-9]\+\s\+[0-9]\+\s\+[0-9]\+\s\+[0-9]\+\)/$optimal_kpoints $optimal_kpoints 1 0 0 0/g" "$vacuum_template"
      fi
      
      cd "$SCRIPT_DIR/vacuum"
      ./run_vacuum_tests.sh $stacking $layers $cpus
      
      # Find optimal vacuum value
      vacuum_data="$SCRIPT_DIR/vacuum/$test_dir_suffix/results/vacuum_vs_energy.dat"
      if [ -f "$vacuum_data" ]; then
        optimal_vacuum=$(find_optimal_value "$vacuum_data")
        echo "Optimal vacuum size = $optimal_vacuum Å"
      else
        echo "Warning: Could not find vacuum convergence data!"
      fi
      
      # Restore original template
      if [ -f "${vacuum_template}.bak" ]; then
        mv "${vacuum_template}.bak" "$vacuum_template"
      fi
      
      cd - > /dev/null
      echo "Vacuum size convergence completed."
    else
      echo "Skipping vacuum size convergence as requested or missing optimal values."
    fi
    
    # Output final optimal parameters
    echo "================================================================"
    echo "Final optimal parameters for $stacking with $layers layer(s):"
    echo "- Energy cutoff (ecut): $optimal_ecut Ry"
    echo "- K-points mesh: $optimal_kpoints x $optimal_kpoints x 1"
    if [ -n "$optimal_vacuum" ]; then
      echo "- Vacuum size: $optimal_vacuum Å"
    fi
    echo "================================================================"
    echo
  done
done

echo "All convergence tests have been completed."
