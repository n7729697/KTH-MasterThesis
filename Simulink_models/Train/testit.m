% Bandpass filter design parameters
fs = 1000;        % Sampling frequency (Hz)
fpass = [100 300]; % Passband frequencies (Hz)
fstop = [50 350]; % Stopband frequencies (Hz)
Ap = 1;           % Passband ripple (dB)
Ast = 60;         % Stopband attenuation (dB)

% Normalize frequencies
Wpass = fpass / (fs/2);
Wstop = fstop / (fs/2);

% Filter order calculation using Kaiser window method
delta_p = (10^(Ap/20) - 1) / (10^(Ap/20) + 1);
delta_s = 10^(-Ast/20);
A = -20 * log10(min(delta_p, delta_s));
if A > 50
    beta = 0.1102 * (A - 8.7);
elseif A >= 21
    beta = 0.5842 * (A - 21)^0.4 + 0.07886 * (A - 21);
else
    beta = 0;
end
N = ceil((A - 8) / (2.285 * abs(Wstop(1) - Wpass(1))));

% Design the filter
h = fir1(N, Wpass, 'bandpass', kaiser(N+1, beta));

% Plot the frequency response
freqz(h, 1, 1024, fs);
title('Bandpass Filter Frequency Response');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
