import matplotlib.pyplot as plt
import numpy as np

# =============================================================================
# 1. Physical Constants and Basic Parameters
# =============================================================================
hbar = 1.054571817e-34  # Planck's constant [J*s] (Reduced)
q_e = 1.602176634e-19  # Electron charge [C]
k_B = 1.380649e-23  # Boltzmann constant [J/K]
h = 2.0 * np.pi * hbar  # Planck constant [J*s]

# For demonstration purposes, we'll use arbitrary units in the Hamiltonian
# and define typical parameters for the Fermi level, temperature, etc.
mu = 0.0  # chemical potential / Fermi level (arbitrary units)
Temp = 300  # K
eta = 1e-5  # small imaginary part to avoid singularities
beta = 1.0 / (
    k_B * Temp / q_e
)  # (1/kB T) in "eV^-1" if you treat energies in eV

# =============================================================================
# 2. Define a Toy Tight-Binding Hamiltonian for the Central Region
#    (Representing 'few-layer graphene' or some region in 1D for simplicity)
# =============================================================================


def build_central_hamiltonian(n_site=10, t0=-2.7):
    """
    Build a 1D chain Hamiltonian for the central device region.
    n_site : number of sites in the central region
    t0     : nearest-neighbor hopping (analogous to typical graphene ~-2.7 eV)
    Return:
        H_c: (n_site x n_site) Hermitian matrix
    """
    H_c = np.zeros((n_site, n_site), dtype=complex)
    for i in range(n_site):
        # On-site energy = 0 for demonstration, or you can set something
        H_c[i, i] = 0.0

    # nearest neighbor hopping
    for i in range(n_site - 1):
        H_c[i, i + 1] = t0
        H_c[i + 1, i] = np.conjugate(t0)  # Hermitian
    return H_c


# =============================================================================
# 3. Define the Self-Energies for the Leads
#    (Here we use a simple wide-band approximation)
# =============================================================================


def wide_band_self_energy(gamma, n_site, edge="left"):
    """
    gamma: coupling strength (broadening) for the lead
    n_site: total sites in the central region
    edge: 'left' or 'right'
    Return:
        Sigma: Self-energy matrix for the specified lead
    """
    Sigma = np.zeros((n_site, n_site), dtype=complex)
    if edge == "left":
        # Coupled to site 0
        Sigma[0, 0] = -1j * gamma / 2.0
    else:
        # Coupled to site n_site-1
        Sigma[-1, -1] = -1j * gamma / 2.0
    return Sigma


def gamma_matrix(Sigma):
    """
    Compute Gamma = i(Sigma - Sigma^\dagger).
    """
    return 1j * (Sigma - Sigma.conjugate().T)


# =============================================================================
# 4. Retarded Green's Function
# =============================================================================


def ret_greens_function(E, H, SigmaL, SigmaR):
    """
    E: energy (float)
    H: Hamiltonian for central region (n_site x n_site)
    SigmaL: self-energy from left lead
    SigmaR: self-energy from right lead
    Return: (n_site x n_site) retarded Green's function G^r(E).
    """
    n_site = H.shape[0]
    # Construct the inverse of [E + i eta - H - SigmaL - SigmaR]
    I = np.eye(n_site, dtype=complex)
    # Add a small imaginary part eta to E to keep the matrix invertible
    energy_matrix = (E + 1j * eta) * I
    # Invert
    G_r = np.linalg.inv(energy_matrix - H - SigmaL - SigmaR)
    return G_r


# =============================================================================
# 5. Transmission Function
#    T(E) = Tr[ GammaL * G^r * GammaR * G^r^\dagger ]
# =============================================================================


def transmission(E, H, SigmaL, SigmaR):
    """
    Compute the transmission at energy E.
    """
    G_r = ret_greens_function(E, H, SigmaL, SigmaR)
    GammaL = gamma_matrix(SigmaL)
    GammaR = gamma_matrix(SigmaR)
    # Transmission
    temp = GammaL @ G_r @ GammaR @ G_r.conjugate().T
    return np.real(np.trace(temp))


# =============================================================================
# 6. Transport Integrals:
#    We compute the relevant moments of the Transmission to get
#    - Conductance G_e
#    - Seebeck coefficient S
#    - Electronic thermal conductance kappa_e
# =============================================================================


