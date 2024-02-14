function spect = transit(ray, freq, spect)
    % applies the effect of transiting through whichever material it is in
    % to the burst. Includes both attenuation and propagation.

    % speed of sound
    if ray.type == "L"
        c = ray.material.clong;
    else
        c = ray.material.cshear;
    end

    % find distance travelled and transit time
    if isfield(ray, 'eq') % straight ray
        dx = ray.stop(1)-ray.start(1);
        dy = ray.stop(2)-ray.start(2);
        d = sqrt(dx^2+dy^2);
        T = d/c;
    else % curved ray - use vertical components so the distance doesn't change with flow
        y = ray.coords(:,end);
        dy = max(y)-min(y);
        cy = c*cosd(ray.theta0);
        T = dy/cy; 
    end

    % Apply attenuation
    if isfield(ray.material, 'alphaLong') % is attenuative, apply attenuation
        % attenuation increases linearly with frequency generally - good
        % approx. Find attenuation at all frequencies required
        if ray.type == "L"
            alpha0 = ray.material.alphaLong;
        else
            alpha0 = ray.material.alphaShear;
        end
        m = alpha0/ray.material.alphaf0; % gradient of line
        alpha = m*freq;

        spect = spect.*10.^(-alpha*d/20); % apply attenuation, converting from dB/m
        
    end

    % apply transit delay
    spect = spect.*exp(-1i*2*pi*freq*T);

end