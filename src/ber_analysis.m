%% Initial config
ebn0 = linspace(0, 12, 1000);

%% Telecommand
% Using BPSK modulation

% BCH channel coding
n = 63;
k = 56;
dmin = 4;

ber_uncoded = berawgn(ebn0, 'psk', 2, 'nondiff');
berBCH_ecss = bercoding(ebn0, 'block', 'hard', n, k, dmin);
berBCH_ccsds = bercoding(ebn0, 'Hamming', 'hard', n);

figure;
% Draw the BER curves
semilogy(ebn0, ber_uncoded, 'b');
hold on;
semilogy(ebn0, berBCH_ecss, 'g');
semilogy(ebn0, berBCH_ccsds, 'Color', '#FF8C00');

% Draw the required BER across
berReq = 1e-5;

berReqX = ebn0(find(ber_uncoded < berReq, 1));
semilogy([0, berReqX], [berReq, berReq], 'r--');

% Draw the lines down to the x-axis
berReqX_ccsds = ebn0(find(berBCH_ccsds < berReq, 1));
berReqX_ecss = ebn0(find(berBCH_ecss < berReq, 1));
ber_min = min(berBCH_ccsds);

semilogy([berReqX, berReqX], [berReq, ber_min], 'r--');
semilogy([berReqX_ccsds, berReqX_ccsds], [berReq, ber_min], 'r--');
semilogy([berReqX_ecss, berReqX_ecss], [berReq, ber_min], 'r--');

% Make a text box with the required Eb/N0 for each curve
annotation('textarrow', [berReqX_ecss/12, berReqX_ecss/12], [0.5, 0.6], 'String', [num2str(berReqX_ecss), ' dB'], 'Color', 'red');
annotation('textarrow', [berReqX_ccsds/12, berReqX_ccsds/12], [0.5, 0.6], 'String', [num2str(berReqX_ccsds), ' dB'], 'Color', 'red');
annotation('textarrow', [berReqX/12, berReqX/12], [0.5, 0.6], 'String', [num2str(berReqX), ' dB'], 'Color', 'red');

text(1, 1e-5, 'Desired BER (1e-5)', 'VerticalAlignment', 'bottom', 'Color', 'red');

grid on;
xlabel('Eb/N0 (dB)');
ylabel('BER');
ylim([1e-10, 1]);
title('TC BPSK Coding Schemes (Upper bounds)');
%legend('BCH Expurgated Hamming (63,56)', 'BCH Hamming (63,57)');
legend('Uncoded BPSK', 'BPSK BCH Expurgated Hamming (63,56)', 'BPSK BCH Hamming (63,57)');

%% Telemetry
% Using OQPSK modulation
n = 255;
k = 223;

ber_oqpsk = berawgn(ebn0, 'oqpsk', 'nondiff');

berRS = bercoding(ebn0, 'RS', 'hard', n, k, 'oqpsk', 'nondiff');

figure;
% Draw the BER curves
semilogy(ebn0, ber_oqpsk, 'b');
hold on;
semilogy(ebn0, berRS, 'g');

% Draw the required BER across
berReq = 1e-5;

berReqX = ebn0(find(ber_oqpsk < berReq, 1));
semilogy([0, berReqX], [berReq, berReq], 'r--');

% Draw the lines down to the x-axis
berReqX_RS = ebn0(find(berRS < berReq, 1));
ber_min = min(berRS);

semilogy([berReqX, berReqX], [berReq, ber_min], 'r--');
semilogy([berReqX_RS, berReqX_RS], [berReq, ber_min], 'r--');

% Make a text box with the required Eb/N0 for each curve
annotation('textarrow', [berReqX_RS/12, berReqX_RS/12], [0.5, 0.6], 'String', [num2str(berReqX_RS), ' dB'], 'Color', 'red');
annotation('textarrow', [berReqX/12, berReqX/12], [0.5, 0.6], 'String', [num2str(berReqX), ' dB'], 'Color', 'red');


grid on;
xlabel('Eb/N0 (dB)');
ylabel('BER');
ylim([1e-8, 1e-1]);
title('TM OQPSK Coding Schemes (Upper bounds)');
legend('Uncoded OQPSK', 'RS (255,223)');