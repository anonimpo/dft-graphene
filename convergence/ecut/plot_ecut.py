#!/usr/bin/env python3

import argparse
import os
import sys

import matplotlib.pyplot as plt
import numpy as np


def plot_ecut_convergence(stacking, layers, show_plot=False):
    """
    Plots Ecut convergence data, determines optimal cutoff, saves the plot,
    and optionally displays it.

    Args:
        stacking (str): Stacking type ('AA', 'AB', 'ABC', or '1L').
        layers (int): Number of layers (relevant for 'AA', 'AB', 'ABC').
        show_plot (bool, optional): Display plot interactively, /
            triggered by --show.
    """

    base_dir = "1L" if stacking == "1L" else f"{stacking}/{layers}L"
    title_prefix = (
        "Monolayer" if stacking == "1L" else f"{stacking}-stacked {layers}L"
    )
    results_dir = os.path.join(base_dir, "results")
    data_file = os.path.join(results_dir, "ecut_vs_energy.dat")
    output_file = os.path.join(
        results_dir, f"ecut_convergence_{stacking}_{layers}L.png"
    )

    os.makedirs(results_dir, exist_ok=True)

    try:
        try:
            data = np.loadtxt(data_file)
            ecut_values = data[:, 0]
            energies = data[:, 1]
        except ValueError as e:
            if "the number of columns changed" in str(e):
                print(
                    "Warning: Inconsistent columns detected in \
                    data file. Attempting to fix..."
                )
                with open(data_file, "r") as f:
                    lines = f.readlines()

                valid_data = []
                for line in lines:
                    parts = line.strip().split()
                    if len(parts) >= 2:
                        try:
                            ecut = float(parts[0])
                            energy = float(parts[1])
                            valid_data.append((ecut, energy))
                        except ValueError:
                            print(f"Skipping invalid line: {line.strip()}")

                if not valid_data:
                    print("Error: No valid data found in file.")
                    sys.exit(1)

                data = np.array(valid_data)
                ecut_values = data[:, 0]
                energies = data[:, 1]
            else:
                raise

        energy_diffs = np.abs(energies - energies[-1])

        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

        ax1.plot(ecut_values, energies, "o-", color="blue")
        ax1.set_xlabel("Cutoff Energy (Ry)")
        ax1.set_ylabel("Total Energy (Ry)")
        ax1.set_title(f"{title_prefix} Graphene: Total Energy vs. Ecut")
        ax1.grid(True)

        ax2.plot(ecut_values, energy_diffs, "o-", color="red")
        ax2.set_xlabel("Cutoff Energy (Ry)")
        ax2.set_ylabel("$|E - E_{max}|$ (Ry)")
        ax2.set_title(f"{title_prefix} Graphene: Energy Convergence")
        ax2.grid(True)
        ax2.set_yscale("log")

        threshold = 0.001  # 1e-3 Ry = 1 meV
        ax2.axhline(
            y=threshold,
            color="green",
            linestyle="--",
            label=f"{threshold*1000:.0f} meV threshold",
        )

        if len(energy_diffs) > 1:
            diff_from_threshold = np.abs(energy_diffs[:-1] - threshold)
            closest_index = np.argmin(diff_from_threshold)
            optimal_ecut = ecut_values[closest_index]
            optimal_diff = energy_diffs[closest_index]

            ax2.text(
                0.95,
                0.95,
                f"Optimal Ecut ≈ {optimal_ecut:.0f} Ry\n(diff ≈ \
                    {optimal_diff:.2e} Ry)",
                transform=ax2.transAxes,
                fontsize=9,
                verticalalignment="top",
                horizontalalignment="right",
                bbox=dict(boxstyle="round,pad=0.3", fc="wheat", alpha=0.5),
            )

            optimal_ecut_file = os.path.join(results_dir, "optimal_ecut.dat")
            with open(optimal_ecut_file, "w") as f:  # Removed try...finally
                f.write(
                    f"# Optimal Ecut (Ry) where \
                    convergence is nearest to {threshold} Ry\n"
                )
                f.write(f"{optimal_ecut:.2f}\n")
            print(f"Optimal cutoff energy saved to {optimal_ecut_file}")

        ax2.legend()  # Add legend before saving
        plt.tight_layout()

        plt.savefig(output_file)
        print(f"Plot saved to {output_file}")
        if show_plot:
            plt.show()

        else:
            plt.close(fig)

    except FileNotFoundError:
        print(f"Error: Data file not found at {data_file}")
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred during plotting: {e}")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Plot Ecut convergence for graphene calculations.",
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

    if args.stacking == "1L":
        args.layers = 1  # Ensure layers is 1 for monolayer
    elif args.layers <= 0:
        parser.error(
            "Number of layers must be greater than 0 if stacking is not 1L."
        )
    elif args.stacking != "1L" and args.layers < 2:
        print(
            f"Warning: Stacking type {args.stacking} typically implies 2 or \
            more layers, but {args.layers} was specified."
        )

    print(
        f"Processing: Stacking={args.stacking},\
        Layers={args.layers}, Show Plot={args.show}"
    )
    plot_ecut_convergence(args.stacking, args.layers, show_plot=args.show)

# hour-spend=15
# future edit= absolute path?
