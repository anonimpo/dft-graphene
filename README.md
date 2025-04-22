# !!!README NOT UPDATED!!!

A collection of Quantum ESPRESSO scripts for DFT calculations of graphene structures.

## Overview

This repository contains scripts and workflows for performing Density Functional Theory (DFT) calculations on graphene systems using Quantum ESPRESSO. It supports single-layer and multi-layer graphene with various stacking configurations (AA, AB, ABC[not yet implemented])]).

## Features

- Parameter convergence testing (energy cutoff, k-points, vacuum size)
- Band structure calculations
- Support for different stacking configurations:
  - Monolayer (1L)
  - AA stacking (2-4 layers)
  - AB stacking (2-4 layers, Bernal)
  - ABC stacking (3-4 layers, rhombohedral)

## Setup

1. Initialize the environment:
   ```bash
   ./init.sh
   ```

2. Activate the Python virtual environment:
   ```bash
   source venv-dft/bin/activate
   ```

## Usage

### Convergence Testing

Run convergence tests for all parameters:
```bash
./convergence/run_convergence.sh <cpus> <stacking> <layers>
```

Example:
```bash
./convergence/run_convergence.sh 4 AA 2  # Run for AA-stacked bilayer with 4 CPUs
```

### Band Structure Calculations

Navigate to the structure directory and run the band calculation:
```bash
cd structures/1L/bands
./run.sh <cpus>
```

### Ploting

still figure it out 


## Dependencies
- Quantum ESPRESSO
- Python 3.13+
- NumPy
- Matplotlib
- SciPy

## found problem
### 1. Venv not activated

if Python is upgraded the venv link need to be updated if not it will cause error, 

solution : 
    Create a new venv-dft or copy some of file & dir from venv with the new python version, that is :

    1. files in venv/bin/python*
    2. dir in venv/lib64
    
