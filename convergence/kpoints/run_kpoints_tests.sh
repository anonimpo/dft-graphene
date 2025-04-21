#!/bin/bash

# Script to run k-point mesh convergence tests for multilayer graphene systems


# --- Usage Function ---
usage() {
  cat << EOF
Usage: $0 [OPTIONS] <stacking_type> <num_layers> <num_cpus>

Runs k-point mesh convergence tests for specified graphene systems.

Arguments:
  <stacking_type>   Stacking type (e.g., AA, AB, 1L for monolayer).
  <num_layers>      Number of layers (integer, ignored if stacking_type is 1L).
  <num_cpus>        Number of CPUs to use for mpirun.

Options:
  -p, --plot        : Show the convergence plot interactively after calculations.
                      The plot is always saved to a file.
  -h, --help        : Display this help message and exit.

Example:
  # Run for 2-layer AA stacking with 4 CPUs and show plot
  $0 -p AA 2 4

  # Run for monolayer with 8 CPUs
  $0 1L 1 8
EOF
  exit 1
}
# --- End Usage Function ---

# --- Option Parsing ---
plot_flag=0

# Define options
SHORT_OPTS="ph" # Added 'h' for help
LONG_OPTS="plot,help" # Added 'help'

# Parse options
PARSED_OPTIONS=$(getopt -o $SHORT_OPTS --long $LONG_OPTS -n "$0" -- "$@")
if [ $? -ne 0 ]; then
    usage # Print usage on error
fi
eval set -- "$PARSED_OPTIONS"

# Extract options and their arguments into variables
while true; do
    case "$1" in
        -p|--plot)
            plot_flag=1
            shift
            ;;
        -h|--help)
            usage # Display help message
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1 # Should not happen with getopt
            ;;
    esac
done

