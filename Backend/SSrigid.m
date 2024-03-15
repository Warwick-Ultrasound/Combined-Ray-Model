% A function which calculates amplitudes for a longitudinal wave approaching 
% a solid-solid boundary. This function is based on the maths on p. 71 of
% JL Rose "Ultrasonic Guided Waves in Solid Media".
function [A, theta] = SSrigid(m1, m2, theta0, f, inType)
    % A function which calculates the amplitudes and angles of the
    % reflected and transmitted waves when a ray of amplitude 
    % 1 is incident on a solid-solid boundary. 
    % 
    % The inputs are:
    % m1: A struct representing the material the ray is originating from
    % within. It should have fields clong, cshear, rho, and G which are the
    % longituinal velocity, shear velocity, density and shear modulus respectively.
    % m2: Another struct, the same as m1, but for the other material.
    % theta0: the angle of incidence.
    % f: the frequency of the incident wave in Hz.
    %
    % The output is two arrays:
    % A: the amplitudes.
    % theta: the angles of reflection/refraction
    % both have 4 elements correspoding to (in order):
    %   Reflected longitudinal
    %   Reflected shear
    %   Transmitted longitudinal
    %   Transmitted shear
    % inType: "long" or "shear" corresponding to the incident wave type

    % calculate angular frequency
    w = 2*pi*f;

    % calculate wavenumbers
    if inType == "L"
        k0 = w/m1.clong;
    else
        k0 = w/m1.cshear;
    end
    k1L = w/m1.clong; % reflected longitudinal
    k1T = w/m1.cshear; % reflected shear
    k2L = w/m2.clong; % reflected longitudinal
    k2T = w/m2.cshear; % reflected shear

    % rename some variables to look like the book
    mu1 = m1.G; % shear modulus
    mu2 = m2.G; % shear modulus
    rho1 = m1.rho; % density
    rho2 = m2.rho; % density
    c1L = m1.clong;
    c1T = m1.cshear;
    c2L = m2.clong;
    c2T = m2.cshear;

    % calculate angles
    alphaL = asind(k0/k1L*sind(theta0));
    alphaT = asind(k0/k1T*sind(theta0));
    betaL = asind(k0/k2L*sind(theta0));
    betaT = asind(k0/k2T*sind(theta0));
    theta = [alphaL, alphaT, betaL, betaT]; 

    % create big matrix
    M = [-cosd(alphaL),                     sind(alphaT),               -cosd(betaL),                    sind(betaT);
         -sind(alphaL),                     -cosd(alphaT),              sind(betaL),                     cosd(betaT);
         -k1L*rho1*c1L^2*cosd(2*alphaT),    k1T*mu1*sind(2*alphaT),     k2L*rho2*c2L^2*cosd(2*betaT),    -k2T*mu2*sind(2*betaT);
         -k1L*mu1*sind(2*alphaL),           -k1T*mu1*cosd(2*alphaT),    -k2L*mu2*sind(2*betaL),          -k2T*mu2*cosd(2*betaT)];

    % create other matrix
    if inType == "L" % NOTE: book has mistake for these: still using old notation from old version but have changed meaning of alphaL and T.
        x = [-cosd(theta0), sind(theta0), k1L*rho1*c1L^2*cosd(2*alphaT), -k1L*mu1*sind(2*theta0)].';
    else
        x = [sind(theta0), cosd(theta0), -k1T*mu1*sind(2*theta0), -k1T*mu1*cosd(2*theta0)].';
    end

    % solve M*A = x for A, the array of amplitudes
    A = M\x;

    % ensure A = 0 when beyond critical angle
    A(real(theta)==90) = 0; 

end