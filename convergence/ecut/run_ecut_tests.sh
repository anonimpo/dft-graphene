#!/bin/bash

# Script to run energy cutoff convergence tests for multilayer graphene systems

# --- Usage Function ---
usage() {
  cat << EOF
Usage: $0 [OPTIONS] <stacking_type> <num_layers> <num_cpus>

Runs energy cutoff convergence tests for specified graphene systems.

Arguments:
  <stacking_type>   Stacking type (e.g., AA, AB, 1L for monolayer).
  <num_layers>      Number of layers (integer, ignored if stacking_type is 1L).
  <num_cpus>        Number of CPUs to use for mpirun.

Options:
  -c, --custom-ecut "VALUES" : Specify custom space-separated ecut values (e.g., "30 40 50").
                               Defaults to a predefined list if not specified.
  -p, --plot                 : Show the convergence plot interactively after calculations.
                               The plot is always saved to a file.
  -h, --help                 : Display this help message and exit.

Example:
  # Run for 2-layer AA stacking with 4 CPUs, default ecut values, and show plot
  $0 -p AA 2 4

  # Run for monolayer with 8 CPUs and custom ecut values
  $0 -c "50 60 70 80" 1L 1 8
EOF
  exit 1
}
# --- End Usage Function ---

# --- Define Paths ---
# Absolute project path - this line will be updated by update_paths.sh
PROJECT_PATH="/run/media/rfa/SATA/Skripsi/DFT/dft-graphene" #! will updated by update_paths.sh
SCRIPT_PATH="${PROJECT_PATH}/convergence/ecut"
# --- End Define Paths ---

# --- Option Parsing ---
custom_ecut=""
plot_flag=0
# convergence_threshold="" # Removed - handled by plot_ecut.py

# Define options
SHORT_OPTS="c:ph" # Added 'h' for help
LONG_OPTS="custom-ecut:,plot,help" # Added 'help'

# Parse options
PARSED_OPTIONS=$(getopt -o $SHORT_OPTS --long $LONG_OPTS -n "$0" -- "$@")
if [ $? -ne 0 ]; then
    usage # Print usage on error
fi
eval set -- "$PARSED_OPTIONS"

# Extract options and their arguments into variables
while true; do
    case "$1" in
        -c|--custom-ecut)
            custom_ecut="$2"
            shift 2
            ;;
        -p|--plot)
            plot_flag=1
            shift
            ;;
        -t|--threshold)
            convergence_threshold="$2"
            shift 2
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

# Define the directory for this specific test using absolute paths
if [ "$stacking" = "1L" ]; then
  # For monolayer, use path relative to SCRIPT_PATH
  test_dir="${SCRIPT_PATH}/1L"
else
  # For multilayer, use stacking/layersL structure relative to SCRIPT_PATH
  test_dir="${SCRIPT_PATH}/${stacking}/${layers}L"
fi

# Check if the directory exists
if [ ! -d "$test_dir" ]; then
  echo "Error: Test directory $test_dir does not exist"
  exit 1
fi

# Define and create the results directory using an absolute path
results_dir="${test_dir}/results"
mkdir -p "$results_dir"

# Define the summary file path
summary_file="${results_dir}/ecut_vs_energy.dat"

# Clear the summary file before starting the loop
> "$summary_file"

# Values of ecutwfc to test

if [ -n "$custom_ecut" ]; then
  # Use custom values if provided
  read -r -a ecut_values <<< "$custom_ecut"
  echo "Using custom ecut values: ${ecut_values[@]}"
else
  # Default values
  ecut_values=(25 30 35 40 45 50 55 60 65 70 75)
  echo "Using default ecut values: ${ecut_values[@]}"
fi

# Loop through each value and run the calculation
for ecut in "${ecut_values[@]}"; do
  echo "Running calculation for ecut = $ecut Ry"

  # Define input and output file paths using absolute paths
  template_file="${test_dir}/template.in"
  input_file="${test_dir}/scf_${ecut}.in"
  output_file="${results_dir}/scf_${ecut}.out"

  # Check if template file exists
  if [ ! -f "$template_file" ]; then
      echo "Error: Template file not found at $template_file" >&2
      exit 1
  fi

  # Create a temporary input file with the current ecut value
  sed "s/ECUT_VALUE/$ecut/g" "$template_file" > "$input_file"

  # Run the calculation
  echo "mpirun -np $cpu pw.x < \"$input_file\" > \"$output_file\""
  mpirun -np $cpu pw.x < "$input_file" > "$output_file" 2>&1

  # Extract total energy - using more flexible pattern
  total_energy=$(grep "!\s*total energy\s*=" "$output_file" | tail -1 | awk '{print $5}')

  # Save to a summary file
  echo "$ecut  $total_energy" >> "$summary_file"

  echo "Completed ecut = $ecut Ry, Total energy = $total_energy Ry"
  echo "------------------------------------"
done

echo "All calculations completed. Results saved in $summary_file"

# --- Convergence Check (Removed - Handled by plot_ecut.py) ---
# The convergence check is now performed and reported by the plotting script.
# --- End Convergence Check ---


# --- Plotting ---
# Define the absolute path to the plot script
plot_script_path="${SCRIPT_PATH}/plot_ecut.py"

# Check if the plotting script exists
if [ -f "$plot_script_path" ]; then
  echo "Plotting results..."
  # Construct the command
  plot_cmd="python \"$plot_script_path\" \"$stacking\" \"$layers\""
  if [ $plot_flag -eq 1 ]; then
    plot_cmd+=" --show"
  fi

  # Execute the command
  eval $plot_cmd
  if [ $? -ne 0 ]; then
    echo "Error running plotting script." >&2
  else
    # Read and print the optimal ecut value if the file exists
    optimal_ecut_file="$results_dir/optimal_ecut.dat"
    if [ -f "$optimal_ecut_file" ]; then
      optimal_e=$(grep -v '^#' "$optimal_ecut_file" | head -n 1 | awk '{print $1}')
      if [ -n "$optimal_e" ]; then
        echo "------------------------------------"
        echo "Optimal Energy Cutoff (ecutwfc) determined to be: $optimal_e Ry"
        echo "(Based on convergence threshold in $plot_script_path)"
        echo "Value saved in $optimal_ecut_file"
        echo "------------------------------------"
      else
        echo "Warning: Could not read optimal ecut value from $optimal_ecut_file" >&2
      fi
    else
      echo "Warning: Optimal ecut file ($optimal_ecut_file) not found. Plotting script might have failed or convergence was not met." >&2
    fi
  fi

else
  echo "Warning: Plotting script $plot_script_path not found. Skipping plotting and optimal ecut determination." >&2
  echo "To plot manually, run: python \"$plot_script_path\" \"$stacking\" \"$layers\" [--show]" >&2
fi
# --- End Plotting ---
#
# hourspend=5 
