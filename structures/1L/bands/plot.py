# Import the necessary packages and modules
import matplotlib.pyplot as plt
import numpy as np

plt.style.use("../../../matplotlib/sci.mplstyle")

# read fermi-energy.txt
try:
    efermi = np.loadtxt("./reference/fermi-energy.txt")
except FileNotFoundError:
    # Default Fermi energy - update this after first SCF calculation
    efermi = 0.0
    print("Warning: Fermi energy file not found. Using 0.0 eV as default.")

# Load data from gr-1L.bands.gnu - check both locations
band_file_paths = ["./reference/gr-1L.bands.gnu", "./gr-1L.bands.gnu"]
data = None

for path in band_file_paths:
    try:
        data = np.loadtxt(path)
        print(f"Successfully loaded band data from {path}")
        break
    except FileNotFoundError:
        continue

if data is None:
    print("Error: Band structure data file not found in any expected location.")
    print("Make sure to run the bands calculation first.")
    exit(1)

k = np.unique(data[:, 0])
bands = np.reshape(data[:, 1], (-1, len(k)))

# Set high-symmetry points from nscf.in
# Make sure the indices don't exceed array bounds
n_points = len(k)
gG1 = k[0]  # Gamma point
# Adjust indices based on actual data size
K_idx = min(40, n_points - 1)
M_idx = min(60, n_points - 1)
gG2_idx = min(90, n_points - 1)

K = k[K_idx]
M = k[M_idx]
gG2 = k[gG2_idx]

print(f"High symmetry points: Gamma={gG1}, K={K}, M={M}, Gamma2={gG2}")

# Create figure object
plt.figure(figsize=(8, 6))
# Plot dotted line at Fermi energy
plt.axhline(0, c="gray", ls=":")
# Plot dotted lines at high-symmetry points
plt.axvline(K, c="gray", ls="--", alpha=0.5)
plt.axvline(M, c="gray", ls="--", alpha=0.5)

# Plot band structure
for band in range(len(bands)):
    plt.plot(k, bands[band, :] - efermi, c="b")

# Add the x and y-axis labels
plt.xlabel("")
plt.ylabel("Energy (eV)")
# Set the axis limits
plt.xlim(gG1, gG2)
plt.ylim(-20, 20)
# Add labels for high-symmetry points
plt.xticks([gG1, K, M, gG2], ["$\Gamma$", "K", "M", "$\Gamma$"])
# Hide x-axis minor ticks
plt.tick_params(axis="x", which="minor", bottom=False, top=False)
# Add title
plt.title("Monolayer Graphene Band Structure")
# Save figure to the pdf file
plt.savefig("./reference/plot-bands.pdf")
