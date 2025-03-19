#!/bin/bash

#SBATCH --job-name=gr_1L_bands
#SBATCH --output=bands_%j.out
#SBATCH --error=bands_%j.err
#SBATCH --ntasks=16            # Number of MPI tasks (cores)
#SBATCH --nodes=1              # Number of nodes
#SBATCH --cpus-per-task=1      # CPU cores per MPI task
#SBATCH --time=1:00:00         # Time limit hrs:min:sec

## Required Modules (adjust based on your HPC environment)
module purge
module load intel/2024.0
module load impi/2021.11.0
module load mkl
module load materials/qe/7.2-impi
module load python/3.8  # Adjust for your HPC

## To handle memory
ulimit -l unlimited

# Set environment variables
export OMP_NUM_THREADS=1

echo "Band structure calculation job started: $(date)"
echo "Running on node: $(hostname)"
echo "Number of MPI tasks: $SLURM_NTASKS"

cd /run/media/rfa/SATA/Skripsi/DFT/Graphene-copy/structures/1L/bands

# Run just the bands calculation, bypassing SCF and NSCF
echo "Running band structure calculation..."
srun bands.x < bands.in > ./reference/bands.out 2>&1

# Check if the calculation was successful
if grep -q "JOB DONE" "./reference/bands.out"; then
  echo "Band structure calculation completed successfully!"
  
  # Automatically generate the plot
  python3 plot.py
  echo "Band structure plot saved as plot-bands.pdf"
else
  echo "Error: Band structure calculation failed!"
  echo "Please check ./reference/bands.out for details."
  exit 1
fi

echo "Job completed: $(date)"