%{
Code originally from Matlab tutorial - "End-to-End CCSDS Telemetry Simulation with RF Impairments and Corrections":

https://uk.mathworks.com/help/satcom/ug/end-to-end-ccsds-telemetry-synchronization-and-channel-coding-simulation-with-rf-impairments-and-corrections.html
%}

modScheme = "OQPSK"; % Modulation scheme
channelCoding = "RS"; % Channel coding scheme

if channelCoding == "convolutional"
    transferFrameLength  = 892; % In bytes. 892 corresponds to 223*4
else % For RS or concatenated
    RSMessageLength      = 223;
    RSInterleavingDepth  = 4; % Any positive integer
end
rolloffFactor     = 0.35; % Root raised cosine filter roll-off factor
samplesPerSymbol  = 4; % Samples per symbol
showConstellation = true; % To improve speed of execution, disable the visualization of constellation

symbolRate             = 10000000; % Symbol rate or Baud rate in Hz
carrierFrequencyOffset = 2e5; % In Hz

EbN0 = 4:0.5:6.5;

maxNumErrors  = 100; % Simulation stops after maxNumErrors bit errors
% Set maxNumBits = 1e8 for a smoother BER curve
maxNumBits    = 1e5; % Simulation stops after processing maxNumBits
maxFramesLost = 100; % Simulation stops after maxFramesLost frames are lost

tmWaveGen = ccsdsTMWaveformGenerator( ...
    "Modulation",modScheme, ...
    "ChannelCoding",channelCoding, ...
    "RolloffFactor",rolloffFactor, ...
    "SamplesPerSymbol",samplesPerSymbol);

if channelCoding == "convolutional"
    tmWaveGen.NumBytesInTransferFrame = transferFrameLength;
else % For RS and concatenated codes
    tmWaveGen.RSMessageLength = RSMessageLength;
    tmWaveGen.RSInterleavingDepth = RSInterleavingDepth;
end
%tmWaveGen


rate = tmWaveGen.info.ActualCodeRate;
M = tmWaveGen.info.NumBitsPerSymbol;
numBitsInTF = tmWaveGen.NumInputBits;
snr = EbN0 + 10*log10(rate) + ...
    10*log10(M) - 10*log10(samplesPerSymbol); % As signal power is scaled to one while introducing noise, 
                                              % SNR value should be reduced by a factor of SPS
numSNR = length(snr);
ber = zeros(numSNR,1);                        % Initialize the BER parameter
bercalc = comm.ErrorRate; 



b = rcosdesign(rolloffFactor,tmWaveGen.FilterSpanInSymbols,samplesPerSymbol);
% |H(f)| = 1  for |f| < fN(1-alpha) - Annex 1 in Section 2.4.17A in [2]
Gain =  sum(b);
rxFilterDecimationFactor = samplesPerSymbol/2;
rxfilter = comm.RaisedCosineReceiveFilter( ...
    "DecimationFactor",rxFilterDecimationFactor, ...
    "InputSamplesPerSymbol",samplesPerSymbol, ...
    "RolloffFactor",rolloffFactor, ...
    "Gain",Gain);



phaseOffset = pi/8;
fqyoffsetobj = comm.PhaseFrequencyOffset( ...
    "FrequencyOffset",carrierFrequencyOffset, ...
    "PhaseOffset",phaseOffset, ...
    "SampleRate",samplesPerSymbol*symbolRate);
coarseFreqSync = comm.CoarseFrequencyCompensator( ...
    "Modulation",modScheme, ...
    "FrequencyResolution",100, ...
    "SampleRate",samplesPerSymbol*symbolRate);
if modScheme == "OQPSK"
    coarseFreqSync.SamplesPerSymbol = samplesPerSymbol;
end
fineFreqSync = comm.CarrierSynchronizer("DampingFactor",1/sqrt(2), ...
    "NormalizedLoopBandwidth",0.0007, ...
    "SamplesPerSymbol",samplesPerSymbol, ...
    "Modulation",modScheme);

samplerateoffsetobj = comm.SampleRateOffset;
Kp = 1/(pi*(1-((rolloffFactor^2)/4)))*cos(pi*rolloffFactor/2);
symsyncobj = comm.SymbolSynchronizer( ...
    "DampingFactor",1/sqrt(2), ...
    "DetectorGain",Kp, ...
    "TimingErrorDetector","Gardner (non-data-aided)", ...
    "Modulation","PAM/PSK/QAM", ...
    "NormalizedLoopBandwidth",0.0001, ...
    "SamplesPerSymbol",samplesPerSymbol/rxFilterDecimationFactor);
if modScheme == "OQPSK"
    symsyncobj.Modulation = "OQPSK";
end

demodobj = HelperCCSDSTMDemodulator("Modulation",modScheme,"ChannelCoding",channelCoding);
if channelCoding == "convolutional"
    decoderobj = HelperCCSDSTMDecoder("ChannelCoding",channelCoding, ...
        "NumBytesInTransferFrame",transferFrameLength, ...
        "Modulation",modScheme);
else % For RS and concatenated
    decoderobj = HelperCCSDSTMDecoder("ChannelCoding",channelCoding, ...
        "RSMessageLength",RSMessageLength, ...
        "RSInterleavingDepth",RSInterleavingDepth, ...
        "Modulation",modScheme);
