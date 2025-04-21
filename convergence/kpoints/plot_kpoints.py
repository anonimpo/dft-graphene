#!/usr/bin/env python3

import argparse
import os
import sys

import matplotlib.pyplot as plt
import numpy as np


def plot_kpoints_convergence(stacking, layers, show_plot=False):
    """
    Plots k-point grid convergence data, determines optimal grid size,
    saves the plot, and optionally displays it.

    Args:
        stacking (str): Stacking type ('AA', 'AB', 'ABC', or '1L').
        layers (int): Number of layers (relevant for 'AA', 'AB', 'ABC').
        show_plot (bool, optional): Display plot interactively,/
            triggered by --show.
    """
    # Determine base directory and title prefix based on stacking/layers
    base_dir = (
        "1L" if stacking == "1L" else os.path.join(stacking, f"{layers}L")
    )
    title_prefix = (
        "Monolayer" if stacking == "1L" else f"{stacking}-stacked {layers}L"
    )
    results_dir = os.path.join(base_dir, "results")
    data_file = os.path.join(results_dir, "kpoints_vs_energy.dat")
    output_file = os.path.join(
        results_dir, f"kpoints_convergence_{stacking}_{layers}L.png"
    )
    optimal_kpoints_file = os.path.join(results_dir, "optimal_kpoints.dat")

    # Ensure results directory exists
    os.makedirs(results_dir, exist_ok=True)

    try:
        # Attempt to read data with flexible handling for inconsistent columns
        try:
            # First try standard loading
            data = np.loadtxt(data_file)
            kpoint_values = data[:, 0]
            energies = data[:, 1]
        except ValueError as e:
            # If error occurs due to inconsistent columns
            if "the number of columns changed" in str(e):
                print(
                    "Warning: Inconsistent columns detected in \
                    data file. Attempting to fix..."
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
                            kpoint = float(parts[0])
                            energy = float(parts[1])
                            valid_data.append((kpoint, energy))
                        except ValueError:
                            print(f"Skipping invalid line: {line.strip()}")

                if not valid_data:
                    print("Error: No valid data found in file.")
                    sys.exit(1)

                # Convert to numpy array
                data = np.array(valid_data)
                kpoint_values = data[:, 0]
                energies = data[:, 1]
            else:
                # If it's a different error, re-raise it
                raise

        # Calculate energy differences (convergence)
        energy_diffs = np.abs(energies - energies[-1])

        # Create figure with two subplots
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

        # Plot total energy vs. k-points
        ax1.plot(kpoint_values, energies, "o-", color="blue")
        ax1.set_xlabel("K-point Grid Size (n×n×1)")
        ax1.set_ylabel("Total Energy (Ry)")
        ax1.set_title(f"{title_prefix} Graphene: Total Energy vs. K-points")
        ax1.grid(True)

        # Plot energy difference vs. k-points (convergence)
        ax2.plot(kpoint_values, energy_diffs, "o-", color="red")
        ax2.set_xlabel("K-point Grid Size (n×n×1)")
        ax2.set_ylabel("$|E - E_{max}|$ (Ry)")
        ax2.set_title(f"{title_prefix} Graphene: Energy Convergence")
        ax2.grid(True)
        ax2.set_yscale("log")

        # Add threshold line for convergence criterion (e.g., 1 meV ~ 0.000073 Ry)
        threshold = 0.001  # 1 meV in Ry
        ax2.axhline(
            y=threshold, color="green", linestyle="--", label="1 meV threshold"
        )
        ax2.legend()

        # Determine optimal k-point grid size
        converged_indices = np.where(energy_diffs <= threshold)[0]
        if len(converged_indices) > 0:
            # Find the first index where convergence is met
            first_converged_index = converged_indices[0]
            optimal_kpoint_value = kpoint_values[first_converged_index]
            optimal_diff = energy_diffs[first_converged_index]

            # Add text annotation for optimal k-point grid
            ax2.text(
                0.95,
                0.95,
                f"Optimal K-grid ≈ {int(optimal_kpoint_value)}x{int(optimal_kpoint_value)}x1\n(diff ≈ {optimal_diff:.2e} Ry)",
                transform=ax2.transAxes,
                fontsize=9,
                verticalalignment="top",
                horizontalalignment="right",
                bbox=dict(boxstyle="round,pad=0.3", fc="wheat", alpha=0.5),
            )

            # Save the optimal k-point value (integer part)
            try:
                with open(optimal_kpoints_file, "w") as f:
                    f.write(
                        f"# Optimal K-point grid size (n) where convergence\n"
                        f"# first meets the threshold of {threshold} Ry\n"
                    )
                    f.write(f"{int(optimal_kpoint_value)}\n")
                print(
                    f"Optimal k-point grid size saved to {optimal_kpoints_file}"
                )
            except IOError as e:
                print(f"Warning: Could not write optimal k-point file: {e}")
        else:
            print(
                "Warning: Convergence threshold not met for any k-point grid size."
            )

        plt.tight_layout()
        plt.savefig(output_file)
        print(f"Plot saved to {output_file}")

        if show_plot:
            plt.show()
        else:
            plt.close(fig)  # Close the figure if not showing interactively

    except FileNotFoundError:
        print(f"Error: Data file not found at {data_file}")
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred during plotting: {e}")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Plot k-point convergence for graphene calculations.",
        formatter_class=argparse.RawTextHelpFormatter,
    )

    parser.add_argument(
        "stacking",
        nargs="?",
        default="1L",
        choices=["1L", "AA", "AB", "ABC"],
        help="Stacking type (default: 1L).",
    )
    parser.add_argument(
        "layers",
        nargs="?",
        type=int,
        default=1,
        help="Number of layers (required if stacking is not 1L, default: 1).",
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="Display the plot interactively.",
    )

    args = parser.parse_args()

    # Validate arguments
    if args.stacking == "1L":
        if args.layers != 1:
            print(
                "Warning: For stacking '1L',\
                layers is automatically set to 1."
            )
        args.layers = 1  # Ensure layers is 1 for monolayer
    elif args.layers <= 0:
        parser.error("Number of layers must be a positive integer.")
    elif args.stacking != "1L" and args.layers < 2:
        # Allow single layer specification even for AA/AB/ABC for flexibility, but warn
        print(
            f"Warning: Stacking type {args.stacking} usually implies >= 2 \
            layers, but {args.layers} was specified."
        )

    print(
        f"Processing: Stacking={args.stacking},\
        Layers={args.layers}, Show Plot={args.show}"
    )
    plot_kpoints_convergence(args.stacking, args.layers, show_plot=args.show)
# hour-spend=1/2 copy from ecut