# Check if the required positional arguments are provided
if [ $# -lt 3 ]; then
  echo "Error: Not enough positional arguments provided." >&2 # Print errors to stderr
  usage
fi

# Assign positional arguments
stacking=$1
layers=$2
cpu=$3
# --- End Option Parsing ---

# --- Determine Paths ---
# Directory for this specific k-point test
kpoint_test_dir=""
# Directory where the corresponding ecut results are stored
ecut_results_dir=""

if [ "$stacking" = "1L" ]; then
  # For monolayer, use simpler paths
  kpoint_test_dir="./1L"
  ecut_results_dir="../ecut/1L/results"
else
  # For multilayer, use stacking/layersL structure
  kpoint_test_dir="./${stacking}/${layers}L"
  ecut_results_dir="../ecut/${stacking}/${layers}L/results"
fi

# Path to the optimal ecut file
optimal_ecut_file="${ecut_results_dir}/optimal_ecut.dat"

# --- Read Optimal Ecut ---
if [ ! -f "$optimal_ecut_file" ]; then
  echo "Error: Optimal ecut file not found at $optimal_ecut_file" >&2
  echo "Please run the ecut convergence test first for $stacking ${layers}L." >&2
  exit 1
fi

# Read the optimal ecut value (expects the value on the second line, skipping comments)
optimal_ecut=$(grep -v '^#' "$optimal_ecut_file" | head -n 1 | awk '{print $1}')

if [ -z "$optimal_ecut" ]; then
    echo "Error: Could not read optimal ecut value from $optimal_ecut_file" >&2
    exit 1
fi

# Basic validation if it's a number (optional but recommended)
if ! [[ "$optimal_ecut" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Invalid optimal ecut value read from $optimal_ecut_file: '$optimal_ecut'" >&2
    exit 1
fi

echo "Using optimal ecutwfc = $optimal_ecut Ry (read from $optimal_ecut_file)"
echo "------------------------------------"

# Define the directory for this specific test (using the kpoint_test_dir variable)
test_dir=$kpoint_test_dir
# --- End Reading Optimal Ecut ---


# Define the directory for this specific test
if [ "$stacking" = "1L" ]; then
  # For monolayer, use a simpler path
  test_dir="./1L"
else
  # For multilayer, use stacking/layersL structure
  test_dir="./${stacking}/${layers}L"
fi

# Check if the directory exists
if [ ! -d "$test_dir" ]; then
  echo "Error: Test directory $test_dir does not exist"
  exit 1
fi

# Create a results directory
mkdir -p "$test_dir/results"

# Values of kpoint meshes to test
kpoint_values=(7 8 9 10 11 12 13 14 15)
shift_values=(0 1)

# Loop through each k-point and shift value combination
for kpoints in "${kpoint_values[@]}"; do
  for shift in "${shift_values[@]}"; do
    echo "Running calculation for k-point mesh = $kpoints x $kpoints x $kpoints with shift = $shift x $shift x $shift (using ecut = $optimal_ecut Ry)"

    # Create a temporary input file with the current kpoints, shift, and optimal ecut values
    # IMPORTANT: Assumes 'ECUT_VALUE' is the placeholder in your template.in
    sed -e "s/KVALUE/$kpoints/g" \
        -e "s/SVALUE/$shift/g" \
        -e "s/ECUT_VALUE/$optimal_ecut/g" \
        "$test_dir/template.in" > "$test_dir/scf_k${kpoints}_s${shift}.in"

    # Run the calculation
    echo "mpirun -np $cpu pw.x < $test_dir/scf_k${kpoints}_s${shift}.in > $test_dir/results/scf_k${kpoints}_s${shift}.out"
    mpirun -np $cpu pw.x < "$test_dir/scf_k${kpoints}_s${shift}.in" > "$test_dir/results/scf_k${kpoints}_s${shift}.out" 2>&1
    
    # Extract total energy - using more flexible pattern
    total_energy=$(grep "!\s*total energy\s*=" "$test_dir/results/scf_k${kpoints}_s${shift}.out" | tail -1 | awk '{print $5}')
    
    # Save to a summary file
    echo "$kpoints $shift $total_energy" >> "$summary_file"

    echo "Completed k-point mesh = $kpoints x $kpoints x $kpoints, shift = $shift x $shift x $shift, Total energy = $total_energy Ry"
    echo "------------------------------------"
  done
done

echo "All calculations completed. Results saved in $summary_file"

# --- Plotting and Optimal K-point Determination ---
# Determine the relative path to the plot script from the project root
# Assuming this script is run from the 'kpoints' directory
plot_script_rel_path="./plot_kpoints.py"
# Construct absolute path relative to this script's location
plot_script_abs_path="$(dirname "$0")/$plot_script_rel_path"

# Check if the plotting script exists
if [ -f "$plot_script_abs_path" ]; then
  echo "Plotting results and determining optimal k-point grid..."
  # Construct the command
  plot_cmd="python \"$plot_script_abs_path\" \"$stacking\" \"$layers\""
  if [ $plot_flag -eq 1 ]; then
    plot_cmd+=" --show"
  fi

  # Execute the command
  eval $plot_cmd
  if [ $? -ne 0 ]; then
    echo "Error running plotting script." >&2
  else
    # Read and print the optimal k-point value if the file exists
    optimal_kpoints_file="$results_dir/optimal_kpoints.dat"
    if [ -f "$optimal_kpoints_file" ]; then
      optimal_k=$(grep -v '^#' "$optimal_kpoints_file" | head -n 1 | awk '{print $1}')
      if [ -n "$optimal_k" ]; then
        echo "------------------------------------"
        echo "Optimal K-point grid size (n x n x 1) determined to be: $optimal_k x $optimal_k x 1"
        echo "(Based on convergence threshold in $plot_script_rel_path)"
        echo "Value saved in $optimal_kpoints_file"
        echo "------------------------------------"
      else
        echo "Warning: Could not read optimal k-point value from $optimal_kpoints_file" >&2
      fi
    else
      echo "Warning: Optimal k-point file ($optimal_kpoints_file) not found. Plotting script might have failed or convergence was not met." >&2
    fi
  fi
else
  echo "Warning: Plotting script $plot_script_abs_path not found. Skipping plotting and optimal k-point determination." >&2
  echo "To plot manually, run: python $plot_script_rel_path $stacking $layers [--show]" >&2
fi
# --- End Plotting ---
