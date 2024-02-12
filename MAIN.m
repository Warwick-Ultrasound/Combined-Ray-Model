% MAIN script - initially just going to be to test everything

clear;
clc;
close all;

% define geometry
gInp.R = 50E-3;
gInp.thick = 10E-3;
gInp.thetaT = 38;
gInp.hp = 15E-3;
gInp.Lp = 10E-3;
gInp.sep = 100E-3;

% ultrasonic burst parameters
t.min = -10E-6; % allows it to be centred of zero at start
t.max = 100E-6; % max travel time of signal
t.len = 1E3; % number of points in time trace
f0 = 1E6; % centre frequency
BW = 40; % bandwidth - note full window width not half-height

% generate burst
time = linspace(t.min, t.max, t.len);
burst = genBurst(time, f0, BW);

% generate geometry struct
g = genGeometry(gInp);

% draw it to check
drawGeometry(g);

% generate a ray from the centre
ray = genRay(g, 0, burst);

% draw the ray
drawRay(ray);