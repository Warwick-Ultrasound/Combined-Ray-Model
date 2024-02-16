function ray = genRay(geom, mat, x0, varargin)
    % Takes the geometry struct from genGeometry, the materials stuct,
    % and an x coordinate for the starting point. Optionally you can also input an angle
    % at which the ray will be deflected from the normal. Generates a ray from the
    % left piezo at 90 degrees to the piezo face. The ray that is output 
    % is a struct with fields: 
    %
    % eq: the equation of the line
    % start: the starting coordinates at the left piezo
    % end: the point at which it intercepts the pipe

    % check that x0 is on the piezo
    bounds = geom.piezoLeftBounds.x;
    if ~(x0>=bounds(1) && x0<=bounds(2))
        error('Error in genRay. Starting location not on piezo');
    end

    m = -1/tand(geom.thetaT); % gradient of ray
    if ~isempty(varargin) % modify gradient to deflect ray
        d_theta = varargin{1};
        m = -1/tand(geom.thetaT+d_theta);
    end
    ray.start = [x0, geom.piezoLeft(x0)]; % starting location
    c = ray.start(2) - m*ray.start(1); % intercept of line
    ray.eq = @(x) m*x+c; % equation of ray

    % intersection point with pipe
    ray.stop = [(geom.pipeExtTop-c)/m, geom.pipeExtTop];

    % ray is travelling through transducer
    ray.material = mat.transducer;

    % type of wave
    ray.type = 'L'; % emitted from piezo

end    