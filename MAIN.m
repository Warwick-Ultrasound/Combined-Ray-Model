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

% generate geometry struct
g = genGeometry(gInp);

% draw it to check
drawGeometry(g);

