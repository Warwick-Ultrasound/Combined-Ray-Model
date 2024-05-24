% This script contains a faster way to obtain the amplitude plots as a
% function of transducer separation - cuts out all of the other analysis
% stuff and uses parallelisation.

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
gInp.thick = 3.0E-3;
gInp.thetaT = 38;
gInp.hp = 15E-3;
gInp.Lp = 10E-3;
LNNLsep = transducerPositionCalc(gInp, mat, 'LNNL');
LLLLsep = transducerPositionCalc(gInp, mat, 'LLLL');
SNNSsep = transducerPositionCalc(gInp, mat, 'SNNS');
SSSSsep = transducerPositionCalc(gInp, mat, 'SSSS');
if isnan(LLLLsep) % decides which signals are plotted in the breakdown plots
    plot1 = "SNNS";
    plot2 = "SSSS";
else
    plot1 = "LNNL";
    plot2 = "LLLL";
end
userSeps = [LNNLsep, LLLLsep, SNNSsep, SSSSsep]; % separations that the user may select
gInp.sep = SNNSsep; % pick one that will always be non-nan for initial setup.
minSep = min(userSeps)-15E-3; % smaller than smallest user separation
maxSep = max(userSeps)+20E-3;
seps = linspace(minSep, maxSep, 50); % list of transducer separations to calculate for --------------(50)

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
t.ddt = 0.1E-9; % smallest change in TTD able to measure
N_interp = ceil(t.dt/t.ddt); % interpolation factor required

% Rays to simulate Parameters(16 total rays possible for each 1 source ray)
Nperp = 50; % Number of source rays perpendicular to piezo --------------------------------------------(50)
Nang = 25; % number of rays angled at each edge of piezo for beam spread ------------------------------(25)
g = genGeometry(gInp); % generate temporary geometry for calculation of rays
[x0, dtheta, A] = genBeam(g, mat, B, Nperp, Nang); % positions, deflections and amplitudes of rays

% flow profile parameters - just a placeholder - doesnt affect anything
flow.profile = @laminar;
flow.v_ave = 0; % initial value, will cycle through v_ave_list
flow.N = 250;
flow.n = 7;

% create a directory to output into
dirName = "Data\Data_"+string(datetime('now', 'Format', 'dd_MM_yy__HH_mm_ss'));
mkdir(dirName);

% cycle transducer positions
pkpk = nan(16, length(seps)); % 1 column per separation, 1 row per pathKey
pkpk_tot = nan(length(seps), 1); % total signal amplitude at each separation from summed waveforms
parfor ss = 1:length(seps)

    % progress indicator
    disp(string((ss-1)/length(seps)*100)+"% done");

    % generate geometry
    g = gInp;
    g.sep = seps(ss);
    g = genGeometry(g);

    % create the paths
    Pup = cell(16, length(x0)); % one column per source ray
    for ii = 1:length(x0)
        paths = genAllPaths(g, mat, x0(ii), B, flow, dtheta(ii), A(ii));
        for jj = 1:16
            Pup{jj,ii} = paths{jj};
        end
    end

    % calculate received signals
    [up, detectionPoints, Arec] = receivedSignal(Pup);

    % peak to peak of total received signal
    pkpk_tot(ss) = max(up) - min(up);

    % Analyse where the contributions come from
    [~, pkpk(:,ss)] = pathAnalyser(Pup, 0);

    % calculate and plot signals from LNNL and LLLL paths
    LLLLsig = zeros(size(Pup{1,1}.burst));
    LNNLsig = zeros(size(LLLLsig));
    for ii = 1:size(Pup,1)
        for jj = 1:size(Pup,2)
            if Pup{ii,jj}.detected
                if Pup{ii,jj}.pathKey == plot1
                    LNNLsig = LNNLsig + Pup{ii,jj}.burst;
                elseif Pup{ii,jj}.pathKey == plot2
                    LLLLsig = LLLLsig + Pup{ii,jj}.burst;
                end
            end
        end
    end
    fig = figure('visible', 'off');
    [start, stop] = arrival_detect(up, 1);
    plot(time(start:stop)/1E-6, LNNLsig(start:stop), time(start:stop)/1E-6, LLLLsig(start:stop));
    hold on;
    plot(time(start:stop)/1E-6, LNNLsig(start:stop)+LLLLsig(start:stop), 'k--');
    legend(plot1, plot2, plot1+"+"+plot2);
    xlabel('Time /\mus');
    ylabel('Amplitude /arb.');
    title("Separation = "+string(seps(ss)/1E-3)+" mm");
    print(dirName+'\\Sepn_'+string(seps(ss)/1E-3)+"_mm_sigBreakdown.pdf", '-dpdf', '-bestfit');
    close(fig);

    % plot figure and save in background
    fig = figure('visible', 'off');
    drawGeometry(g, 'off');
    drawAllPaths(Pup);
    title("Separation = "+string(seps(ss)/1E-3)+" mm");
    print(dirName+'\\Sepn_'+string(seps(ss)/1E-3)+"_mm_geom.pdf", '-dpdf', '-bestfit');
    close(fig);

    fig = figure('visible', 'off');
    plot(time(start:stop)/1E-6, up(start:stop));
    xlabel('Time /\mus');
    ylabel('Amplitude /arb.');
    title("Separation = "+string(seps(ss)/1E-3)+" mm");
    print(dirName+'\\Sepn_'+string(seps(ss)/1E-3)+"_mm_sig.pdf", '-dpdf', '-bestfit');
    close(fig);

end

% generate pathKeys array outside of parfor
g = gInp;
g.sep = seps(1);
g = genGeometry(g);
paths = genAllPaths(g, mat, x0(1), B, flow, dtheta(1), A(1));
col = paths(:,1); % one source ray, all resultant rays. Contains all poss pathKeys
pathKeys = cell(size(col));
for ii = 1:length(col)
    pathKeys{ii} = col{ii}.pathKey;
end

% sometimes, some of the paths not possible => don't plot their distances
nonNaN = ~isnan(userSeps);
userSepsKeys = {'LNNL', 'LLLL', 'SNNS', 'SSSS'};

figure;
bar3(seps/1E-3, pkpk.');
ylabel('Transducer Separation /mm');
xticklabels(pathKeys);
view(62,18);

% plot pk-pk of 5 largest contributors
maxpkpk = max(pkpk, [], 2); % max from each path
[~,I] = maxk(maxpkpk, 5); % find 5 paths which have the largest maxima
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
leg{end+1} = 'Received Amplitude';
legend(leg);
xlabel('Separation /mm');
ylabel('Peak to Peak Ampltiude /arb.');
print(dirName + '\max_pkpk_top5.pdf', '-dpdf', '-bestfit');

% save workspace to record all params and most output numerically
save(dirName + '\workspace');

findfigs;
toc;