def fermi_dirac(E, mu, T):
    """
    Fermi-Dirac distribution at energy E, chemical potential mu, temperature T.
    Here we assume E, mu in eV, T in K,
    so we need k_B T in eV => k_B[T=1K] ~ 8.617e-5 eV/K
    """
    kB_eV = 8.617333262e-5  # eV/K
    return 1.0 / (1.0 + np.exp((E - mu) / (kB_eV * T)))


def dfermi_dE(E, mu, T):
    """
    Derivative of the Fermi function wrt E.
    """
    f = fermi_dirac(E, mu, T)
    return -f * (1.0 - f) / (8.617333262e-5 * T)  # derivative wrt E (in eV)


def compute_transport_coefficients(energy_grid, H, SigmaL, SigmaR, mu, T):
    """
    Integrate T(E) with the Fermi-Dirac weights to get:
      - G_e (electrical conductance)
      - S   (Seebeck)
      - k_e (electronic thermal conductivity)
    Returns: G_e, S, k_e
    """
    # Precompute T(E) on the grid
    T_of_E = np.array([transmission(E, H, SigmaL, SigmaR) for E in energy_grid])

    dfdE = np.array([dfermi_dE(E, mu, T) for E in energy_grid])
    f = np.array([fermi_dirac(E, mu, T) for E in energy_grid])

    # \mathcal{L}_0, \mathcal{L}_1, \mathcal{L}_2
    # Note: E, mu in eV => we keep that in mind for correct unit conversions
    dE = energy_grid[1] - energy_grid[0]
    L0 = np.sum(T_of_E * (-dfdE)) * dE
    L1 = np.sum((energy_grid - mu) * T_of_E * (-dfdE)) * dE
    L2 = np.sum((energy_grid - mu) ** 2 * T_of_E * (-dfdE)) * dE

    # Convert from dimensionless to appropriate units:
    #   G_e = (2q^2/h) * L0 in SI if T(E) dimension is dimensionless
    #   S   = -(1/(q T)) * L1/L0
    #   k_e = (2/hT) [L2 - (L1^2 / L0)]
    #
    # For demonstration, we'll keep it "in units of G0 = 2e^2/h" etc.

    # 2e^2/h in SI units is ~ (2 * 1.602e-19^2)/(6.626e-34) ~ 7.748e-5 S
    # If we want dimensionless, we can just keep the factor (2) for spin
    # and not do additional conversions.
    e2_over_h = (q_e**2) / h
    factor = 2.0 * e2_over_h  # spin-degeneracy factor of 2 included

    G_e = factor * L0  # Electrical conductance in [S] (if energies in J).
    # But we used energies in eV, so be cautious about a further factor ~ eV->J
    # In many tight-binding computations, you either keep everything in eV and do final conversions.
    # We'll treat L0, L1, L2 as dimensionless integrals with energy in eV, then correct with e^2/h in SI.
    # => need (1 eV) in Joules: 1 eV ~ 1.602e-19 J, so each E factor in L1, L2 is in eV => multiply by eV->J

    # Let's incorporate (eV->J) properly for L0, L1, L2:
    eV_to_J = 1.602176634e-19
    L0_SI = L0
    L1_SI = L1 * eV_to_J
    L2_SI = L2 * (eV_to_J**2)

    # Now G_e in SI
    G_e = 2.0 * e2_over_h * L0_SI

    # Seebeck coefficient [V/K]
    #   S = -(1/(q T)) (L1 / L0) in eV-based => Multiply by eV/q_e to get Volts
    #   or do it carefully with L1_SI etc.
    # We'll do an approach standard in eV units:
    #   S [V/K] = - (1/(q_e T)) * (L1_SI / (eV_to_J * L0_SI))
    #            = -( L1_SI / (q_e * T * L0_SI) )
    # But L1_SI has factor eV->J already
    S_ = -(L1_SI / (q_e * Temp * L0_SI))

    # Thermal conductance from electron part
    #   k_e = 2/h T [L2 - L1^2/L0], in typical NEGF + Landauer formalism
    # But with correct unit conversions:
    #   k_e [W/K] = 2/h * [L2_SI - (L1_SI^2 / L0_SI)] / T
    #   Then multiply by eV_to_J/h if you had raw dimensionless integrals.
    # Let's do it carefully:
    k_factor = 2.0 / h
    # h in J*s, L2_SI in J^2, so dimension of k_factor * L2_SI / T is J/s / K => W/K. Perfect.
    k_e = k_factor * (L2_SI - (L1_SI**2 / L0_SI)) / Temp

    return G_e, S_, k_e, T_of_E


# =============================================================================
# Main Program: Demonstration
# =============================================================================

