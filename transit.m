function outBurst = transit(ray, time, burst)
    % applies the effect of transiting through whichever material it is in
    % to the burst. Includes both attenuation and propagation.

    % doing everything in frequency domain => take FFT
    fs = 1/(time(2)-time(1));
    freq = linspace(-fs/2, fs/2, length(time));
    spect = fftshift(fft(burst));

    % find distance travelled
    dx = ray.stop(1)-ray.start(1);
    dy = ray.stop(2)-ray.start(2);
    d = sqrt(dx^2+dy^2);
    
    % find time of transit
    if ray.type == "long"
        c = ray.material.clong;
    else
        c = ray.material.cshear;
    end
    T = d/c;

    % Apply attenuation
    if isfield(ray.material, 'alphaLong') % is attenuative, apply attenuation
        % attenuation increases linearly with frequency generally - good
        % approx. Find attenuation at all frequencies required
        if ray.type == "long"
            alpha0 = ray.material.alphaLong;
        else
            alpha0 = ray.material.alphaShear;
        end
        m = alpha0/ray.material.alphaf0; % gradient of line
        alpha = m*freq;

        spect = spect.*exp(-alpha*d); % apply attenuation
        
    end

    % apply transit delay
    spect = spect.*exp(-1i*2*pi*freq*T);

    % IFFT
    outBurst = ifft(ifftshift(spect), 'symmetric');
end