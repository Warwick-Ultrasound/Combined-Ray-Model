% material definitions

T = 20; % temperature

% PEEK
PEEK.clong = c_PEEK(T);
PEEK.cshear = c_PEEK_shear(T);
PEEK.G = 1.52E9;
PEEK.rho = 1.285E3; 

% PVC
PVC.clong = 2352; % longitudinal speed
PVC.cshear = 1093;  % shear speed
PVC.G = 1.80E9; % shear modulus
PVC.rho = 1505;  % mass density
PVC.alphaLong = 267; % longitudinal attenuation
PVC.alphaShear = 553; % shear attenuation
PVC.alphaf0 = 1E6; % frequency at which attenuation measured

% Steel SS316
steel.clong = 5790;
steel.cshear = 3220; 
steel.G = 79.2E9;
steel.rho = 7870; 
steel.alphaLong = 8;
steel.alphaShear = 8;
steel.alphaf0 = 1E6;

% water
water.clong = c_water(20);
water.rho = 1000;