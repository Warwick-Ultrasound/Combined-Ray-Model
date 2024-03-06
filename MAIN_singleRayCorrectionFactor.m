% Just calculate a single ray path and find the FPCF to check it
% agrees with literature values

clear;
clc;
close all;

tic;

% add backend to path
addpath('Backend');

pathKey = 'LNNL'; % which path to use

% define geometry
gInp.R = 50E-3;
gInp.thick = 3E-3;
gInp.thetaT = 38;
gInp.hp = 15E-3;
gInp.Lp = 10E-3;
gInp.sep = 100E-3; % recalculate this later, just temp value to prevent an error

% define materials
run materials.m; % imports material structs
mat.pipe = PVC;
mat.transducer = PEEK;
mat.fluid = water;
mat.outside = air;
mat.coupling = 'rigid';

% calculate transducer separation
gInp.sep = transducerPositionCalc(gInp, mat, pathKey);

% ultrasonic burst parameters
t.min = -10E-6; % allows it to be centred on zero at start
t.max = 210E-6; % max travel time of signal
f0 = 1E6; % centre frequency
BW = 30; % bandwidth (% of f0) - note full window width not half-height
% calc sample rate from Nyquist
fmax = (1+BW/100)*f0;
Nyquist = 2*fmax;
fs = 40*Nyquist; % 40 x nyquist to be safe
t.dt = 1/fs;
t.len = ceil((t.max - t.min)/t.dt); % number of points in time domain

% flow profile parameters
flow.profile = @turbulent;
flow.v_ave = 1; % average flow velocity
flow.N = 2000;
flow.n = 8;

% generate burst
time = linspace(t.min, t.max, t.len);
B = genBurst(time, f0, BW);

% TTD measurement info
d_dt = 0.001E-9; % minimum TTD measurable
ts = time(2)-time(1); % sample interval
Ninterp = ceil(ts/d_dt);

% generate geometry struct
g = genGeometry(gInp);

% draw it to check
figure;
drawGeometry(g);

% ray parameters
x0 = 0; % middle of left piezo
dtheta = 0; % no beam spread
A = 1;

% ---- upstream and downstream paths ----
Pdown = createPath(g, mat, x0, pathKey, B, flow);
flow.v_ave = -flow.v_ave; % switch flow direction
Pup = createPath(g, mat, x0, pathKey, B, flow);
flow.v_ave = -flow.v_ave; % change back

% plot path on geometry figure
drawPath(Pup);

% calculate received signals
up = Pup.burst;
down = Pdown.burst;

% measure TTD using transit time difference in wedge directly for
% less computational error
lastup = Pup.rays{end};
dup = lastup.stop-lastup.start; % displacement vector in reception wedge
dup = sqrt(sum(dup.^2)); % distance
lastdown = Pdown.rays{end};
ddown = lastdown.stop-lastdown.start; % displacement vector in reception wedge
ddown = sqrt(sum(ddown.^2)); % distance
dl = abs(ddown - dup); % differenec in wedge transit due to flow
TTD = dl/mat.transducer.clong;

% plot received signals
[start, stop] = arrival_detect(up, 1);
figure;
plot(time/1E-6, up, time/1E-6, down);
xlabel('Time /\mus');
ylabel('Amplitude /arb.');
xlim(time([start,stop])/1E-6);

% calculate theoretical TTD for plug flow
theta_f = asind( mat.fluid.clong/mat.transducer.clong * sind(g.thetaT) );
theoryTTD = 4*(2*g.R)*flow.v_ave*tand(theta_f)/mat.fluid.clong^2;

toc;

% divide the two to get the correction factor required
FPCF = theoryTTD/TTD;

disp(flow);
disp("FPCF = "+string(FPCF));