#!/usr/bin/env python3

import sys

import matplotlib.pyplot as plt
import numpy as np

try:
    plt.style.use("../../../matplotlib/sci.mplstyle")
except:
    pass


def plot_vacuum_convergence(stacking, layers):
    """
    Plot the energy vs. vacuum size convergence data.

    Args:
        stacking (str): Stacking type (AA, AB, ABC, 1L)
        layers (int): Number of layers
    """
    # File to read data from - handle special case for monolayer
    if stacking == "1L":
        data_file = f"1L/results/vacuum_vs_energy.dat"
        title_prefix = "Monolayer"
    else:
        data_file = f"{stacking}/{layers}L/results/vacuum_vs_energy.dat"
        title_prefix = f"{stacking}-stacked {layers}L"

    try:
        # Attempt to read data with flexible handling for inconsistent columns
        try:
            # First try standard loading
            data = np.loadtxt(data_file)
            vacuum_values = data[:, 0]
            energies = data[:, 1]
        except ValueError as e:
            # If error occurs due to inconsistent columns
            if "the number of columns changed" in str(e):
                print(
                    "Warning: Inconsistent columns detected in data file. Attempting to fix..."
                )

                # Read the file as text and process line by line
                with open(data_file, "r") as f:
                    lines = f.readlines()

                # Filter out lines that don't have both values
                valid_data = []
                for line in lines:
                    parts = line.strip().split()
                    if (
                        len(parts) >= 2
                    ):  # Only use lines with at least 2 columns
                        try:
                            vacuum = float(parts[0])
                            energy = float(parts[1])
                            valid_data.append((vacuum, energy))
                        except ValueError:
                            print(f"Skipping invalid line: {line.strip()}")

                if not valid_data:
                    print("Error: No valid data found in file.")
                    sys.exit(1)

                # Convert to numpy array
                data = np.array(valid_data)
                vacuum_values = data[:, 0]
                energies = data[:, 1]
            else:
                # If it's a different error, re-raise it
                raise

        # Calculate energy differences (convergence)
        energy_diffs = np.abs(energies - energies[-1])

        # Create figure with two subplots
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

        # Plot total energy vs. vacuum size
        ax1.plot(vacuum_values, energies, "o-", color="blue")
        ax1.set_xlabel("Vacuum Size (Å)")
        ax1.set_ylabel("Total Energy (Ry)")
        ax1.set_title(f"{title_prefix} Graphene: Total Energy vs. Vacuum Size")
        ax1.grid(True)

        # Plot energy difference vs. vacuum size (convergence)
        ax2.plot(vacuum_values, energy_diffs, "o-", color="red")
        ax2.set_xlabel("Vacuum Size (Å)")
        ax2.set_ylabel("$|E - E_{max}|$ (Ry)")
        ax2.set_title(f"{title_prefix} Graphene: Energy Convergence")
        ax2.grid(True)
        ax2.set_yscale("log")

        # Add threshold line for convergence criterion (e.g., 1 meV ~ 0.000073 Ry)
        threshold = 0.000073  # 1 meV in Ry
        ax2.axhline(
            y=threshold, color="green", linestyle="--", label="1 meV threshold"
        )
        ax2.legend()

        plt.tight_layout()
        # Use appropriate filename for monolayer vs. multilayer
        if stacking == "1L":
            output_file = "./1L/results/1L_vacuum_convergence.pdf"
        else:
            output_file = f"./{stacking}/{layers}L/results/{stacking}_{layers}L_vacuum_convergence.pdf"
        plt.savefig(output_file)
        print(f"Plot saved as {output_file}")
        plt.show()

    except FileNotFoundError:
        print(f"Error: Data file {data_file} not found.")
        sys.exit(1)


if __name__ == "__main__":
    # Check if the correct arguments are provided
    if len(sys.argv) == 1:
        # Default to monolayer if no arguments provided
        print("No arguments provided, defaulting to monolayer graphene")
        stacking = "1L"
        layers = 1
    elif len(sys.argv) == 3:
        stacking = sys.argv[1]  # 1L, AA, AB, or ABC
        layers = int(sys.argv[2])  # 1, 2, 3, or 4
    else:
        print("Usage: python plot_vacuum.py <stacking_type> <num_layers>")
        print("Examples:")
        print("  python plot_vacuum.py          # Plot monolayer (default)")
        print("  python plot_vacuum.py 1L 1     # Plot monolayer")
        print("  python plot_vacuum.py AA 2     # Plot AA-stacked bilayer")
        sys.exit(1)

    plot_vacuum_convergence(stacking, layers)
