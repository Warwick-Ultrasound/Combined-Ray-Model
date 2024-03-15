% Solid - liquid boundary condition calculator. Gives the amplitudes of the
% waves in the solid and liquid. Following Rose "Ultrasonic Guided Waves in Solid Media"
function [A, theta] = LSboundary(m1, m2, theta0, f)
    % A function which calculates the amplitudes and angles of the
    % reflected and transmitted waves when a ray of amplitude 
    % 1 is incident on a solid-liquid boundary. 
    % 
    % The inputs are:
    % m1: A struct representing the material the ray is originating from
    % within. It should have fields clong, cshear, rho, and G which are the
    % longituinal velocity, shear velocity, density and shear modulus respectively.
    % m2: Another struct, the same as m1, but for the other material. Leave
    % out any shear parameters for the liquid, as it doesn't support shear.
    % theta0: the angle of incidence.
    % f: the frequency of the incident wave in Hz.
    %
    % The output is two arrays:
    % A: the amplitudes.
    % theta: the angles of reflection/refraction
    % both have 3 elements correspoding to (in order):
    %   Reflected longitudinal
    %   Transmitted longitudinal
    %   transmitted shear

    % calculate angular frequency
    w = 2*pi*f;

    % calculate wavenumbers
    k0 = w/m1.clong; % indient wavenumber
    k1L = w/m1.clong; % reflected longitudinal
    k2T = w/m2.cshear; % transmitted shear
    k2L = w/m2.clong; % transmitted longitudinal

    % rename some variables to look like the book
    mu2 = m2.G; % shear modulus
    rho1 = m1.rho; % density
    rho2 = m2.rho; % density
    c1L = m1.clong;
    c2L = m2.clong;
    c2T = m2.cshear;

    % calculate angles
    alphaL = asind(k0/k1L*sind(theta0));
    betaL = asind(k0/k2L*sind(theta0));
    betaT = asind(k0/k2T*sind(theta0));
    theta = [alphaL, betaL, betaT]; 

    M = [-cosd(alphaL),                     -cosd(betaL),                       sind(betaT);
         -k1L*rho1*c1L^2,                   k1L*rho2*c2L^2*cosd(2*betaT),       -k2T*mu2*sind(2*betaT);
         0,                                 -k2L*mu2*sind(2*betaL),             -k2T*mu2*cosd(2*betaT)];

    x = [-cosd(alphaL), k1L*rho1*c1L^2, 0].';

    % solve M*A = x for A, the array of amplitudes
    A = M\x;

    % ensure A = 0 when beyond critical angle
    A(real(theta)==90) = 0;

end
   