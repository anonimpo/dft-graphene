#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
import os

def plot_band_structure():
    # Try to read fermi energy
    try:
        with open('reference/fermi-energy.txt', 'r') as f:
            efermi = float(f.read().strip())
    except (FileNotFoundError, ValueError):
        print("Warning: Couldn't read Fermi energy, setting to 0")
        efermi = 0.0
    
    # Load the band structure data
    bands_file = 'gr-aa-2L.bands.gnu'
    if not os.path.exists(bands_file):
        print(f"Error: Band structure file '{bands_file}' not found")
        return
    
    data = np.loadtxt(bands_file)
    k = np.unique(data[:, 0])
    bands = np.reshape(data[:, 1], (-1, len(k)))
    
    # Set high-symmetry points
    n_points = len(k)
    gG1 = k[0]
    K_idx = min(40, n_points-1)  # Adjust based on your specific k-path
    M_idx = min(60, n_points-1)  # Adjust based on your specific k-path
    gG2_idx = min(90, n_points-1)  # Adjust based on your specific k-path
    
    K = k[K_idx]
    M = k[M_idx]
    gG2 = k[gG2_idx]
    
    # Create plot
    plt.figure(figsize=(10, 6))
    
    # Plot band structure
    for band in range(len(bands)):
        plt.plot(k, bands[band, :] - efermi, c="blue", linewidth=0.8)
    
    # Add reference lines and labels
    plt.axhline(0, c="gray", ls=":", linewidth=0.8, label="Fermi Level")
    plt.axvline(K, c="gray", ls="--", alpha=0.5, linewidth=0.8)
    plt.axvline(M, c="gray", ls="--", alpha=0.5, linewidth=0.8)
    
    plt.xlim(gG1, gG2)
    plt.ylim(-5, 5)  # Adjust the energy range as needed
    plt.xlabel("Wave Vector")
    plt.ylabel("Energy (eV)")
    plt.title("AA-stacked Bilayer Graphene Band Structure")
    
    # Add high-symmetry point labels
    plt.xticks([gG1, K, M, gG2], ["$\Gamma$", "K", "M", "$\Gamma$"])
    
    # Add a grid for better readability
    plt.grid(alpha=0.3)
    
    plt.tight_layout()
    plt.savefig("plot-bands.pdf", dpi=300)
    print("Band structure plot saved as plot-bands.pdf")

if __name__ == "__main__":
    plot_band_structure()