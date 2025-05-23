#!/usr/bin/env python3

import os

import matplotlib.pyplot as plt
import numpy as np

plt.style.use("/home/rfa/SATA/Skripsi/DFT/dft-graphene/matplotlib/sci.mplstyle")


def plot_band_structure():
    # Try to read fermi energy
    try:
        with open("reference/fermi-energy.txt", "r") as f:
            efermi = float(f.read().strip())
    except (FileNotFoundError, ValueError):
        print("Warning: Couldn't read Fermi energy, setting to 0")
        efermi = 0.0

    # Load the band structure data
    bands_file = "gr-aa-2L.bands.gnu"
    if not os.path.exists(bands_file):
        print(f"Error: Band structure file '{bands_file}' not found")
        return

    data = np.loadtxt(bands_file)
    k = np.unique(data[:, 0])
    bands = np.reshape(data[:, 1], (-1, len(k)))

    # Set high-symmetry points
    # n_points = len(k)
    gG1 = k[0]
    K = k[40]
    M = k[60]
    gG2 = k[90]
    # K_idx = min(40, n_points - 1)
    # M_idx = min(60, n_points - 1)
    # gG2_idx = min(90, n_points - 1)

    # K = k[K_idx]
    # M = k[M_idx]
    # gG2 = k[gG2_idx]

    # Create plot
    plt.figure(figsize=(8, 6))

    # Plot band structure
    for band in range(len(bands)):
        plt.plot(k, bands[band, :] - efermi, c="blue", linewidth=0.8)

    # Add reference lines and labels
    plt.axhline(0, c="gray", ls=":", linewidth=0.8, label="Fermi Level")
    plt.axvline(K, c="gray", ls="--", alpha=0.5, linewidth=0.8)
    plt.axvline(M, c="gray", ls="--", alpha=0.5, linewidth=0.8)

    plt.xlim(gG1, gG2)
    plt.ylim(-20, 20)  # Adjust the energy range
    plt.xlabel("Wave Vector")
    plt.ylabel("Energy (eV)")
    plt.title("AA-stacked Bilayer Graphene Band Structure")

    # Add high-symmetry point labels
    plt.xticks([gG1, K, M, gG2], ["$\Gamma$", "K", "M", "$\Gamma$"])

    # Add a grid for better readability
    plt.grid(alpha=0.3)

    plt.tight_layout()
    plt.savefig("./reference/plot-bands.pdf", dpi=300)
    print("Band structure plot saved as plot-bands.pdf")
    plt.show()


if __name__ == "__main__":
    plot_band_structure()
