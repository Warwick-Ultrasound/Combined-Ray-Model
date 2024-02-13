function P = createPath(g, mat, x0, pathKey, B, flow)
    % Takes an x location that is within the bounds of the left piezo and
    % generates a ray normal to it. Then, propagates the ray through the
    % system and creates a path struct. 
    %
    % Inputs:
    %   geom: geometry array
    %   mat: materials array
    %   x0: x location of starting ray
    %   pathKey: string indicating wave modes in form [top wall, bottom
    %   wall, bottom wall, top wall]. Each can take values 'L' or 'S', and
    %   the bottom wall can also be 'N' for case where it reflects and
    %   doesn't enter.
    %   B: struct of burst with fields:
    %       t: time array
    %       y: amplitude array
    %   flow: struct of flow with fields
    %       profile: equation of flow profile
    %       v_ave: average flow velcoity
    %       N: number of points per transit
    %       n: order of turbulent profile, set to anything if not using
    %
    % Output:
    %   A path structure with fields:
    %       rays: a cell array with all of the ray structs in it.
    %       burst: the ultrasnic signal that reaches the detector.
    %       pathKey: the input pathKey.

    % pick out correct function for SS boundary
    switch mat.coupling
        case 'rigid'
            SSboundary = @SSrigid;
        case 'slip'
            SSboundary = @SSslip;
        otherwise
            error('No coupling type selected in materials struct. Valid are options are rigid or slip.' );
    end

    % will operate on burst in frequency domain => FFT
    fs = 1/(B.t(2)-B.t(1));
    freq = linspace(-fs/2, fs/2, length(B.t));
    spect = fftshift(fft(B.y));
    
    % initialise rays cell array
    if any(pathKey == 'N')
        P.rays = cell(6,1); % no bottom wall transits
    else
        P.rays = cell(8,1);
    end

    % generate ray at left piezo
    P.rays{1} = genRay(g, mat, x0);

    % propagate through wedge
    spect = transit(P.rays{1}, freq, spect);

    % refract into top wall
    [A,theta] = SSboundary(mat.transducer, mat.pipe, getAngle(P.rays{1}), B.f0, P.rays{1}.type);
    switch pathKey(1)
        case 'L'
            spect = spect*A(3);
            P.rays{2} = genArbRay(P.rays{1}.stop, theta(3), 'L', mat.pipe, g, 'pipeIntTop');
        case 'S'
            spect = spect*A(4);
            P.rays{2} = genArbRay(P.rays{1}.stop, theta(4), 'S', mat.pipe, g, 'pipeIntTop');
    end

    % propagate through top wall
    spect = transit(P.rays{2}, freq, spect);

    % refract into fluid
    [A,theta] = SLboundary(mat.pipe, mat.fluid, getAngle(P.rays{2}), B.f0, pathKey(1));
    spect = spect*A(3); % always transmitted longitudinal
    P.rays{3} = calcFluidRay(P.rays{2}.stop, theta(3), flow, g, mat, flow.n);

    % transmit through fluid
    spect = transit(P.rays{3}, freq, spect);

    % two cases now - either goes into the back wall or doesn't
    switch any(pathKey=='N')
        case 1 % no transit in back wall

            % reflect off bottom wall
            [A,theta] = LSboundary(mat.fluid, mat.pipe, theta(3), B.f0);
            spect = spect*A(1);

            % generate return ray
            P.rays{4} = calcFluidRay(P.rays{3}.stop, theta(1), flow, g, mat, flow.n);

            theta_w = theta(1); % save angle in still water

            % transmit through fluid
            spect = transit(P.rays{3}, freq, spect);

            i_ray = 5; % next ray number to insert

        case 0 % does transit through back wall

            % transmit into back wall
            [A,theta] = LSboundary(mat.fluid, mat.pipe, theta(3), B.f0);
            switch pathKey(2)
                case 'L'
                    spect = spect*A(2);
                    P.rays{4} = genArbRay(P.rays{3}.stop, theta(2), 'L', mat.pipe, g, 'pipeExtBot');
                    thetaNext = theta(2); % incidence angle for next interaction
                case 'S'
                    spect = spect*A(3);
                    P.rays{4} = genArbRay(P.rays{3}.stop, theta(3), 'S', mat.pipe, g, 'pipeExtBot');
                    thetaNext = theta(3);
            end

            % transit through wall towards outer surface
            spect = transit(P.rays{4}, freq, spect);

            % reflect from outer surface
            [A, theta] = SLboundary(mat.pipe, mat.outside, thetaNext, B.f0, P.rays{4}.type);
            switch pathKey(3)
                case 'L'
                    spect = spect*A(1);
                    P.rays{5} = genArbRay(P.rays{4}.stop, 180-theta(1), 'L', mat.pipe, g, 'pipeIntBot');
                case 'S'
                    spect = spect*A(2);
                    P.rays{5} = genArbRay(P.rays{4}.stop, 180-theta(2), 'S', mat.pipe, g, 'pipeIntBot');
            end

            % transmit through wall to inner surface
            spect = transit(P.rays{5}, freq, spect);

            % refract into fluid for upward return
            [A, theta] = SLboundary(mat.pipe, mat.fluid, getAngle(P.rays{5}), B.f0, P.rays{5}.type);
            spect = spect*A(3);
            P.rays{6} = calcFluidRay(P.rays{5}.stop, theta(3), flow, g, mat, flow.n);
            theta_w = theta(3); % save angle in stil water

            % transmit through fluid
            spect = transit(P.rays{6}, freq, spect);

            i_ray = 7; % next ray number to insert

    end

    % transmit into top wall
    [A, theta] = LSboundary(mat.fluid, mat.pipe, theta_w, B.f0);
    switch pathKey(4)
        case 'L'
            spect = spect*A(2);
            P.rays{i_ray} = genArbRay(P.rays{i_ray-1}.stop, 180-theta(2), 'L', mat.pipe, g, 'pipeExtTop');
        case 'S'
            spect = spect*A(3);
            P.rays{i_ray} = genArbRay(P.rays{i_ray-1}.stop, 180-theta(3), 'S', mat.pipe, g, 'pipeExtTop');
    end

    % transit through top wall
    spect = transit(P.rays{i_ray}, freq, spect); 
    i_ray = i_ray + 1;

    % refract into wedge
    [A, theta] = SSboundary(mat.pipe, mat.transducer, getAngle(P.rays{i_ray-1}), B.f0, P.rays{i_ray-1}.type);
    spect = spect*A(3); % always longitudinal
    P.rays{i_ray} = genArbRay(P.rays{i_ray-1}.stop, 180-theta(3), 'L', mat.transducer, g, 'piezoRight');

    % transit through wedge
    spect = transit(P.rays{i_ray}, freq, spect);

    % IFFT
    P.burst = ifft(ifftshift(spect), 'symmetric');

    % insert other params for keeping track of path
    P.time = B.t;
    P.pathKey = pathKey;
    P.x0 = x0;
