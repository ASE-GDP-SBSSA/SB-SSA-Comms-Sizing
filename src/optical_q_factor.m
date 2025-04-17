%{
Finding the Q factor given a BER and the subsequent required power.
%}

%% Helper Functions
function Q = findQFactor(BER)
    Q = sqrt(2) * erfcinv(BER/0.5);
end

function BER = findBER(Q)
    BER = 0.5 * erfc(Q/sqrt(2));
end

function Q = findQFactorFromPower(P, P_Q2, n)
    Q = 2 * (P/P_Q2).^(1/n);
end

function P_b = findRSCodedBER(n, m, t, BER_uncoded)
    M = 2; % OOK
    h = m / log2(M);
    %P_s = 1 - (1 - BER_uncoded)^h;
    P_s = BER_uncoded;

    P_b = (1/m) * (1/n);

    to_sum = 0;
    for ell = t+1:n
        to_sum = to_sum + nchoosek(n, ell) * P_s^ell * (1 - P_s)^(n-ell);
    end

    P_b = P_b * to_sum;
end

%% Configuration
BER_req = 1e-5;
P_Q2 = 28*10^-9; % W (28 nW), power required for Q=2
n_exp = 0.57;

warning('off', 'all');

%% Find power required across BER range
P_dBm_range = linspace(-50, -35, 1000);
P_range = 10.^(P_dBm_range/10) * 10^-3; % Convert to W

Q_range = findQFactorFromPower(P_range, P_Q2, n_exp);
BER_range = findBER(Q_range);

% Find power required for desired BER
Q_req = findQFactor(BER_req);
P_req = P_Q2 * (Q_req/2)^n_exp;
P_req_dBm = 10*log10(P_req*10^3);

%% Find power required for RS coded BER
n = 255;
k = 223;
d_min = n - k + 1;
t = 0.5 * (d_min - 1);

BER_coded_range = zeros(size(BER_range));

for i = 1:length(BER_range)
    disp(['Calculating RS coded BER for BER = ', num2str(BER_range(i))]);
    BER_coded_range(i) = findRSCodedBER(n, k, t, BER_range(i));
end

% Find power required for desired BER
P_req_dBm_coded = P_dBm_range(find(BER_coded_range < BER_req, 1));

%% Display results
disp(['Required power for BER = ', num2str(BER_req), ' w/o coding: ', num2str(P_req_dBm), ' dBm']);
disp(['Required power for BER = ', num2str(BER_req), ' w/ RS coding: ', num2str(P_req_dBm_coded), ' dBm']);

%% Plot
figure;
semilogy(P_dBm_range, BER_range, 'b-','LineWidth',2);
hold on;
semilogy(P_dBm_range, BER_coded_range, 'g-','LineWidth',2);

% Draw a line across for the required BER
semilogy([P_dBm_range(1), P_req_dBm], [BER_req, BER_req], 'r--');
semilogy([P_req_dBm, P_req_dBm], [1e-10, BER_req], 'r--');
semilogy([P_req_dBm_coded, P_req_dBm_coded], [1e-10, BER_req], 'r--');

grid on;
xlabel('Power (dBm)');
ylabel('BER');
ylim([1e-9, 1]);
title('BER vs. Required Power for O3K');
legend('O3K Uncoded', 'O3K RS(255,223)');


