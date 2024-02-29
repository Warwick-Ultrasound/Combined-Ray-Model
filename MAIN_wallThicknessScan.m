clear;
clc;
close all;
tic;

% add backend to path
addpath('Backend');

% define materials
run materials.m; % imports material structs
mat.pipe = PVC;
mat.transducer = PEEK;
mat.fluid = water;
mat.outside = air;
mat.coupling = 'rigid';

% define geometry
gInp.R = 50E-3;
thick = linspace(0.1E-3, 5E-3, 50); % wall thicknesses to cycle through
gInp.thick = thick(1);
gInp.thetaT = 38;
gInp.hp = 15E-3;
gInp.Lp = 10E-3;
LNNLsep = transducerPositionCalc(gInp, mat, 'LNNL');
SNNSsep = transducerPositionCalc(gInp, mat, 'SNNS');
gInp.sep = LNNLsep;

% ultrasonic burst parameters
t.min = -10E-6; % allows it to be centred on zero at start
t.max = 300E-6; % max travel time of signal
f0 = 1E6; % centre frequency
BW = 30; % bandwidth (% of f0) - note full window width not half-height
% calc sample rate from Nyquist
fmax = (1+BW/100)*f0;
Nyquist = 2*fmax;
fs = 4*Nyquist; % 4 x nyquist to be safe
t.dt = 1/fs;
t.len = ceil((t.max - t.min)/t.dt); % number of points in time domain
% generate burst
time = linspace(t.min, t.max, t.len);
B = genBurst(time, f0, BW);

% timing precsion
t.ddt = 0.001E-9; % smallest change in TTD able to measure
N_interp = ceil(t.dt/t.ddt); % interpolation factor required

% Rays to simulate Parameters(16 total rays possible for each 1 source ray)
Nperp = 50; % Number of source rays perpendicular to piezo
Nang = 15; % number of rays angled at each edge of piezo for beam spread
g = genGeometry(gInp); % generate temporary geometry for calculation of rays
[x0, dtheta, A] = genBeam(g, mat, B, Nperp, Nang); % positions, deflections and amplitudes of rays

% flow profile parameters
F.profile = @laminar;
F.v_ave = 0.1;
F.N = 250;
F.n = 7;

% calculate theoretical for plug flow
theta_f = asind( mat.fluid.clong/mat.transducer.clong * sind(g.thetaT) );
theoryTTD = 4*(2*g.R)*abs(F.v_ave)*tand(theta_f)/mat.fluid.clong^2;

error = nan(size(thick));
LLpkpkSS = nan(size(thick)); % first two = position, last 2 = received wave type
LLpkpkLL = nan(size(thick));
SSpkpkSS = nan(size(thick));
SSpkpkLL = nan(size(thick));
for tt = 1:length(thick)

    % progress indicator
    disp(string((tt-1)/length(thick)*100)+"% done");

    % set flow = F
    flow = F;

    % set wall thickness
    gInp.thick = thick(tt);
    
    % ----  calculate for SS position ----
    gInp.sep = transducerPositionCalc(gInp, mat, 'SNNS');
    g = genGeometry(gInp);

    % create the paths
    Pdown = cell(16, length(x0)); % one column per source ray
    Pup = cell(size(Pdown));
    for ii = 1:length(x0)
        paths = genAllPaths(g, mat, x0(ii), B, flow, dtheta(ii), A(ii));
        for jj = 1:16
            Pdown{jj,ii} = paths{jj};
        end
    end
    flow.v_ave = -flow.v_ave; % switch flow to other direction
    for ii = 1:length(x0)
        paths = genAllPaths(g, mat, x0(ii), B, flow, dtheta(ii), A(ii));
        for jj = 1:16
            Pup{jj,ii} = paths{jj};
        end
    end

    % calculate received signals
    up = receivedSignal(Pup);
    down = receivedSignal(Pdown);

    % measure TTD
    [start, stop] = arrival_detect(up, 1); % detect location of arrival
    dtSS = flow_process_SG_filt(up, down, time, N_interp, start, stop);

    % get amplitudes of contributions in SS position
    [pathKeys, pkpk] = pathAnalyser(Pup, 0);
    SSpkpkSS(tt) = pkpk(pathKeys == 'SNNS');
    SSpkpkLL(tt) = pkpk(pathKeys == 'LNNL');

    % ---- calculate for LL position ----
    gInp.sep = transducerPositionCalc(gInp, mat, 'LNNL');
    g = genGeometry(gInp);

    % set flow = F
    flow = F;

    % create the paths
    Pdown = cell(16, length(x0)); % one column per source ray
    Pup = cell(size(Pdown));
    for ii = 1:length(x0)
        paths = genAllPaths(g, mat, x0(ii), B, flow, dtheta(ii), A(ii));
        for jj = 1:16
            Pdown{jj,ii} = paths{jj};
        end
    end
    flow.v_ave = -flow.v_ave; % switch flow to other direction
    for ii = 1:length(x0)
        paths = genAllPaths(g, mat, x0(ii), B, flow, dtheta(ii), A(ii));
        for jj = 1:16
            Pup{jj,ii} = paths{jj};
        end
    end

    % calculate received signals
    up = receivedSignal(Pup);
    down = receivedSignal(Pdown);

    % measure TTD
    [start, stop] = arrival_detect(up, 1); % detect location of arrival
    dtLL = flow_process_SG_filt(up, down, time, N_interp, start, stop);

    % calculate error
    error(tt) = (dtSS-dtLL)/dtLL;

    % get amplitudes of contributions in LL position
    [pathKeys, pkpk] = pathAnalyser(Pup, 0);
    LLpkpkSS(tt) = pkpk(pathKeys == 'SNNS');
    LLpkpkLL(tt) = pkpk(pathKeys == 'LNNL');

end

figure;
tiledlayout(3,1);
nexttile;
plot(thick/1E-3, error*100);
xlabel('Wall Thickness /mm');
ylabel('Error /%')

nexttile;
plot(thick/1E-3, LLpkpkLL, thick/1E-3, LLpkpkSS);
legend('LNNL', 'SNNS');
xlabel('Wall Thickness /mm');
ylabel('Peak to Peak Amplitude /arb.');
title('Amplitudes in LNNL position');

nexttile;
plot(thick/1E-3, SSpkpkLL, thick/1E-3, SSpkpkSS);
legend('LNNL', 'SNNS');
xlabel('Wall Thickness /mm');
ylabel('Peak to Peak Amplitude /arb.');
title('Amplitudes in SNNS position');