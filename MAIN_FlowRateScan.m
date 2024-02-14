% MAIN script - Tests at a variety of flow rates and reports back the
% transit time difference as a function of flow velcoity, the flow profile
% correction factor, and a breakdown of which paths the ultrasound has
% taken to reach the detector.

clear;
clc;
close all;

% add backend to path
addpath('Backend');

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
t.max = 210E-6; % max travel time of signal
t.len = 1E4; % number of points in time trace
f0 = 1E6; % centre frequency
BW = 30; % bandwidth (% of f0) - note full window width not half-height

% flow profile parameters
flow.profile = @laminar;
flow.v_ave = 0; % initial value, will cycle through v_ave_list
flow.v_ave_list = linspace(0,1,10); % list of flow rates to cycle through
flow.N = 500;
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

% cycle through flow rates
TTD = nan(size(flow.v_ave_list));
for ff = 1:length(flow.v_ave_list)
    % progress indicator
    disp(string(ff/length(flow.v_ave_list)*100)+"% done");

    % set flow rate
    flow.v_ave = flow.v_ave_list(ff);

    % create the paths
    Pdown = cell(16, Ns); % one column per source ray
    Pup = cell(size(Pdown));
    for ii = 1:Ns
        paths = genAllPaths(g, mat, x0(ii), B, flow);
        for jj = 1:16
            Pdown{jj,ii} = paths{jj};
        end
    end
    flow.v_ave = -flow.v_ave; % switch flow to other direction
    for ii = 1:Ns
        paths = genAllPaths(g, mat, x0(ii), B, flow);
        for jj = 1:16
            Pup{jj,ii} = paths{jj};
        end
    end

    % calculate received signals
    up = receivedSignal(Pup);
    down = receivedSignal(Pdown);

    % measure TTD
    TTD(ff) = flow_process_SG_filt(up, down, time, 100, 1, length(time));
    
end

% draw last calculated path 
for ii = 1:Ns
    for jj = 1:16
        path = Pup{jj,ii};
        if path.detected
            drawPath(path);
        end
    end
end

% plot last caculated pair of waveforms
figure;
plot(time/1E-6, down, time/1E-6, up);
xlabel('Time /\mus');
ylabel('Amplitude /arb.');
legend('down', 'up');

% Analyse where the contributions come from
pathAnalyser(Pup, 1);

% TTD PLOT
% calculate theoretical for plug flow
theta_f = asind( mat.fluid.clong/mat.transducer.clong * sind(g.thetaT) );
theoryTTD = 4*(2*g.R)*flow.v_ave_list*tand(theta_f)/mat.fluid.clong^2;
% plot
figure;
plot(flow.v_ave_list, TTD/1E-9, flow.v_ave_list, theoryTTD/1E-9);
xlabel('Average Flow Speed /ms^{-1}');
ylabel("Transit Time Difference /ns");
legend('Ray Model with Profile', 'Conventional Model (Plug Flow)');

% calculate hydraulic correction factor from gradients
fitRayModel = fit(flow.v_ave_list.', TTD.', 'poly1');
vals = coeffvalues(fitRayModel);
mRayModel = vals(1);
fitConvModel = fit(flow.v_ave_list.', theoryTTD.', 'poly1');
vals = coeffvalues(fitConvModel);
mConvModel = vals(1);
clear vals;
FPCF = mConvModel/mRayModel;
disp('Correction Factor is '+string(FPCF));

findfigs;