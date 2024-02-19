function [x0, dtheta, A] = genBeam(g, mat, B, Np, Nfan)
    % Gives the x coordinates, deflection angles and amplitudes of a beam
    % calculated from a huygens model of the piezo.

    rp = 100E-3; % distance between sources and calculation path (far field)
    theta_step = 0.1; % angular step size
    Lp = sqrt(diff(g.piezoLeftBounds.x)^2 + diff(g.piezoLeftBounds.y)^2); % piezo length

    % calculate max angle beam goes out to
    A0 = Huygens(g, mat, B, 0, -rp); % straight under rightmost edge at rp
    A = A0; % initialise variable to change
    thetaMax = 0;
    while A > 0.25*A0 % keep going until amplitude drops by 75%
        thetaMax = thetaMax + theta_step;
        A = Huygens(g, mat, B, rp*sind(thetaMax), -rp*cosd(thetaMax));
    end

    % --- generate (x,y) coords for Huygens model ---
    x0 = linspace(g.piezoLeftBounds.x(1), g.piezoLeftBounds.x(2), Np);
    x0 = repelem(x0, Nfan);
    dtheta = linspace(-thetaMax, thetaMax, Nfan);
    dtheta = repmat(dtheta, 1, Np);
    A = ones(size(dtheta));

end
function A = Huygens(g, mat, B, x, y)
    % Uses a simple Huygens model to calculate the amplitude at a single
    % point a (x,y). The piezo right edge is located at x=0 and the piezo
    % sits along y=0.

    Ns = 25; % Number of sources along piezo length
    Lp = sqrt(diff(g.piezoLeftBounds.x)^2 + diff(g.piezoLeftBounds.y)^2); % piezo length
    xs = linspace(-Lp, 0, Ns); % source x locations
    A = 0; % amplitude
    k = 2*pi*B.f0/mat.transducer.clong; % wavenumber in transducer
    for ii = 1:Ns
        dx = x - xs(ii);
        dy = y;
        d = sqrt(dx^2 + dy^2); % source - receiver dist
        A = A + 1/sqrt(d)*sin(k*d);
    end
    A = abs(A); % max value in time
end