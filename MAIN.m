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
gInp.sep = 99E-3;

% Number of source rays (16 total rays possible for each 1 source ray)
Ns = 10;

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
flow.n = 7;

% generate burst
time = linspace(t.min, t.max, t.len);
B = genBurst(time, f0, BW);

% generate geometry struct
g = genGeometry(gInp);

% draw it to check
drawGeometry(g);

% generate x locations along piezo
x0 = linspace(g.piezoLeftBounds.x(1), g.piezoLeftBounds.x(2), Ns);

% create the paths
Pdown = cell(16, Ns); % one column per source ray
Pup = cell(size(Pdown));
for ii = 1:Ns
    paths = genAllPaths(g, mat, x0(ii), B, flow);
    for jj = 1:16
        Pdown{jj,ii} = paths{jj};
    end
end
flow.v_ave = -flow.v_ave;
for ii = 1:Ns
    paths = genAllPaths(g, mat, x0(ii), B, flow);
    for jj = 1:16
        Pup{jj,ii} = paths{jj};
    end
end

% draw path
for ii = 1:Ns
    for jj = 1:16
        path = Pup{jj,ii};
        if path.detected
            drawPath(path);
        end
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
pathAnalyser(Pup);

findfigs;