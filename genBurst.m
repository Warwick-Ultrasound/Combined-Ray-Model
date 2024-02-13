function B = genBurst(t, f0, BW)
    % Generates a burst on time array t with centre frequency f0 and the
    % specified percentage bandwidth (between 0 and 100). Note that
    % bandwidth isnt the half-height of the peak but the full hanning
    % window width.

    % calculate frequency axis of FFT
    fs = 1/(t(2)-t(1));
    freq = linspace(-fs/2, fs/2, length(t));

    % make the FFT of the burst
    spect = zeros(size(freq));
    [~,centre] = min(abs(freq - f0));
    df = freq(2) - freq(1);
    width = round(BW/100 * f0 / df); % width of hanning window
    start = round(centre - width/2);
    stop = start + width;
    window = hann(width);
    spect(start:stop-1) = window;

    % IFFT to get signal
    y = ifft(ifftshift(spect), 'symmetric');

    % move so that highest point is at t = 0
    [~,zero] = min(abs(t));
    B.y = circshift(y, zero);

    % fill in additional info
    B.t = t;
    B.f0 = f0;
    B.BW = BW;
end