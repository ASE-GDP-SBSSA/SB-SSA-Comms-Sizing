%{
Calculate the required Eb/N0 and estimated losses for set parameters.
%}

%% Helper function
% Find the required Eb/N0 for a given BER
function EbN0 = findEbN0(BER_target, modtype)
    EbNo_range = linspace(0, 12, 1000);
    BER = berawgn(EbNo_range, modtype, 'nondiff'); % Should probably add option for diff or other final params
    EbN0 = EbNo_range(find(BER < BER_target, 1));
end

%% Set parameters
c = physconst('LightSpeed');

BER = 1e-5; % Bit error rate we want to achieve
path_length = 1.83e6; % Path length in meters
f = 2.245e9; % Frequency in Hz
T = 20.0; % Temperature in Celsius
P_atm = 101.325e3; % Atmospheric pressure in Pa
rho_wv = 7.5; % Water vapor density in g/m^3
elev = 15; % Elevation angle in degrees
rr = 3; % Rain rate in mm/hr

% Modulation
modtype = 'oqpsk';

%% Calculate required Eb/N0
EbN0 = findEbN0(BER, modtype);
disp(['Required Eb/N0: ', num2str(EbN0), ' dB']);

%% Calculate estimated losses
% Free space loss
lambda = c / f;
L_fs = fspl(path_length, lambda);
disp(['Free space loss: ', num2str(L_fs), ' dB']);

% Atmospheric loss
L_atm = gaspl(path_length, f, T, P_atm, rho_wv);
disp(['Atmospheric loss: ', num2str(L_atm), ' dB']);

% Rain loss
L_rain = rainpl(path_length, f, rr, elev);
disp(['Rain loss: ', num2str(L_rain), ' dB']);

% Total atmospheric losses
disp(['Total atmospheric losses: ', num2str(L_atm + L_rain), ' dB']);