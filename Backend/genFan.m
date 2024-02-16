function [x0, theta, A] = genFan(g, mat, B, Nperp, Nang)
    % Generates the x coordinates and angles for a fan beam coming from the
    % left piezo. Inputs:
    %   g: geometry struct
    %   mat: materials struct
    %   B: burst struct
    %   Nperp: number of perpendicular rays
    %   Nang: number of angled rays on EACH end of piezo
    %
    % returns:
    %   x0: positions of starting points
    %   theta: deflection angles
    %   A: relative amplitudes at the different angles. Assume = 1 when
    %   rays parallel.

    % Hugens model to find amplitudes and angles for fanned part of beam
    [theta_spread, A_spread] = beamAngle(g, mat, B, Nang);

    % initialise output arrays
    x0 = nan(Nperp + 2*Nang, 1);
    theta = nan(size(x0));
    A = nan(size(x0));

    % leftmost edge
    theta(1:Nang) = -flip(theta_spread);
    x0(1:Nang) = g.piezoLeftBounds.x(1)*ones(Nang, 1);
    A(1:Nang) = flip(A_spread);

    % middle part of perpendicular rays
    x0(Nang+1:Nang+Nperp) = linspace(g.piezoLeftBounds.x(1), g.piezoLeftBounds.x(2), Nperp);
    theta(Nang+1:Nang+Nperp) = zeros(Nperp, 1);
    A(Nang+1:Nang+Nperp) = ones(Nperp, 1);

    % right edge
    theta(Nang+Nperp+1:end) = theta_spread;
    x0(Nang+Nperp+1:end) = g.piezoLeftBounds.x(2)*ones(Nang, 1);
    A(Nang+Nperp+1:end) = A_spread;

end