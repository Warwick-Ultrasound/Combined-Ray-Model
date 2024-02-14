% MAIN script - initially just going to be to test everything

clear;
clc;
close all;

% define geometry
gInp.R = 50E-3;
gInp.thick = 3E-3;
gInp.thetaT = 38;
gInp.hp = 15E-3;
gInp.Lp = 20E-3;
gInp.sep = 95E-3;

% define materials
run materials.m; % imports material structs
mat.pipe = PVC;
mat.transducer = PEEK;
mat.fluid = water;
mat.outside = air;
mat.coupling = 'rigid';

% ultrasonic burst parameters
t.min = -10E-6; % allows it to be centred on zero at start
t.max = 200E-6; % max travel time of signal
t.len = 1E4; % number of points in time trace
f0 = 1E6; % centre frequency
BW = 40; % bandwidth - note full window width not half-height

% flow profile parameters
flow.profile = @laminar;
flow.v_ave = 1;
flow.N = 1000;
flow.n = nan;

% generate burst
time = linspace(t.min, t.max, t.len);
B = genBurst(time, f0, BW);

% generate geometry struct
g = genGeometry(gInp);

% draw it to check
drawGeometry(g);

% create the paths
Pdown = genAllPaths(g, mat, 0, B, flow);
flow.v_ave = -flow.v_ave;
Pup = genAllPaths(g, mat, 0, B, flow);

% draw path
for ii = 1:length(Pup)
    path = Pup{ii};
    if path.detected
        drawPath(path);
    end
end

% calculate received signals
up = receivedSignal(Pup);
down = receivedSignal(Pdown);

% plot waveforms
figure;
plot(time/1E-6, down, time/1E-6, up);
xlabel('Time /\mus');
ylabel('Amplitude /arb.');
legend('down', 'up');

% measure TTD
TTD = flow_process_SG_filt(up, down, time, 100, 1, length(time));
disp('TTD is '+string(TTD/1E-9)+' ns');

% Analyse where the contributions come from
keys = cell(size(Pup));
pkpk = nan(size(Pup));
for ii = 1:length(Pup)
    keys{ii} = Pup{ii}.pathKey;
    pkpk(ii) = Pup{ii}.pk_pk;
end
temp = keys;
keys = categorical(keys);
keys = reordercats(keys, temp);
clear temp;
figure;
bar(keys, pkpk);
ylabel("Peak to Peak Amplitude");
xlabel("Path Taken");
title('Breakdown of Contributions from Different Paths');

findfigs;