end

costellationobj = comm.ConstellationDiagram;         % Default view is for QPSK
if modScheme == "BPSK"
    costellationobj.ReferenceConstellation = [1, -1];
end



numBitsForBER = 8; % For detecting which frame is synchronized
numMessagesInBlock = 2^numBitsForBER;
s = RandStream("mt19937ar","Seed",73);
for isnr = 1:numSNR
    reset(s);                            % Reset to get repeatable results
    nextSym = [];
    reset(bercalc);
    berinfo = bercalc(int8(1), int8(1)); % Initialize berinfo before BER is calculated
    tfidx = 1;
    numFramesLost = 0;
    prevdectfidx = 0;
    inputBuffer = zeros(numBitsInTF, 256,"int8");
    while((berinfo(2) < maxNumErrors) && ...
            (berinfo(3) < maxNumBits) && ...
            (numFramesLost < maxFramesLost))
        % Transmitter side processing
        bits = int8(randi(s,[0 1],numBitsInTF-numBitsForBER,1));
        % The first 8 bits correspond to the TF index modulo 256. When
        % synchronization modules are included, there can be a few frames
        % where synchronization is lost temporarily and then locks again.
        % In such cases, to calculate the BER, these 8 bits aid in
        % identifying which TF is decoded. If an error in these 8 bits
        % exists, then this error is detected by looking at the difference
        % between consecutive decoded bits. If an error is detected, then
        % that frame is considered lost. Even though the data link layer is
        % out of scope of this example, the data link layer has a similar
        % mechanism. In this example, only for calculating the BER, this
        % mechanism is adopted. The mechanism that is adopted in this
        % example is not as specified in the data link layer of the CCSDS
        % standard. And this mechanism is not specified in the physical
        % layer of the CCSDS standard.
        msg = [int2bit(mod(tfidx-1,numMessagesInBlock),numBitsForBER);bits];
        inputBuffer(:,mod(tfidx-1,numMessagesInBlock)+1) = msg;
        tx = tmWaveGen(msg);

        % Introduce RF impairments
        cfoInroduced = fqyoffsetobj(tx);                % Introduce CFO
        delayed = samplerateoffsetobj(cfoInroduced); % Introduce timing offset
        rxtemp = awgn(delayed, snr(isnr),'measured',s);  % Add AWGN

        numsym = length(cfoInroduced);
        [rx,nextSym] = buffer([nextSym;rxtemp],numsym);

        % Receiver-side processing
        coarseSynced = coarseFreqSync(rx);          % Coarse frequency synchronization
        normfSync = coarseSynced/rms(coarseSynced); % Normalize
        fineSynced = fineFreqSync(normfSync);       % Track frequency and phase
        filtered = rxfilter(fineSynced);            % Root raised cosine filter
        timeSynced = symsyncobj(filtered);          % Symbol timing synchronization
        timeSynced = timeSynced/rms(timeSynced);    % Normalize
        

        % Visualize constellation
        if showConstellation
            % Plot constellation of first 1000 symbols in a TF so
            % that variable size of fineSynced does not impede the
            % requirement of constant input size for the
            % comm.ConstellationDiagram System object.
            costellationobj(timeSynced);
        end

        demodData = demodobj(timeSynced); % Demodulate

        % Perform phase ambiguity resolution, frame synchronization, and channel decoding
        decoded = decoderobj(demodData);  

        dectfidx = bit2int(decoded(1:8),8)+1;                % See the value of first 8 bits
        % Calculate BER and adjust all buffers accordingly
        if tfidx > 30 && ~isempty(decoded) % Consider to calculate BER only after 30 TFs are processed
            
            % As the value of first 8 bits is increased by one in each
            % iteration, if the difference between the current decoded
            % decimal value of first 8 bits is not equal to the previously
            % decoded one, then it indicates a frame loss.
            if dectfidx - prevdectfidx ~= 1
                numFramesLost = numFramesLost + 1;
                disp(['Frame lost at tfidx: ' num2str(tfidx) ...
                    '. Total frames lost: ' num2str(numFramesLost)]);
            else
                berinfo = bercalc(inputBuffer(:,dectfidx),decoded);
                if nnz(inputBuffer(:,dectfidx)-decoded)
                    disp(['Errors occurred at tfidx: ' num2str(tfidx) ...
                        '. Num errors: ' num2str(nnz(inputBuffer(:,dectfidx) - decoded))])
                end
            end
        end
        prevdectfidx = mod(dectfidx,numMessagesInBlock);
        % Update tfidx
        if ~isempty(decoded)
            tfidx = tfidx + 1;
        end
    end
    fprintf("\n");
    currentBer = berinfo(1);
    ber(isnr) = currentBer;
    disp(['Eb/N0: ' num2str(EbN0(isnr)) '. BER: ' num2str(currentBer) ...
        '. Num frames lost: ' num2str(numFramesLost)]);
    
    % Reset objects
    reset(tmWaveGen);
    reset(fqyoffsetobj);
    reset(samplerateoffsetobj);
    reset(coarseFreqSync);
    reset(rxfilter);
    reset(symsyncobj);
    reset(fineFreqSync);
    reset(demodobj);
    reset(decoderobj);
end