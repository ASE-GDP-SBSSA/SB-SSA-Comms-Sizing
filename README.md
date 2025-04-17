# SB-SSA-Comms-Sizing

Initial sizing for the communications subsystem of our space-based space situational awareness mission.

## Files

- `XX_comms_sizing.py`: Used for preliminary link budget analysis
- `ber_analysis.m`: Produces plots for RF modulation and coding schemes
- `link_budget_tests.m`: Used for pulling attenuation losses from MATLAB
- `optical_terminal_tests.py`: Testing limits on buffer and interface speed (used to justify ethernet port on optical terminal and solid-state data recorder)
- `optical_q_factor.m`: Converts Q2 factor from representative optical terminal to find required power for specific BER
- `end_to_end_XX.m`: Does waveform generation and simulation for telecommand and telemetry RF links using MATLAB
