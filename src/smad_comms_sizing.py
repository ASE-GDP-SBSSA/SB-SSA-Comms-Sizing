"""
Using SMAD (3rd edition) for downlink design as described on page 568.
"""

import numpy as np

"""
1. Select carrier frequency from ECSS-E-ST-50-05C Rev 2 (Radio frequency and modulation)
    Presume we are classified as "Space Operations" (SO)
    Therefore, only one band available to us for downlink: 2200-2290 MHz
    To note, standards say maximum bandwidth is 6 MHz and can only operate when ground station is visible. 
"""

frequency = 2245 # MHz (centre of band)

"""
2. Select transmitter power
"""

P = 20 # W (from SMAD FireSat mission), transmitter power

"""
3. Estimate RF losses between transmitter and antenna
"""

L_l = -1 # dB (from SMAD), transmitter line losses

"""
4. Determine required beamwidth for satellite antenna
"""

D_t = 0.1 # m, antenna diameter, complete guess

theta_t = 21 / (frequency * 1e-3 * D_t) # degree, beamwidth of satellite antenna

"""
5. Estimate the maximum antenna pointing offset angle
"""

e_t = 27 # degree (guess, from FireSat mission)

"""
6. Calculate transmit antenna gain
    Using eqs. 13-20 and 13-21 from SMAD
"""

G_pt = 44.3 - 10*np.log10(theta_t) # dBi, peak gain
L_pt = -12 * (e_t / theta_t)**2 # dB, pointing loss

G_t = G_pt + L_pt # dBi

"""
7. Calculate space loss
    Using eq. 13-23a from SMAD
"""

path_length = 2.569e3 # km

L_s = 147.55 - 20*np.log10(path_length) - 20*np.log10(frequency * 1e6) # dB

"""
8. Estimate propagation absorption losses due to atmosphere
"""

zenith_attenuation = 1e-2 # dB, from fig. 13-10 in SMAD
min_elevation_angle = 10 # degree

polarisation_loss = 0.3 # dB, from SMAD, accounts for mismatch between satellite and ground station polarisation
radome_loss = 1 # dB, from SMAD, accounts for losses due to using a radome

L_a = (zenith_attenuation / np.sin(min_elevation_angle)) + polarisation_loss + radome_loss # dB

"""
9. Select ground station antenna diameter and estimate pointing error
"""

D_r = 2.5 # m, antenna diameter, KSAT ground station
receiver_efficiency = 0.55
G_rp = -159.59 + 20*np.log10(D_r) + 20*np.log10(frequency * 1e6) + 20*np.log10(receiver_efficiency) # dBi, peak gain

theta_r = 21 / (frequency * 1e-3 * D_r) # degree, beamwidth of ground station antenna
e_r = 0.1 * theta_r # degree, pointing error, auto-tracking so 10% of beamwidth, from SMAD

""" 
10. Calculate receive antenna gain
"""

L_pr = -12 * (e_r / theta_r)**2 # dB, pointing loss
G_r = G_rp + L_pr # dBi

"""
11. Estimate system noise temperature
"""

T_s = 135 # K, from SMAD table 13-10

"""
12. Estimate Eb/No for required data rate
"""

R = 86e6 # bps, from SMAD
EIRP = 10*np.log10(P) + L_l + G_t # dBW

Eb_No = EIRP + L_pr + L_s + L_a + G_r + 228.6 - 10*np.log10(R) - 10*np.log10(T_s) # dB

C_No = Eb_No + 10*np.log10(R) # dB

"""
13. Get required Eb/No for desired BER for selected modulation and coding technique
"""

BER = 1e-5
Eb_No_req = 9.6 # dB, from SMAD fig. 13-9, QPSK

"""
14. Implementation losses
"""

L_im = 2 # dB, from SMAD
Eb_No_req += L_im

"""
15. Calculate link margin, rain attenuation only considered > 8 GHz
    Aiming for a margin of > 3 dB
"""

link_margin = Eb_No - Eb_No_req # dB

"""
Print results
"""

print('Frequency: {:.2f} MHz'.format(frequency))
print('Transmitter Power: {:.2f} W'.format(P))
print('    -> {:.2f} dBW'.format(10*np.log10(P)))
print('Transmitter Line Losses: {:.2f} dB'.format(L_l))
print('Transmit Antenna Beamwidth: {:.2f} degree'.format(theta_t))
print('Transmit Antenna Pointing Offset: {:.2f} degree'.format(e_t))
print('Transmit Antenna Gain (peak): {:.2f} dBi'.format(G_pt))
print('Transmit Antenna Gain (net): {:.2f} dBi'.format(G_t))
print('Space Loss: {:.2f} dB'.format(L_s))
print('Atmospheric Loss: {:.2f} dB'.format(L_a))
print('Receiver Antenna Beamwidth: {:.2f} degree'.format(theta_r))
print('Receiver Antenna Pointing Error: {:.2f} degree'.format(e_r))
print('Receiver Antenna Diameter: {:.2f} m'.format(D_r))
print('Receiver Antenna Gain (peak): {:.2f} dBi'.format(G_rp))
print('Receiver Antenna Gain: {:.2f} dBi'.format(G_r))
print('System Noise Temperature: {:.2f} K'.format(T_s))
print('Eb/No: {:.2f} dB'.format(Eb_No))
print('Required Eb/No: {:.2f} dB'.format(Eb_No_req))
print('Link Margin: {:.2f} dB'.format(link_margin))





