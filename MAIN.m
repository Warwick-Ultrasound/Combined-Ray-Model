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
gInp.sep = 142E-3;

% define materials
run materials.m; % imports material structs
mat.pipe = PVC;
mat.transducer = PEEK;
mat.fluid = water;
mat.outside = air;
mat.coupling = 'rigid';

% ultrasonic burst parameters
t.min = -10E-6; % allows it to be centred on zero at start
t.max = 100E-6; % max travel time of signal
t.len = 1E3; % number of points in time trace
f0 = 1E6; % centre frequency
BW = 40; % bandwidth - note full window width not half-height

% flow profile parameters
flow.profile = @laminar;
flow.v_ave = 200;
flow.N = 500;
flow.n = nan;

% generate burst
time = linspace(t.min, t.max, t.len);
B = genBurst(time, f0, BW);

% generate geometry struct
g = genGeometry(gInp);

% draw it to check
drawGeometry(g);

% create the path
pathKey = 'SSLL';
P = createPath(g, mat, 0, pathKey, B, flow);

drawPath(P);
findfigs;