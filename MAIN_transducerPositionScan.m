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
gInp.R = 26.8E-3;
gInp.thick = 4.7E-3;
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
maxSep = max(userSeps)+20E-3;
seps = linspace(minSep, maxSep, 50); % list of transducer separations to calculate for

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
t.ddt = 0.01E-9; % smallest change in TTD able to measure
N_interp = ceil(t.dt/t.ddt); % interpolation factor required

% Rays to simulate Parameters(16 total rays possible for each 1 source ray)
Nperp = 50; % Number of source rays perpendicular to piezo
Nang = 15; % number of rays angled at each edge of piezo for beam spread
g = genGeometry(gInp); % generate temporary geometry for calculation of rays
[x0, dtheta, A] = genBeam(g, mat, B, Nperp, Nang); % positions, deflections and amplitudes of rays

% flow profile parameters
initialFlow.profile = @laminar;
initialFlow.v_ave = 1; % initial value, will cycle through v_ave_list
initialFlow.N = 250;
initialFlow.n = 7;

% measurement of incient amplitude on piezo
Nbins = 15;
Abinned = nan(length(seps), Nbins);

% calculate theoretical for plug flow
theta_f = asind( mat.fluid.clong/mat.transducer.clong * sind(g.thetaT) );
theoryTTD = 4*(2*g.R)*abs(initialFlow.v_ave)*tand(theta_f)/mat.fluid.clong^2;

% create a directory to output into
dirName = "Data\Data_"+string(datetime('now', 'Format', 'dd_MM_yy__HH_mm_ss'));
mkdir(dirName);

% cycle transducer positions
TTD = nan(length(seps),1); % one for each transducer separation
pkpk = nan(16, length(seps)); % 1 column per separation, 1 row per pathKey
FPCF = nan(length(seps),1);
pkpk_tot = nan(length(seps), 1); % total signal amplitude at each separation from summed waveforms
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
    [up, detectionPoints, Arec] = receivedSignal(Pup);
    down = receivedSignal(Pdown);

    % add to Abinned to see where energy is incident on piezo
    Abinned(ss,:) = receivedSignalHist(g, detectionPoints, Arec, Nbins);

    % measure TTD
    [start, stop] = arrival_detect(up, 1); % detect location of arrival
    [TTD(ss), pkpk_tot(ss)] = flow_process_SG_filt(up, down, time, N_interp, start, stop);

    % Analyse where the contributions come from - doesn't matter which flow
    % rate, so just do last one
    [pathKeys, pkpk(:,ss)] = pathAnalyser(Pup, 0);

    % calculate and plot signals from LNNL and LLLL paths
    LLLLsig = zeros(size(Pup{1,1}.burst));
    LNNLsig = zeros(size(LLLLsig));
    for ii = 1:size(Pup,1)
        for jj = 1:size(Pup,2)
            if Pup{ii,jj}.detected
                if Pup{ii,jj}.pathKey == "LNNL"
                    LNNLsig = LNNLsig + Pup{ii,jj}.burst;
                elseif Pup{ii,jj}.pathKey == "LLLL"
                    LLLLsig = LLLLsig + Pup{ii,jj}.burst;
                end
            end
        end
    end
    fig = figure('visible', 'off');
    plot(time(start:stop)/1E-6, LNNLsig(start:stop), time(start:stop)/1E-6, LLLLsig(start:stop));
    hold on;
    plot(time(start:stop)/1E-6, LNNLsig(start:stop)+LLLLsig(start:stop), 'k--');
    legend('LNNL', 'LLLL', 'LNNL+LLLL');
    xlabel('Time /\mus');
    ylabel('Amplitude /arb.');
    title("Separation = "+string(seps(ss)/1E-3)+" mm");
    print(dirName+'\\Sepn_'+string(seps(ss)/1E-3)+"_mm_sigBreakdown.pdf", '-dpdf', '-bestfit');
    close(fig);

    % calculate theoretical for plug flow
    FPCF(ss) = theoryTTD/TTD(ss); % linear => only need one point to find FPCF

    % plot figure and save in background
    fig = figure('visible', 'off');
    drawGeometry(g, 'off');
    drawAllPaths(Pup);
    title("Separation = "+string(seps(ss)/1E-3)+" mm");
    print(dirName+'\\Sepn_'+string(seps(ss)/1E-3)+"_mm_geom.pdf", '-dpdf', '-bestfit');
    close(fig);

    fig = figure('visible', 'off');
    plot(time(start:stop)/1E-6, up(start:stop), time(start:stop)/1E-6, down(start:stop));
    xlabel('Time /\mus');
    ylabel('Amplitude /arb.');
    title("Separation = "+string(seps(ss)/1E-3)+" mm");
    print(dirName+'\\Sepn_'+string(seps(ss)/1E-3)+"_mm_sig.pdf", '-dpdf', '-bestfit');
    close(fig);

end

% sometimes, some of the paths not possible => don't plot their distances
nonNaN = ~isnan(userSeps);
userSepsKeys = {'LNNL', 'LLLL', 'SNNS', 'SSSS'};

figure;
plot(seps/1E-3, FPCF);
xline(userSeps(nonNaN)/1E-3, 'k-', userSepsKeys(nonNaN));
xlabel("Transducer Separation /mm");
ylabel("Hydraulic Correction Factor");
print(dirName + '\FPCF.pdf', '-dpdf', '-bestfit');

figure;
bar3(seps/1E-3, pkpk.');
ylabel('Transducer Separation /mm');
xticklabels(pathKeys);
view(62,18);

% plot pk-pk of 5 largest contributors
maxpkpk = max(pkpk, [], 2);
[~,I] = maxk(maxpkpk, 5);
% if any row contains all zeros, remove it.
plotLines = pkpk(I,:);
remList = []; % list of indicies to remove
for ii = 1:length(I)
    if all(plotLines(ii,:) == 0)
        remList(end+1) = ii; % remove from I
    end
end
I(remList) = [];
plotLines = pkpk(I,:);
% plot
figure;
plot(seps/1E-3, plotLines);
hold on;
plot(seps/1E-3, pkpk_tot, 'k--');
xline(userSeps(nonNaN)/1E-3, 'k-', userSepsKeys(nonNaN));
leg = pathKeys(I);
leg(end+1) = 'Received Amplitude';
legend(leg);
xlabel('Separation /mm');
ylabel('Peak to Peak Ampltiude /arb.');
print(dirName + '\max_pkpk_top5.pdf', '-dpdf', '-bestfit');

% plot amplitude into each bin on the piezo
L = linspace(0, gInp.Lp, Nbins); % NOTE: approximate only - slight shift
figure;
surf(seps/1E-3, L/1E-3, Abinned.', 'EdgeColor', 'none');
xlabel('Separation /mm');
ylabel('Length along piezo /mm');
zlabel('Amplitude in bin /arb.');
zlim([0, max(Abinned, [], 'all')]);

% save workspace to record all params and most output numerically
save(dirName + '\workspace');

findfigs;
toc;