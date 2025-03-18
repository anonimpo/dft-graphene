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

echo "Starting AA 4-layer graphene calculations with $cpu CPUs..."

# SCF calculation
echo "Running SCF calculation..."
mpirun -np $cpu pw.x < scf.in > ./reference/scf.out 2>&1  # Redirect stderr to stdout
grep -oP 'Fermi energy is\s+\K-?\d+\.\d+' ./reference/scf.out > ./reference/fermi-energy.txt

if [ $? -ne 0 ]; then
  echo "Error: SCF calculation failed." >&2
  exit 1
fi

# NSCF calculation
echo "Running NSCF calculation..."
mpirun -np $cpu pw.x < nscf.in > ./reference/nscf.out 2>&1
if [ $? -ne 0 ]; then
  echo "Error: NSCF calculation failed." >&2
  exit 1
fi

# Band structure calculation
echo "Running band structure calculation..."
mpirun -np $cpu bands.x < bands.in > ./reference/bands.out 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Band structure calculation failed." >&2
  exit 1
fi


echo "Band structure calculations completed successfully."

# Ask if the user wants to plot the band structure
read -p "Do you want to plot the band structure? (y/n): " plot_choice
if [ "$plot_choice" = "y" ] || [ "$plot_choice" = "Y" ]; then
  echo "Plotting the band structure..."
  python3 plot.py
  echo "Band structure plot saved as plot-bands.pdf"
  
  # Check if using Kitty terminal and display the image
  if [ "$TERM" = "xterm-kitty" ]; then
    echo "Detected Kitty terminal, displaying the plot..."
    kitty icat plot-bands.pdf
  fi
fi