%{
Code originally from Matlab tutorial - "End-to-End CCSDS Telecommand Simulation with RF Impairments and Corrections":

https://uk.mathworks.com/help/satcom/ug/end-to-end-ccsds-telecommand-simulation-with-rf-impairments-and-corrections.html

%}

%% Configuration
% Samples per symbol
sps = 20; % Default value for BPSK

% Symbol rate (660k calculated from link budget sheet)
n_s = 10; % Using Rec. 2.2.8 from CCSDS 401 (2.0) B, sets symbol rates
symbolRate = 1000*2^n_s; % Smallest symbol rate that matches req. symbol rate
%disp(['Symbol rate: ', num2str(symbol_rate), ' Hz']);

cfg = ccsdsTCConfig;
cfg.ChannelCoding = "BCH";
cfg.Modulation = "BPSK";
cfg.ModulationIndex = 1.2; % Applicable with PCM/PSK/PM and PCM/PM/biphase-L. Supported range in this example is [0.2 1.5].
if strcmpi(cfg.Modulation,"PCM/PSK/PM")
    cfg.SymbolRate = symbolRate;
end
cfg.SamplesPerSymbol = sps;

% Receiver parameters
normLoopBWCarrier = 0.005;      % Normalized loop bandwidth for carrier synchronizer
normLoopBWSubcarrier = 0.00005; % Normalized loop bandwidth for subcarrier synchronizer 
normLoopBWSymbol = 0.005;       % Normalized loop bandwidth for symbol synchronizer

% Simulation parameters
numBurst = 1000; % Number of burst transmissions
EsNodB = linspace(4,12,10);%[8 8.5]; % Es/No in dB
SNRIn = EsNodB - 10*log10(sps); % SNR in dB from Es/No

%% Processing Chain
% Initialization of variables to store BER and number of CLTUs lost
bitsErr = zeros(length(SNRIn),1);
cltuErr = zeros(length(SNRIn),1);

% Square root raised cosine (SRRC) transmit and receive filter objects for BPSK
% SRRC transmit filter object
txfilter = comm.RaisedCosineTransmitFilter;
txfilter.RolloffFactor = 0.35;    % Filter rolloff
txfilter.FilterSpanInSymbols = 6; % Filter span
txfilter.OutputSamplesPerSymbol = sps;
% SRRC receive filter object
rxfilter = comm.RaisedCosineReceiveFilter;
rxfilter.RolloffFactor = 0.35;    % Filter rolloff
rxfilter.FilterSpanInSymbols = 6; % Filter span
rxfilter.DecimationFactor = 1;
rxfilter.InputSamplesPerSymbol = sps;

% Sample rate
fs = sps*symbolRate;

