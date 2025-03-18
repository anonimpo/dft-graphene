#!/bin/bash

# Script to run energy cutoff convergence tests for multilayer graphene systems
# Usage: ./run_ecut_tests.sh <stacking_type> <num_layers> <num_cpus> <custom_ecut>
# Example: ./run_ecut_tests.sh AA 2 4

# Check if the required parameters are provided
if [ $# -lt 3 ]; then
  echo "Error: Not enough arguments provided."
  echo "Usage: $0 <stacking_type> <num_layers> <num_cpus>"
  echo "Example: $0 AA 2 4  # Runs AA bilayer with 4 CPUs"
  exit 1
fi

stacking=$1
layers=$2
cpu=$3
custom_ecut=$4

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

# Values of ecutwfc to test
#ecut_values=(30 40 50 60 70 80)
if [ -n "$custom_ecut" ]; then]
  ecut_values=($custom_ecut)
else
    ecut_values=(20 22 24 26 30 35 40 45 50 55 60 65 70 75 80)
fi

# Loop through each value and run the calculation
for ecut in "${ecut_values[@]}"; do
  echo "Running calculation for ecut = $ecut Ry"
  
  # Create a temporary input file with the current ecut value
  sed "s/ECUT_VALUE/$ecut/g" "$test_dir/template.in" > "$test_dir/scf_${ecut}.in"
  
  # Run the calculation
  echo "mpirun -np $cpu pw.x < $test_dir/scf_${ecut}.in > $test_dir/results/scf_${ecut}.out"
  mpirun -np $cpu pw.x < "$test_dir/scf_${ecut}.in" > "$test_dir/results/scf_${ecut}.out" 2>&1
  
  # Extract total energy - using more flexible pattern
  total_energy=$(grep "!\s*total energy\s*=" "$test_dir/results/scf_${ecut}.out" | tail -1 | awk '{print $5}')
  
  # Save to a summary file
  echo "$ecut  $total_energy" >> "$test_dir/results/ecut_vs_energy.dat"
  
  echo "Completed ecut = $ecut Ry, Total energy = $total_energy Ry"
  echo "------------------------------------"
done

echo "All calculations completed. Results saved in $test_dir/results/ecut_vs_energy.dat"
echo "To plot the results, use the provided plot_ecut.py script"
