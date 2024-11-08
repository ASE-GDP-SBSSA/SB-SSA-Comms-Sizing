import numpy
import matplotlib.pyplot as plt

# Define link budget parameters
frequency = 2.2 # GHz
wavelength = 0.1364
tx_power_w = 5.6 # W
tx_power = 10 * numpy.log10(tx_power_w) # dBm, convert to dBm from W

tx_antenna_gain = 0 # dBi
eirp = tx_power + tx_antenna_gain # dBW
path_length = 2.569E3 # km
space_loss = 147.55 - (20 * numpy.log10(path_length * 1000)) - (20 * numpy.log10(frequency * 10**9)) # dB
system_losses = -5 # dB

rx_antenna_gain = 40 # dBi
system_noise_temp = 250 # K
data_rate = 5e6 # 5 Mbps
eb_no = eirp + space_loss + system_losses + rx_antenna_gain + 228.6 - 10 * numpy.log10(data_rate) - 10 * numpy.log10(system_noise_temp) # dB
required_eb_no = 9.6 # dB
link_margin = eb_no - required_eb_no # dB

# Print link budget parameters
print('Frequency: {:.2e} Hz'.format(frequency))
print('Wavelength: {:.3f} m'.format(wavelength))
print('TX Power: {:.2f} dBm'.format(tx_power))
print('TX Antenna Gain: {:.2f} dBi'.format(tx_antenna_gain))
print('EIRP: {:.2f} dBW'.format(eirp))
print('Path Length: {:.2f} m'.format(path_length))
print('Space Loss: {:.2f} dB'.format(space_loss))
print('System Losses: {:.2f} dB'.format(system_losses))
print('RX Antenna Gain: {:.2f} dBi'.format(rx_antenna_gain))
print('System Noise Temperature: {:.2f} K'.format(system_noise_temp))
print('Data Rate: {:.2e} bps'.format(data_rate))
print('Eb/No: {:.2f} dB'.format(eb_no))
print('Required Eb/No: {:.2f} dB'.format(required_eb_no))
print('Link Margin: {:.2f} dB'.format(link_margin))