for iSNR = 1:length(SNRIn)
    disp(['Processing SNR: ', num2str(SNRIn(iSNR)), ' dB']);

    % Set the random number generator to default
    rng default

    % SNR value in the loop
    SNRdB = SNRIn(iSNR);

    % Initialization of error computing parameters
    totNumErrs = 0;
    numErr = 0;
    totNumBits = 0;
    cltuLost = 0;

    for iBurst = 1:numBurst
        if mod(iBurst,10) == 0
            disp(['Processing burst number: ', num2str(iBurst)]);
        end

        % Acquisition sequence with 800 octets
        acqSeqLength = 6400;
        acqBits = repmat([0;1], 0.5*acqSeqLength, 1); % Alternating ones and zeros with zero as starting bit, starting bit can be either zero or one

        % CCSDS TC Waveform for acquisition sequence
        % Maximum subcarrier frequency offset specified in CCSDS TC is
        % ±(2*1e-4)*fsc, where fsc is the subcarrier frequency
        subFreqOffset = 3.2; % Subcarrier frequency offset in Hz
        subPhaseOffset = 4;  % Subcarrier phase offset in degrees
        % Frequency offset in Hz
        % Signal modulation as per the specified scheme in CCSDS telecommmand
        % Subcarrier impairments are not applicable with BPSK and PCM/PM/biphase-L
        cfg.DataFormat = 'acquisition sequence';
        acqSymb = ccsdsTCWaveform(acqBits,cfg);
        cfg.DataFormat = 'CLTU';

        % CCSDS TC waveform for CLTU
        transferFramesLength = 640;                   % Number of octets in the transfer frame
        inBits = randi([0 1],transferFramesLength,1); % Bits in the TC transfer frame
        waveSymb = ccsdsTCWaveform(inBits,cfg);

        % CCSDS TC waveform with acquisition sequence and CLTU
        waveform = [acqSymb;waveSymb];

        % Transmit filtering for BPSK
        % Pulse shaping using SRRC filter
        data = [waveform;zeros(txfilter.FilterSpanInSymbols,1)];
        txSig = txfilter(data);
       
        % Add carrier frequency and phase offset
        freqOffset = 200000;  % Frequency offset in Hz
        phaseOffset = 20;     % Phase offset in degrees
        if fs <= (2*freqOffset)
            error('Sample rate must be greater than twice the frequency offset');
        end
        pfo = comm.PhaseFrequencyOffset('FrequencyOffset',freqOffset, ...
            'PhaseOffset',phaseOffset,'SampleRate',fs);
        txSigOffset = pfo(txSig);

        % Timing offset as an integer number of samples
        timingErr = 5;        % Timing error must be <= 0.4*sps
        delayedSig  = [zeros(timingErr,1);txSigOffset]; 

        % Pass the signal through an AWGN channel
        rxSig = awgn(complex(delayedSig),SNRdB,'measured',iBurst);

        % Coarse carrier frequency synchronization
        % Coarse carrier frequency synchronization for BPSK and PCM/PSK/biphase-L
        coarseSync = comm.CoarseFrequencyCompensator( ...
            'Modulation','BPSK','FrequencyResolution',100, ...
            'SampleRate',fs);
        
        % Compensation for coarse frequency offset
        [rxCoarse,estCoarseFreqOffset] = coarseSync(rxSig);
        
        % Receive filtering
        % SRRC receive filtering for BPSK
        rxFiltDelayed = rxfilter(rxCoarse);
        rxFilt = rxFiltDelayed(rxfilter.FilterSpanInSymbols*sps+1:end);
        
        % Fine frequency and phase correction
        fineSync = comm.CarrierSynchronizer('SamplesPerSymbol',sps, ...
            'Modulation','BPSK','NormalizedLoopBandwidth',normLoopBWCarrier);
        [rxFine,phErr] = fineSync(rxFilt);

        % Subcarrier frequency and phase correction
        rxSub = real(rxFine);

        % Timing synchronization and symbol demodulation
        timeSync = HelperCCSDSTCSymbolSynchronizer('SamplesPerSymbol',sps, ...
            'NormalizedLoopBandwidth',normLoopBWSymbol);
        [rxSym,timingErr] = timeSync(rxSub);
         
        % Search for start sequence and bit recovery
        bits = HelperCCSDSTCCLTUBitRecover(rxSym,cfg,'Error Correcting',0.8);
        bits = bits(~cellfun('isempty',bits)); % Removal of empty cell array contents
       
        % Length of transfer frames with fill bits
        if strcmpi(cfg.ChannelCoding,'BCH')
            messageLength = 56;
        else
            messageLength = 0.5*cfg.LDPCCodewordLength;
        end
        frameLength = messageLength*ceil(length(inBits)/messageLength);
        
        if (isempty(bits)) || (length(bits{1})~= frameLength) ||(length(bits)>1)
            cltuLost = cltuLost + 1;
        else
            numErr = sum(abs(double(bits{1}(1:length(inBits)))-inBits));
            totNumErrs = totNumErrs + numErr;
            totNumBits = totNumBits + length(inBits);
        end
    end
    bitsErr(iSNR) = totNumErrs/totNumBits;
    cltuErr(iSNR) = cltuLost;

    % Display of bit error rate and number of CLTUs lost
    fprintf([['\nBER with ', num2str(SNRdB+10*log10(sps)) ],' dB Es/No : %1.2e\n'],bitsErr(iSNR));
    fprintf([['\nNumber of CLTUs lost with ', num2str(SNRdB+10*log10(sps)) ],' dB Es/No : %d\n'],cltuErr(iSNR));
end

% Convert Es/No to Eb/No
N_bps = 1; % Number of bits per symbol
R_c = 1; % Code rate
EbNodB = EsNodB - 10*log10(N_bps*R_c);

% Desired BER
BER_target = 1e-5;

% Find the required Eb/N0 for a given BER
EbNo_req = EbNodB(find(bitsErr < BER_target, 1));
disp(['Required Eb/N0: ', num2str(EbNo_req), ' dB']);



%% Plot results

% Plot BER vs. Es/No
figure;
semilogy(EsNodB,bitsErr,'-','LineWidth',2);
grid on;
xlabel('Es/No (dB)');
ylabel('BER');
title('BER vs. Es/No for BPSK');

% BER vs. Eb/No
figure;
semilogy(EbNodB,bitsErr,'-','LineWidth',2);
grid on;
xlabel('Eb/No (dB)');
ylabel('BER');
title('BER vs. Eb/No for BPSK');





