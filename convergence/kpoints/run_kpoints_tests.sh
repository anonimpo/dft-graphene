#!/bin/bash

# Script to run k-point mesh convergence tests for multilayer graphene systems
# Usage: ./run_kpoints_tests.sh <stacking_type> <num_layers> <num_cpus>
# Example: ./run_kpoints_tests.sh AA 2 4

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
kpoint_values=(6 8 12 16 24)

# Loop through each value and run the calculation
for kpoints in "${kpoint_values[@]}"; do
  echo "Running calculation for k-point mesh = $kpoints x $kpoints x 1"
  
  # Create a temporary input file with the current kpoints value
  sed "s/KVALUE/$kpoints/g" "$test_dir/template.in" > "$test_dir/scf_k${kpoints}.in"
  
  # Run the calculation
  echo "mpirun -np $cpu pw.x < $test_dir/scf_k${kpoints}.in > $test_dir/results/scf_k${kpoints}.out"
  mpirun -np $cpu pw.x < "$test_dir/scf_k${kpoints}.in" > "$test_dir/results/scf_k${kpoints}.out" 2>&1
  
  # Extract total energy - using more flexible pattern
  total_energy=$(grep "!\s*total energy\s*=" "$test_dir/results/scf_k${kpoints}.out" | tail -1 | awk '{print $5}')
  
  # Save to a summary file
  echo "$kpoints  $total_energy" >> "$test_dir/results/kpoints_vs_energy.dat"
  
  echo "Completed k-point mesh = $kpoints x $kpoints x 1, Total energy = $total_energy Ry"
  echo "------------------------------------"
done

echo "All calculations completed. Results saved in $test_dir/results/kpoints_vs_energy.dat"
echo "To plot the results, use the provided plot_kpoints.py script"