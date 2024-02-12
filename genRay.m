function ray = genRay(geom, x0)
    % Takes the geometry struct from genGeometry and an x coordinate forthe
    % starting point. Generates a ray from the left piezo at 90 degrees to
    % the piezo face. The ray that is output is a struct with two fields: 
    % eq: the equation of the line
    % start: the starting coordinates at the left piezo

    % check that x0 is on the piezo
    bounds = geom.piezoLeftBounds.x;
    if ~(x0>bounds(1) && x0<bounds(2))
        error('Error in createRay. Starting location not on piezo');
    end

    m = -1/tand(geom.thetaT); % gradient of ray
    ray.start = [x0, geom.piezoLeft(x0)]; % starting location
    c = ray.start(2) - m*ray.start(1); % intercept of line
    ray.eq = @(x) m*x+c; % equation of ray

end    