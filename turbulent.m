function v = turbulent(r, R, v_ave, n)
    if r <= R
        v = (1-abs(r)/R).^(1/n); % correct shape, but need to scale

        x = linspace(0,R,5000);
        dx = x(2)-x(1);
        meanV = sum( ((1-abs(x)/R).^(1/n)) .* (2*pi*x*dx)); % integrates over the circle
        A = pi*R^2;
        meanV = meanV / A; % average flow velocity

        % now scale v
        v = v/meanV * v_ave; % first term is normalised, 2nd scales it be be v_ave over pipe.

    else 
        v = 0/0;
    end
end