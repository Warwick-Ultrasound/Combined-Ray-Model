% MAIN script - Scans the transducer position around where a user would put
% them for the longitudinal and shear paths. Records the amplitude from the
% different paths through the system as a function of transducer position
% and the correction factor that would be required.

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
gInp.thick = 3E-3;
gInp.thetaT = 38;
gInp.hp = 15E-3;
gInp.Lp = 10E-3;
LNNLsep = transducerPositionCalc(gInp, mat, 'LNNL');
LLLLsep = transducerPositionCalc(gInp, mat, 'LLLL');
SNNSsep = transducerPositionCalc(gInp, mat, 'SNNS');
SSSSsep = transducerPositionCalc(gInp, mat, 'SSSS');
userSeps = [LNNLsep, LLLLsep, SNNSsep, SSSSsep]; % separations that the user may select
gInp.sep = SNNSsep; % pick one that will always be non-nan for initial setup.
minSep = min(userSeps)-15E-3; % smaller than smallest user separation
maxSep = max(userSeps)+15E-3;
seps = linspace(minSep, maxSep, 300); % list of transducer separations to calculate for

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
Nperp = 100; % Number of source rays perpendicular to piezo
Nang = 25; % number of rays angled at each edge of piezo for beam spread
g = genGeometry(gInp); % generate temporary geometry for calculation of rays
[x0, dtheta, A] = genBeam(g, mat, B, Nperp, Nang); % positions, deflections and amplitudes of rays

% flow profile parameters
initialFlow.profile = @laminar;
initialFlow.v_ave = 1; % initial value, will cycle through v_ave_list
initialFlow.N = 250;
initialFlow.n = 7;

% calculate theoretical for plug flow
theta_f = asind( mat.fluid.clong/mat.transducer.clong * sind(g.thetaT) );
theoryTTD = 4*(2*g.R)*abs(initialFlow.v_ave)*tand(theta_f)/mat.fluid.clong^2;

% create a directory to output into
dirName = "Data_"+string(datetime('now', 'Format', 'dd_MM_yy__HH_mm_ss'));
mkdir(dirName);

% cycle through flow rates
TTD = nan(length(seps),1); % one for each transducer separation
pkpk = nan(16, length(seps)); % 1 column per separation, 1 row per pathKey
FPCF = nan(length(seps),1);
for ss = 1:length(seps)

    % progress indicator
    disp(string((ss-1)/length(seps)*100)+"% done");

    % reset flow struct
    flow = initialFlow;

    % generate geometry
    g = gInp;
    g.sep = seps(ss);
    g = genGeometry(g);

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
    TTD(ss) = flow_process_SG_filt(up, down, time, N_interp, start, stop);

    % Analyse where the contributions come from - doesn't matter which flow
    % rate, so just do last one

    [pathKeys, pkpk(:,ss)] = pathAnalyser(Pup, 0);

    % calculate theoretical for plug flow
    FPCF(ss) = theoryTTD/TTD(ss); % linear => only need one point to find FPCF

    % plot figure and save in background
    f = figure('visible', 'off');
    tiledlayout(2,1);
    nexttile;
    drawGeometry(g, 'off');
    drawAllPaths(Pup);
    title("Separation = "+string(seps(ss)/1E-3)+" mm");
    nexttile;
    plot(time(start:stop)/1E-6, up(start:stop), time(start:stop)/1E-6, down(start:stop));
    xlabel('Time /\mus');
    ylabel('Amplitude /arb.');
    saveas(f, dirName+'\\Sepn_'+string(seps(ss)/1E-3)+"_mm.png");

end

% % draw last calculated set of paths on top of geometry
% drawGeometry(g);
% drawAllPaths(Pup);

f = figure;
plot(seps/1E-3, FPCF);
xline(userSeps/1E-3, 'k-', {'LNNL', 'LLLL', 'SNNS', 'SSSS'});
xlabel("Transducer Separation /mm");
ylabel("Hydraulic Correction Factor");
saveas(f, dirName + '\FPCF.png');

figure;
bar3(seps/1E-3, pkpk.');
ylabel('Transducer Separation /mm');
xticklabels(pathKeys);
view(62,18);

% plot pk-pk of 5 largest contributors
maxpkpk = max(pkpk, [], 2);
[~,I] = maxk(maxpkpk, 5);
f = figure;
plot(seps/1E-3, pkpk(I,:));
xline(userSeps/1E-3, 'k-', {'LNNL', 'LLLL', 'SNNS', 'SSSS'});
legend(pathKeys(I));
xlabel('Separation /mm');
ylabel('Peak to Peak Ampltiude /arb.');
saveas(f, dirName + '\max_pkpk_top5.png');

% save workspace to record all params and most output numerically
save(dirName + '\workspace');

findfigs;
toc;