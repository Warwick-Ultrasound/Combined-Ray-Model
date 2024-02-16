function [theta, A] = beamAngle(g, mat, B, Nang)
    % Uses a simple Huygens model to work out how much beam spread there is
    % coming from the piezo then returns arrays of angles and relative amplitudes
    % corresponding to all angles where A < 10% of max. Inputs are geometry 
    % struct, materials struct, then burst struct, number of angular rays to output for.

    rp = 25E-3; % distance away from edge of piezo to calculate amplitude
    A0 = Huygens(g, mat, B, rp, 0); % amplitude normal to piezo
    A = A0; % initialise so can get into while loop

    theta_step = 0.1; % angular step /deg

    % find max angle of beam 
    thetaMax = 0; % initialise varying angle
    while A > 0.1*A0
        thetaMax = thetaMax + theta_step;
        A = Huygens(g, mat, B, rp, thetaMax);
    end

    % calculate output arrays
    theta = linspace(0, thetaMax, Nang);
    A = nan(size(theta));
    for ii = 1:Nang
        A(ii) = Huygens(g, mat, B, rp, theta(ii))/A0;
    end
end
function A = Huygens(g, mat, B, rp, ang)
    % Uses a simple Huygens model to calculate the amplitude at a single
    % point a distance rp away from the edge of the piezo at an angle ang.

    Ns = 25; % Number of sources along piezo length
    Lp = sqrt(diff(g.piezoLeftBounds.x)^2 + diff(g.piezoLeftBounds.y)^2); % piezo length
    xs = linspace(-Lp, 0, Ns); % source x locations
    A = 0; % amplitude
    k = 2*pi*B.f0/mat.transducer.clong; % wavenumber in transducer
    for ii = 1:Ns
        dx = rp*sind(ang) - xs(ii);
        dy = -rp*cosd(ang);
        d = sqrt(dx^2 + dy^2); % source - receiver dist
        A = A + 1/sqrt(d)*sin(k*d);
    end
    A = abs(A); % max value in time
end