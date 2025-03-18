#!/bin/bash

# Check if the number of CPUs is provided.
if [ -z "$1" ]; then
  echo "Error: Number of CPUs must be specified as the first argument." >&2
  exit 1
fi

# Check if the number of CPUs is a positive integer.
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Error: Number of CPUs must be a positive integer." >&2
  exit 1
fi

cpu=$1

echo "Starting Monolayer graphene relaxation with $cpu CPUs..."

# Relaxation calculation
echo "Running relaxation calculation..."
mpirun -np $cpu pw.x < relax.in > ./reference/relax.out 2>&1

# Check if the calculation was successful
if grep -q "JOB DONE" "./reference/relax.out"; then
  echo "Relaxation calculation completed successfully!"
  
  # Extract relaxed structure
  echo "Extracting relaxed structure..."
  awk '/ATOMIC_POSITIONS/,/K_POINTS|CELL_PARAMETERS/' "./reference/relax.out" | 
    grep -v "ATOMIC_POSITIONS" | grep -v "K_POINTS" | grep -v "CELL_PARAMETERS" | 
    grep -v "^$" > "./reference/relaxed_positions.dat"
  
  # Extract relaxed cell parameters
  if grep -q "CELL_PARAMETERS" "./reference/relax.out"; then
    awk '/CELL_PARAMETERS/,/ATOMIC_POSITIONS/' "./reference/relax.out" | 
      grep -v "CELL_PARAMETERS" | grep -v "ATOMIC_POSITIONS" | 
      grep -v "^$" > "./reference/relaxed_cell.dat"
    echo "Relaxed cell parameters saved to ./reference/relaxed_cell.dat"
  fi
  
  # Extract final total energy
  final_energy=$(grep -o "total energy\s*=\s*-[0-9]\+\.[0-9]\+" "./reference/relax.out" | tail -1 | awk '{print $4}')
  echo "Final energy: $final_energy Ry"
  
  echo "Relaxed positions saved to ./reference/relaxed_positions.dat"
  echo "Now you can use these coordinates for SCF and band structure calculations."
else
  echo "Error: Relaxation calculation failed!"
  echo "Please check ./reference/relax.out for details."
  exit 1
fi
